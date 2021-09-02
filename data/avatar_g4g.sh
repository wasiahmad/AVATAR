#!/usr/bin/env bash

if [[ ! -d g4g_functions ]]; then
    python g4g_fn.py;
fi

for split in train valid test; do
    python gen_tests.py \
        --src_dir g4g_functions \
        --out_dir avatar_g4g_fn \
        --split $split;
done