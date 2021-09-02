import sys

sys.path.append('..')

import os
import json
import numpy
import argparse
from pathlib import Path
from codegen.preprocessing.lang_processors.java_processor import JavaProcessor
from codegen.preprocessing.lang_processors.python_processor import PythonProcessor

root_folder = "../third_party"
jprocessor = JavaProcessor(root_folder=root_folder)
pyprocessor = PythonProcessor(root_folder=root_folder)

considered_types = [
    "int ",
    "int [ ]",
]

allowed_return_types = [
    "boolean",
    "int",
    "long",
    "String",
    "double",
    "float",
]

NUM_TEST_CASES = 10
# we do not chose negative integers as parameters
# because often they indicate lengths/sizes
MIN_INT = 0
MAX_INT = 200
MAX_ARRAY_ARG_SIZE = 50
INDENT = ' ' * 4


def get_return_type(code):
    """
    this function will only work for 1 word return types
    :param code:
    :return:
    """
    assert isinstance(code, str) or isinstance(
        code, list
    ), f"function is not the right type, should be str or list : {code}"
    if isinstance(code, str):
        code = code.split()
    return code[code.index("(") - 2]


def generate_test_case_string(arg_types):
    java_case_string = ''
    python_case_string = ''
    for i in range(len(arg_types)):
        assert arg_types[i] in considered_types
        var = 'param{}'.format(i)
        if arg_types[i] == 'int ':
            java_case_string += (1 * INDENT) + 'List<Integer> {} = new ArrayList<>();\n'.format(var)
            python_case_string += (1 * INDENT) + '{} = list()\n'.format(var)
            for j in range(NUM_TEST_CASES):
                param = numpy.random.randint(MIN_INT, MAX_INT)
                java_case_string += (1 * INDENT) + '{}.add({});\n'.format(var, param)
                python_case_string += (1 * INDENT) + '{}.append({})\n'.format(var, param)
        elif arg_types[i] == 'int [ ]':
            python_case_string += (1 * INDENT) + '{} = list()\n'.format(var)
            for j in range(NUM_TEST_CASES):
                ARR_SIZE = numpy.random.randint(0, MAX_ARRAY_ARG_SIZE) + 1
                param = numpy.random.randint(MIN_INT, MAX_INT, ARR_SIZE)
                param_str = '[' + ','.join([str(num) for num in param]) + ']'
                java_case_string += (1 * INDENT) + '{}.add(new int[]{});\n'.format(var, param_str)
                python_case_string += (1 * INDENT) + '{}.append({});\n'.format(var, param_str)

    return java_case_string, python_case_string


def generate_param_specific_body_python(arg_types, tc_string, is_ret_type_float):
    gen_part = 'f_filled('
    for i in range(len(arg_types)):
        if i != 0:
            gen_part += ','
        gen_part += 'param{}[i]'.format(i)
    gen_part += ')'

    gold_part = 'f_gold('
    for i in range(len(arg_types)):
        if i != 0:
            gold_part += ','
        gold_part += 'param{}[i]'.format(i)
    gold_part += ')'

    if is_ret_type_float:
        gen_part = '(0.0000001 + abs({}))'.format(gen_part)
        gold_part = '(0.0000001 + abs({}))'.format(gold_part)
        condition = 'abs(1 - {} / {}) < 0.001'.format(gold_part, gen_part)
    else:
        condition = gold_part + ' == ' + gen_part

    program = ''
    program += tc_string
    program += (1 * INDENT) + 'n_success = 0\n'
    program += (1 * INDENT) + 'for i in range(len(param0)):\n'
    program += (2 * INDENT) + 'if({})'.format(condition) + '\n'
    program += (3 * INDENT) + 'n_success+=1\n'
    program += (1 * INDENT) + 'print("#Results: %i, %i" % (n_success, len(param)))'
    return program


def generate_python_program(fn_name, fn, types, tc_string, is_ret_type_float):
    fn = fn.replace(fn_name, 'f_gold')
    program = ''
    program += fn
    program += '\n\n\n'
    program += '#TOFILL\n\n'

    program += 'if __name__ == "__main__":\n'
    program += generate_param_specific_body_python(types, tc_string, is_ret_type_float)
    return program


