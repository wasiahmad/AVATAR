import os
import json
import random
import argparse
from dpu_utils.codeutils.deduplication import DuplicateDetector

random.seed(1234)


def cluster(examples, language):
    detector = DuplicateDetector(
        set_similarity_threshold=0.8,
        multiset_similarity_threshold=0.7,
        min_num_tokens_per_document=1
    )
    for ex_id, ex in examples.items():
        rand_idx = random.randrange(len(ex[language]))
        detector.add_file(
            id=ex_id,
            tokens=ex[language][rand_idx]["code"].split(),
            language=language
        )

    clusters = detector.compute_duplicates()  # List[Set[example_id]]
    detector.print_clone_set_stats(clusters)
    clustered_ex_ids = [ex_id for c in clusters for ex_id in c]
    for ex_id, _ in examples.items():
        if ex_id not in clustered_ex_ids:
            # include the singletones here
            clusters.append(set([ex_id]))
    print(f"Clustered {len(examples)} problems into {len(clusters)} clusters.")
    return clusters


def split(args):
    examples = dict()
    for file in args.src_file:
        with open(file, 'r') as f:
            for line in f:
                ex = json.loads(line)
                assert ex["id"] not in examples
                examples[ex["id"]] = ex

    train_examples = []
    valid_examples = []
    test_examples = []
    total = len(examples)
    num_test = total * (args.test_percent / 100)
    num_valid = total * (args.valid_percent / 100)

    clustered_examples = cluster(examples, "java")
    random.shuffle(clustered_examples)
    for cidx, one_cluster in enumerate(clustered_examples):
        c_examples = []
        for ex_id in one_cluster:
            c_examples.append({
                "id": examples[ex_id]["id"],
                "java": [soln["code"] for soln in examples[ex_id]["java"]],
                "python": [soln["code"] for soln in examples[ex_id]["python"]]
            })
        if len(test_examples) < num_test:
            test_examples.extend(c_examples)
        elif len(valid_examples) < num_valid:
            valid_examples.extend(c_examples)
        else:
            train_examples.extend(c_examples)

    if train_examples:
        with open(os.path.join(args.out_dir, 'train.jsonl'), 'w', encoding='utf8') as fw:
            fw.write('\n'.join([json.dumps(ex) for ex in train_examples]) + '\n')

    if valid_examples:
        with open(os.path.join(args.out_dir, 'valid.jsonl'), 'w', encoding='utf8') as fw:
            fw.write('\n'.join([json.dumps(ex) for ex in valid_examples]) + '\n')

    if test_examples:
        with open(os.path.join(args.out_dir, 'test.jsonl'), 'w', encoding='utf8') as fw:
            fw.write('\n'.join([json.dumps(ex) for ex in test_examples]) + '\n')


def get_all_possible_pairs(eid, java_solutions, python_solutions):
    if len(java_solutions) == 1 and len(python_solutions) == 1:
        result = [{
            "id": eid,
            "java_code": java_solutions[0],
            "python_code": python_solutions[0]
        }]
    else:
        result = []
        for i, java_solution in enumerate(java_solutions):
            for j, python_solution in enumerate(python_solutions):
                result.append({
                    "id": "{}_js{}_ps{}".format(eid, i, j),
                    "java_code": java_solution,
                    "python_code": python_solution
                })

    return result


def prepare(args):
    def single_prepare(filename, split, k):
        file_prefix = '{}.java-python'.format(split)
        id_file = os.path.join(args.out_dir, '{}.id'.format(file_prefix))
        java_file = os.path.join(args.out_dir, '{}.java'.format(file_prefix))
        python_file = os.path.join(args.out_dir, '{}.python'.format(file_prefix))

        with open(id_file, 'w', encoding='utf8') as id_writer, \
                open(java_file, 'w', encoding='utf8') as java_writer, \
                open(python_file, 'w', encoding='utf8') as python_writer, \
                open(filename, encoding='utf8') as f:
            for line in f:
                ex = json.loads(line.strip())
                java_solutions = ex['java'][:k]
                python_solutions = ex['python'][:k]
                pairs = get_all_possible_pairs(ex['id'], java_solutions, python_solutions)
                id_writer.write('\n'.join([p["id"] for p in pairs]) + '\n')
                java_writer.write('\n'.join([p["java_code"] for p in pairs]) + '\n')
                python_writer.write('\n'.join([p["python_code"] for p in pairs]) + '\n')

    filename = os.path.join(args.src_dir, 'train.jsonl')
    if os.path.exists(filename):
        single_prepare(filename, 'train', args.k)
    filename = os.path.join(args.src_dir, 'valid.jsonl')
    if os.path.exists(filename):
        single_prepare(filename, 'valid', 1)
    filename = os.path.join(args.src_dir, 'test.jsonl')
    if os.path.exists(filename):
        single_prepare(filename, 'test', 1)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--src_file", type=str, nargs='+', help='Source file')
    parser.add_argument("--src_dir", type=str, help='Source directory')
    parser.add_argument("--out_dir", type=str, help='Output directory')
    parser.add_argument("--fn", type=str, choices=['split', 'prepare'], help='Name of the function')
    parser.add_argument("--k", type=int, default=5, help='Number of submissions to consider for train split')
    parser.add_argument("--test_percent", type=int, default=20,
                        help='Percentage of the full data will be used to construct test set')
    parser.add_argument("--valid_percent", type=int, default=10,
                        help='Percentage of the full data will be used to construct valid set')
    args = parser.parse_args()

    if args.fn == 'split':
        split(args)
    elif args.fn == 'prepare':
        prepare(args)
