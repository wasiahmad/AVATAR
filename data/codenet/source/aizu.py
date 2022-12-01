# -*- coding: utf-8 -*-
import os
import json
import csv
import random
import shutil
import pathlib
import argparse
from collections import Counter


def main():
    csv_filename = os.path.join(args.metadata_dir, "problem_list.csv")
    with open(csv_filename, 'r') as csvfile:
        csvreader = csv.reader(csvfile)
        # id,name,dataset,time_limit,memory_limit,rating,tags,complexity
        fields = next(csvreader)
        for row in csvreader:
            codenet_pid = row[0]
            if row[2] == "AIZU":
                problem_metafile = os.path.join(args.metadata_dir, f"{codenet_pid}.csv")
                java_solutions = []
                python_solutions = []
                with open(problem_metafile, 'r') as f:
                    csvreader = csv.reader(f)
                    # submission_id,problem_id,user_id,date,language,original_language,filename_ext,status,cpu_time,memory,code_size,accuracy
                    fields = next(csvreader)
                    for row in csvreader:
                        submission_id = row[0]
                        file_ext = row[6]
                        status = row[7]
                        if status == "Accepted":
                            if file_ext == "py":
                                soln_path = os.path.join(args.data_dir, codenet_pid, "Python", f"{submission_id}.py")
                                if os.path.exists(soln_path):
                                    python_solutions.append(soln_path)
                            elif file_ext == "java":
                                soln_path = os.path.join(args.data_dir, codenet_pid, "Java", f"{submission_id}.java")
                                if os.path.exists(soln_path):
                                    java_solutions.append(soln_path)

                if len(java_solutions) > 0 and len(python_solutions) > 0:
                    if len(java_solutions) > 20:
                        random.shuffle(java_solutions)
                        java_solutions = java_solutions[:20]
                    if len(python_solutions) > 20:
                        random.shuffle(python_solutions)
                        python_solutions = python_solutions[:20]
                    out_dir = os.path.join(args.output_dir, codenet_pid, "A")
                    pathlib.Path(out_dir).mkdir(parents=True, exist_ok=True)
                    for fpath in java_solutions + python_solutions:
                        src_file = pathlib.Path(fpath)
                        tgt_file = os.path.join(out_dir, src_file.name)
                        try:
                            shutil.copy(src_file, tgt_file)
                        except:
                            pass


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--data_dir",
        default="Project_CodeNet/data",
        help='CodeNet data directory path'
    )
    parser.add_argument(
        "--metadata_dir",
        default="Project_CodeNet/metadata",
        help='CodeNet metadata directory path'
    )
    parser.add_argument(
        "--output_dir",
        required=True,
        help='Output directory path'
    )
    args = parser.parse_args()
    main()
