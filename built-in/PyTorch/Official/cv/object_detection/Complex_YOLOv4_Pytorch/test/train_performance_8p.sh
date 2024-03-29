#网络名称,同目录名称,需要模型审视修改
Network="Complex_ID4108_for_yolov4"
# 数据集路径,保持为空,不需要修改
data_path=""
#当前路径,不需要修改
cur_path=`pwd`
#训练batch_size,需要模型审视修改
batch_size=64
RANK_SIZE=8

#参数校验，不需要修改
for para in $*
do
    if [[ $para == --data_path* ]];then
        data_path=`echo ${para#*=}`
    fi
done

###############指定训练脚本执行路径###############
# cd到与test文件夹同层级目录下执行脚本，提高兼容性；test_path_dir为包含test文件夹的路径
cur_path_last_dirname=${cur_path##*/}
if [ x"${cur_path_last_dirname}" == x"test" ]; then
    test_path_dir=${cur_path}
    cd ..
    cur_path=$(pwd)
else
    test_path_dir=${cur_path}/test
fi


# 非平台场景时source 环境变量
check_etp_flag=$(env | grep etp_running_flag)
etp_flag=$(echo ${check_etp_flag#*=})
if [ x"${etp_flag}" != x"true" ]; then
    source ${test_path_dir}/env_npu.sh
else
    current_time=$(date +%s)
    mkdir /npu/traindata/${current_time}
    tar xzvf /${data_path}/kitti.tar.gz -C /npu/traindata/${current_time}/
    data_path=/npu/traindata/${current_time}/kitti/
fi

if [ ! -d './dataset/kitti/training' ]
then
	ln -s ${data_path}/training/ ./dataset/kitti/training
	ln -s ${data_path}/testing/ ./dataset/kitti/testing
fi



#训练开始时间，不需要修改
start_time=$(date +%s)
echo "start_time: ${start_time}"

#创建DeviceID输出目录，不需要修改
device_id=0
if [ ! -d ${cur_path}/test/output/${device_id} ];then
    mkdir -p ${cur_path}/test/output/$device_id/
fi

cd src

python3 -m torch.distributed.launch --nproc_per_node=${RANK_SIZE} train.py \
     --dist-url 'tcp://127.0.0.1:29500' \
     --dist-backend 'hccl' \
     --multiprocessing-distributed \
     --batch_size ${batch_size} \
     --print_freq 40 \
     --num_workers 16 \
     --num_epochs 10 > ${cur_path}/test/output/$device_id/train_perf_8p.log 2>&1

#训练结束时间，不需要修改
end_time=$(date +%s)
echo "end_time: ${end_time}"
e2e_time=$(( $end_time - $start_time ))

#最后一个迭代FPS值
step_time=`grep -a 'Epoch:.*Time' ${cur_path}/test/output/$device_id/train_perf_8p.log  |awk 'END {print}'| awk -F "Time" '{print $2}' | awk -F "Data" '{print $1}' | awk -F " " '{print $3}'| cut -d ')' -f1`
FPS=`awk 'BEGIN{printf "%.2f\n", '${batch_size}'/'${step_time}'}'`

#最后一个迭代loss值
loss=`grep -a 'Epoch:.*Loss'  ${cur_path}/test/output/$device_id/train_perf_8p.log|awk 'END {print}'| awk -F "Loss" '{print $2}' | awk -F " " '{print $2}' | cut -d '(' -f2 | cut -d ')' -f1`

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
grep -a 'Epoch:.*Loss'  ${cur_path}/test/output/$device_id/train_perf_8p.log | awk -F "Loss" '{print $2}' | awk -F " " '{print $2}' | cut -d '(' -f2 | cut -d ')' -f1 >> $cur_path/test/output/$device_id/train_${CaseName}_loss.txt

#关键信息打印到${CaseName}.log中，不需要修改
echo "Network = ${Network}" > $cur_path/test/output/$device_id/${CaseName}.log
echo "RankSize = ${RANK_SIZE}" >> $cur_path/test/output/$device_id/${CaseName}.log
echo "BatchSize = ${BatchSize}" >> $cur_path/test/output/$device_id/${CaseName}.log
echo "DeviceType = ${DeviceType}" >> $cur_path/test/output/$device_id/${CaseName}.log
echo "CaseName = ${CaseName}" >> $cur_path/test/output/$device_id/${CaseName}.log
echo "ActualFPS = ${FPS}" >> $cur_path/test/output/$device_id/${CaseName}.log
echo "TrainingTime = ${e2e_time}" >> $cur_path/test/output/$device_id/${CaseName}.log
echo "ActualLoss = ${loss}" >> $cur_path/test/output/$device_id/${CaseName}.log
echo "E2ETrainingTime = ${e2e_time}" >> $cur_path/test/output/$device_id/${CaseName}.log
if [ x"${etp_flag}" = x"true" ]; then
    rm -rf ${data_path}
fi