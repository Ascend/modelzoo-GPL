#网络名称,同目录名称,需要模型审视修改
Network="Complex_yolov4"
# 数据集路径,保持为空,不需要修改
data_path=""
device_id=0
#当前路径,不需要修改
cur_path=`pwd`
#训练batch_size,需要模型审视修改
batch_size=8
RANK_SIZE=1

#参数校验，不需要修改
for para in $*
do
    if [[ $para == --device_id* ]];then
        device_id=`echo ${para#*=}`
    elif [[ $para == --data_path* ]];then
        data_path=`echo ${para#*=}`
    fi
done

if [ ! -d './dataset/kitti/training' ]
then
	ln -s ${data_path}/training/ ./dataset/kitti/training
	ln -s ${data_path}/testing/ ./dataset/kitti/testing
fi

#训练开始时间，不需要修改
start_time=$(date +%s)
echo "start_time: ${start_time}"

# 校验是否指定了device_id,分动态分配device_id与手动指定device_id,此处不需要修改
device_id=0
if [ $ASCEND_DEVICE_ID ];then
	export device_id=${ASCEND_DEVICE_ID}
    echo "device id is ${ASCEND_DEVICE_ID}"
elif [ ${device_id} ];then
    echo "device id is ${device_id}"
else
    "[Error] device id must be config"
    exit 1
fi

#创建DeviceID输出目录，不需要修改
if [ ! -d ${cur_path}/test/output/${device_id} ];then
    mkdir -p ${cur_path}/test/output/$device_id/
fi

source test/env_npu.sh
cd src

taskset -c 0-32 python3 train.py --local_rank $device_id --batch_size $batch_size --num_workers 4 --num_epochs 2 > ${cur_path}/test/output/$device_id/train_perf_1p.log 2>&1

#训练结束时间，不需要修改
end_time=$(date +%s)
echo "end_time: ${end_time}"
e2e_time=$(( $end_time - $start_time ))

#最后一个迭代FPS值
step_time=`grep -a 'Epoch:.*Time'  ${cur_path}/test/output/$device_id/train_perf_1p.log|awk 'END {print}'| awk -F "Time" '{print $2}' | awk -F "Data" '{print $1}' | awk -F " " '{print $3}'| cut -d ')' -f1`
FPS=`awk 'BEGIN{printf "%.2f\n", '${batch_size}'/'${step_time}'}'`

#最后一个迭代loss值
loss=`grep -a 'Epoch:.*Loss'  ${cur_path}/test/output/$device_id/train_perf_1p.log|awk 'END {print}'| awk -F "Loss" '{print $2}' | awk -F " " '{print $2}' | cut -d '(' -f2 | cut -d ')' -f1`

#打印，不需要修改
echo "Final Performance images/sec : $FPS"
echo "ActualLoss : ${loss}"
echo "E2E Training Duration sec : $e2e_time"

#稳定性精度看护结果汇总
#训练用例信息，不需要修改
BatchSize=${batch_size}
DeviceType=`uname -m`
CaseName=${Network}_bs${BatchSize}_${RANK_SIZE}'p'_'perf'

#提取Loss到train_${CaseName}_loss.txt中，需要模型审视修改
grep -a 'Epoch:.*Loss'  ${cur_path}/test/output/$device_id/train_perf_1p.log | awk -F "Loss" '{print $2}' | awk -F " " '{print $2}' | cut -d '(' -f2 | cut -d ')' -f1 >> $cur_path/test/output/$device_id/train_${CaseName}_loss.txt

#关键信息打印到${CaseName}.log中，不需要修改
echo "Network = ${Network}" > $cur_path/test/output/$device_id/${CaseName}.log
echo "RankSize = ${RANK_SIZE}" >> $cur_path/test/output/$device_id/${CaseName}.log
echo "BatchSize = ${BatchSize}" >> $cur_path/test/output/$device_id/${CaseName}.log
echo "DeviceType = ${DeviceType}" >> $cur_path/test/output/$device_id/${CaseName}.log
echo "CaseName = ${CaseName}" >> $cur_path/test/output/$device_id/${CaseName}.log
echo "ActualFPS = ${FPS}" >> $cur_path/test/output/$device_id/${CaseName}.log
echo "TrainingTime = ${TrainingTime}" >> $cur_path/test/output/$device_id/${CaseName}.log
echo "ActualLoss = ${loss}" >> $cur_path/test/output/$device_id/${CaseName}.log
echo "E2ETrainingTime = ${e2e_time}" >> $cur_path/test/output/$device_id/${CaseName}.log
