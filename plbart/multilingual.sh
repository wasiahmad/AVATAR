#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8
CURRENT_DIR=$(pwd)
CODE_DIR_HOME=$(realpath ..)

evaluator_script="${CODE_DIR_HOME}/evaluation"
codebleu_path="${CODE_DIR_HOME}/evaluation/CodeBLEU"
prog_test_case_dir="${CODE_DIR_HOME}/test_cases"

GPU=${1:-0}
export CUDA_VISIBLE_DEVICES=$GPU

# <path to a file which contains a list of languages separated by new lines>
lang_list=${CODE_DIR_HOME}/plbart/lang_dict.txt
lang_pairs="java-python,python-java"

# assume 32 batch size, 4 gpus.
BATCH_SIZE=8
UPDATE_FREQ=1
MAX_UPDATES=30000
WARMUP=1500

USER_DIR=${CODE_DIR_HOME}/plbart/source
restore_path=${CODE_DIR_HOME}/models/plbart/checkpoint_11_100000.pt

function train() {
    DATA_SRC=$1
    if [[ $DATA_SRC == 'program' ]]; then
        path_2_data=${CODE_DIR_HOME}/data
    elif [[ $DATA_SRC == 'function' ]]; then
        path_2_data=${CODE_DIR_HOME}/data/parallel_functions
    fi

    SAVE_DIR=${CURRENT_DIR}/${DATA_SRC}/multilingual
    mkdir -p $SAVE_DIR

    printf "Training For : $lang_pairs \n"
    fairseq-train $path_2_data/plbart-bin \
        --user-dir $USER_DIR \
        --task translation_multi_simple_epoch_extended \
        --lang-dict $lang_list \
        --lang-tok-style 'mbart' \
        --lang-pairs $lang_pairs \
        --batch-size $BATCH_SIZE \
        --update-freq $UPDATE_FREQ \
        --arch mbart_base \
        --layernorm-embedding \
        --sampling-method concat \
        --encoder-langtok "src" \
        --decoder-langtok \
        --criterion label_smoothed_cross_entropy \
        --label-smoothing 0.2 \
        --optimizer adam \
        --adam-eps 1e-06 \
        --adam-betas '(0.9, 0.98)' \
        --lr-scheduler inverse_sqrt \
        --lr 5e-05 \
        --warmup-updates $WARMUP \
        --max-update $MAX_UPDATES \
        --dropout 0.1 \
        --attention-dropout 0.1 \
        --weight-decay 0.1 \
        --no-epoch-checkpoints \
        --patience 10 \
        --seed 1234 \
        --log-format json \
        --log-interval 100 \
        --save-dir $SAVE_DIR \
        --eval-bleu \
        --eval-bleu-detok space \
        --eval-tokenized-bleu \
        --eval-bleu-remove-bpe sentencepiece \
        --best-checkpoint-metric bleu \
        --valid-subset valid \
        --eval-bleu-args '{"beam": 5}' \
        --maximize-best-checkpoint-metric \
        --restore-file $restore_path \
        --reset-dataloader \
        --reset-optimizer \
        --reset-meters \
        --reset-lr-scheduler \
        2>&1 | tee $SAVE_DIR/training.log

}

function program_translation_ngram_evaluation() {
    SOURCE_LANG=$1
    TARGET_LANG=$2
    MODEL_PATH=${CURRENT_DIR}/program/multilingual/checkpoint_best.pt
    SAVE_DIR=${CURRENT_DIR}/program/multilingual/${SOURCE_LANG}2${TARGET_LANG}
    mkdir -p $SAVE_DIR

    FILE_PREF=${SAVE_DIR}/test
    RESULT_FILE=${SAVE_DIR}/ngram_eval.txt
    path_2_data=${CODE_DIR_HOME}/data
    GOUND_TRUTH_PATH=${path_2_data}/test.jsonl

    echo "==========================================================================" | tee $RESULT_FILE
    echo "Source: ${SOURCE_LANG}                              Target: ${TARGET_LANG}" | tee -a $RESULT_FILE
    echo "--------------------------------------------------------------------------" | tee -a $RESULT_FILE

    fairseq-generate ${path_2_data}/plbart-bin \
        --path $MODEL_PATH \
        --user-dir $USER_DIR \
        --task translation_multi_simple_epoch_extended \
        --gen-subset test \
        --source-lang $SOURCE_LANG \
        --target-lang $TARGET_LANG \
        --scoring sacrebleu \
        --remove-bpe 'sentencepiece' \
        --max-len-b 500 \
        --batch-size 8 \
        --encoder-langtok "src" \
        --decoder-langtok \
        --lang-tok-style 'mbart' \
        --lang-dict $lang_list \
        --lang-pairs $lang_pairs \
        --beam 10 >$FILE_PREF

    cat $FILE_PREF | grep -P "^H" | sort -V | cut -f 3- | cut -d' ' -f 2- >$FILE_PREF.output

    python $evaluator_script/evaluator.py \
        --references $GOUND_TRUTH_PATH \
        --predictions $FILE_PREF.output \
        --language $TARGET_LANG \
        2>&1 | tee -a $RESULT_FILE

    export PYTHONPATH=$CODE_DIR_HOME
    python $codebleu_path/calc_code_bleu.py \
        --ref $GOUND_TRUTH_PATH \
        --hyp $FILE_PREF.output \
        --lang $TARGET_LANG \
        2>&1 | tee -a $RESULT_FILE

    python $evaluator_script/compile.py \
        --input_file $FILE_PREF.output \
        --language $TARGET_LANG \
        2>&1 | tee -a $RESULT_FILE

}

