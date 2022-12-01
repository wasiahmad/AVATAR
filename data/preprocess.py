import os
import sys
import json
import ast
import javalang
import argparse

sys.path.append(".")
sys.path.append("..")

from os import listdir
from difflib import SequenceMatcher
from pathlib import Path
from codegen.preprocessing.lang_processors.java_processor import JavaProcessor
from codegen.preprocessing.lang_processors.python_processor import PythonProcessor

root_folder = "../third_party"
jprocessor = JavaProcessor(root_folder=root_folder)
pyprocessor = PythonProcessor(root_folder=root_folder)


def is_parsable(programString, lang):
    if lang == 'java':
        try:
            javalang.parse.parse(programString)
        except javalang.parser.JavaSyntaxError as syntax_error:
            return False
        except javalang.tokenizer.LexerError as lexer_error:
            return False
        return True
    elif lang == 'python':
        try:
            ast.parse(programString, filename='NA')
        except SyntaxError:
            return False
        except Exception:
            return False
        return True
    else:
        raise NotImplementedError


class Solution:
    def __init__(
            self,
            source,
            lang,
            problem_id,
            code_tokens,
            functions_standalone=[],
            functions_class=[],
            submission_id=""
    ):
        self.source = source
        self.lang = lang
        self.problem_id = problem_id
        self.code_tokens = code_tokens
        self.submission_id = submission_id
        self.functions_standalone = functions_standalone
        self.functions_class = functions_class

    def __repr__(self):
        return 'source: ' + self.source + '\n' + \
               'lang: ' + self.lang + '\n' + \
               'problem_id: ' + self.problem_id + '\n' + \
               'code: ' + ' '.join(self.code_tokens) + '\n' + \
               'submission_id: ' + self.submission_id + '\n'

    def __str__(self):
        return 'source: ' + self.source + '\n' + \
               'lang: ' + self.lang + '\n' + \
               'problem_id: ' + self.problem_id + '\n' + \
               'code: ' + ' '.join(self.code_tokens) + '\n' + \
               'submission_id: ' + self.submission_id + '\n'


def write_output_to_file(problems, file_to_write):
    mode = 'w'
    if os.path.exists(file_to_write):
        mode = 'a'
        with open(file_to_write, mode, encoding='utf8') as fw:
            fw.write('\n')
    with open(file_to_write, mode, encoding='utf8') as fw:
        fw.write('\n'.join([json.dumps(p) for p in problems]))


def calculate_similarity(code1_tokens, code2_tokens):
    code1 = ' '.join(code1_tokens)
    code2 = ' '.join(code2_tokens)
    return SequenceMatcher(None, code1, code2).ratio()


def separate_less_similar_solutions(solutions, k):
    if len(solutions) <= k:
        return solutions

    result = [solutions[0]]
    solutions.remove(result[0])
    for i in range(k - 1):
        min_distance = 999999
        selected_solution = None
        for solution in solutions:
            distance_sum = 0.0
            for res in result:
                distance_sum += calculate_similarity(solution.code_tokens, res.code_tokens)
            if min_distance > distance_sum:
                min_distance = distance_sum
                selected_solution = solution

        if selected_solution is not None:
            result.append(selected_solution)
            solutions.remove(selected_solution)

    return result


