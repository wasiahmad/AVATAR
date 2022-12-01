#!/usr/bin/env bash

CODE_DIR_HOME=$(pwd)

###################################################################
pretrained_model=${CODE_DIR_HOME}/models/transcoder
mkdir -p $pretrained_model

cd $pretrained_model || exit

URL_PREFIX=https://dl.fbaipublicfiles.com/transcoder/pre_trained_models
PRE_MODELS=(
    TransCoder_model_1 # for C++ -> Java, Java -> C++ and Java -> Python
    TransCoder_model_2 # for C++ -> Python, Python -> C++ and Python -> Java
    translator_transcoder_size_from_DOBF
)

for model_name in "${PRE_MODELS[@]}"; do
    if [[ ! -f ${model_name}.pth ]]; then
        wget ${URL_PREFIX}/${model_name}.pth
    fi
done

URL_PREFIX=https://dl.fbaipublicfiles.com/transcoder/pre_trained_models/online_st_models
PRE_MODELS=(
    Online_ST_CPP_Java
    Online_ST_CPP_Python
    Online_ST_Java_Python
    Online_ST_Java_CPP
    Online_ST_Python_CPP
    Online_ST_Python_Java
)

for model_name in "${PRE_MODELS[@]}"; do
    if [[ ! -f ${model_name}.pth ]]; then
        wget ${URL_PREFIX}/${model_name}.pth
    fi
done

cd $CODE_DIR_HOME || exit

###################################################################
pretrained_model=${CODE_DIR_HOME}/models/plbart
mkdir -p $pretrained_model

cd $pretrained_model || exit
FILE=checkpoint_11_100000.pt
# https://drive.google.com/file/d/19OLKx0YY0yVorzZa-caFW0-hALVvX7gt
if [[ ! -f "$FILE" ]]; then
    fileid="19OLKx0YY0yVorzZa-caFW0-hALVvX7gt"
    curl -c ./cookie -s -L "https://drive.google.com/uc?export=download&id=${fileid}" >/dev/null
    curl -Lb ./cookie "https://drive.google.com/uc?export=download&confirm=$(awk '/download/ {print $NF}' ./cookie)&id=${fileid}" -o ${FILE}
    rm ./cookie
fi
cd $CODE_DIR_HOME || exit
