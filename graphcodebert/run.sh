#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8;
CURRENT_DIR=`pwd`
CODE_DIR_HOME=`realpath ..`;

evaluator_script="${CODE_DIR_HOME}/evaluation";
codebleu_path="${CODE_DIR_HOME}/evaluation/CodeBLEU";
export COMPILED_SO_FILE="${codebleu_path}/parser/my-languages.so"

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

# for some reason, the model cannot be loaded from hugginface.models
# pretrained_model="microsoft/graphcodebert-base";
# so we download the files (from https://huggingface.co/microsoft/graphcodebert-base/tree/main)
# and save in a local directory (run download.sh file)
pretrained_model=${CODE_DIR_HOME}/models/graphcodebert;

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
    --config_name $pretrained_model \
    --tokenizer_name $pretrained_model \
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
    2>&1 | tee ${SAVE_DIR}/training.log;

}


function evaluate () {

MODEL_PATH=${SAVE_DIR}/checkpoint-best-ppl/pytorch_model.bin;
RESULT_FILE=${SAVE_DIR}/result.txt;
GOUND_TRUTH_PATH=${path_2_data}/test.jsonl;

python run.py \
    --do_test \
    --model_type roberta \
    --model_name_or_path $pretrained_model \
    --config_name $pretrained_model \
    --tokenizer_name $pretrained_model \
    --load_model_path $MODEL_PATH \
    --data_dir $path_2_data \
    --source $SOURCE \
    --target $TARGET \
    --output_dir $SAVE_DIR \
    --max_source_length $source_length \
    --max_target_length $target_length \
    --beam_size 5 \
    --eval_batch_size 16 \
    2>&1 | tee ${SAVE_DIR}/evaluation.log;

python $evaluator_script/evaluator.py \
    --references $GOUND_TRUTH_PATH \
    --predictions $SAVE_DIR/test.output \
    --language $TARGET \
    2>&1 | tee -a $RESULT_FILE;

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
DATA_DIR=${CODE_DIR_HOME}/evaluation/TransCoder;
OUT_DIR=${SAVE_DIR}/transcoder_eval;
mkdir -p $OUT_DIR;
RESULT_FILE=${OUT_DIR}/result.txt;
GOUND_TRUTH_PATH=${DATA_DIR}/test.java-python.$TARGET;

python run.py \
    --do_test \
    --model_type roberta \
    --model_name_or_path $pretrained_model \
    --config_name $pretrained_model \
    --tokenizer_name $pretrained_model \
    --load_model_path $MODEL_PATH \
    --data_dir $DATA_DIR \
    --source $SOURCE \
    --target $TARGET \
    --output_dir $OUT_DIR \
    --max_source_length $source_length \
    --max_target_length $target_length \
    --beam_size 5 \
    --eval_batch_size 16 \
    2>&1 | tee ${OUT_DIR}/evaluation.txt;

python $evaluator_script/evaluator.py \
    --references $GOUND_TRUTH_PATH \
    --txt_ref \
    --predictions $OUT_DIR/test.output \
    --language $TARGET \
    2>&1 | tee -a $RESULT_FILE;

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
