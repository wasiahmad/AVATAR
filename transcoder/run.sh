#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8;
CURRENT_DIR=`pwd`
CODE_DIR_HOME=`realpath ..`;

GPU=${1:-0};
EVAL_DATA=${2:-avatar};
MODEL_NAME=${3:-'transcoder-dobf'};
MODEL_TYPE=${4:-'multilingual'};

export CUDA_VISIBLE_DEVICES=$GPU
evaluator_script="${CODE_DIR_HOME}/evaluation";
codebleu_path="${CODE_DIR_HOME}/evaluation/CodeBLEU";
pretrained_model=${CODE_DIR_HOME}/models/transcoder;

path_2_data=${CODE_DIR_HOME}/data;
if [[ $EVAL_DATA == 'g4g' ]]; then
    path_2_data=${path_2_data}/transcoder_test_gfg;
fi


function evaluate () {

SOURCE_LANG=$1
TARGET_LANG=$2
INPUT_FILE=${path_2_data}/test.java-python.${SOURCE_LANG};
BPE_PATH=${CODE_DIR_HOME}/codegen/bpe/cpp-java-python/codes

RESULT_DIR=${CURRENT_DIR}/${EVAL_DATA}/${MODEL_NAME}/${SOURCE_LANG}2${TARGET_LANG};
TEXT_REF=""
if [[ $EVAL_DATA == 'g4g' ]]; then
    RESULT_DIR=${RESULT_DIR}/transcoder_eval;
    GOUND_TRUTH_PATH=${path_2_data}/test.java-python.${TARGET_LANG};
    TEXT_REF="--txt_ref"
else
    GOUND_TRUTH_PATH=${path_2_data}/test.jsonl;
fi

mkdir -p $RESULT_DIR
FILE_PREF=${RESULT_DIR}/test;
RESULT_FILE=${RESULT_DIR}/result.txt;

if [[ $MODEL_NAME == 'transcoder-ft' ]]; then
    if [[ $MODEL_TYPE == 'multilingual' ]]; then
        EXP_ID=${SOURCE_LANG}-${TARGET_LANG}_${TARGET_LANG}-${SOURCE_LANG};
        MODEL_FILENAME=best-valid_python-java_mt_bleu.pth;
    else
        EXP_ID=${SOURCE_LANG}-${TARGET_LANG};
        MODEL_FILENAME=best-valid_${SOURCE_LANG}-${TARGET_LANG}_mt_bleu.pth;
    fi
    MODEL_PATH=${CURRENT_DIR}/${EVAL_DATA}/${MODEL_NAME}/${EXP_ID};
    MODEL_PATH=${MODEL_PATH}/${MODEL_FILENAME};
elif [[ $MODEL_NAME == 'transcoder-dobf' ]]; then
    MODEL_PATH=${pretrained_model}/translator_transcoder_size_from_DOBF.pth;
else
    if [[ "$SOURCE_LANG" = "java" && "$TARGET_LANG" = "python" ]]; then
        MODEL_PATH=${pretrained_model}/TransCoder_model_1.pth;
    elif [[ "$SOURCE_LANG" = "python" && "$TARGET_LANG" = "java" ]]; then
        MODEL_PATH=${pretrained_model}/TransCoder_model_2.pth;
    fi
fi

export PYTHONPATH=$CODE_DIR_HOME;
python translate.py \
    --model_path $MODEL_PATH \
    --src_lang $SOURCE_LANG \
    --tgt_lang $TARGET_LANG \
    --BPE_path $BPE_PATH \
    --input_file $INPUT_FILE \
    --output_file $FILE_PREF.output \
    --beam_size 5;

python $evaluator_script/evaluator.py \
    --references $GOUND_TRUTH_PATH $TEXT_REF \
    --predictions $FILE_PREF.output \
    --language $TARGET_LANG \
    2>&1 | tee $RESULT_FILE;

cd $codebleu_path;
python calc_code_bleu.py \
    --ref $GOUND_TRUTH_PATH $TEXT_REF \
    --hyp $FILE_PREF.output \
    --lang $TARGET_LANG \
    2>&1 | tee -a $RESULT_FILE;
cd $CURRENT_DIR;

[[ $EVAL_DATA == 'g4g' ]] && return 0;

python $evaluator_script/compile.py \
    --input_file $FILE_PREF.output \
    --language $TARGET_LANG \
    2>&1 | tee -a $RESULT_FILE;

count=`ls -1 *.class 2>/dev/null | wc -l`;
[[ $count != 0 ]] && rm *.class;

}

evaluate java python;
evaluate python java;
