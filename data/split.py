import os
import json
import random
import argparse

random.seed(1234)


def split(args):
    examples = dict()
    for file in args.src_file:
        with open(file, 'r') as f:
            for line in f:
                ex = json.loads(line)
                splits = ex["id"].split('_')
                assert len(splits) == 3
                source = splits[0]
                problem_id = splits[1] + '_' + splits[2]
                if source not in examples:
                    examples[source] = dict()
                assert problem_id not in examples[source]
                examples[source][problem_id] = ex

    train_examples = []
    valid_examples = []
    test_examples = []
    for source, problems in examples.items():
        problem_ids = list(problems.keys())
        total = len(problem_ids)
        indices = list(range(total))
        random.shuffle(indices)
        num_test = total // 5  # 20% of the total
        num_valid = total // 10  # 10% of the total
        num_train = total - (num_valid + num_test)
        for i, idx in enumerate(indices):
            problem_id = problem_ids[idx]
            one_ex = {
                "id": problems[problem_id]["id"],
                "java": [soln["code"] for soln in problems[problem_id]["java"]],
                "python": [soln["code"] for soln in problems[problem_id]["python"]]
            }
            if i < num_train:
                train_examples.append(one_ex)
            elif i < num_train + num_valid:
                valid_examples.append(one_ex)
            else:
                test_examples.append(one_ex)

    with open(os.path.join(args.out_dir, 'train.jsonl'), 'w', encoding='utf8') as fw:
        fw.write('\n'.join([json.dumps(ex) for ex in train_examples]) + '\n')

    with open(os.path.join(args.out_dir, 'valid.jsonl'), 'w', encoding='utf8') as fw:
        fw.write('\n'.join([json.dumps(ex) for ex in valid_examples]) + '\n')

    with open(os.path.join(args.out_dir, 'test.jsonl'), 'w', encoding='utf8') as fw:
        fw.write('\n'.join([json.dumps(ex) for ex in test_examples]) + '\n')


def get_all_possible_pairs(java_solutions, python_solutions):
    result = []
    for java_solution in java_solutions:
        for python_solution in python_solutions:
            result.append({
                "java_code": java_solution,
                "python_code": python_solution
            })

    return result


def prepare(args):
    def single_prepare(split, k):
        file_prefix = '{}.java-python'.format(split)
        java_file = os.path.join(args.out_dir, '{}.java'.format(file_prefix))
        python_file = os.path.join(args.out_dir, '{}.python'.format(file_prefix))

        with open(java_file, 'w', encoding='utf8') as java_writer, \
                open(python_file, 'w', encoding='utf8') as python_writer, \
                open(os.path.join(args.src_dir, '{}.jsonl'.format(split))) as f:
            for line in f:
                ex = json.loads(line.strip())
                java_solutions = ex['java'][:k]
                python_solutions = ex['python'][:k]
                pairs = get_all_possible_pairs(java_solutions, python_solutions)
                java_writer.write('\n'.join([p["java_code"] for p in pairs]) + '\n')
                python_writer.write('\n'.join([p["python_code"] for p in pairs]) + '\n')

    single_prepare('train', args.k)
    single_prepare('valid', 1)
    single_prepare('test', 1)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--src_file", type=str, nargs='+', help='Source file')
    parser.add_argument("--src_dir", type=str, help='Source directory')
    parser.add_argument("--out_dir", type=str, help='Output directory')
    parser.add_argument("--fn", type=str, choices=['split', 'prepare'], help='Name of the function')
    parser.add_argument("--k", type=int, default=5, help='Number of submissions to consider for train split')
    args = parser.parse_args()

    if args.fn == 'split':
        split(args)
    elif args.fn == 'prepare':
        prepare(args)
