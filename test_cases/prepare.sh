#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8
CURRENT_DIR=$(pwd)
HOME_DIR=$(realpath ..)
DATA_DIR=$HOME_DIR/data

python ${CURRENT_DIR}/atcoder_map.py \
    --source_file $DATA_DIR/atcoder.jsonl \
    --atcoder_tests_dir $CURRENT_DIR/atcoder_test_cases \
    --output_file $CURRENT_DIR/atcoder_id2tests.jsonl

python ${CURRENT_DIR}/codeforces_map.py \
    --source_file $DATA_DIR/codeforces.jsonl \
    --codeforces_tests_dir $CURRENT_DIR/description2code_current/codeforces \
    --output_file $CURRENT_DIR/codeforces_id2tests.jsonl

mkdir -p tmp
export PYTHONPATH=$HOME_DIR

python filter.py \
    --source atcoder \
    --mode filter \
    --ref_path ${HOME_DIR}/data/test.jsonl \
    --testcases_dir $CURRENT_DIR \
    --outfolder tmp \
    --source_lang java \
    --target_lang python \
    --input_test_cases $CURRENT_DIR/atcoder_id2tests.jsonl \
    --output_test_cases $CURRENT_DIR/atcoder_id2tests_filtered.jsonl

python filter.py \
    --source atcoder \
    --mode validate \
    --ref_path ${HOME_DIR}/data/test.jsonl \
    --testcases_dir $CURRENT_DIR \
    --outfolder tmp \
    --source_lang java \
    --target_lang python \
    --input_test_cases $CURRENT_DIR/atcoder_id2tests_filtered.jsonl

python filter.py \
    --source codeforces \
    --mode filter \
    --ref_path ${HOME_DIR}/data/test.jsonl \
    --testcases_dir $CURRENT_DIR \
    --outfolder tmp \
    --source_lang java \
    --target_lang python \
    --input_test_cases $CURRENT_DIR/codeforces_id2tests.jsonl \
    --output_test_cases $CURRENT_DIR/codeforces_id2tests_filtered.jsonl

python filter.py \
    --source codeforces \
    --mode validate \
    --ref_path ${HOME_DIR}/data/test.jsonl \
    --testcases_dir $CURRENT_DIR \
    --outfolder tmp \
    --source_lang java \
    --target_lang python \
    --input_test_cases $CURRENT_DIR/codeforces_id2tests_filtered.jsonl

rm -rf tmp
