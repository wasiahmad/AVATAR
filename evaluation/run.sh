#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8;
CURRENT_DIR=`pwd`
CODE_DIR_HOME=`realpath ..`;

SPLIT=test
SOURCE=${1:-java};
TARGET=${2:-python};
MODEL=${3:-codebert};

if [[ $MODEL == transcoder* ]]; then
    HYP_PATH_PREFIX=${CODE_DIR_HOME}/transcoder/g4g/${MODEL};
elif [[ $MODEL == "plbart-multilingual" ]]; then
    HYP_PATH_PREFIX=${CODE_DIR_HOME}/plbart/g4g/multilingual;
else
    HYP_PATH_PREFIX=${CODE_DIR_HOME}/${MODEL}/g4g;
fi

DATA_DIR=${CODE_DIR_HOME}/data/transcoder_test_gfg
HYP_PATH=${HYP_PATH_PREFIX}/${SOURCE}2${TARGET}/transcoder_eval/${SPLIT}.output;
OUTDIR=${CURRENT_DIR}/${MODEL}
mkdir -p $OUTDIR

export PYTHONPATH=$CODE_DIR_HOME;
python compute_ca.py \
    --src_path ${DATA_DIR}/${SPLIT}.java-python.${SOURCE} \
    --ref_path ${DATA_DIR}/${SPLIT}.java-python.${TARGET} \
    --hyp_paths $HYP_PATH \
    --id_path ${DATA_DIR}/${SPLIT}.java-python.id \
    --split $SPLIT \
    --outfolder $OUTDIR \
    --source_lang $SOURCE \
    --target_lang $TARGET \
    --retry_mismatching_types True;

python classify_errors.py \
    --logfile ${OUTDIR}/${SPLIT}_${SOURCE}-${TARGET}.log \
    --lang $TARGET;
