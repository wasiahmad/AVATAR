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
MODEL_NAME=${4:-'transcoder'} # transcoder, transcoder-dobf, transcoder-st

export CUDA_VISIBLE_DEVICES=$GPU
echo "Source: $SOURCE Target: $TARGET"
pretrained_model_path=${CODE_DIR_HOME}/models/transcoder

function program_translation_ngram_evaluation() {
    path_2_data=${CODE_DIR_HOME}/data
    BPE_PATH=${CODE_DIR_HOME}/codegen/bpe/cpp-java-python/codes
    INPUT_FILE=${path_2_data}/test.java-python.${SOURCE}
    GROUND_TRUTH_PATH=${path_2_data}/test.jsonl

    SAVE_DIR=${CURRENT_DIR}/zero_shot/${MODEL_NAME}/program/${SOURCE}2${TARGET}
    mkdir -p $SAVE_DIR
    FILE_PREF=${SAVE_DIR}/test
    RESULT_FILE=${SAVE_DIR}/ngram_eval.txt

    if [[ $MODEL_NAME == 'transcoder-st' ]]; then
        if [[ "$SOURCE" == "java" && "$TARGET" == "python" ]]; then
            MODEL_PATH=${pretrained_model_path}/Online_ST_Java_Python.pth
        elif [[ "$SOURCE" == "python" && "$TARGET" == "java" ]]; then
            MODEL_PATH=${pretrained_model_path}/Online_ST_Python_Java.pth
        fi
    elif [[ $MODEL_NAME == 'transcoder-dobf' ]]; then
        MODEL_PATH=${pretrained_model_path}/translator_transcoder_size_from_DOBF.pth
    else
        if [[ "$SOURCE" == "java" && "$TARGET" == "python" ]]; then
            MODEL_PATH=${pretrained_model_path}/TransCoder_model_1.pth
        elif [[ "$SOURCE" == "python" && "$TARGET" == "java" ]]; then
            MODEL_PATH=${pretrained_model_path}/TransCoder_model_2.pth
        fi
    fi

    export PYTHONPATH=$CODE_DIR_HOME
    python translate.py \
        --model_path $MODEL_PATH \
        --src_lang $SOURCE \
        --tgt_lang $TARGET \
        --BPE_path $BPE_PATH \
        --input_file $INPUT_FILE \
        --output_file $FILE_PREF.output \
        --beam_size 10

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
    SAVE_DIR=${CURRENT_DIR}/zero_shot/${MODEL_NAME}/program/${SOURCE}2${TARGET}
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
    path_2_data=${CODE_DIR_HOME}/data/parallel_functions
    BPE_PATH=${CODE_DIR_HOME}/codegen/bpe/cpp-java-python/codes
    INPUT_FILE=${path_2_data}/test.java-python.${SOURCE}
    GROUND_TRUTH_PATH=${path_2_data}/test.java-python.${TARGET}

    SAVE_DIR=${CURRENT_DIR}/zero_shot/${MODEL_NAME}/function/${SOURCE}2${TARGET}
    mkdir -p $SAVE_DIR
    FILE_PREF=${SAVE_DIR}/test
    RESULT_FILE=${SAVE_DIR}/ngram_eval.txt

    if [[ $MODEL_NAME == 'transcoder-st' ]]; then
        if [[ "$SOURCE" == "java" && "$TARGET" == "python" ]]; then
            MODEL_PATH=${pretrained_model_path}/Online_ST_Java_Python.pth
        elif [[ "$SOURCE" == "python" && "$TARGET" == "java" ]]; then
            MODEL_PATH=${pretrained_model_path}/Online_ST_Python_Java.pth
        fi
    elif [[ $MODEL_NAME == 'transcoder-dobf' ]]; then
        MODEL_PATH=${pretrained_model_path}/translator_transcoder_size_from_DOBF.pth
    else
        if [[ "$SOURCE" == "java" && "$TARGET" == "python" ]]; then
            MODEL_PATH=${pretrained_model_path}/TransCoder_model_1.pth
        elif [[ "$SOURCE" == "python" && "$TARGET" == "java" ]]; then
            MODEL_PATH=${pretrained_model_path}/TransCoder_model_2.pth
        fi
    fi

    export PYTHONPATH=$CODE_DIR_HOME
    python translate.py \
        --model_path $MODEL_PATH \
        --src_lang $SOURCE \
        --tgt_lang $TARGET \
        --BPE_path $BPE_PATH \
        --input_file $INPUT_FILE \
        --output_file $FILE_PREF.output \
        --beam_size 10

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
    SAVE_DIR=${CURRENT_DIR}/zero_shot/${MODEL_NAME}/function/${SOURCE}2${TARGET}
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

program_translation_ngram_evaluation
program_translation_exec_evaluation

function_translation_ngram_evaluation
function_translation_exec_evaluation
