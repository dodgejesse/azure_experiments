#!/bin/bash


# create azure storage, probably blob storage

# get shared access signature SAS

##### current solution: put key on image, ssh stuff. 

az batch pool create \
   --id HelloWorldFromImage2 \
   --target-dedicated 3 \
   --vm-size "Standard_F4" \
   --start-task-command-line "echo hi" \
   --start-task-wait-for-success \
   --image '/subscriptions/8557c4b8-f939-4cca-80f5-d17b546717af/resourceGroups/Jesse/providers/Microsoft.Compute/images/vmForBatch3-image-20180114151452' \
   --node-agent-sku-id "batch.node.ubuntu 16.04"


exit

# potential next steps:
# make a job factory, which submits different jobs to each node
# make a vm, which i can update, which i can also use to create images



# Let's change the pool to enable automatic scaling of compute nodes.
# This autoscale formula specifies that the number of nodes should be adjusted according
# to the number of active tasks, up to a maximum of 10 compute nodes.
az batch pool autoscale enable \
   --pool-id mypool-windows \
   --auto-scale-formula "$averageActiveTaskCount = avg($ActiveTasks.GetSample(TimeInterval_Minute * 15));$TargetDedicated = min(10, $averageActiveTaskCount);"

# We can monitor the resizing of the pool.
az batch pool show --pool-id mypool-windows

# Once we no longer require the pool to automatically scale, we can disable it.
az batch pool autoscale disable --pool-id mypool-windows
