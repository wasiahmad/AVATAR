#!/usr/bin/env bash

export PYTHONIOENCODING=utf-8;
DATA_DIR=`pwd`
HOME_DIR=`realpath ..`;

#############################################
#        Download GeeksforGeeks Data        #
#############################################
FILE=GeeksForGeeks.zip
if [[ ! -f "$FILE" ]]; then
    # https://drive.google.com/file/d/1EEY96YzFAVmyKVmPr2gEm10hXETsrIBU
    fileid="1EEY96YzFAVmyKVmPr2gEm10hXETsrIBU"
    curl -c ./cookie -s -L "https://drive.google.com/uc?export=download&id=${fileid}" > /dev/null
    curl -Lb ./cookie "https://drive.google.com/uc?export=download&confirm=`awk '/download/ {print $NF}' ./cookie`&id=${fileid}" -o ${FILE}
    rm ./cookie
    unzip ${FILE}
fi

#############################################
#           Download AtCoder Data           #
#############################################
FILE=atcoder.zip
if [[ ! -f "$FILE" ]]; then
    # https://drive.google.com/file/d/1pywwzH5RKDLlDjClK_eFsZJJuHwDb4eg
    fileid="1pywwzH5RKDLlDjClK_eFsZJJuHwDb4eg"
    curl -c ./cookie -s -L "https://drive.google.com/uc?export=download&id=${fileid}" > /dev/null
    curl -Lb ./cookie "https://drive.google.com/uc?export=download&confirm=`awk '/download/ {print $NF}' ./cookie`&id=${fileid}" -o ${FILE}
    rm ./cookie
    unzip ${FILE}
fi

#############################################
#           Download CodeJam Data           #
#############################################
FILE=codejam.zip
if [[ ! -f "$FILE" ]]; then
    # https://drive.google.com/file/d/1Qi33871gi_cvnGLmQ3zqQDRMke5B0Sf6
    fileid="1Qi33871gi_cvnGLmQ3zqQDRMke5B0Sf6"
    curl -c ./cookie -s -L "https://drive.google.com/uc?export=download&id=${fileid}" > /dev/null
    curl -Lb ./cookie "https://drive.google.com/uc?export=download&confirm=`awk '/download/ {print $NF}' ./cookie`&id=${fileid}" -o ${FILE}
    rm ./cookie
    unzip ${FILE}
fi

#############################################
#          Download CodeForces Data         #
#############################################
FILE=CodeForces.zip
if [[ ! -f "$FILE" ]]; then
    # https://drive.google.com/file/d/1tlU0lCeObkS43a9ZiyV0htOdj-DNKbdt
    fileid="1tlU0lCeObkS43a9ZiyV0htOdj-DNKbdt"
    curl -c ./cookie -s -L "https://drive.google.com/uc?export=download&id=${fileid}" > /dev/null
    curl -Lb ./cookie "https://drive.google.com/uc?export=download&confirm=`awk '/download/ {print $NF}' ./cookie`&id=${fileid}" -o ${FILE}
    rm ./cookie
    unzip ${FILE}
fi

#############################################
#          Download ProjectEuler Data       #
#############################################
FILE=ProjectEuler.zip
if [[ ! -f "$FILE" ]]; then
    # https://drive.google.com/file/d/1V5a6U_u-y7I5mRt0cJlINHBy3a6miiUY
    fileid="1V5a6U_u-y7I5mRt0cJlINHBy3a6miiUY"
    curl -c ./cookie -s -L "https://drive.google.com/uc?export=download&id=${fileid}" > /dev/null
    curl -Lb ./cookie "https://drive.google.com/uc?export=download&confirm=`awk '/download/ {print $NF}' ./cookie`&id=${fileid}" -o ${FILE}
    rm ./cookie
    unzip ${FILE}
fi

#############################################
#           Download LeetCode Data          #
#############################################
FILE=LeetCode.zip
if [[ ! -f "$FILE" ]]; then
    # https://drive.google.com/file/d/1dVzdhSLIRhFG1hGYqbOMO8gQ9Pb8Qilo
    fileid="1dVzdhSLIRhFG1hGYqbOMO8gQ9Pb8Qilo"
    curl -c ./cookie -s -L "https://drive.google.com/uc?export=download&id=${fileid}" > /dev/null
    curl -Lb ./cookie "https://drive.google.com/uc?export=download&confirm=`awk '/download/ {print $NF}' ./cookie`&id=${fileid}" -o ${FILE}
    rm ./cookie
    unzip ${FILE}
fi
