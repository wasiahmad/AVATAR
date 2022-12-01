#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8
CURRENT_DIR=$(pwd)
CODE_DIR_HOME=$(realpath ..)

evaluator_script="${CODE_DIR_HOME}/evaluation"
codebleu_path="${CODE_DIR_HOME}/evaluation/CodeBLEU"
prog_test_case_dir="${CODE_DIR_HOME}/test_cases"

GPU=${1:-0}
SOURCE=${2:-java}
TARGET=${3:-python}
MODEL=${4:-adaptedCodeGPT}

export CUDA_VISIBLE_DEVICES=$GPU
echo "Source: $SOURCE Target: $TARGET"

if [[ $MODEL == 'CodeGPT' ]]; then
    OUTPUT_DIR=${CURRENT_DIR}/codegpt
    if [[ $LANG == 'python' ]]; then
        PRETRAINDIR="microsoft/CodeGPT-small-py"
    else
        PRETRAINDIR="microsoft/CodeGPT-small-java"
    fi
elif [[ $MODEL == 'adaptedCodeGPT' ]]; then
    OUTPUT_DIR=${CURRENT_DIR}/adaptedCodeGPT
    if [[ $LANG == 'python' ]]; then
        PRETRAINDIR="microsoft/CodeGPT-small-py-adaptedGPT2"
    else
        PRETRAINDIR="microsoft/CodeGPT-small-java-adaptedGPT2"
    fi
fi

function train() {
    DATA_SRC=$1
    if [[ $DATA_SRC == 'program' ]]; then
        path_2_data=${CODE_DIR_HOME}/data
    elif [[ $DATA_SRC == 'function' ]]; then
        path_2_data=${CODE_DIR_HOME}/data/parallel_functions
    fi

    SAVE_DIR=${OUTPUT_DIR}/${DATA_SRC}/${SOURCE}2${TARGET}
    mkdir -p $SAVE_DIR

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
        --per_gpu_train_batch_size 8 \
        --per_gpu_eval_batch_size 8 \
        --gradient_accumulation_steps 1 \
        --num_train_epochs 20 \
        --logging_steps 100 \
        --save_steps 2000 \
        --overwrite_output_dir \
        --seed 42 \
        2>&1 | tee ${SAVE_DIR}/training.log

}

function program_translation_ngram_evaluation() {
    SAVE_DIR=${OUTPUT_DIR}/program/${SOURCE}2${TARGET}
    path_2_data=${CODE_DIR_HOME}/data
    MODEL_PATH=${SAVE_DIR}/checkpoint-best-ppl/pytorch_model.bin
    GROUND_TRUTH_PATH=${path_2_data}/test.jsonl
    RESULT_FILE=${SAVE_DIR}/ngram_eval.txt

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
        --beam_size 10 \
        --per_gpu_eval_batch_size 8 \
        --seed 42 \
        2>&1 | tee ${SAVE_DIR}/evaluation.log

    python $evaluator_script/evaluator.py \
        --references $GROUND_TRUTH_PATH \
        --predictions $SAVE_DIR/test.output \
        --language $TARGET \
        2>&1 | tee $RESULT_FILE

    export PYTHONPATH=$CODE_DIR_HOME
    python $codebleu_path/calc_code_bleu.py \
        --ref $GROUND_TRUTH_PATH \
        --hyp $SAVE_DIR/test.output \
        --lang $TARGET \
        2>&1 | tee -a $RESULT_FILE

    python $evaluator_script/compile.py \
        --input_file $SAVE_DIR/test.output \
        --language $TARGET \
        2>&1 | tee -a $RESULT_FILE

    count=$(ls -1 *.class 2>/dev/null | wc -l)
    [[ $count != 0 ]] && rm *.class

}

function program_translation_exec_evaluation() {
    SAVE_DIR=${OUTPUT_DIR}/program/${SOURCE}2${TARGET}
    EXEC_DIR=${SAVE_DIR}/executions
    mkdir -p $EXEC_DIR
    RESULT_FILE=$SAVE_DIR/exec_eval.txt

    export PYTHONPATH=$CODE_DIR_HOME
    python $prog_test_case_dir/compute_ca.py \
        --hyp_paths $SAVE_DIR/test.output \
        --ref_path ${CODE_DIR_HOME}/data/test.jsonl \
        --testcases_dir $prog_test_case_dir \
        --outfolder $EXEC_DIR \
        --source_lang $SOURCE \
        --target_lang $TARGET \
        2>&1 | tee $RESULT_FILE
}

function function_translation_ngram_evaluation() {
    SAVE_DIR=${OUTPUT_DIR}/function/${SOURCE}2${TARGET}
    MODEL_PATH=${SAVE_DIR}/checkpoint-best-ppl/pytorch_model.bin
    RESULT_FILE=${SAVE_DIR}/ngram_eval.txt
    DATA_DIR=${CODE_DIR_HOME}/data/transcoder_test_gfg
    GROUND_TRUTH_PATH=${DATA_DIR}/test.java-python.$TARGET

    python -u run.py \
        --data_dir $DATA_DIR \
        --source $SOURCE \
        --target $TARGET \
        --output_dir $SAVE_DIR \
        --pretrain_dir $PRETRAINDIR \
        --load_model_path $MODEL_PATH \
        --model_type gpt2 \
        --block_size 512 \
        --do_infer \
        --beam_size 10 \
        --per_gpu_eval_batch_size 8 \
        --seed 42 \
        2>&1 | tee ${SAVE_DIR}/evaluation.log

    python $evaluator_script/evaluator.py \
        --references $GROUND_TRUTH_PATH \
        --txt_ref \
        --predictions $SAVE_DIR/test.output \
        --language $TARGET \
        2>&1 | tee $RESULT_FILE

    export PYTHONPATH=$CODE_DIR_HOME
    python $codebleu_path/calc_code_bleu.py \
        --ref $GROUND_TRUTH_PATH \
        --txt_ref \
        --hyp $SAVE_DIR/test.output \
        --lang $TARGET \
        2>&1 | tee -a $RESULT_FILE

}

function function_translation_exec_evaluation() {
    SAVE_DIR=${OUTPUT_DIR}/function/${SOURCE}2${TARGET}
    DATA_DIR=${CODE_DIR_HOME}/data/transcoder_test_gfg
    EXEC_DIR=${SAVE_DIR}/executions
    mkdir -p $EXEC_DIR
    RESULT_FILE=${SAVE_DIR}/exec_eval.txt

    export PYTHONPATH=$CODE_DIR_HOME
    python $evaluator_script/compute_ca.py \
        --src_path $DATA_DIR/test.java-python.${SOURCE} \
        --ref_path $DATA_DIR/test.java-python.${TARGET} \
        --hyp_paths $SAVE_DIR/test.output \
        --id_path $DATA_DIR/test.java-python.id \
        --split test \
        --outfolder $EXEC_DIR \
        --source_lang $SOURCE \
        --target_lang $TARGET \
        --retry_mismatching_types True \
        2>&1 | tee $RESULT_FILE

    python $evaluator_script/classify_errors.py \
        --logfile $EXEC_DIR/test_${SOURCE}-${TARGET}.log \
        --lang $TARGET \
        2>&1 | tee -a $RESULT_FILE
}

train 'program'
train 'function'

program_translation_ngram_evaluation
program_translation_exec_evaluation

function_translation_ngram_evaluation
function_translation_exec_evaluation
