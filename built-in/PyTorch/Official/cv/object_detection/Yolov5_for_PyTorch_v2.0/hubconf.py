'''# -*- coding: utf-8 -*-
# BSD 3-Clause License
#
# Copyright (c) 2017
# All rights reserved.
# Copyright 2022 Huawei Technologies Co., Ltd
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# ==========================================================================
'''

dependencies = ['torch', 'yaml']

import os

import torch

from models.yolo import Model
from utils import google_utils


def create(name, pretrained, channels, classes):
    """Creates a specified YOLOv5 model

    Arguments:
        name (str): name of model, i.e. 'yolov5s'
        pretrained (bool): load pretrained weights into the model
        channels (int): number of input channels
        classes (int): number of model classes

    Returns:
        pytorch model
    """
    config = os.path.join(os.path.dirname(__file__), 'models', '%s.yaml' % name)  # model.yaml path
    try:
        model = Model(config, channels, classes)
        if pretrained:
            ckpt = '%s.pt' % name  # checkpoint filename
            google_utils.attempt_download(ckpt)  # download if not found locally
            state_dict = torch.load(ckpt, map_location=torch.device('cpu'))['model'].float().state_dict()  # to FP32
            state_dict = {k: v for k, v in state_dict.items() if model.state_dict()[k].shape == v.shape}  # filter
            model.load_state_dict(state_dict, strict=False)  # load
        return model

    except Exception as e:
        help_url = 'https://github.com/ultralytics/yolov5/issues/36'
        s = 'Cache maybe be out of date, deleting cache and retrying may solve this. See %s for help.' % help_url
        raise Exception(s) from e


def yolov5s(pretrained=False, channels=3, classes=80):
    """YOLOv5-small model from https://github.com/ultralytics/yolov5

    Arguments:
        pretrained (bool): load pretrained weights into the model, default=False
        channels (int): number of input channels, default=3
        classes (int): number of model classes, default=80

    Returns:
        pytorch model
    """
    return create('yolov5s', pretrained, channels, classes)


def yolov5m(pretrained=False, channels=3, classes=80):
    """YOLOv5-medium model from https://github.com/ultralytics/yolov5

    Arguments:
        pretrained (bool): load pretrained weights into the model, default=False
        channels (int): number of input channels, default=3
        classes (int): number of model classes, default=80

    Returns:
        pytorch model
    """
    return create('yolov5m', pretrained, channels, classes)


def yolov5l(pretrained=False, channels=3, classes=80):
    """YOLOv5-large model from https://github.com/ultralytics/yolov5

    Arguments:
        pretrained (bool): load pretrained weights into the model, default=False
        channels (int): number of input channels, default=3
        classes (int): number of model classes, default=80

    Returns:
        pytorch model
    """
    return create('yolov5l', pretrained, channels, classes)


def yolov5x(pretrained=False, channels=3, classes=80):
    """YOLOv5-xlarge model from https://github.com/ultralytics/yolov5

    Arguments:
        pretrained (bool): load pretrained weights into the model, default=False
        channels (int): number of input channels, default=3
        classes (int): number of model classes, default=80

    Returns:
        pytorch model
    """
    return create('yolov5x', pretrained, channels, classes)
