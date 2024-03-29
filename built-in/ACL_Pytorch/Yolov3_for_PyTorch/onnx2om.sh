##### 参数设置
GETOPT_ARGS=`getopt -o 'h' -al tag:,model:,nms_mode:,quantify:,bs:,soc: -- "$@"`
eval set -- "$GETOPT_ARGS"
while [ -n "$1" ]
do
    case "$1" in
        --tag) tag=$2; shift 2;;
        --model) model=$2; shift 2;;
        --nms_mode) nms_mode=$2; shift 2;;
        --quantify) quantify=$2; shift 2;;
        --bs) bs=$2; shift 2;;
        --soc) soc=$2; shift 2;;
        --) break ;;
    esac
done

if [[ -z $tag ]]; then tag=9.6.0; fi
if [[ -z $model ]]; then model=yolov3; fi
if [[ -z $nms_mode ]]; then nms_mode=nms_op; fi
if [[ -z $quantify ]]; then quantify=False; fi
if [[ -z $bs ]]; then bs=4; fi
if [[ -z $soc ]]; then soc=Ascend310P3; fi

args_info="=== onnx2om args === \n tag: $tag \n model: $model \n nms_mode: $nms_mode \n quantify: $quantify \n bs: $bs \n soc: $soc"
echo -e $args_info

##### 方式一 nms后处理脚本
if [[ $nms_mode == nms_script ]] ; then
    echo "方式一 nms后处理脚本"
    atc --model=${model}.onnx --output=${model}_bs${bs} \
        --framework=5 --input_format=NCHW --soc_version=${soc} --log=error \
        --input_shape="images:${bs},3,640,640" \
        --optypelist_for_implmode="Sigmoid" --op_select_implmode=high_performance || exit 1
fi

##### 方式二 nms后处理算子
if [[ $nms_mode == nms_op ]] ; then
    echo "方式二 nms后处理算子"
    atc --model=${model}.onnx --output=${model}_bs${bs} \
        --framework=5 --input_format=NCHW --soc_version=${soc} --log=error \
        --input_shape="images:${bs},3,640,640;img_info:${bs},4" \
        --optypelist_for_implmode="Sigmoid" --op_select_implmode=high_performance || exit 1
fi

echo -e "onnx导出om模型 Success \n"
