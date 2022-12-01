#!/usr/bin/env bash

HOME_DIR=$(realpath ..)
CURRENT_DIR=$(pwd)

TGT_DIR=${CURRENT_DIR}/parallel_functions
if [[ ! -d $TGT_DIR ]]; then
    python mine_para_fn.py \
        --sim 0.8 \
        --out_dir $TGT_DIR
    # we generate train data from AVATAR
    # use the G4G validation and test set from TransCoder
    for SPLIT in valid test; do
        cp transcoder_test_gfg/${SPLIT}.java-python.id $TGT_DIR
        cp transcoder_test_gfg/${SPLIT}.java-python.java $TGT_DIR
        cp transcoder_test_gfg/${SPLIT}.java-python.python $TGT_DIR
    done
fi
