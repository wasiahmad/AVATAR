#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8;
CURRENT_DIR=`pwd`
CODE_DIR_HOME=`realpath ..`;

GPU=${1:-0};
EVAL_DATA=${2:-avatar};

export CUDA_VISIBLE_DEVICES=$GPU
evaluator_script="${CODE_DIR_HOME}/evaluation";
codebleu_path="${CODE_DIR_HOME}/evaluation/CodeBLEU";
pretrained_model=${CODE_DIR_HOME}/models/transcoder;

if [[ $EVAL_DATA == 'avatar' ]]; then
    path_2_data=${CODE_DIR_HOME}/data;
elif [[ $EVAL_DATA == 'g4g' ]]; then
    path_2_data=${CODE_DIR_HOME}/evaluation/TransCoder;
fi


function evaluate () {

SOURCE_LANG=$1
TARGET_LANG=$2
INPUT_FILE=${path_2_data}/test.java-python.${SOURCE_LANG};

if [[ $EVAL_DATA == 'g4g' ]]; then
    RESULT_DIR=${CURRENT_DIR}/${EVAL_DATA}/${SOURCE_LANG}2${TARGET_LANG}/transcoder_eval;
    GOUND_TRUTH_PATH=${path_2_data}/test.java-python.${TARGET_LANG};
else
    RESULT_DIR=${CURRENT_DIR}/${EVAL_DATA}/${SOURCE_LANG}2${TARGET_LANG};
    GOUND_TRUTH_PATH=${path_2_data}/test.jsonl;
fi

mkdir -p $RESULT_DIR
FILE_PREF=${RESULT_DIR}/test;
RESULT_FILE=${RESULT_DIR}/result.txt;

if [[ "$SOURCE_LANG" = "java" && "$TARGET_LANG" = "python" ]]; then
    MODEL_PATH=${pretrained_model}/model_1.pth;
elif [[ "$SOURCE_LANG" = "python" && "$TARGET_LANG" = "java" ]]; then
    MODEL_PATH=${pretrained_model}/model_2.pth;
fi

export PYTHONPATH=$CODE_DIR_HOME;
python translate.py \
    --model_path $MODEL_PATH \
    --src_lang $SOURCE_LANG \
    --tgt_lang $TARGET_LANG \
    --BPE_path ./data/BPE_with_comments_codes \
    --input_file $INPUT_FILE \
    --output_file $FILE_PREF.output \
    --beam_size 5;

python $evaluator_script/evaluator.py \
    --references $GOUND_TRUTH_PATH \
    --txt_ref \
    --predictions $FILE_PREF.output \
    --language $TARGET_LANG \
    2>&1 | tee -a $RESULT_FILE;

cd $codebleu_path;
python calc_code_bleu.py \
    --ref $GOUND_TRUTH_PATH \
    --txt_ref \
    --hyp $FILE_PREF.output \
    --lang $TARGET_LANG \
    2>&1 | tee -a $RESULT_FILE;
cd $CURRENT_DIR;

}

evaluate java python;
evaluate python java;
