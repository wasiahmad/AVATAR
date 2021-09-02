#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8;
CURRENT_DIR=`pwd`
CODE_DIR_HOME=`realpath ..`;

evaluator_script="${CODE_DIR_HOME}/evaluation";
codebleu_path="${CODE_DIR_HOME}/evaluation/CodeBLEU";

GPU=${1:-0};
DATA_SRC=${2:-avatar};
export CUDA_VISIBLE_DEVICES=$GPU

# <path to a file which contains a list of languages separated by new lines>
lang_list=${CODE_DIR_HOME}/plbart/lang_dict.txt;
lang_pairs="java-python,python-java";

if [[ $DATA_SRC == 'avatar' ]]; then
    path_2_data=${CODE_DIR_HOME}/data;
elif [[ $DATA_SRC == 'g4g' ]]; then
    path_2_data=${CODE_DIR_HOME}/data/g4g_functions;
fi

SAVE_DIR=${CURRENT_DIR}/${DATA_SRC}/multilingual;
mkdir -p $SAVE_DIR

# Assume 32 batch sizes, use 2 GPUs.
BATCH_SIZE=4;
UPDATE_FREQ=4;
MAX_UPDATES=30000;
WARMUP=1500;

USER_DIR=${CODE_DIR_HOME}/plbart/source;
restore_path=${CODE_DIR_HOME}/models/plbart/checkpoint_11_100000.pt;


function train() {

printf "Training For : $lang_pairs \n";
fairseq-train $path_2_data/plbart-bin \
    --user-dir $USER_DIR \
    --task translation_multi_simple_epoch_extended \
    --lang-dict $lang_list \
    --lang-pairs $lang_pairs \
    --batch-size $BATCH_SIZE \
    --update-freq $UPDATE_FREQ \
    --fp16 \
    --arch mbart_base \
    --layernorm-embedding \
    --sampling-method "temperature" \
    --sampling-temperature 1.5 \
    --encoder-langtok "src" \
    --decoder-langtok \
    --criterion label_smoothed_cross_entropy \
    --label-smoothing 0.2 \
    --optimizer adam \
    --adam-eps 1e-06 \
    --adam-betas '(0.9, 0.98)' \
    --lr-scheduler inverse_sqrt \
    --lr 5e-05 \
    --warmup-updates $WARMUP \
    --max-update $MAX_UPDATES \
    --dropout 0.1 \
    --attention-dropout 0.1 \
    --weight-decay 0.1 \
    --no-epoch-checkpoints \
    --patience 10 \
    --seed 1234 \
    --log-format json \
    --log-interval 100 \
    --save-dir $SAVE_DIR \
    --eval-bleu \
    --eval-bleu-detok space \
    --eval-tokenized-bleu \
    --eval-bleu-remove-bpe sentencepiece \
    --best-checkpoint-metric bleu \
    --valid-subset valid \
    --eval-bleu-args '{"beam": 5}' \
    --maximize-best-checkpoint-metric \
    --restore-file $restore_path \
    --reset-dataloader \
    --reset-optimizer \
    --reset-meters \
    --reset-lr-scheduler \
    2>&1 | tee $SAVE_DIR/training.log;

}


function evaluate() {

SOURCE_LANG=$1;
TARGET_LANG=$2;
MODEL_PATH=${SAVE_DIR}/checkpoint_best.pt;
RESULT_DIR=${SAVE_DIR}/${SOURCE_LANG}2${TARGET_LANG};
mkdir -p $RESULT_DIR;

FILE_PREF=${RESULT_DIR}/output;
RESULT_FILE=${RESULT_DIR}/result.txt;
GOUND_TRUTH_PATH=${path_2_data}/test.jsonl;

echo "==========================================================================" | tee $RESULT_FILE;
echo "Source: "${SOURCE_LANG}"                            Target: "${TARGET_LANG} | tee -a $RESULT_FILE;
echo "--------------------------------------------------------------------------" | tee -a $RESULT_FILE;

fairseq-generate ${path_2_data}/plbart-bin \
    --path $MODEL_PATH \
    --user-dir $USER_DIR \
    --task translation_multi_simple_epoch_extended \
    --gen-subset test \
    --source-lang $SOURCE_LANG \
    --target-lang $TARGET_LANG \
    --sacrebleu \
    --remove-bpe 'sentencepiece'\
    --max-len-b 500 \
    --batch-size 8 \
    --encoder-langtok "src" \
    --decoder-langtok \
    --lang-dict $lang_list \
    --lang-pairs $lang_pairs \
    --beam 5 > $FILE_PREF;

cat $FILE_PREF | grep -P "^H" |sort -V |cut -f 3- | cut -d' ' -f 2- > $FILE_PREF.hyp;

python $evaluator_script/evaluator.py \
    --references $GOUND_TRUTH_PATH \
    --predictions $FILE_PREF.hyp \
    --language $TARGET_LANG \
    2>&1 | tee -a $RESULT_FILE;

cd $codebleu_path;
python calc_code_bleu.py \
    --ref $GOUND_TRUTH_PATH \
    --hyp $FILE_PREF.hyp \
    --lang $TARGET_LANG \
    2>&1 | tee -a $RESULT_FILE;
cd $CURRENT_DIR;

python $evaluator_script/compile.py \
    --input_file $FILE_PREF.hyp \
    --language $TARGET_LANG \
    2>&1 | tee -a $RESULT_FILE;

}


function predict_transcoder_eval () {

SOURCE_LANG=$1;
TARGET_LANG=$2;
MODEL_PATH=${SAVE_DIR}/checkpoint_best.pt;
DATA_DIR=${CODE_DIR_HOME}/data/transcoder_test_gfg;

RESULT_DIR=${SAVE_DIR}/${SOURCE_LANG}2${TARGET_LANG}/transcoder_eval;
mkdir -p $RESULT_DIR;
FILE_PREF=${RESULT_DIR}/test;
RESULT_FILE=${RESULT_DIR}/result.txt;
GOUND_TRUTH_PATH=${DATA_DIR}/test.java-python.$TARGET_LANG;

fairseq-generate ${DATA_DIR}/plbart-bin \
    --path $MODEL_PATH \
    --user-dir $USER_DIR \
    --task translation_multi_simple_epoch_extended \
    --gen-subset test \
    --source-lang $SOURCE_LANG \
    --target-lang $TARGET_LANG \
    --sacrebleu \
    --remove-bpe 'sentencepiece'\
    --max-len-b 500 \
    --batch-size 8 \
    --encoder-langtok "src" \
    --decoder-langtok \
    --lang-dict $lang_list \
    --lang-pairs $lang_pairs \
    --beam 5 > $FILE_PREF.log;

cat $FILE_PREF.log | grep -P "^H" |sort -V |cut -f 3- | cut -d' ' -f 2- > $FILE_PREF.output;

python $evaluator_script/evaluator.py \
    --references $GOUND_TRUTH_PATH \
    --txt_ref \
    --predictions $FILE_PREF.output \
    --language $TARGET_LANG \
    2>&1 | tee $RESULT_FILE;

cd $codebleu_path;
python calc_code_bleu.py \
    --ref $GOUND_TRUTH_PATH \
    --txt_ref \
    --hyp $FILE_PREF.output \
    --lang $TARGET_LANG \
    2>&1 | tee -a $RESULT_FILE;
cd $CURRENT_DIR;

}


train;
evaluate java python;
evaluate python java;
predict_transcoder_eval java python;
predict_transcoder_eval python java;