def generate_param_specific_body_java(arg_types, tc_string, is_ret_type_float):
    gen_part = 'f_filled('
    for i in range(len(arg_types)):
        if i != 0:
            gen_part += ','
        gen_part += 'param{}.get(i)'.format(i)
    gen_part += ')'

    gold_part = 'f_gold('
    for i in range(len(arg_types)):
        if i != 0:
            gold_part += ','
        gold_part += 'param{}.get(i)'.format(i)
    gold_part += ')'

    if is_ret_type_float:
        gen_part = '(0.0000001 + Math.abs({}))'.format(gen_part)
        gold_part = '(0.0000001 + Math.abs({}))'.format(gold_part)
        condition = 'Math.abs(1 - {} / {}) < 0.001'.format(gold_part, gen_part)
    else:
        condition = gold_part + ' == ' + gen_part

    program = ''
    program += (1 * INDENT) + 'int n_success = 0;\n'
    program += tc_string
    program += (1 * INDENT) + 'for(int i = 0; i < param0.size(); ++i)\n'
    program += (1 * INDENT) + '{\n'
    program += (2 * INDENT) + 'if({})'.format(condition) + '\n'
    program += (2 * INDENT) + '{\n'
    program += (3 * INDENT) + 'n_success+=1;\n'
    program += (2 * INDENT) + '}\n'
    program += (1 * INDENT) + '}\n'
    program += (1 * INDENT) + 'System.out.println("#Results:" + n_success + ", " + param0.size());\n'
    return program


def generate_java_program(fn_name, fn, types, tc_string, is_ret_type_float):
    fn = fn.replace(fn_name, 'f_gold')
    program = 'import java.util.*;\n' \
              'import java.util.stream.*;\n' \
              'import java.lang.*;\n' \
              'import javafx.util.Pair;\n'
    program += '\n'
    program += 'public class {}'.format(fn_name) + '{ \n\n'
    program += fn
    program += '\n\n\n'
    program += '//TOFILL\n\n'
    program += 'public static void main(String args[]) {\n'
    program += generate_param_specific_body_java(types, tc_string, is_ret_type_float)
    program += '}\n'
    program += '}\n'
    return program


def generate_programs(
        fn_name,
        java_fn,
        python_fn,
        types,
        is_ret_type_float):
    java_cs, python_cs = generate_test_case_string(types)
    java_program = generate_java_program(
        fn_name, java_fn, types, java_cs, is_ret_type_float
    )
    py_program = generate_python_program(
        fn_name, python_fn, types, python_cs, is_ret_type_float
    )
    return java_program, py_program


def main(params):
    filename = os.path.join(params.src_dir, '{}.jsonl'.format(params.split))
    j_output_dir = os.path.join(params.out_dir, params.split, 'java')
    Path(j_output_dir).mkdir(parents=True, exist_ok=True)
    p_output_dir = os.path.join(params.out_dir, params.split, 'python')
    Path(p_output_dir).mkdir(parents=True, exist_ok=True)

    with open(filename, 'r', encoding='utf8') as f:
        for line in f:
            ex = json.loads(line.strip())
            assert len(ex["java"]) == 1 and len(ex["python"]) == 1
            java_code = ex["java"][0]
            python_code = ex["python"][0]

            fn_name = jprocessor.get_function_name(java_code)
            types, names = jprocessor.extract_arguments(java_code)
            if len(types) == 0:
                continue
            ret_type = get_return_type(java_code)
            if ret_type not in allowed_return_types:
                continue
            is_match = [t in considered_types for t in set(types)]
            if all(is_match):
                is_ret_type_float = ret_type in ["float", "double"]
                java_fn = jprocessor.detokenize_code(java_code)
                python_fn = pyprocessor.detokenize_code(python_code)
                java_program, python_program = generate_programs(
                    fn_name, java_fn, python_fn, types,
                    is_ret_type_float
                )
                file = os.path.join(j_output_dir, '{}.java'.format(ex['id']))
                with open(file, 'w', encoding='utf8') as fw:
                    fw.write(java_program)
                file = os.path.join(p_output_dir, '{}.py'.format(ex['id']))
                with open(file, 'w', encoding='utf8') as fw:
                    fw.write(python_program)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--src_dir", type=str, help='source directory')
    parser.add_argument("--out_dir", type=str, help='output directory')
    parser.add_argument("--split", type=str, help='split')
    args = parser.parse_args()

    main(args)
