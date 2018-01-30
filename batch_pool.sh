#!/bin/bash

NUMRESTARTS=10
POOLID="DebugAutoscalePool5"
JOBID="DebugAutoscaleJob5"
TASKID="DebugAutoscaleTask5"
WAIT_SECONDS=5

# https://docs.microsoft.com/en-us/cli/azure/batch/pool?view=azure-cli-latest#az_batch_pool_create

az batch pool create \
   --id ${POOLID} \
   --vm-size "Standard_F4" \
   --image '/subscriptions/8557c4b8-f939-4cca-80f5-d17b546717af/resourceGroups/Jesse/providers/Microsoft.Compute/images/vmFromImage-image' \
   --node-agent-sku-id "batch.node.ubuntu 16.04" \
   --target-low-priority-nodes ${NUMRESTARTS} \

#
#   --start-task-command-line "echo hi" \
#   --start-task-wait-for-success \

   


az batch job create --id ${JOBID} --pool-id ${POOLID}

for i in `seq 1 ${NUMRESTARTS}`; do
    az batch task create --job-id ${JOBID} --task-id ${TASKID}_${i} --command-line "/bin/bash -c 'source /home/jessedd/software/anaconda2/bin/activate hparamopt; cd /home/jessedd/projects/dan; git fetch --all; git reset --hard origin/master; python dan_sentiment.py > /home/jessedd/output_${i}.txt; scp -o StrictHostKeyChecking=no -i /home/jessedd/jesse-key-pair-uswest2.pem /home/jessedd/output_${i}.txt jessedd@52.226.68.175:/home/jessedd/azure_experiments/results/output_0${i}.txt'"
done


while true; do
    POOL_STATUS=`az batch pool show --pool-id ${POOLID} | grep allocationState\" | awk '{print $2}' | sed s/,// | sed s/\"// | sed s/\"//`
    echo ${POOL_STATUS}
    if [ "${POOL_STATUS}" == "steady" ]; then
	echo "the pool is max size, about to set resize"
	break
    else
	echo "waiting ${WAIT_SECONDS} seconds for pool to finish resizing"
	sleep ${WAIT_SECONDS}
    fi
done



# evaluation interval has to be parsable by https://github.com/gweis/isodate/blob/master/src/isodate/isoduration.py, with minimum time as 5 min.
az batch pool autoscale enable \
   --pool-id ${POOLID} \
   --auto-scale-evaluation-interval 'P00Y00M00DT00H05M00S' \
   --auto-scale-formula '$averageActiveTaskCount = avg($ActiveTasks.GetSample(TimeInterval_Minute * 1));$TargetLowPriorityNodes = min(${NUMRESTARTS}, $averageActiveTaskCount);'


exit