def main(args):
    result = []
    unique_ids = set()

    for contest_dir in listdir(args.src_dir):
        # contest_dir = abc001 ....
        if contest_dir == '.DS_Store':
            continue
        for problem_dir in listdir(args.src_dir + '/' + contest_dir):
            # problem_dir = A, B, C, D ....
            if problem_dir == '.DS_Store':
                continue
            java_solutions = []
            python_solutions = []
            for solution in listdir(args.src_dir + '/' + contest_dir + '/' + problem_dir):
                # solution = 2736192.java ....
                if solution == '.DS_Store':
                    continue
                solution_path = args.src_dir + '/' + contest_dir + '/' + problem_dir + '/' + solution
                submission_id = solution.split('.')[0]
                submission_id = ''.join(list(filter(str.isdigit, submission_id)))  # extract only digits
                ext = solution.split('.')[1]

                try:
                    if ext == 'java':
                        with open(solution_path, 'rb') as f:
                            code = f.read().decode("utf-8", errors="replace")
                            if not is_parsable(code, 'java'):
                                continue

                            code_tokens = jprocessor.tokenize_code(code)
                            try:
                                fn_standalone, fn_class = jprocessor.extract_functions(code_tokens)
                                functions_standalone = [(jprocessor.get_function_name(fn), fn) for fn in fn_standalone]
                                functions_class = [(jprocessor.get_function_name(fn), fn) for fn in fn_class]
                            except:
                                functions_standalone, functions_class = [], []

                            if len(code_tokens) > args.java_max_len:
                                continue
                            if len(code_tokens) < args.min_len:
                                continue
                            java_solutions.append(
                                Solution(
                                    args.source,
                                    'java',
                                    contest_dir + '_' + problem_dir,
                                    code_tokens,
                                    functions_standalone,
                                    functions_class,
                                    submission_id
                                )
                            )
                    elif ext == 'py':
                        with open(solution_path, 'rb') as f:
                            code = f.read().decode("utf-8", errors="replace")
                            if not is_parsable(code, 'python'):
                                continue

                            code_tokens = pyprocessor.tokenize_code(code)
                            try:
                                fn_standalone, fn_class = pyprocessor.extract_functions(code_tokens)
                                functions_standalone = [(pyprocessor.get_function_name(fn), fn) for fn in fn_standalone]
                                functions_class = [(pyprocessor.get_function_name(fn), fn) for fn in fn_class]
                            except:
                                functions_standalone, functions_class = [], []

                            if len(code_tokens) > args.python_max_len:
                                continue
                            if len(code_tokens) < args.min_len:
                                continue
                            python_solutions.append(
                                Solution(
                                    args.source,
                                    'java',
                                    contest_dir + '_' + problem_dir,
                                    code_tokens,
                                    functions_standalone,
                                    functions_class,
                                    submission_id
                                )
                            )
                except Exception as error:
                    print(solution_path, error)
                    pass
                if len(java_solutions) >= 20 and len(python_solutions) >= 20:
                    break

            if len(java_solutions) > 0 and len(python_solutions) > 0:
                java_solutions = separate_less_similar_solutions(java_solutions, args.k)
                python_solutions = separate_less_similar_solutions(python_solutions, args.k)
                _id = args.source + "_" + contest_dir + "_" + problem_dir
                assert _id not in unique_ids
                result.append({
                    "id": _id,
                    "java": [{
                        "id": js.submission_id,
                        "code": ' '.join(js.code_tokens),
                        "functions_standalone": js.functions_standalone,
                        "functions_class": js.functions_class
                    } for js in java_solutions],
                    "python": [{
                        "id": ps.submission_id,
                        "code": ' '.join(ps.code_tokens),
                        "functions_standalone": ps.functions_standalone,
                        "functions_class": ps.functions_class
                    } for ps in python_solutions]
                })
                unique_ids.add(_id)

    print('[{}] Total problems preprocessed - {}'.format(args.source, len(result)))
    write_output_to_file(result, args.out_file)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--src_dir", type=str, help='Source directory')
    parser.add_argument("--out_file", type=str, help='Output file')
    parser.add_argument("--source", type=str, help='Online judge')
    parser.add_argument("--min_len", type=int, default=10, help='Filter data smaller than min_len')
    parser.add_argument("--java_max_len", type=int, default=464, help='Filter data beyond maximum length')
    parser.add_argument("--python_max_len", type=int, default=464, help='Filter data beyond maximum length')
    parser.add_argument("--k", type=int, default=5, help='Number of submissions to consider')
    args = parser.parse_args()

    main(args)
