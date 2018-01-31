#!/bin/bash

# job specifications
SRCH_TPE="bayes_opt"
ITERS=2
BATCH_SIZE=1
SPACE="dropl2learn_bad_lr"


PROJECT_NAME="${SRCH_TPE}__${SPACE}"
EXPERIMENT_NUM=1

NUMRESTARTS=3
POOLID="${PROJECT_NAME}Pool${EXPERIMENT_NUM}"
JOBID="${PROJECT_NAME}Job${EXPERIMENT_NUM}"
TASKID="${PROJECT_NAME}Task${EXPERIMENT_NUM}"
WAIT_SECONDS=5


# docs: https://docs.microsoft.com/en-us/cli/azure/batch/pool?view=azure-cli-latest#az_batch_pool_create
az batch pool create \
   --id ${POOLID} \
   --vm-size "Standard_F4" \
   --image '/subscriptions/8557c4b8-f939-4cca-80f5-d17b546717af/resourceGroups/Jesse/providers/Microsoft.Compute/images/vm_for_batch_node' \
   --node-agent-sku-id "batch.node.ubuntu 16.04" \
   --target-low-priority-nodes ${NUMRESTARTS}


   
CUR_IP=`az network public-ip show --resource-group Jesse --name JesseHeadNode1-ip | grep ipAddress | awk '{print $2}' | sed s/\"// | sed s/\"// | sed s/,//`


az batch job create --id ${JOBID} --pool-id ${POOLID}

for i in `seq 1 ${NUMRESTARTS}`; do


    COMMANDS=""
    COMMANDS="${COMMANDS} source /home/jessedd/software/anaconda2/bin/activate hparamopt;"
    COMMANDS="${COMMANDS} cd /home/jessedd/projects/hyperopt;"
    COMMANDS="${COMMANDS} git fetch;"
    COMMANDS="${COMMANDS} git reset --hard origin/master;"
    COMMANDS="${COMMANDS} cd /home/jessedd/projects/dpp_mixed_mcmc;"
    COMMANDS="${COMMANDS} git fetch;"
    COMMANDS="${COMMANDS} git reset --hard origin/master;"
    COMMANDS="${COMMANDS} cd /home/jessedd/projects/ARKcat/src/train_and_eval;"
    COMMANDS="${COMMANDS} git fetch;"
    COMMANDS="${COMMANDS} git reset --hard origin/master;"
    COMMANDS="${COMMANDS} bash azure.sh ${SRCH_TPE} 0${i} ${CUR_IP} ${ITERS} ${BATCH_SIZE} ${SPACE};"

    az batch task create --job-id ${JOBID} --task-id ${TASKID}_${i} --command-line "/bin/bash -c '${COMMANDS}'"



done


#while true; do
#    POOL_STATUS=`az batch pool show --pool-id ${POOLID} | grep allocationState\" | awk '{print $2}' | sed s/,// | sed s/\"// | sed s/\"//`
#    echo "current status of allocationState: ${POOL_STATUS}"
#    if [ "${POOL_STATUS}" == "steady" ]; then
#	echo "the pool is now steady (not resizing), about to set autoscale"
#	break
#    else
#	echo "waiting ${WAIT_SECONDS} seconds for pool to finish resizing"
#	sleep ${WAIT_SECONDS}
#    fi
#done

# evaluation interval has to be parsable by https://github.com/gweis/isodate/blob/master/src/isodate/isoduration.py, with minimum time as 5 min.
#az batch pool autoscale enable \
#   --pool-id ${POOLID} \
#   --auto-scale-evaluation-interval 'P00Y00M00DT00H05M00S' \
#   --auto-scale-formula '$averageActiveTaskCount = avg($ActiveTasks.GetSample(TimeInterval_Minute * 1));$TargetLowPriorityNodes = min(${NUMRESTARTS}, $averageActiveTaskCount);'


start=`date +%s`
while true; do
    NUM_COMPLETE_JOBS=`az batch job task-counts show --job-id ${JOBID} | grep completed | awk '{print $2}' | sed s/,//`
    NUM_FAILED_JOBS=`az batch job task-counts show --job-id ${JOBID} | grep failed | awk '{print $2}' | sed s/,//`
    NUM_RUNNING_JOBS=`az batch job task-counts show --job-id ${JOBID} | grep running | awk '{print $2}' | sed s/,//`
    NUM_ACTIVE_JOBS=`az batch job task-counts show --job-id ${JOBID} | grep active | awk '{print $2}' | sed s/,//`
    
    echo "currently ${NUM_COMPLETE_JOBS} finished."
    if [ "${NUM_COMPLETE_JOBS}" == "${NUMRESTARTS}" ]; then
	echo "all jobs finished. now deleting job and pool."
	az batch job delete --job-id ${JOBID} --yes
	az batch pool delete --pool-id ${POOLID} --yes
	break
    else
	echo "job statistics:"
	echo "completed: ${NUM_COMPLETE_JOBS}, failed: ${NUM_FAILED_JOBS}, active: ${NUM_ACTIVE_JOBS}, running: ${NUM_RUNNING_JOBS}, total jobs: ${NUMRESTARTS}"
	echo "waiting ${WAIT_SECONDS} seconds for all jobs to complete. thus far, waited $((`date +%s`-start)) seconds"
	sleep ${WAIT_SECONDS}
    fi
done
