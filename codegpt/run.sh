#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8;
CURRENT_DIR=`pwd`
CODE_DIR_HOME=`realpath ..`;

evaluator_script="${CODE_DIR_HOME}/evaluation";
codebleu_path="${CODE_DIR_HOME}/evaluation/CodeBLEU";

GPU=${1:-0};
SOURCE=${2:-java};
TARGET=${3:-python};
MODEL=${4:-adaptedCodeGPT};

export CUDA_VISIBLE_DEVICES=$GPU
echo "Source: $SOURCE Target: $TARGET"

path_2_data=${CODE_DIR_HOME}/data;
if [[ $MODEL == 'CodeGPT' ]]; then
    SAVE_DIR=${CURRENT_DIR}/codegpt;
    if [[ $LANG == 'python' ]]; then
        PRETRAINDIR="microsoft/CodeGPT-small-py";
    else
        PRETRAINDIR="microsoft/CodeGPT-small-java";
    fi
elif [[ $MODEL == 'adaptedCodeGPT' ]]; then
    SAVE_DIR=${CURRENT_DIR}/adaptedCodeGPT;
    if [[ $LANG == 'python' ]]; then
        PRETRAINDIR="microsoft/CodeGPT-small-py-adaptedGPT2";
    else
        PRETRAINDIR="microsoft/CodeGPT-small-java-adaptedGPT2";
    fi
fi

SAVE_DIR=${SAVE_DIR}/${SOURCE}2${TARGET};
mkdir -p $SAVE_DIR

# TODO: Use of more than 1 GPU causes error

function train (){

python run.py \
    --data_dir $path_2_data \
    --source $SOURCE \
    --target $TARGET \
    --output_dir $SAVE_DIR \
    --pretrain_dir $PRETRAINDIR \
    --model_type gpt2 \
    --block_size 512 \
    --do_train \
    --node_index 0 \
    --learning_rate 5e-5 \
    --weight_decay 0.01 \
    --evaluate_during_training \
    --per_gpu_train_batch_size 4 \
    --per_gpu_eval_batch_size 8 \
    --gradient_accumulation_steps 8 \
    --num_train_epochs 20 \
    --logging_steps 100 \
    --save_steps 2000 \
    --overwrite_output_dir \
    --seed 42 \
    2>&1 | tee ${SAVE_DIR}/training.log;

}


function evaluate () {

MODEL_PATH=${SAVE_DIR}/checkpoint-best-ppl/pytorch_model.bin;
RESULT_FILE=${SAVE_DIR}/result.txt;
GOUND_TRUTH_PATH=${path_2_data}/test.jsonl;

python -u run.py \
    --data_dir $path_2_data \
    --source $SOURCE \
    --target $TARGET \
    --output_dir $SAVE_DIR \
    --pretrain_dir $PRETRAINDIR \
    --load_model_path $MODEL_PATH \
    --model_type gpt2 \
    --block_size 512 \
    --do_infer \
    --beam_size 5 \
    --logging_steps 100 \
    --seed 42 \
    2>&1 | tee ${SAVE_DIR}/evaluation.log;

python $evaluator_script/evaluator.py \
    --references $GOUND_TRUTH_PATH \
    --predictions $SAVE_DIR/test.output \
    --language $TARGET \
    2>&1 | tee $RESULT_FILE;

cd $codebleu_path;
python calc_code_bleu.py \
    --ref $GOUND_TRUTH_PATH \
    --hyp $SAVE_DIR/test.output \
    --lang $TARGET \
    2>&1 | tee -a $RESULT_FILE;
cd $CURRENT_DIR;

python $evaluator_script/compile.py \
    --input_file $SAVE_DIR/test.output \
    --language $TARGET \
    2>&1 | tee -a $RESULT_FILE;

}


train;
evaluate;
