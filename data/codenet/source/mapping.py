# -*- coding: utf-8 -*-
import os
import glob
import json
import csv
import argparse
from collections import Counter

"""
Map CodeNet problem id (which is an anonymize version) to AtCoder problem ids.
"""

"""
# CodeNet provides problem meta-data in a CSV file
# Filepath: Project_CodeNet/metadata/problem_list.csv
# Entries in the file looks like:
...
p03393,AtCoder Grand Contest 022 - Diverse Word,AtCoder,2000,262144,,,
p03394,AtCoder Grand Contest 022 - GCD Sequence,AtCoder,2000,262144,,,
p03395,AtCoder Grand Contest 022 - Remainder Game,AtCoder,2000,262144,,,
p03396,AtCoder Grand Contest 022 - Shopping,AtCoder,2000,262144,,,
p03397,AtCoder Grand Contest 022 - Median Replace,AtCoder,2000,262144,,,
p03398,AtCoder Grand Contest 022 - Checkers,AtCoder,2000,262144,,,
...

# We convert name of the problem as:
AtCoder Beginner Contest --> ABC
AtCoder Regular Contest --> ARC
AtCoder Grand Contest --> AGC
AtCoder Heuristic Contest --> AHC

# So, following are sample conversions:
(p03393,AtCoder Grand Contest 022) --> AGC022/A
(p03394,AtCoder Grand Contest 022) --> AGC022/B
(p03395,AtCoder Grand Contest 022) --> AGC022/C
(p03396,AtCoder Grand Contest 022) --> AGC022/D
(p03397,AtCoder Grand Contest 022) --> AGC022/E
(p03398,AtCoder Grand Contest 022) --> AGC022/F
# Assumption: the problems are sorted based on difficulty level (A->B->C->D->E->F)

# Then we check if test cases exist for the problem by looking at:
--> inputs: atcoder_test_cases/AGC022/A/in
--> outputs: atcoder_test_cases/AGC022/A/out

# Every input and output combination are in a separate file. For example,
# Inputs
atcoder_test_cases/AGC022/A/in/01.txt
atcoder_test_cases/AGC022/A/in/02.txt
...
# Outputs
atcoder_test_cases/AGC022/A/out/01.txt
atcoder_test_cases/AGC022/A/out/02.txt
...
# Note: the input/output file names are same, but they could be anything
# E.g., 01.txt, sample_01.txt, subtask_1_01.txt
"""

EXCEPTIONS = ["ABC163", "AGC043"]
EXCEPTIONS2 = ["ARC058_ABC042", "ARC059_ABC043"]
EXCEPTIONS2_MAP = {
    "ARC058": "ARC058_ABC042",
    "ARC059": "ARC059_ABC043",
    "ABC042": "ARC058_ABC042",
    "ABC043": "ARC059_ABC043"
}


def codenet_atcoder_desc_to_id(name):
    """
    Convert AtCoder Grand Contest 022 --> AGC022
    """
    ATCODER_CONTEST_NAME_MAP = {
        "AtCoder Beginner Contest": "ABC",
        "AtCoder Regular Contest": "ARC",
        "AtCoder Grand Contest": "AGC",
        "AtCoder Heuristic Contest": "AHC"
    }
    atcoder_id = ""
    if name.startswith("AtCoder Beginner Contest"):
        atcoder_id += "ABC"
    elif name.startswith("AtCoder Regular Contest"):
        atcoder_id += "ARC"
    elif name.startswith("AtCoder Grand Contest"):
        atcoder_id += "AGC"
    elif name.startswith("AtCoder Heuristic Contest"):
        atcoder_id += "AHC"
    elif name.startswith("ACL Contest 1"):
        atcoder_id += "ACL1"
    elif name.startswith("ACL Beginner Contest"):
        atcoder_id += "ABL"
    else:
        # print(f"Unknown contest name - {name}")
        return None, None

    try:
        name_splits = name.split(" ")
        if atcoder_id in ["ACL1", "ABL"]:
            assert name_splits[3] == "-"
            suffix = " ".join(name_splits[4:])
        else:
            assert name_splits[3].isdigit()
            atcoder_id += name_splits[3]
            assert name_splits[4] == "-"
            suffix = " ".join(name_splits[5:])
        return atcoder_id, suffix
    except:
        return None, None


def codenet_id_to_atcoder_id(metadata_folder):
    csv_filename = os.path.join(metadata_folder, "problem_list.csv")
    sub_task_map = Counter()
    cnet_id_to_atc_id = dict()

    total, no_mapping = 0, 0
    with open(csv_filename, 'r') as csvfile:
        csvreader = csv.reader(csvfile)
        fields = next(csvreader)
        # fields = id,name,dataset,time_limit,memory_limit,rating,tags,complexity
        for row in csvreader:
            codenet_pid = row[0]
            if row[2] == "AtCoder":
                name = row[1]
                atcoder_id, suffix = codenet_atcoder_desc_to_id(name)
                total += 1
                if atcoder_id is not None and suffix is not None:
                    letter = chr(ord('A') + sub_task_map[atcoder_id])
                    cnet_id_to_atc_id[codenet_pid] = atcoder_id + "/" + letter
                    sub_task_map[atcoder_id] += 1
                else:
                    no_mapping += 1

    print(f"We are unable to link {no_mapping}/{total} CodeNet problems to an AtCoder problem.")
    return cnet_id_to_atc_id


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--metadata_dir",
        default="../data/Project_CodeNet/metadata",
        help='CodeNet metadata directory path'
    )
    parser.add_argument(
        "--output_file",
        default="codenet_to_atcoder_tests.jsonl",
        help='output jsonl file path',
    )
    args = parser.parse_args()

    cnet_id_to_atc_id = codenet_id_to_atcoder_id(args.metadata_dir)
    print(f"Writing to {args.output_file}")
    with open(args.output_file, "w") as writer:
        for k, v in cnet_id_to_atc_id.items():
            obj = {"codenet_id": k, "atcoder_id": v}
            writer.write(json.dumps(obj) + "\n")
