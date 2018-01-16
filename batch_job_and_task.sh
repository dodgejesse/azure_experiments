#!/bin/bash

#az batch job create --id myjob2 --pool-id HelloWorldFromImage2

for i in `seq 1 10`; do
    az batch task create --job-id myjob2 --task-id combinedtask${i} --command-line "/bin/sh -c 'touch /home/jessedd/tmp_${i}.txt; scp -o StrictHostKeyChecking=no -i /home/jessedd/jesse-key-pair-uswest2.pem /home/jessedd/tmp_${i}.txt jessedd@52.170.203.202:/home/jessedd/azure/results/'"
done




