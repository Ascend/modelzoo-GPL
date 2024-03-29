#!/bin/bash

###############指定训练脚本执行路径###############
# cd到与test文件夹同层级目录下执行脚本，提高兼容性；test_path_dir为包含test文件夹的路径
cur_path=`pwd`
cur_path_last_dirname=${cur_path##*/}
if [ x"${cur_path_last_dirname}" == x"test" ];then
    test_path_dir=${cur_path}
    cd ..
    cur_path=`pwd`
else
    test_path_dir=${cur_path}/test
fi
RANK_SIZE=8
batch_size=512
img_size=320
model_name=yolov3
# 数据集路径,保持为空,不需要修改
data_path=""
datasets="voc"
#训练epochs
epochs=2
#网络名称 yolov3-320*320
Network="Yolov3_ID4084_for_PyTorch"

for para in $*
do
   if [[ $para == --model_name* ]];then
      	model_name=`echo ${para#*=}`
   elif [[ $para == --batch_size* ]];then
      	batch_size=`echo ${para#*=}`
   elif [[ $para == --data_path* ]];then
        data_path=`echo ${para#*=}`
   elif [[ $para == --datasets* ]];then
        datasets=`echo ${para#*=}`
   elif [[ $para == --img_size* ]];then
      	img_size=`echo ${para#*=}`
   elif [[ $para == --conda_name* ]];then
        conda_name=`echo ${para#*=}`
        source ${test_path_dir}/set_conda.sh --conda_name=$conda_name
        source activate $conda_name
   fi
done

# 数据集建立软链接
if [ ${datasets} == "coco" ];then
  echo "data_path is: ${data_path}"
  if [ ! -d './data/coco' ]
  then
    ln -s ${data_path} ./data/coco
  fi
fi

# 非平台场景时source 环境变量
check_etp_flag=`env | grep etp_running_flag`
etp_flag=`echo ${check_etp_flag#*=}`
if [ x"${etp_flag}" != x"true" ];then
    source  ${test_path_dir}/env_npu.sh
    if [ ${datasets} == "voc" ];then
      ln -nsf ${data_path} .
    fi
else
  cp -r ${data_path}/VOC.tar.gz ${cur_path}
  tar -xavf VOC.tar.gz
fi
# 指定训练所使用的npu device卡id
device_id=0

# 校验是否指定了device_id,分动态分配device_id与手动指定device_id,此处不需要修改
if [ $ASCEND_DEVICE_ID ];then
    echo "device id is ${ASCEND_DEVICE_ID}"
elif [ ${device_id} ];then
    export ASCEND_DEVICE_ID=${device_id}
    echo "device id is ${ASCEND_DEVICE_ID}"
else
    "[Error] device id must be config"
    exit 1
fi

#################创建日志输出目录，不需要修改#################
if [ -d ${test_path_dir}/output/${ASCEND_DEVICE_ID} ];then
    rm -rf ${test_path_dir}/output/${ASCEND_DEVICE_ID}
    mkdir -p ${test_path_dir}/output/$ASCEND_DEVICE_ID
else
    mkdir -p ${test_path_dir}/output/$ASCEND_DEVICE_ID
fi
#训练开始时间，不需要修改
start_time=$(date +%s)
nohup python3 -m torch.distributed.launch --nproc_per_node 8 train.py --data ${datasets}.yaml --cfg ${model_name}.yaml --epochs ${epochs} --weights '' --batch-size ${batch_size} --noval --img-size ${img_size} >${test_path_dir}/output/${ASCEND_DEVICE_ID}/train_${ASCEND_DEVICE_ID}.log 2>&1 &
wait
#训练结束时间，不需要修改
end_time=$(date +%s)
e2e_time=$(( $end_time - $start_time ))

#结果打印，不需要修改
echo "------------------ Final result ------------------"
#输出性能FPS，需要模型审视修改
fps=`grep -a 'it/s'  $test_path_dir/output/${ASCEND_DEVICE_ID}/train_${ASCEND_DEVICE_ID}.log|awk -F " " '{print $NF}'|awk -F "i" '{print $1}'|tail -n 1`
FPS=`echo "${batch_size} * ${fps}" |bc`
#打印，不需要修改
echo "Final Performance images/sec : $FPS"

#输出训练精度,需要模型审视修改
#train_accuracy=`grep -a 'all' $test_path_dir/output/${ASCEND_DEVICE_ID}/train_${ASCEND_DEVICE_ID}.log|tail -1|awk -F ' ' '{print $NF}'`

#打印，不需要修改
#echo "Final Train Accuracy : ${train_accuracy}"
echo "E2E Training Duration sec : $e2e_time"

#性能看护结果汇总
#训练用例信息，不需要修改
BatchSize=${batch_size}
DeviceType=`uname -m`
CaseName=${Network}_bs${BatchSize}_${RANK_SIZE}'p'_'perf'

##获取性能数据，不需要修改
#吞吐量
ActualFPS=${FPS}
#单迭代训练时长
TrainingTime=`awk 'BEGIN{printf "%.2f\n", '${batch_size}'*1000/'${FPS}'}'`


#关键信息打印到${CaseName}.log中，不需要修改
echo "Network = ${Network}" > $test_path_dir/output/$ASCEND_DEVICE_ID/${CaseName}.log
echo "RankSize = ${RANK_SIZE}" >> $test_path_dir/output/$ASCEND_DEVICE_ID/${CaseName}.log
echo "BatchSize = ${BatchSize}" >> $test_path_dir/output/$ASCEND_DEVICE_ID/${CaseName}.log
echo "DeviceType = ${DeviceType}" >> $test_path_dir/output/$ASCEND_DEVICE_ID/${CaseName}.log
echo "CaseName = ${CaseName}" >> $test_path_dir/output/$ASCEND_DEVICE_ID/${CaseName}.log
echo "ActualFPS = ${ActualFPS}" >> $test_path_dir/output/$ASCEND_DEVICE_ID/${CaseName}.log
echo "TrainingTime = ${TrainingTime}" >> $test_path_dir/output/$ASCEND_DEVICE_ID/${CaseName}.log
echo "E2ETrainingTime = ${e2e_time}" >> $test_path_dir/output/$ASCEND_DEVICE_ID/${CaseName}.log
#处理数据集
if [ x"${etp_flag}" == x"true" ];then
    rm -rf ${cur_path}/VOC.tar.gz ${cur_path}/VOC
fi