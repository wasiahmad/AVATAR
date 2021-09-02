import sys

sys.path.append('..')

import os
import json
from data.split import prepare, split


class Namespace:
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)


def main():
    ignore_java_functions = []
    with open('transcoder_test_gfg/test.java-python.java', encoding='utf8') as f:
        for line in f:
            ignore_java_functions.append(line.strip())

    ignore_python_functions = []
    with open('transcoder_test_gfg/test.java-python.python', encoding='utf8') as f:
        for line in f:
            ignore_python_functions.append(line.strip())

    def is_match(code, language):
        if language == 'java':
            for fn in ignore_java_functions:
                if fn == code:
                    return True
        elif language == 'python':
            for fn in ignore_python_functions:
                if fn == code:
                    return True
        return False

    result = []
    java_ignored = 0
    python_ignored = 0
    with open('geeksforgeeks.jsonl', encoding='utf8') as f:
        for line in f:
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
                            if not is_match(fn_body, "java"):
                                java_functions.append({
                                    "id": prog["id"],
                                    "code": fn_body,
                                })

            for prog in ex["python"]:
                if len(prog["functions_class"]) == 0:
                    if len(prog["functions_standalone"]) == 1:
                        fn_body = prog["functions_standalone"][0][1]
                        if not is_match(fn_body, "python"):
                            python_functions.append({
                                "id": prog["id"],
                                "code": fn_body,
                            })

            if len(java_functions) > 0 and len(python_functions) > 0:
                result.append({
                    "id": ex["id"],
                    "java": java_functions,
                    "python": python_functions
                })

    if java_ignored > 0:
        print('{} java functions ignored due to overlap to transcoder_g4g')
    if python_ignored > 0:
        print('{} python functions ignored due to overlap to transcoder_g4g')

    OUT_DIR = 'g4g_functions'
    if not os.path.exists(OUT_DIR):
        os.makedirs(OUT_DIR)

    OUT_JSONL = os.path.join(OUT_DIR, 'paralllel_functions.jsonl')
    with open(OUT_JSONL, 'w', encoding='utf8') as fw:
        fw.write('\n'.join([json.dumps(p) for p in result]))

    args = Namespace(
        src_file=[OUT_JSONL],
        out_dir=OUT_DIR,
        k=5
    )
    split(args)
    args = Namespace(
        src_dir=OUT_DIR,
        out_dir=OUT_DIR,
        k=5
    )
    prepare(args)


if __name__ == '__main__':
    main()