function program_translation_exec_evaluation() {
    SOURCE_LANG=$1
    TARGET_LANG=$2
    SAVE_DIR=${CURRENT_DIR}/program/multilingual/${SOURCE_LANG}2${TARGET_LANG}
    EXEC_DIR=${SAVE_DIR}/executions
    mkdir -p $EXEC_DIR
    RESULT_FILE=$SAVE_DIR/exec_eval.txt

    export PYTHONPATH=$CODE_DIR_HOME
    python $prog_test_case_dir/compute_ca.py \
        --hyp_paths $SAVE_DIR/test.output \
        --ref_path ${CODE_DIR_HOME}/data/test.jsonl \
        --testcases_dir $prog_test_case_dir \
        --outfolder $EXEC_DIR \
        --source_lang $SOURCE_LANG \
        --target_lang $TARGET_LANG \
        2>&1 | tee $RESULT_FILE
}

function function_translation_ngram_evaluation() {
    SOURCE_LANG=$1
    TARGET_LANG=$2
    MODEL_PATH=${CURRENT_DIR}/function/multilingual/checkpoint_best.pt
    SAVE_DIR=${CURRENT_DIR}/function/multilingual/${SOURCE_LANG}2${TARGET_LANG}
    mkdir -p $SAVE_DIR

    DATA_DIR=${CODE_DIR_HOME}/data/transcoder_test_gfg
    FILE_PREF=${SAVE_DIR}/test
    RESULT_FILE=${SAVE_DIR}/result.txt
    GOUND_TRUTH_PATH=${DATA_DIR}/test.java-python.$TARGET_LANG

    echo "==========================================================================" | tee $RESULT_FILE
    echo "Source: ${SOURCE_LANG}                              Target: ${TARGET_LANG}" | tee -a $RESULT_FILE
    echo "--------------------------------------------------------------------------" | tee -a $RESULT_FILE

    fairseq-generate ${DATA_DIR}/plbart-bin \
        --path $MODEL_PATH \
        --user-dir $USER_DIR \
        --task translation_multi_simple_epoch_extended \
        --gen-subset test \
        --source-lang $SOURCE_LANG \
        --target-lang $TARGET_LANG \
        --scoring sacrebleu \
        --remove-bpe 'sentencepiece' \
        --max-len-b 500 \
        --batch-size 8 \
        --encoder-langtok "src" \
        --decoder-langtok \
        --lang-tok-style 'mbart' \
        --lang-dict $lang_list \
        --lang-pairs $lang_pairs \
        --beam 10 >$FILE_PREF

    cat $FILE_PREF | grep -P "^H" | sort -V | cut -f 3- | cut -d' ' -f 2- >$FILE_PREF.output

    python $evaluator_script/evaluator.py \
        --references $GOUND_TRUTH_PATH \
        --txt_ref \
        --predictions $FILE_PREF.output \
        --language $TARGET_LANG \
        2>&1 | tee $RESULT_FILE

    export PYTHONPATH=$CODE_DIR_HOME
    python $codebleu_path/calc_code_bleu.py \
        --ref $GOUND_TRUTH_PATH \
        --txt_ref \
        --hyp $FILE_PREF.output \
        --lang $TARGET_LANG \
        2>&1 | tee -a $RESULT_FILE

}

function function_translation_exec_evaluation() {
    SOURCE=$1
    TARGET=$2
    SAVE_DIR=${CURRENT_DIR}/function/multilingual/${SOURCE}2${TARGET}
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

program_translation_ngram_evaluation java python
program_translation_exec_evaluation java python
program_translation_ngram_evaluation python java
program_translation_exec_evaluation python java

function_translation_ngram_evaluation java python
function_translation_exec_evaluation java python
function_translation_ngram_evaluation python java
function_translation_exec_evaluation python java
