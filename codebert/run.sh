#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8;
CURRENT_DIR=`pwd`
CODE_DIR_HOME=`realpath ..`;

evaluator_script="${CODE_DIR_HOME}/evaluation";
codebleu_path="${CODE_DIR_HOME}/evaluation/CodeBLEU";

GPU=${1:-0};
SOURCE=${2:-java};
TARGET=${3:-python};
DATA_SRC=${4:-avatar};

export CUDA_VISIBLE_DEVICES=$GPU
echo "Source: $SOURCE Target: $TARGET"

if [[ $DATA_SRC == 'avatar' ]]; then
    path_2_data=${CODE_DIR_HOME}/data;
elif [[ $DATA_SRC == 'g4g' ]]; then
    path_2_data=${CODE_DIR_HOME}/data/g4g_functions;
fi

SAVE_DIR=${CURRENT_DIR}/${DATA_SRC}/${SOURCE}2${TARGET};
mkdir -p $SAVE_DIR
pretrained_model="microsoft/codebert-base";

source_length=510;
target_length=510;


function train () {

NUM_TRAIN_EPOCHS=20;
lr=5e-5;
TRAIN_BATCH_SIZE=32; # Full consolidated batch size
GRAD_ACCUM_STEP=4; # We need to use 2 GPUs, batch_size_per_gpu=4

python run.py \
    --do_train \
    --do_eval \
    --model_type roberta \
    --config_name roberta-base \
    --tokenizer_name roberta-base \
    --model_name_or_path $pretrained_model \
    --data_dir $path_2_data \
    --source $SOURCE \
    --target $TARGET \
    --output_dir $SAVE_DIR \
    --max_source_length $source_length \
    --max_target_length $target_length \
    --num_train_epochs $NUM_TRAIN_EPOCHS \
    --train_batch_size $TRAIN_BATCH_SIZE \
    --eval_batch_size 8 \
    --beam_size 5 \
    --gradient_accumulation_steps $GRAD_ACCUM_STEP \
    --learning_rate $lr \
    --log_file $SAVE_DIR/finetune.log;

}


function evaluate () {

MODEL_PATH=${SAVE_DIR}/checkpoint-best-ppl/pytorch_model.bin;
RESULT_FILE=${SAVE_DIR}/result.txt;
GOUND_TRUTH_PATH=${path_2_data}/test.jsonl;

python run.py \
    --do_test \
    --model_type roberta \
    --model_name_or_path $pretrained_model \
    --config_name roberta-base \
    --tokenizer_name roberta-base  \
    --load_model_path $MODEL_PATH \
    --data_dir $path_2_data \
    --source $SOURCE \
    --target $TARGET \
    --output_dir $SAVE_DIR \
    --max_source_length $source_length \
    --max_target_length $target_length \
    --beam_size 5 \
    --eval_batch_size 16 \
    --log_file ${SAVE_DIR}/evaluation.txt;

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


function predict_transcoder_eval () {

MODEL_PATH=${SAVE_DIR}/checkpoint-best-ppl/pytorch_model.bin;
DATA_DIR=${CODE_DIR_HOME}/data/transcoder_test_gfg;
OUT_DIR=${SAVE_DIR}/transcoder_eval;
mkdir -p $OUT_DIR;
RESULT_FILE=${OUT_DIR}/result.txt;
GOUND_TRUTH_PATH=${DATA_DIR}/test.java-python.$TARGET;

python run.py \
    --do_test \
    --model_type roberta \
    --model_name_or_path $pretrained_model \
    --config_name roberta-base \
    --tokenizer_name roberta-base  \
    --load_model_path $MODEL_PATH \
    --data_dir $DATA_DIR \
    --source $SOURCE \
    --target $TARGET \
    --output_dir $OUT_DIR \
    --max_source_length $source_length \
    --max_target_length $target_length \
    --beam_size 5 \
    --eval_batch_size 16 \
    --log_file ${OUT_DIR}/evaluation.txt;

python $evaluator_script/evaluator.py \
    --references $GOUND_TRUTH_PATH \
    --txt_ref \
    --predictions $OUT_DIR/test.output \
    --language $TARGET \
    2>&1 | tee $RESULT_FILE;

cd $codebleu_path;
python calc_code_bleu.py \
    --ref $GOUND_TRUTH_PATH \
    --txt_ref \
    --hyp $OUT_DIR/test.output \
    --lang $TARGET \
    2>&1 | tee -a $RESULT_FILE;
cd $CURRENT_DIR;

}


train;
evaluate;
predict_transcoder_eval;
