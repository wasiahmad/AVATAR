#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8
DATA_DIR=$(pwd)

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

function download_to_run_prepare() {
    #############################################
    #        Download GeeksforGeeks Data        #
    #############################################
    # https://drive.google.com/file/d/1EEY96YzFAVmyKVmPr2gEm10hXETsrIBU
    fileid="1EEY96YzFAVmyKVmPr2gEm10hXETsrIBU"
    filename=GeeksForGeeks.zip
    if [[ ! -f "$filename" ]]; then
        wget_gdrive $fileid $DATA_DIR/$filename
        unzip $DATA_DIR/$filename -d $DATA_DIR
    fi

    #############################################
    #           Download AtCoder Data           #
    #############################################
    # https://drive.google.com/file/d/1pywwzH5RKDLlDjClK_eFsZJJuHwDb4eg
    fileid="1pywwzH5RKDLlDjClK_eFsZJJuHwDb4eg"
    filename=AtCoder.zip
    if [[ ! -f "$filename" ]]; then
        wget_gdrive $fileid $DATA_DIR/$filename
        unzip $DATA_DIR/$filename -d $DATA_DIR
    fi

    #############################################
    #           Download CodeJam Data           #
    #############################################
    # https://drive.google.com/file/d/1Qi33871gi_cvnGLmQ3zqQDRMke5B0Sf6
    fileid="1Qi33871gi_cvnGLmQ3zqQDRMke5B0Sf6"
    filename=CodeJam.zip
    if [[ ! -f "$filename" ]]; then
        wget_gdrive $fileid $DATA_DIR/$filename
        unzip $DATA_DIR/$filename -d $DATA_DIR
    fi

    #############################################
    #          Download CodeForces Data         #
    #############################################
    # https://drive.google.com/file/d/1tlU0lCeObkS43a9ZiyV0htOdj-DNKbdt
    fileid="1tlU0lCeObkS43a9ZiyV0htOdj-DNKbdt"
    filename=CodeForces.zip
    if [[ ! -f "$filename" ]]; then
        wget_gdrive $fileid $DATA_DIR/$filename
        unzip $DATA_DIR/$filename -d $DATA_DIR
    fi

    #############################################
    #          Download ProjectEuler Data       #
    #############################################
    # https://drive.google.com/file/d/1V5a6U_u-y7I5mRt0cJlINHBy3a6miiUY
    fileid="1V5a6U_u-y7I5mRt0cJlINHBy3a6miiUY"
    filename=ProjectEuler.zip
    if [[ ! -f "$filename" ]]; then
        wget_gdrive $fileid $DATA_DIR/$filename
        unzip $DATA_DIR/$filename -d $DATA_DIR
    fi

    #############################################
    #           Download LeetCode Data          #
    #############################################
    # https://drive.google.com/file/d/1dVzdhSLIRhFG1hGYqbOMO8gQ9Pb8Qilo
    fileid="1dVzdhSLIRhFG1hGYqbOMO8gQ9Pb8Qilo"
    filename=LeetCode.zip
    if [[ ! -f "$filename" ]]; then
        wget_gdrive $fileid $DATA_DIR/$filename
        unzip $DATA_DIR/$filename -d $DATA_DIR
    fi

}

function dl_transcoder_data() {
    #############################################
    #       Download TransCoder Test Data       #
    #############################################
    # https://drive.google.com/file/d/1b84rqC2-26MMyRJfH3rCvGhEkHn-NupR
    fileid="1b84rqC2-26MMyRJfH3rCvGhEkHn-NupR"
    filename=transcoder_test_gfg.zip
    if [[ ! -f "$filename" ]]; then
        wget_gdrive $fileid $DATA_DIR/$filename
        unzip $DATA_DIR/$filename -d $DATA_DIR
    fi

    # https://drive.google.com/file/d/1rRUzndsvU6hyH5eNnm4Vx_95TNt5jURk
    fileid="1rRUzndsvU6hyH5eNnm4Vx_95TNt5jURk"
    filename=transcoder_evaluation_gfg.zip
    if [[ ! -f "$filename" ]]; then
        wget_gdrive $fileid $DATA_DIR/$filename
        unzip $DATA_DIR/$filename -d $DATA_DIR
    fi
}

function download() {
    # download the data used in the paper
    # https://drive.google.com/file/d/1ch8BCPmMfHFq8D7NRxmU0ps-Ymv80h4a
    fileid="1ch8BCPmMfHFq8D7NRxmU0ps-Ymv80h4a"
    filename=data.zip
    if [[ ! -f "$filename" ]]; then
        wget_gdrive $fileid $DATA_DIR/$filename
        unzip $DATA_DIR/$filename -d $DATA_DIR
    fi
    # https://drive.google.com/file/d/1ql9nkGnfpOn27p8M_JtpgCpezbbjIOUD
    fileid="1ql9nkGnfpOn27p8M_JtpgCpezbbjIOUD"
    filename=parallel_functions.zip
    if [[ ! -f "$filename" ]]; then
        wget_gdrive $fileid $DATA_DIR/$filename
        unzip $DATA_DIR/$filename -d $DATA_DIR
    fi
}

download
dl_transcoder_data
