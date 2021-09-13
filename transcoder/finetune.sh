#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8;
CURRENT_DIR=`pwd`
CODE_DIR_HOME=`realpath ..`;

GPU=${1:-0};
DATA_SRC=${2:-avatar};
MT_STEPS=${3:-"java-python,python-java"}

if [[ $DATA_SRC == 'avatar' ]]; then
    path_2_data=${CODE_DIR_HOME}/data;
elif [[ $DATA_SRC == 'g4g' ]]; then
    path_2_data=${CODE_DIR_HOME}/data/g4g_functions;
fi

export CUDA_VISIBLE_DEVICES=$GPU
SAVE_DIR=${CURRENT_DIR}/${DATA_SRC};
mkdir -p $SAVE_DIR

pretrained_model=${CODE_DIR_HOME}/models/transcoder;
MODEL_PATH=${pretrained_model}/translator_transcoder_size_from_DOBF.pth;
TRAIN_SCRIPT=${CODE_DIR_HOME}/codegen/model/train.py;
EXP_NAME=transcoder-ft;
EXP_ID="${MT_STEPS//,/_}";

VALID_METRICS="valid_python-java_mt_bleu";
if [[ $MT_STEPS == "java-python" ]]; then
    VALID_METRICS="valid_java-python_mt_bleu";
fi


export PYTHONPATH=$CODE_DIR_HOME;
python $TRAIN_SCRIPT \
--exp_name $EXP_NAME \
--exp_id $EXP_ID \
--dump_path $SAVE_DIR \
--data_path $path_2_data/transcoder-bin \
--split_data_accross_gpu local \
--max_len 512 \
--mt_steps $MT_STEPS \
--encoder_only False \
--n_layers 0 \
--n_layers_encoder 6  \
--n_layers_decoder 6 \
--emb_dim 1024 \
--n_heads 8 \
--lgs 'java-python' \
--max_vocab 64000 \
--roberta_mode false \
--reload_model "$MODEL_PATH,$MODEL_PATH" \
--lgs_mapping 'java:java_sa,python:python_sa'  \
--amp 2 \
--fp16 true  \
--batch_size 4 \
--accumulate_gradients 4 \
--epoch_size 2000 \
--max_epoch 20 \
--optimizer 'adam_inverse_sqrt,warmup_updates=200,lr=0.0001,weight_decay=0.01' \
--eval_bleu true \
--eval_bleu_valid_only true \
--validation_metrics ${VALID_METRICS} \
--stopping_criterion "${VALID_METRICS},5" \
2>&1 | tee ${SAVE_DIR}/finetune.log;