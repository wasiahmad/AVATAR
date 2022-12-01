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

export CUDA_VISIBLE_DEVICES=$GPU
echo "Source: $SOURCE Target: $TARGET"

USER_DIR=${CODE_DIR_HOME}/plbart/source
restore_path=${CODE_DIR_HOME}/models/plbart/checkpoint_11_100000.pt
langs=java,python,en_XX

# assume 32 batch size, 4 gpus.
BATCH_SIZE=8
UPDATE_FREQ=1
MAX_UPDATES=30000
WARMUP=1500

function train() {
    DATA_SRC=$1
    if [[ $DATA_SRC == 'program' ]]; then
        path_2_data=${CODE_DIR_HOME}/data
    elif [[ $DATA_SRC == 'function' ]]; then
        path_2_data=${CODE_DIR_HOME}/data/parallel_functions
    fi

    SAVE_DIR=${CURRENT_DIR}/${DATA_SRC}/${SOURCE}2${TARGET}
    mkdir -p $SAVE_DIR

    fairseq-train $path_2_data/plbart-bin \
        --user-dir $USER_DIR \
        --langs $langs \
        --task translation_from_pretrained_plbart \
        --arch mbart_base \
        --layernorm-embedding \
        --truncate-source \
        --source-lang $SOURCE \
        --target-lang $TARGET \
        --criterion label_smoothed_cross_entropy \
        --label-smoothing 0.1 \
        --batch-size $BATCH_SIZE \
        --update-freq $UPDATE_FREQ \
        --optimizer adam \
        --adam-eps 1e-06 \
        --adam-betas '(0.9, 0.98)' \
        --lr-scheduler polynomial_decay \
        --lr 5e-05 \
        --warmup-updates $WARMUP \
        --max-update $MAX_UPDATES \
        --dropout 0.1 \
        --attention-dropout 0.1 \
        --weight-decay 0.1 \
        --seed 1234 \
        --log-format json \
        --log-interval 100 \
        --restore-file $restore_path \
        --reset-dataloader \
        --reset-optimizer \
        --reset-meters \
        --reset-lr-scheduler \
        --eval-bleu \
        --eval-bleu-detok space \
        --eval-tokenized-bleu \
        --eval-bleu-remove-bpe sentencepiece \
        --eval-bleu-args '{"beam": 5}' \
        --best-checkpoint-metric bleu \
        --maximize-best-checkpoint-metric \
        --no-epoch-checkpoints \
        --patience 10 \
        --ddp-backend no_c10d \
        --save-dir $SAVE_DIR \
        2>&1 | tee ${SAVE_DIR}/training.log

}

function program_translation_ngram_evaluation() {
    SAVE_DIR=${CURRENT_DIR}/program/${SOURCE}2${TARGET}
    path_2_data=${CODE_DIR_HOME}/data
    MODEL_PATH=${SAVE_DIR}/checkpoint_best.pt
    FILE_PREF=${SAVE_DIR}/test
    GROUND_TRUTH_PATH=${path_2_data}/test.jsonl
    RESULT_FILE=${SAVE_DIR}/ngram_eval.txt

    fairseq-generate $path_2_data/plbart-bin \
        --user-dir $USER_DIR \
        --path $MODEL_PATH \
        --truncate-source \
        --task translation_from_pretrained_plbart \
        --gen-subset test \
        --source-lang $SOURCE \
        --target-lang $TARGET \
        --scoring sacrebleu \
        --remove-bpe 'sentencepiece' \
        --max-len-b 500 \
        --batch-size 8 \
        --beam 10 \
        --langs $langs >$FILE_PREF

    cat $FILE_PREF | grep -P "^H" | sort -V | cut -f 3- | sed 's/\[${TARGET}\]//g' >$FILE_PREF.output

    python $evaluator_script/evaluator.py \
        --references $GROUND_TRUTH_PATH \
        --predictions $FILE_PREF.output \
        --language $TARGET \
        2>&1 | tee $RESULT_FILE

    export PYTHONPATH=$CODE_DIR_HOME
    python $codebleu_path/calc_code_bleu.py \
        --ref $GROUND_TRUTH_PATH \
        --hyp $FILE_PREF.output \
        --lang $TARGET \
        2>&1 | tee -a $RESULT_FILE

    python $evaluator_script/compile.py \
        --input_file $FILE_PREF.output \
        --language $TARGET \
        2>&1 | tee -a $RESULT_FILE

    count=$(ls -1 *.class 2>/dev/null | wc -l)
    [[ $count != 0 ]] && rm *.class

}

function program_translation_exec_evaluation() {
    SAVE_DIR=${CURRENT_DIR}/program/${SOURCE}2${TARGET}
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
    SAVE_DIR=${CURRENT_DIR}/function/${SOURCE}2${TARGET}
    MODEL_PATH=${SAVE_DIR}/checkpoint_best.pt
    DATA_DIR=${CODE_DIR_HOME}/data/transcoder_test_gfg
    FILE_PREF=${SAVE_DIR}/test
    RESULT_FILE=${SAVE_DIR}/ngram_eval.txt
    GROUND_TRUTH_PATH=${DATA_DIR}/test.java-python.$TARGET

    fairseq-generate $DATA_DIR/plbart-bin \
        --user-dir $USER_DIR \
        --path $MODEL_PATH \
        --truncate-source \
        --task translation_from_pretrained_plbart \
        --gen-subset test \
        --source-lang $SOURCE \
        --target-lang $TARGET \
        --scoring sacrebleu \
        --remove-bpe 'sentencepiece' \
        --max-len-b 500 \
        --batch-size 8 \
        --beam 10 \
        --langs $langs >$FILE_PREF

    cat $FILE_PREF | grep -P "^H" | sort -V | cut -f 3- | sed 's/\[${TARGET}\]//g' >$FILE_PREF.output

    python $evaluator_script/evaluator.py \
        --references $GROUND_TRUTH_PATH \
        --txt_ref \
        --predictions $FILE_PREF.output \
        --language $TARGET \
        2>&1 | tee $RESULT_FILE

    export PYTHONPATH=$CODE_DIR_HOME
    python $codebleu_path/calc_code_bleu.py \
        --ref $GROUND_TRUTH_PATH \
        --txt_ref \
        --hyp $FILE_PREF.output \
        --lang $TARGET \
        2>&1 | tee -a $RESULT_FILE

}

function function_translation_exec_evaluation() {
    SAVE_DIR=${CURRENT_DIR}/function/${SOURCE}2${TARGET}
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
