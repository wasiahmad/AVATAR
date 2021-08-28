#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8;
CURRENT_DIR=`pwd`
CODE_DIR_HOME=`realpath ..`;

evaluator_script="${CODE_DIR_HOME}/evaluation";
codebleu_path="${CODE_DIR_HOME}/evaluation/CodeBLEU";

GPU=${1:-0};
SOURCE=${2:-java};
TARGET=${3:-python};

export CUDA_VISIBLE_DEVICES=$GPU
echo "Source: $SOURCE Target: $TARGET"

path_2_data=${CODE_DIR_HOME}/data;
SAVE_DIR=${CURRENT_DIR}/transformer/${SOURCE}2${TARGET};
mkdir -p $SAVE_DIR

EMBED_DIM=768; # 512
FFN_EMBED_DIM=3072 # 2048
NUM_HEADS=12; # 8
NUM_LAYERS=6;

# Assume 32 batch sizes, use 2 GPUs
BATCH_SIZE=4;
UPDATE_FREQ=4;
MAX_UPDATES=100000;
WARMUP=1500;


function train () {

fairseq-train "$path_2_data"/binary \
    --source-lang $SOURCE \
    --target-lang $TARGET \
    --save-dir $SAVE_DIR \
    --skip-invalid-size-inputs-valid-test \
    --arch transformer \
    --task translation \
    --truncate-source \
    --max-source-positions 512 \
    --max-target-positions 512 \
    --encoder-learned-pos \
    --decoder-learned-pos \
    --layernorm-embedding \
    --no-scale-embedding \
    --encoder-embed-dim $EMBED_DIM \
    --decoder-embed-dim $EMBED_DIM \
    --encoder-ffn-embed-dim $FFN_EMBED_DIM \
    --decoder-ffn-embed-dim $FFN_EMBED_DIM \
    --encoder-layers $NUM_LAYERS \
    --decoder-layers $NUM_LAYERS \
    --encoder-attention-heads $NUM_HEADS \
    --decoder-attention-heads $NUM_HEADS \
    --attention-dropout 0.2 \
    --activation-dropout 0.2 \
    --dropout 0.2 \
    --share-all-embeddings \
    --share-decoder-input-output-embed \
    --required-batch-size-multiple 1 \
    --criterion label_smoothed_cross_entropy \
    --label-smoothing 0.1 \
    --weight-decay 0.01 \
    --optimizer adam \
    --adam-betas "(0.9, 0.999)" \
    --adam-eps 1e-08 \
    --clip-norm 1.0 \
    --lr-scheduler polynomial_decay \
    --lr 1e-04 \
    --max-update $MAX_UPDATES \
    --warmup-updates $WARMUP \
    --batch-size $BATCH_SIZE \
    --update-freq $UPDATE_FREQ \
    --validate-interval 1 \
    --patience 10 \
    --eval-bleu \
    --eval-bleu-detok space \
    --eval-tokenized-bleu \
    --eval-bleu-remove-bpe sentencepiece \
    --eval-bleu-args '{"beam": 5}' \
    --best-checkpoint-metric bleu \
    --maximize-best-checkpoint-metric \
    --no-epoch-checkpoints \
    --find-unused-parameters \
    --ddp-backend=no_c10d \
    --seed 1234 \
    --log-format json \
    --log-interval 100 \
    2>&1 | tee ${SAVE_DIR}/training.log;

}


function evaluate () {

MODEL_PATH=${SAVE_DIR}/checkpoint_best.pt;
FILE_PREF=${SAVE_DIR}/output;
RESULT_FILE=${SAVE_DIR}/result.txt;
GOUND_TRUTH_PATH=${path_2_data}/test.jsonl;

fairseq-generate "$path_2_data"/binary \
    --path $MODEL_PATH \
    --task translation \
    --gen-subset test \
    --source-lang $SOURCE \
    --target-lang $TARGET \
    --sacrebleu \
    --remove-bpe 'sentencepiece' \
    --max-len-b 500 \
    --batch-size 8 \
    --beam 5 > $FILE_PREF

cat $FILE_PREF | grep -P "^H" |sort -V |cut -f 3- > $FILE_PREF.hyp

python $evaluator_script/evaluator.py \
    --references $GOUND_TRUTH_PATH \
    --predictions $FILE_PREF.hyp \
    --language $TARGET \
    2>&1 | tee -a $RESULT_FILE;

cd $codebleu_path;
python calc_code_bleu.py \
    --ref $GOUND_TRUTH_PATH \
    --hyp $FILE_PREF.hyp \
    --lang $TARGET \
    2>&1 | tee -a $RESULT_FILE;
cd $CURRENT_DIR;

python $evaluator_script/compile.py \
    --input_file $FILE_PREF.hyp \
    --language $TARGET \
    2>&1 | tee -a $RESULT_FILE;

}


train;
evaluate;
