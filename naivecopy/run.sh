#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8;
CURRENT_DIR=`pwd`
CODE_DIR_HOME=`realpath ../`;

evaluator_script="${CODE_DIR_HOME}/evaluation";
codebleu_path="${CODE_DIR_HOME}/evaluation/CodeBLEU";
path_2_data=${CODE_DIR_HOME}/data;

function evaluate () {

SOURCE_LANG=$1
TARGET_LANG=$2
RESULT_DIR=${CURRENT_DIR}/${SOURCE_LANG}2${TARGET_LANG};
mkdir -p $RESULT_DIR

RESULT_FILE=${RESULT_DIR}/result.txt;
GOUND_TRUTH_PATH=${path_2_data}/test.jsonl;
INPUT_FILE=${path_2_data}/test.java-python.${SOURCE_LANG};

python $evaluator_script/evaluator.py \
    --references $GOUND_TRUTH_PATH \
    --predictions $INPUT_FILE \
    --language $TARGET_LANG \
    2>&1 | tee -a $RESULT_FILE;

cd $codebleu_path;
python calc_code_bleu.py \
    --ref $GOUND_TRUTH_PATH \
    --hyp $INPUT_FILE \
    --lang $TARGET_LANG \
    2>&1 | tee -a $RESULT_FILE;
cd $CURRENT_DIR;

}

evaluate java python;
evaluate python java;
