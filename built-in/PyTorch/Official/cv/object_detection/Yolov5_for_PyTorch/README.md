# 1.版本说明
yolov5版本Tags=v2.0, python版本为3.7.5

# 2.准备数据集

## 2.1下载coco2017数据集，并解压，解压后目录如下所示：

```
├── coco_data: #根目录
     ├── train2017 #训练集图片，约118287张
     ├── val2017 #验证集图片，约5000张
     └── annotations #标注目录
     		  ├── instances_train2017.json #对应目标检测、分割任务的训练集标注文件
     		  ├── instances_val2017.json #对应目标检测、分割任务的验证集标注文件
     		  ├── captions_train2017.json 
     		  ├── captions_val2017.json 
     		  ├── person_keypoints_train2017.json 
     		  └── person_keypoints_val2017.json
```

## 2.2 生成yolov5专用标注文件

（1）将代码仓中coco/coco2yolo.py和coco/coco_class.txt拷贝到coco_data**根目录**

（2）运行coco2yolo.py

```
python3 coco2yolo.py
```

（3）运行上述脚本后，将在coco_data**根目录**生成train2017.txt和val2017.txt

# 3.配置数据集路径

修改data/coco.yaml文件中的train字段和val字段，分别指向上一节生成的train2017.txt和val2017.txt，如：  

```
train: /data/coco_data/train2017.txt  
val: /data/coco_data/val2017.txt  
```

# 4.GPU,CPU依赖
按照requirements-GPU.txt安装python依赖包  

# 5.NPU依赖
按照requirements.txt安装python依赖包，还需安装(NPU-driver.run, NPU-firmware.run, NPU-toolkit.run, torch-ascend.whl, apex.whl)

# 6.编译安装Opencv-python

为了获得最好的图像处理性能，***请编译安装opencv-python而非直接安装***。编译安装步骤如下：

```
export GIT_SSL_NO_VERIFY=true
git clone https://github.com/opencv/opencv.git
cd opencv
mkdir -p build
cd build
cmake -D BUILD_opencv_python3=yes -D BUILD_opencv_python2=no -D PYTHON3_EXECUTABLE=/usr/local/python3.7.5/bin/python3.7m -D PYTHON3_INCLUDE_DIR=/usr/local/python3.7.5/include/python3.7m -D PYTHON3_LIBRARY=/usr/local/python3.7.5/lib/libpython3.7m.so -D PYTHON3_NUMPY_INCLUDE_DIRS=/usr/local/python3.7.5/lib/python3.7/site-packages/numpy/core/include -D PYTHON3_PACKAGES_PATH=/usr/local/python3.7.5/lib/python3.7/site-packages -D PYTHON3_DEFAULT_EXECUTABLE=/usr/local/python3.7.5/bin/python3.7m ..
make -j$nproc
make install
```

# 7.NPU 单机单卡训练指令  
yolov5s:

```
bash train_npu_1p_v5s.sh  
```


yolov5x:

```
bash train_npu_1p.sh 
```


# 8.NPU 单机八卡训练指令  
yolov5s:

```
bash train_npu_8p_mp_v5s.sh 
```


yolov5x:

```
bash train_npu_8p_mp.sh  
```



# 9.NPU evalution指令  
（1）将evaluation_npu_1p.sh 中的参数--coco_instance_path修改为数据集中的实际路径，如将该脚本修改为

```
python3.7 test.py --data /data/coco.yaml --coco_instance_path /data/coco/annotations/instances_val2017.json --img-size 672 --weight 'yolov5_0.pt' --batch-size 32 --device npu --npu 0
```

（2）启动评估

```
bash evaluation_npu_1p.sh
```

# 10.GPU 单机单卡训练指令  
python train.py --data coco.yaml --cfg yolov5x.yaml --weights '' --batch-size 32 --device 0  

# 11.GPU 单机八卡训练指令  
python -m torch.distributed.launch --nproc_per_node 8 train.py --data coco.yaml --cfg yolov5x.yaml --weights '' --batch-size 256  

# 12.CPU指令  
python train.py --data coco.yaml --cfg yolov5x.yaml --weights '' --batch-size 32 --device cpu  

# 13.导出onnx指令
python export_onnx.py --weights ./xxx.pt --img-size 640 --batch-size 1