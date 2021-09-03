import re
import sys
import json
import logging
import argparse

logging.basicConfig(
    format='%(asctime)s - %(levelname)s - %(name)s -   %(message)s',
    datefmt='%m/%d/%Y %H:%M:%S',
    level=logging.INFO, stream=sys.stdout
)
logger = logging.getLogger(__name__)

PYTHON_ERROR_CLASSES = [
    'SyntaxError',
    'TypeError',
    'NameError',
    'UnboundLocalError',
    'AttributeError',
    'ZeroDivisionError',
    'IndexError',
    'RecursionError',
    'KeyError',
    'ValueError',
    'OverflowError'
]

JAVA_ERROR_CLASSES = {
    'TypeError': ('list', [
        ('string', 'error: incompatible types:'),
        ('string', 'error: incomparable types:'),
        ('string', 'error: unexpected type'),
        ('string', 'cannot be applied to given types'),
        ('regexp', 'error: .* required, but .* found'),
        ('string', 'error: char cannot be dereferenced'),
        ('string', 'error: int cannot be dereferenced'),
        ('string', 'error: boolean cannot be dereferenced'),
        ('regexp', 'error: .* type not allowed'),
    ]),
    'SyntaxError': ('regexp', 'error: .* expected'),
    'IllegalStartOfExpression': ('string', 'error: illegal start of expression'),
    'ArrayIndexOutOfBoundsException': ('string', 'java.lang.ArrayIndexOutOfBoundsException'),
    'VariableAlreadyDefined': ('regexp', 'error: variable .* is already defined'),
    'NoSuitableMethodFound': ('string', 'error: no suitable method found'),
    'ElseWithoutIf': ('string', "error: 'else' without 'if'"),
    'CantFindSymbol': ('string', 'error: cannot find symbol'),
    'BadOperand': ('string', 'error: bad operand type'),
    'NotAStatement': ('string', 'error: not a statement'),
    'UnclosedStringLiteral': ('string', 'error: unclosed string literal'),
    'NoReturnStatement': ('string', 'error: missing return statement'),
    'InvalidMethod': ('string', 'error: invalid method declaration; return type required'),
    'StackOverflowError': ('string', 'java.lang.StackOverflowError'),
    'StringIndexOutOfBoundsException': ('string', 'java.lang.StringIndexOutOfBoundsException'),
    'NumberFormatException': ('string', 'java.lang.NumberFormatException'),
    'IllegalArgumentException': ('string', 'java.lang.IllegalArgumentException'),
    'UnreachableStatement': ('string', 'error: unreachable statement'),
    'IntNumberTooLong': ('string', 'error: integer number too large'),
    'NullPointerException': ('string', 'java.lang.NullPointerException'),
    'IndexOutOfBoundsException': ('string', 'java.lang.IndexOutOfBoundsException'),
    'ArithmeticException': ('string', 'java.lang.ArithmeticException'),
    'VariableNotInitialized': ('regexp', 'error: variable .* might not have been initialized'),
    'BreakOutsideSwitchOrLoop': ('string', 'error: break outside switch or loop')
}

JAVA_ERROR_TYPES = {
    'Compilation Errors': [
        'TypeError',
        'SyntaxError',
        'IllegalStartOfExpression',
        'VariableAlreadyDefined',
        'NoSuitableMethodFound',
        'ElseWithoutIf',
        'CantFindSymbol',
        'BadOperand',
        'NotAStatement',
        'UnclosedStringLiteral',
        'NoReturnStatement',
        'InvalidMethod',
        'UnreachableStatement',
        'IntNumberTooLong',
        'VariableNotInitialized',
        'BreakOutsideSwitchOrLoop',
    ],
    'Runtime Errors': [
        'ArrayIndexOutOfBoundsException',
        'StackOverflowError',
        'StringIndexOutOfBoundsException',
        'NumberFormatException',
        'IllegalArgumentException',
        'NullPointerException',
        'IndexOutOfBoundsException',
        'ArithmeticException',
    ]
}


def is_match(regex, text):
    pattern = re.compile(regex)
    return pattern.search(text) is not None


def is_match_list(list_of_err_txt, text):
    for v in list_of_err_txt:
        if (v[0] == 'string' and v[1] in text) or \
                (v[0] == 'regexp' and is_match(v[1], text)):
            return True
    return False


def classify_python_errors(args):
    error_counts = {k: 0 for k in PYTHON_ERROR_CLASSES}
    total_errors = 0
    with open(args.logfile, encoding='utf8') as f:
        for line in f:
            msg = line.strip()[2:-2]
            if msg.startswith('error : '):
                total_errors += 1
                matched = False
                for err in PYTHON_ERROR_CLASSES:
                    if err in msg:
                        error_counts[err] += 1
                        matched = True
                        break

                if not matched and args.verbose:
                    logger.info(msg)

    error_counts['other'] = total_errors - sum(error_counts.values())
    error_counts['total'] = total_errors
    print(json.dumps(error_counts, indent=4, sort_keys=True))


def classify_java_errors(args):
    error_counts = {k: 0 for k in JAVA_ERROR_CLASSES.keys()}
    total_errors = 0
    with open(args.logfile, encoding='utf8') as f:
        for line in f:
            msg = line.strip()[2:-2]
            if msg.startswith('error : '):
                total_errors += 1
                matched = False
                for k, v in JAVA_ERROR_CLASSES.items():
                    if (v[0] == 'string' and v[1] in msg) or \
                            (v[0] == 'regexp' and is_match(v[1], msg)) or \
                            (v[0] == 'list' and is_match_list(v[1], msg)):
                        error_counts[k] += 1
                        matched = True
                        break

                if not matched and args.verbose:
                    logger.info(msg)

    error_counts['other'] = total_errors - sum(error_counts.values())
    error_counts['total'] = total_errors
    print(json.dumps(error_counts, indent=4, sort_keys=True))

    result = {k: 0 for k in JAVA_ERROR_TYPES.keys()}
    for k, v in JAVA_ERROR_TYPES.items():
        for i in v:
            result[k] += error_counts[i]
    print(json.dumps(result, indent=4, sort_keys=True))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Evaluate leaderboard predictions for BigCloneBench dataset.')
    parser.add_argument('--logfile', required=True, type=str, help="log filepath.")
    parser.add_argument('--lang', required=True, type=str, help='language name', choices=['java', 'python'])
    parser.add_argument('--verbose', action='store_true', help='enable logging')
    args = parser.parse_args()
    if args.lang == 'java':
        classify_java_errors(args)
    else:
        classify_python_errors(args)
