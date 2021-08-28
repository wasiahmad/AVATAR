#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8;
CURRENT_DIR=`pwd`
CODE_DIR_HOME=`realpath ../..`;

SPLIT=test
SOURCE=${1:-java};
TARGET=${2:-python};
MODEL=${3:-codebert};
DATA_SRC=${4:-g4g};

if [[ $MODEL == "plbart-multilingual" ]]; then
    HYP_PATH_PREFIX=${CODE_DIR_HOME}/plbart/${DATA_SRC}/multilingual;
else
    HYP_PATH_PREFIX=${CODE_DIR_HOME}/${MODEL}/${DATA_SRC};
fi

HYP_PATH=${HYP_PATH_PREFIX}/${SOURCE}2${TARGET}/transcoder_eval/${SPLIT}.output;
OUTDIR=${CURRENT_DIR}/${MODEL}
mkdir -p $OUTDIR

export PYTHONPATH=$CODE_DIR_HOME;
python evaluate.py \
    --ref_path ${SPLIT}.java-python.${TARGET} \
    --hyp_paths $HYP_PATH \
    --id_path ${SPLIT}.java-python.id \
    --split $SPLIT \
    --outfolder $OUTDIR \
    --source_lang $SOURCE \
    --target_lang $TARGET \
    --retry_mismatching_types True;
