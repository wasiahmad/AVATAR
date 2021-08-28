#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8;
CURRENT_DIR=`pwd`
CODE_DIR_HOME=`realpath ..`;

evaluator_script="${CODE_DIR_HOME}/evaluation";
codebleu_path="${CODE_DIR_HOME}/evaluation/CodeBLEU";

GPU=${1:-0};
SOURCE=${2:-java};
TARGET=${3:-python};
DATA_SRC=${4:-avatar};

export CUDA_VISIBLE_DEVICES=$GPU
echo "Source: $SOURCE Target: $TARGET"

if [[ $DATA_SRC == 'avatar' ]]; then
    path_2_data=${CODE_DIR_HOME}/data;
elif [[ $DATA_SRC == 'g4g' ]]; then
    path_2_data=${CODE_DIR_HOME}/data/g4g_functions;
fi

SAVE_DIR=${CURRENT_DIR}/${DATA_SRC}/${SOURCE}2${TARGET};
mkdir -p $SAVE_DIR

restore_path=${CODE_DIR_HOME}/models/plbart/checkpoint_11_100000.pt;
langs=java,python,en_XX

# Assume 32 batch sizes, use 2 GPUs.
BATCH_SIZE=4;
UPDATE_FREQ=4;
MAX_UPDATES=30000;
WARMUP=1500;


function train () {

fairseq-train $path_2_data/plbart-bin \
    --langs $langs \
    --task translation_from_pretrained_bart \
    --arch mbart_base \
    --layernorm-embedding \
    --truncate-source \
    --source-lang $SOURCE \
    --target-lang $TARGET \
    --criterion label_smoothed_cross_entropy \
    --label-smoothing 0.1 \
    --batch-size $BATCH_SIZE \
    --update-freq $UPDATE_FREQ \
    --optimizer adam \
    --adam-eps 1e-06 \
    --adam-betas '(0.9, 0.98)' \
    --lr-scheduler polynomial_decay \
    --lr 5e-05 \
    --warmup-updates $WARMUP \
    --max-update $MAX_UPDATES \
    --dropout 0.1 \
    --attention-dropout 0.1 \
    --weight-decay 0.1 \
    --seed 1234 \
    --log-format json \
    --log-interval 100 \
    --restore-file $restore_path \
    --reset-dataloader \
    --reset-optimizer \
    --reset-meters \
    --reset-lr-scheduler \
    --eval-bleu \
    --eval-bleu-detok space \
    --eval-tokenized-bleu \
    --eval-bleu-remove-bpe sentencepiece \
    --eval-bleu-args '{"beam": 5}' \
    --best-checkpoint-metric bleu \
    --maximize-best-checkpoint-metric \
    --no-epoch-checkpoints \
    --patience 10 \
    --ddp-backend no_c10d \
    --save-dir $SAVE_DIR \
    2>&1 | tee ${SAVE_DIR}/training.log;

}


function evaluate () {

MODEL_PATH=${SAVE_DIR}/checkpoint_best.pt;
FILE_PREF=${SAVE_DIR}/output;
RESULT_FILE=${SAVE_DIR}/result.txt;
GOUND_TRUTH_PATH=${path_2_data}/test.jsonl;

fairseq-generate $path_2_data/plbart-bin \
    --path $MODEL_PATH \
    --truncate-source \
    --task translation_from_pretrained_bart \
    --gen-subset test \
    --source-lang $SOURCE \
    --target-lang $TARGET \
    --sacrebleu \
    --remove-bpe 'sentencepiece' \
    --max-len-b 500 \
    --batch-size 8 \
    --beam 5 \
    --langs $langs > $FILE_PREF

cat $FILE_PREF | grep -P "^H" |sort -V |cut -f 3- | sed 's/\[${TARGET}\]//g' > $FILE_PREF.hyp

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


function predict_transcoder_eval () {

MODEL_PATH=${SAVE_DIR}/checkpoint_best.pt;
DATA_DIR=${CODE_DIR_HOME}/evaluation/TransCoder
OUT_DIR=${SAVE_DIR}/transcoder_eval;
mkdir -p $OUT_DIR
FILE_PREF=${OUT_DIR}/test;
RESULT_FILE=${OUT_DIR}/result.txt;
GOUND_TRUTH_PATH=${DATA_DIR}/test.java-python.$TARGET;

fairseq-generate $DATA_DIR/plbart-bin \
    --path $MODEL_PATH \
    --truncate-source \
    --task translation_from_pretrained_bart \
    --gen-subset test \
    --source-lang $SOURCE \
    --target-lang $TARGET \
    --sacrebleu \
    --remove-bpe 'sentencepiece' \
    --max-len-b 500 \
    --batch-size 8 \
    --beam 5 \
    --langs $langs > $FILE_PREF.log

cat $FILE_PREF.log | grep -P "^H" |sort -V |cut -f 3- | sed 's/\[${TARGET}\]//g' > $FILE_PREF.output

python $evaluator_script/evaluator.py \
    --references $GOUND_TRUTH_PATH \
    --txt_ref \
    --predictions $FILE_PREF.output \
    --language $TARGET \
    2>&1 | tee -a $RESULT_FILE;

cd $codebleu_path;
python calc_code_bleu.py \
    --ref $GOUND_TRUTH_PATH \
    --txt_ref \
    --hyp $FILE_PREF.output \
    --lang $TARGET \
    2>&1 | tee -a $RESULT_FILE;
cd $CURRENT_DIR;

}


train;
evaluate;
predict_transcoder_eval;
