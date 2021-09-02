#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8;
CURRENT_DIR=`pwd`
CODE_DIR_HOME=`realpath ..`;
export PYTHONPATH=$CODE_DIR_HOME;

function bpe_encode () {

for SPLIT in "${SPLITS[@]}"; do
    if [[ ! -f $DEST_DIR/${SPLIT}.java-python.bpe.java ]]; then
        python bpe_encode.py \
            --codes ${CODE_DIR_HOME}/codegen/bpe/cpp-java-python/codes \
            --inputs $DATA_DIR/${SPLIT}.java-python.java \
                $DATA_DIR/${SPLIT}.java-python.python \
            --outputs $DEST_DIR/${SPLIT}.java-python.bpe.java \
                $DEST_DIR/${SPLIT}.java-python.bpe.python \
            --max_len 510 \
            --workers 60;
    fi
done

}


function binarize () {

VOCAB_PATH=${CODE_DIR_HOME}/codegen/bpe/cpp-java-python/vocab

for SPLIT in "${SPLITS[@]}"; do
    for lang in java python; do
        TXT_PATH=$DEST_DIR/${SPLIT}.java-python.bpe.$lang
        BIN_PATH=$DEST_DIR/${SPLIT}.java-python.$lang
        python ${CODE_DIR_HOME}/codegen/model/preprocess.py $VOCAB_PATH $TXT_PATH $BIN_PATH;
    done
done

}


DATA_DIR=${CODE_DIR_HOME}/data
SPLITS=(train valid test)
DEST_DIR=$DATA_DIR/transcoder-bin
mkdir -p $DEST_DIR
bpe_encode;
binarize;

DATA_DIR=${CODE_DIR_HOME}/data/g4g_functions
SPLITS=(train valid test)
DEST_DIR=$DATA_DIR/transcoder-bin
mkdir -p $DEST_DIR
bpe_encode;
binarize;
