#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8;
DATA_DIR=`pwd`
HOME_DIR=`realpath ..`;

K=${1:-5};


function preprocess () {

if [[ ! -f ${DATA_DIR}/atcoder.jsonl ]]; then
    python preprocess.py \
        --source atcoder \
        --src_dir ${DATA_DIR}/AtCoder \
        --out_file ${DATA_DIR}/atcoder.jsonl \
        --min_len 10 \
        --java_max_len 464 \
        --python_max_len 464 \
        --k 5;
fi

if [[ ! -f ${DATA_DIR}/codejam.jsonl ]]; then
    python preprocess.py \
        --source codejam \
        --src_dir ${DATA_DIR}/CodeJam \
        --out_file ${DATA_DIR}/codejam.jsonl \
        --min_len 10 \
        --java_max_len 464 \
        --python_max_len 464 \
        --k 5;
fi

if [[ ! -f ${DATA_DIR}/codeforces.jsonl ]]; then
    python preprocess.py \
        --source codeforces \
        --src_dir ${DATA_DIR}/CodeForces \
        --out_file ${DATA_DIR}/codeforces.jsonl \
        --min_len 10 \
        --java_max_len 464 \
        --python_max_len 464 \
        --k 5;
fi

if [[ ! -f ${DATA_DIR}/geeksforgeeks.jsonl ]]; then
    python preprocess.py \
        --source geeksforgeeks \
        --src_dir ${DATA_DIR}/GeeksForGeeks \
        --out_file ${DATA_DIR}/geeksforgeeks.jsonl \
        --min_len 10 \
        --java_max_len 464 \
        --python_max_len 464 \
        --k 5;
fi

if [[ ! -f ${DATA_DIR}/projecteuler.jsonl ]]; then
    python preprocess.py \
        --source projecteuler \
        --src_dir ${DATA_DIR}/ProjectEuler \
        --out_file ${DATA_DIR}/projecteuler.jsonl \
        --min_len 10 \
        --java_max_len 464 \
        --python_max_len 464 \
        --k 5;
fi

if [[ ! -f ${DATA_DIR}/leetcode.jsonl ]]; then
    python preprocess.py \
        --source leetcode \
        --src_dir ${DATA_DIR}/LeetCode \
        --out_file ${DATA_DIR}/leetcode.jsonl \
        --min_len 10 \
        --java_max_len 464 \
        --python_max_len 464 \
        --k 5;
fi

}

function prepare () {

FILES=()
FILES+=(${DATA_DIR}/atcoder.jsonl)
FILES+=(${DATA_DIR}/codejam.jsonl)
FILES+=(${DATA_DIR}/codeforces.jsonl)
FILES+=(${DATA_DIR}/geeksforgeeks.jsonl)
FILES+=(${DATA_DIR}/projecteuler.jsonl)
FILES+=(${DATA_DIR}/leetcode.jsonl)

if [[ ! -f ${DATA_DIR}/train.jsonl ]]; then
    python split.py \
        --src_file "${FILES[@]}" \
        --out_dir $DATA_DIR \
        --fn 'split';
fi

python split.py \
    --src_dir $DATA_DIR \
    --out_dir $DATA_DIR \
    --fn 'prepare' \
    --k $K;

}

preprocess;
prepare;