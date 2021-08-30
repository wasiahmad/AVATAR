#!/usr/bin/env bash

CODE_DIR_HOME=`pwd`

###################################################################
pretrained_model=${CODE_DIR_HOME}/models/transcoder;
mkdir -p $pretrained_model

cd $pretrained_model;
# download from https://github.com/facebookresearch/CodeGen/blob/master/docs/transcoder.md#pre-trained-models
# model_1.pth for C++ -> Java, Java -> C++ and Java -> Python
wget https://dl.fbaipublicfiles.com/transcoder/pre_trained_models/TransCoder_model_1.pth
# model_2.pth for C++ -> Python, Python -> C++ and Python -> Java
wget https://dl.fbaipublicfiles.com/transcoder/pre_trained_models/TransCoder_model_2.pth
# translator_transcoder_size_from_DOBF.pth for Java -> Python and Python -> Java
wget https://dl.fbaipublicfiles.com/transcoder/pre_trained_models/translator_transcoder_size_from_DOBF.pth
cd $CODE_DIR_HOME;

###################################################################
pretrained_model=${CODE_DIR_HOME}/models/plbart;
mkdir -p $pretrained_model

cd $pretrained_model;
FILE=checkpoint_11_100000.pt
# https://drive.google.com/file/d/19OLKx0YY0yVorzZa-caFW0-hALVvX7gt
if [[ ! -f "$FILE" ]]; then
    fileid="19OLKx0YY0yVorzZa-caFW0-hALVvX7gt"
    curl -c ./cookie -s -L "https://drive.google.com/uc?export=download&id=${fileid}" > /dev/null
    curl -Lb ./cookie "https://drive.google.com/uc?export=download&confirm=`awk '/download/ {print $NF}' ./cookie`&id=${fileid}" -o ${FILE}
    rm ./cookie
fi
cd $CODE_DIR_HOME;

###################################################################
pretrained_model=${CODE_DIR_HOME}/models/graphcodebert;
mkdir -p $pretrained_model
prefix_url="https://huggingface.co/microsoft/graphcodebert-base/resolve/main";

cd $pretrained_model;
wget ${prefix_url}/config.json;
wget ${prefix_url}/merges.txt;
wget ${prefix_url}/pytorch_model.bin;
wget ${prefix_url}/special_tokens_map.json;
wget ${prefix_url}/tokenizer_config.json;
wget ${prefix_url}/vocab.json;
cd $CODE_DIR_HOME;
