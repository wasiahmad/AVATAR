#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8
DATA_DIR=$(pwd)
DATA_ROOT_DIR=$(realpath ..)

url=https://dax-cdn.cdn.appdomain.cloud/dax-project-codenet/1.0.0

# download main data
FILE=Project_CodeNet.tar.gz
if [[ ! -f $DATA_DIR/$FILE ]]; then
    wget -c $url/$FILE -P $DATA_DIR
    tar -xzf $DATA_DIR/$FILE -C $DATA_DIR
fi

# download meta data
FILE=Project_CodeNet_metadata.tar.gz
if [[ ! -f $DATA_DIR/$FILE ]]; then
    wget -c $url/$FILE -P $DATA_DIR
    tar -xzf $DATA_DIR/$FILE -C $DATA_DIR
fi

JSONL_DATA_DIR=$DATA_DIR/jsonl
mkdir -p $JSONL_DATA_DIR

# create AIZU data
rm -rf $DATA_ROOT_DIR/AIZU
python ${DATA_DIR}/source/aizu.py \
    --data_dir $DATA_DIR/Project_CodeNet/data \
    --metadata_dir $DATA_DIR/Project_CodeNet/metadata \
    --output_dir $DATA_ROOT_DIR/AIZU

# create AtCoder data
rm -rf $DATA_ROOT_DIR/AtCoder
python ${DATA_DIR}/source/atcoder.py \
    --data_dir $DATA_DIR/Project_CodeNet/data \
    --metadata_dir $DATA_DIR/Project_CodeNet/metadata \
    --output_dir $DATA_ROOT_DIR/AtCoder
