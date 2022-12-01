# -*- coding: utf-8 -*-
import os
import glob
import json
import csv
import argparse
from collections import Counter
from statistics import mean, median


def get_problem_ids(testdir):
    problem_ids = []
    for name in glob.glob(testdir + "/*/", recursive=True):
        # path_to_dir/codeforces/1_A/ --> 1_A
        name = name.replace(testdir, "")[1:-1]
        problem_ids.append(name)
    return problem_ids


def problem_to_test_paths(pids, testdir):
    test_cases = {}
    for pid in pids:
        # pid is in form 1_A
        test_folder = testdir + "/" + pid + "/samples"
        inputs, outputs = [], []

        io_files = glob.glob(test_folder + "/*")
        for inf in io_files:
            if os.stat(inf).st_size == 0:
                continue
            filename, in_extension = os.path.splitext(os.path.basename(inf))
            assert in_extension == ".txt"
            if filename.endswith("input"):
                outfname = filename.replace("input", "output")
                outf = os.path.join(test_folder + f"/{outfname}{in_extension}")
                if os.path.exists(outf) and os.stat(outf).st_size != 0:
                    inputs.append(inf.replace(testdir + "/", ""))
                    outputs.append(outf.replace(testdir + "/", ""))
            elif filename.endswith("output"):
                continue
            else:
                raise ValueError()

        if inputs and outputs:
            assert len(inputs) == len(outputs)
            test_cases[pid] = {"inputs": inputs, "outputs": outputs}

    print(f"Test cases found for {len(test_cases)} Codeforces problems.")
    return test_cases


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source_file",
        default="../data/data/codeforces.jsonl",
        help='Codeforces source filepath'
    )
    parser.add_argument(
        "--codeforces_tests_dir",
        default="description2code_current/codeforces",
        help='root folder of codeforces tests',
    )
    parser.add_argument(
        "--output_file",
        default="codeforces_id2tests.jsonl",
        help='output jsonl file path',
    )
    args = parser.parse_args()

    prob_ids = get_problem_ids(args.codeforces_tests_dir)
    test_cases = problem_to_test_paths(prob_ids, args.codeforces_tests_dir)

    target_ids = []  # e.g., codeforces_797_A
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
            _id = tid.replace("codeforces_", "")
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

    print(f"Test cases found for {total} Codeforces examples that are part of AVATAR.")
    print(f"Test cases not found for {len(missing_tests)} Codeforces examples that are part of AVATAR.")
    print(f"#test-cases: avg: {mean(num_test_cases)}, max: {max(num_test_cases)}, "
          f"min:{min(num_test_cases)}, median: {median(num_test_cases)}")
    # print(f"We failed to find test cases for the following Codeforces problems.")
    # print(list(sorted(missing_tests)))
