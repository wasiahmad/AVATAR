#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8;
CURRENT_DIR=`pwd`
CODE_DIR_HOME=`realpath ..`;
export PYTHONPATH=$CODE_DIR_HOME;

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
CACHE_DIR=${SAVE_DIR}/cached_data
mkdir -p $SAVE_DIR
mkdir -p $CACHE_DIR

pretrained_model=${CODE_DIR_HOME}/models/codet5_base;
tokenizer_path=${CURRENT_DIR}/bpe;
source_length=510;
target_length=510;


function train () {

NUM_TRAIN_EPOCHS=20;
lr=5e-5;
TRAIN_BATCH_SIZE=2; # per_gpu_train_bsz * num_gpu
GRAD_ACCUM_STEP=16; # effective_bsz = train_bsz * grad_accum_steps

python run_gen.py \
    --do_train \
    --do_eval \
    --save_last_checkpoints \
    --always_save_model \
    --task translate \
    --sub_task "${SOURCE}-${TARGET}" \
    --model_type codet5 \
    --tokenizer_name roberta-base \
    --tokenizer_path $tokenizer_path \
    --model_name_or_path $pretrained_model \
    --output_dir $SAVE_DIR \
    --num_train_epochs $NUM_TRAIN_EPOCHS \
    --warmup_steps 100 \
    --learning_rate $lr \
    --patience 5 \
    --data_dir $path_2_data \
    --cache_path $CACHE_DIR \
    --res_dir $SAVE_DIR \
    --train_batch_size $TRAIN_BATCH_SIZE \
    --gradient_accumulation_steps $GRAD_ACCUM_STEP \
    --eval_batch_size 8 \
    --max_source_length $source_length \
    --max_target_length $target_length \
    --beam_size 5 \
    2>&1 | tee ${SAVE_DIR}/training.log;

}


function evaluate () {

MODEL_PATH=${SAVE_DIR}/checkpoint-best-ppl/pytorch_model.bin;
RESULT_FILE=${SAVE_DIR}/result.txt;
GOUND_TRUTH_PATH=${path_2_data}/test.jsonl;

python run_gen.py \
    --do_test \
    --model_type codet5 \
    --tokenizer_name roberta-base \
    --tokenizer_path $tokenizer_path \
    --model_name_or_path $pretrained_model \
    --task translate \
    --sub_task "${SOURCE}-${TARGET}" \
    --output_dir $SAVE_DIR \
    --data_dir $path_2_data \
    --cache_path $CACHE_DIR \
    --res_dir $SAVE_DIR \
    --eval_batch_size 8 \
    --max_source_length $source_length \
    --max_target_length $target_length \
    --beam_size 5 \
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

count=`ls -1 *.class 2>/dev/null | wc -l`;
[[ $count != 0 ]] && rm *.class;

}


function predict_transcoder_eval () {

MODEL_PATH=${SAVE_DIR}/checkpoint-best-ppl/pytorch_model.bin;
DATA_DIR=${CODE_DIR_HOME}/data/transcoder_test_gfg;
OUT_DIR=${SAVE_DIR}/transcoder_eval;
mkdir -p $OUT_DIR;
RESULT_FILE=${OUT_DIR}/result.txt;
GOUND_TRUTH_PATH=${DATA_DIR}/test.java-python.$TARGET;

python run_gen.py \
    --do_test \
    --model_type codet5 \
    --tokenizer_name roberta-base \
    --tokenizer_path $tokenizer_path \
    --model_name_or_path $pretrained_model \
    --task translate \
    --sub_task "${SOURCE}-${TARGET}" \
    --output_dir $SAVE_DIR \
    --data_dir $DATA_DIR \
    --cache_path $OUT_DIR \
    --res_dir $OUT_DIR \
    --eval_batch_size 8 \
    --max_source_length $source_length \
    --max_target_length $target_length \
    --beam_size 5 \
    2>&1 | tee ${OUT_DIR}/evaluation.log;

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
