# -*- coding: utf-8 -*-
import os
import glob
import json
import csv
import argparse
from collections import Counter
from statistics import mean, median

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


def get_problem_ids(testdir):
    problem_ids = []
    for name in glob.glob(testdir + "/*/*/", recursive=True):
        # path_to_dir/atcoder_test_cases/ABC155/A/ --> ABC155/A
        name = name.replace(testdir, "")[1:-1]
        task, subtask = name.split("/")
        if task in EXCEPTIONS2:
            task1, task2 = task.split("_")
            problem_ids.append(task1 + "/" + subtask)
            problem_ids.append(task2 + "/" + subtask)
        else:
            problem_ids.append(name)
    return problem_ids


def problem_to_test_paths(pids, testdir):
    included, skipped = 0, 0
    test_cases = {}
    for pid in pids:
        # pid is in form ABC155/A
        task, subtask = pid.split("/")
        test_folder = testdir + "/" + pid
        inputs, outputs = [], []
        if task in EXCEPTIONS:
            input_files = glob.glob(test_folder + "/*")
        else:
            if task in EXCEPTIONS2_MAP:
                test_folder = testdir + "/" + EXCEPTIONS2_MAP[task] + "/" + subtask
            input_files = glob.glob(test_folder + "/in/*")
        for inf in input_files:
            filename, in_extension = os.path.splitext(os.path.basename(inf))
            outf = os.path.join(test_folder + f"/out/{filename}{in_extension}")
            if not os.path.exists(outf):
                if in_extension == ".in":
                    outf = os.path.join(test_folder + f"/out/{filename}.out")

            if os.path.exists(inf) and os.path.exists(outf) and \
                    (os.stat(inf).st_size != 0 and os.stat(outf).st_size != 0):
                included += 1
                inf = inf.replace(testdir + "/", "")
                outf = outf.replace(testdir + "/", "")
                inputs.append(inf)
                outputs.append(outf)
            else:
                skipped += 1

        if inputs and outputs:
            assert len(inputs) == len(outputs)
            # pid = task.lower() + "_" + subtask  # ABC155/A -> abc155_A
            pid = task + "_" + subtask  # ABC155/A -> ABC155_A
            test_cases[pid] = {"inputs": inputs, "outputs": outputs}

    print(f"Test cases found for {len(test_cases)} AtCoder problems.")
    return test_cases


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source_file",
        default="../data/data/atcoder.jsonl",
        help='AtCoder source filepath'
    )
    parser.add_argument(
        "--atcoder_tests_dir",
        default="../data/atcoder_test_cases",
        help='root folder of Project_CodeNet directory',
    )
    parser.add_argument(
        "--output_file",
        default="codenet_to_atcoder_tests.jsonl",
        help='output jsonl file path',
    )
    args = parser.parse_args()

    prob_ids = get_problem_ids(args.atcoder_tests_dir)
    test_cases = problem_to_test_paths(prob_ids, args.atcoder_tests_dir)

    target_ids = []  # e.g., atcoder_arc010_A
    with open(args.source_file, "r") as f:
        for line in f:
            ex = json.loads(line)
            target_ids.append(ex["id"])

    print(f"Writing to {args.output_file}")
    total = 0
    missing_tests = set()
    num_test_cases = []
    with open(args.output_file, "w") as writer:
        for tid in target_ids:
            _id = tid.replace("atcoder_", "")
            if _id in test_cases:
                obj = {
                    "avatar_id": tid,
                    **test_cases[_id],
                }
                writer.write(json.dumps(obj) + "\n")
                total += 1
                num_test_cases.append(len(test_cases[_id]["inputs"]))
            else:
                missing_tests.add(tid)

    print(f"Test cases found for {total} AtCoder examples that are part of AVATAR.")
    print(f"Test cases not found for {len(missing_tests)} AtCoder examples that are part of AVATAR.")
    print(f"#test-cases: avg: {mean(num_test_cases)}, max: {max(num_test_cases)}, "
          f"min:{min(num_test_cases)}, median: {median(num_test_cases)}")
    # print(f"We failed to find test cases for the following AtCoder problems.")
    # print(list(sorted(missing_tests)))
