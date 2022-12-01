import sys

sys.path.append('..')

import os
import json
import logging
import argparse
import subprocess
from tqdm import tqdm
from itertools import chain
from data.split import prepare, split


class Namespace:
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)


def count_file_lines(file_path):
    """
    Counts the number of lines in a file using wc utility.
    :param file_path: path to file
    :return: int, no of lines
    """
    num = subprocess.check_output(['wc', '-l', file_path])
    num = num.decode('utf-8').split(' ')
    return int(num[0])


def n_grams(s, n):
    tokens = [token for token in s.split(" ") if token != ""]
    ngrams = zip(*[tokens[i:] for i in range(n)])
    return [" ".join(ngram) for ngram in ngrams]


def range_ngrams(s, ngram_range):
    if ngram_range[0] == ngram_range[1]:
        return n_grams(s, ngram_range[0])
    ngrams = chain(*(n_grams(s, i) for i in range(*ngram_range)))
    return [" ".join(ngram) for ngram in ngrams]


def jaccard_similarity(list1, list2):
    intersection = len(list(set(list1).intersection(list2)))
    union = (len(set(list1)) + len(set(list2))) - intersection
    return float(intersection) / union


def main(args, logger):
    ignore_java_functions = []
    for split in ['valid', 'test']:
        with open('transcoder_test_gfg/{}.java-python.java'.format(split), encoding='utf8') as f:
            for line in f:
                ignore_java_functions.append(
                    range_ngrams(line.strip(), ngram_range=(1, args.ngram))
                )

    ignore_python_functions = []
    for split in ['valid', 'test']:
        with open('transcoder_test_gfg/{}.java-python.python'.format(split), encoding='utf8') as f:
            for line in f:
                ignore_python_functions.append(
                    range_ngrams(line.strip(), ngram_range=(1, args.ngram))
                )

    def search(code, language):
        assert language in ['java', 'python']
        index = ignore_java_functions if language == 'java' else ignore_python_functions
        code_ngrams = range_ngrams(code.strip(), ngram_range=(1, args.ngram))
        matched_docs = []
        for item_idx, item in enumerate(index):
            # compute jaccard index
            s = jaccard_similarity(item, code_ngrams)
            if s > args.sim:
                matched_docs.append([item_idx, item, s])
        if len(matched_docs) > 0:
            top_match = matched_docs[0]
            top_code = ' '.join(top_match[1])
            logger.warning(
                '[{}] {} is matched to [{}-{}] {}'.format(
                    language,
                    code.replace("\u2581", "_"),
                    str(top_match[0]),
                    str(top_match[2]),
                    top_code.replace("\u2581", "_")
                )
            )
            return True
        else:
            return False

    filenames = [
        'geeksforgeeks.jsonl',
        'atcoder.jsonl',
        'codejam.jsonl',
        'codeforces.jsonl',
        'projecteuler.jsonl',
        'leetcode.jsonl',
        'aizu.jsonl',
    ]
    result = []
    for filename in filenames:
        java_ignored = 0
        python_ignored = 0
        current_size = len(result)
        with open(filename, 'r', encoding='utf8') as f:
            for line in tqdm(f, total=count_file_lines(filename)):
                ex = json.loads(line)
                java_functions = []
                python_functions = []
                for prog in ex["java"]:
                    if len(prog["functions_class"]) == 0:
                        if len(prog["functions_standalone"]) == 2:
                            idx = -1
                            if prog["functions_standalone"][0][0] == 'main':
                                idx = 1
                            elif prog["functions_standalone"][1][0] == 'main':
                                idx = 0
                            if idx != -1:
                                fn_body = prog["functions_standalone"][idx][1]
                                if not search(fn_body, "java"):
                                    java_functions.append({
                                        "id": prog["id"],
                                        "code": fn_body,
                                    })
                                else:
                                    java_ignored += 1

                for prog in ex["python"]:
                    if len(prog["functions_class"]) == 0:
                        if len(prog["functions_standalone"]) == 1:
                            fn_body = prog["functions_standalone"][0][1]
                            if not search(fn_body, "python"):
                                python_functions.append({
                                    "id": prog["id"],
                                    "code": fn_body,
                                })
                            else:
                                python_ignored += 1

                if len(java_functions) > 0 and len(python_functions) > 0:
                    result.append({
                        "id": ex["id"],
                        "java": java_functions,
                        "python": python_functions
                    })

        if java_ignored > 0:
            logger.info('{} java functions ignored due to overlap to transcoder_g4g'.format(java_ignored))
        if python_ignored > 0:
            logger.info('{} python functions ignored due to overlap to transcoder_g4g'.format(python_ignored))
        newly_added = len(result) - current_size
        if newly_added > 0:
            source = os.path.splitext(os.path.basename(filename))[0]
            logger.info('{} parallel functions are extracted from {}.'.format(newly_added, source))

    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--sim", type=float, default=1.0, help='Jaccard similarity threshold')
    parser.add_argument("--ngram", type=int, default=1, help='Use n-gram to compute Jaccard index')
    parser.add_argument("--out_dir", type=str, default='g4g_functions', help='Output directory')
    args = parser.parse_args()

    if not os.path.exists(args.out_dir):
        os.makedirs(args.out_dir)

    logging.basicConfig(handlers=[logging.FileHandler(
        filename=os.path.join(args.out_dir, 'preprocess.log'),
        encoding='utf-8', mode='w'
    )],
        format='%(asctime)s,%(msecs)d %(name)s %(levelname)s %(message)s',
        datefmt='%H:%M:%S',
        level=logging.INFO)

    logger = logging.getLogger('processing')
    result = main(args, logger)

    OUT_JSONL = os.path.join(args.out_dir, 'paralllel_functions.jsonl')
    with open(OUT_JSONL, 'w', encoding='utf8') as fw:
        fw.write('\n'.join([json.dumps(p) for p in result]))

    args = Namespace(
        src_file=[OUT_JSONL],
        out_dir=args.out_dir,
        k=5,
        test_percent=0,
        valid_percent=0,
    )
    split(args)
    args = Namespace(
        src_dir=args.out_dir,
        out_dir=args.out_dir,
        k=5
    )
    prepare(args)
