# 1.版本说明
yolov5版本Tags=v6.0，配置yolov5s, python版本为3.7.5

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

修改data/coco.yaml中path字段，指向coco数据集，如：

```
path: ./datasets/coco
```

修改data/coco.yaml文件中的train字段和val字段，分别指向上一节生成的train2017.txt和val2017.txt，如：  

```
train: /data/coco_data/train2017.txt  
val: /data/coco_data/val2017.txt  
```

# 4.GPU,CPU依赖
按照requirements.txt安装python依赖包  

# 5.NPU依赖
安装Ascend包（包括driver、firmware、torch、torch_npu、apex等）

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

# 7.NPU 单机单卡性能测试  

```
bash test/train_yolov5s_performance_1p.sh  
```

# 8. NPU 单机八卡性能测试

```
bash test/train_yolov5s_performance_8p.sh
```

# 9. NPU 单机八卡精度测试
训练:
```
bash test/train_yolov5s_full_8p.sh   
```

评估
```
python val.py --data ./data/coco.yaml --img-size 640 --weight 'xxx.pt' --batch_size 32 --device 0
```
