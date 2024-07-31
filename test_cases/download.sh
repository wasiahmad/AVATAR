#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8
DATA_DIR=$(pwd)
HOME_DIR=$(realpath ..)

function wget_dropbox() {
    FILE_ID=$1
    FILENAME=$2
    DEST_PATH=$2
    if [[ ! -f "$DEST_PATH" ]]; then
        echo "Downloading Codeforces test cases from https://www.dropbox.com/s/${FILE_ID}/$FILENAME"
        wget https://www.dropbox.com/s/${FILE_ID}/$FILENAME -O $DEST_PATH
    fi
}

function wget_gdrive() {
    GDRIVE_FILE_ID=$1
    DEST_PATH=$2
    if [[ ! -f "$DEST_PATH" ]]; then
        echo "Downloading AtCoder test cases from https://drive.google.com/file/d/${GDRIVE_FILE_ID}"
        wget --save-cookies cookies.txt 'https://docs.google.com/uc?export=download&id='$GDRIVE_FILE_ID -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1/p' >confirm.txt
        wget --load-cookies cookies.txt -O $DEST_PATH 'https://docs.google.com/uc?export=download&id='$GDRIVE_FILE_ID'&confirm='$(<confirm.txt)
        rm cookies.txt confirm.txt
    fi
}

# Download Codeforces test cases
filename=description2code_current.zip
fileid="zwj6u4caehf54s0"
wget_dropbox $fileid $filename $DATA_DIR/$filename
Codeforces_TEST_DIR=$DATA_DIR/description2code_current
if [[ ! -d "$Codeforces_TEST_DIR" ]]; then
    echo "Decompressing $DATA_DIR/$filename"
    unzip $DATA_DIR/$filename -d $DATA_DIR
fi

# Download AtCoder test cases
filename=atcoder_test_cases.tar.gz # 11.58 GB filesize
fileid="1AInTHzaZqym7WsT1B7yc8nZy7dA3ovPf"
wget_gdrive $fileid $DATA_DIR/$filename
AtCoder_TEST_DIR=$DATA_DIR/atcoder_test_cases
if [[ ! -d "$AtCoder_TEST_DIR" ]]; then
    echo "Decompressing $DATA_DIR/$filename"
    tar -xzf $DATA_DIR/$filename -C $DATA_DIR
fi
