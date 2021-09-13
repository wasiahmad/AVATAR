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
SAVE_DIR=${CURRENT_DIR}/rnn/${SOURCE}2${TARGET};
mkdir -p $SAVE_DIR

# Assume 32 batch sizes, Use multiple GPUs for higher sizes.
BATCH_SIZE=16;
UPDATE_FREQ=2;
MAX_UPDATES=30000;


function train () {

fairseq-train "$path_2_data"/binary \
    --save-dir $SAVE_DIR \
    --skip-invalid-size-inputs-valid-test \
    --arch lstm \
    --task translation \
    --truncate-source \
    --encoder-embed-dim 512 \
    --decoder-embed-dim 512 \
    --source-lang $SOURCE \
    --target-lang $TARGET \
    --encoder-layers 1 \
    --decoder-layers 1 \
    --encoder-bidirectional \
    --encoder-hidden-size 512 \
    --decoder-hidden-size 512 \
    --decoder-attention 1 \
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
    --lr 1e-03 \
    --max-update $MAX_UPDATES \
    --batch-size $BATCH_SIZE \
    --update-freq $UPDATE_FREQ \
    --validate-interval 1 \
    --patience 5 \
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
    2>&1 | tee $RESULT_FILE;

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

count=`ls -1 *.class 2>/dev/null | wc -l`;
[[ $count != 0 ]] && rm *.class;

}


train;
evaluate;
