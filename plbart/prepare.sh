#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8;
CURRENT_DIR=`pwd`
CODE_DIR_HOME=`realpath ..`;

TOK_DIR=${CODE_DIR_HOME}/plbart/tokenizer
DICT_FILE=${TOK_DIR}/dict.txt # dict.txt
if [[ ! -f $DICT_FILE ]]; then
    SPM_VOCAB=${TOK_DIR}/sentencepiece.bpe.vocab
    cut -f1 $SPM_VOCAB | tail -n +4 | sed "s/$/ 100/g" > $DICT_FILE
fi


function spm_preprocess () {

for SPLIT in "${SPLITS[@]}"; do
    if [[ ! -f $DATA_DIR/${SPLIT}.java-python.spm.java ]]; then
        python ${TOK_DIR}/encode.py \
            --model_file $TOK_DIR/sentencepiece.bpe.model \
            --input_source $DATA_DIR/${SPLIT}.java-python.java \
            --input_target $DATA_DIR/${SPLIT}.java-python.python \
            --output_source $DATA_DIR/${SPLIT}.java-python.spm.java \
            --output_target $DATA_DIR/${SPLIT}.java-python.spm.python \
            --max_len 510 \
            --workers 60;
    fi
done

}


function binarize () {

if [[ -d $DEST_DIR ]]; then
    return 0
fi

if [[ -f $DATA_DIR/train.java-python.spm.java && \
      -f $DATA_DIR/train.java-python.spm.python ]]; then
    INCLUDE_TRAIN="--trainpref $DATA_DIR/train.java-python.spm"
else
    INCLUDE_TRAIN=""
fi

fairseq-preprocess \
    --source-lang java \
    --target-lang python \
    $INCLUDE_TRAIN \
    --validpref $DATA_DIR/valid.java-python.spm \
    --testpref $DATA_DIR/test.java-python.spm \
    --destdir $DEST_DIR \
    --workers 60 \
    --srcdict $DICT_FILE \
    --tgtdict $DICT_FILE;

fairseq-preprocess \
    --source-lang python \
    --target-lang java \
    $INCLUDE_TRAIN \
    --validpref $DATA_DIR/valid.java-python.spm \
    --testpref $DATA_DIR/test.java-python.spm \
    --destdir $DEST_DIR \
    --workers 60 \
    --srcdict $DICT_FILE \
    --tgtdict $DICT_FILE;

}


DATA_DIR=${CODE_DIR_HOME}/data
SPLITS=(train valid test)
DEST_DIR=$DATA_DIR/plbart-bin
spm_preprocess;
binarize;

DATA_DIR=${CODE_DIR_HOME}/data/g4g_functions
SPLITS=(train valid test)
DEST_DIR=$DATA_DIR/plbart-bin
spm_preprocess;
binarize;

DATA_DIR=${CODE_DIR_HOME}/evaluation/TransCoder
SPLITS=(valid test)
DEST_DIR=$DATA_DIR/plbart-bin
spm_preprocess;
binarize;
