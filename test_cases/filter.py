import os
import sys
import json
import logging
import argparse
import subprocess

from pathlib import Path
from concurrent.futures import ProcessPoolExecutor
from codegen.model.src.utils import (
    EXT,
    MAX_VIRTUAL_MEMORY,
    limit_virtual_memory,
    read_file_lines,
)

TREE_SITTER_ROOT = Path(__file__).resolve().parents[1].joinpath("third_party")
import codegen.preprocessing.lang_processors.java_processor
import codegen.preprocessing.lang_processors.python_processor
from codegen.preprocessing.lang_processors.lang_processor import LangProcessor

logging.basicConfig(
    format='%(asctime)s - %(levelname)s - %(name)s -   %(message)s',
    datefmt='%m/%d/%Y %H:%M:%S',
    level=logging.INFO, stream=sys.stdout
)
logger = logging.getLogger(__name__)

EVAL_SCRIPT_FOLDER = {
    "atcoder": "atcoder_test_cases",
    "codeforces": "description2code_current/codeforces"
}


def is_number(s):
    try:
        float(s)
        return True
    except ValueError:
        return False


def is_valid_number(n1, n2):
    if abs(float(n1) - float(n2)) < 1e-6:
        return True
    return False


def is_content_same(model_out, ref_out):
    try:
        with open(model_out) as f1, open(ref_out) as f2:
            lines1 = f1.read().strip().split("\n")
            lines2 = f2.read().strip().split("\n")
            if len(lines1) != len(lines2):
                return False, "different number of lines"
            for l1, l2 in zip(lines1, lines2):
                if l1.strip() != l2.strip():
                    token1s = l1.strip().split()
                    token2s = l2.strip().split()
                    if len(token1s) == len(token2s):
                        for idx in range(len(token1s)):
                            if token1s[idx] != token2s[idx]:
                                if is_number(token1s[idx]) and is_number(token2s[idx]):
                                    if not is_valid_number(token1s[idx], token2s[idx]):
                                        return False, "number output diff is larger than 1e-6"
                                else:
                                    return False, "non-number output mismatch"
                    else:
                        return False, "mismatch number of outputs"
            return True, None
    except Exception as e:
        return False, "output comparison failed"


def eval_state(proc, proc_name, model_out, exp_out):
    try:
        result, stderr = proc.communicate(timeout=30)
        if stderr:
            error_msg = stderr.decode("utf-8", errors="replace")
            if "ValueError: invalid literal for int() with base 10" in error_msg:
                return "ignore", "wrong test case"
            elif "EOFError: EOF when reading a line" in error_msg:
                return "ignore", "wrong test case"
            elif "map ( int , input ( ).split ( ) ) ValueError: not enough values to unpack" in error_msg:
                return "ignore", "wrong test case"
            else:
                return "error", stderr.decode("utf-8", errors="replace")
        else:
            if os.stat(model_out).st_size == 0:
                return "failure", "no program output"
            else:
                is_passed, msg = is_content_same(model_out, exp_out)
                if is_passed:
                    return "success", None
                else:
                    return "failure", msg
    except subprocess.TimeoutExpired:
        c = (
                "kill `ps aux | grep '"
                + proc_name
                + "' | grep -v jupyter | grep -v grep | awk '{print($2)}'`"
        )
        subprocess.run(
            c, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        return "timeout", None
    except KeyboardInterrupt:
        raise
    except:
        return "error", stderr.decode("utf-8", errors="replace")


def run_python_program(script_path, i_file, o_file):
    model_out = f"{os.path.splitext(script_path)[0]}_{Path(i_file).stem}.out"
    proc = subprocess.Popen(
        f"{limit_virtual_memory(MAX_VIRTUAL_MEMORY)}; "
        f"python {script_path} < {i_file} > {model_out}",
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        shell=True,
        executable="/bin/bash",
    )
    res = eval_state(proc, f"python {script_path}", model_out, o_file)
    return res


def run_java_program(script_path, i_file, o_file):
    folder = os.path.dirname(script_path)
    name = os.path.basename(script_path).split(".")[0]
    model_out = f"{os.path.splitext(script_path)[0]}_{Path(i_file).stem}.out"
    proc = subprocess.Popen(
        f'{limit_virtual_memory(MAX_VIRTUAL_MEMORY)}; '
        f'cd {folder} && javac {name}.java && java {name} < {i_file} > {model_out}',
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        shell=True,
        executable='/bin/bash'
    )
    res = eval_state(proc, f"java {name}", model_out, o_file)
    return res


def submit_programs(
        model_translations,
        id,
        lang,
        outfolder,
        test_cases,
        test_case_ios,
):
    lang_processor = LangProcessor.processors[lang](root_folder=TREE_SITTER_ROOT)
    i = id.rstrip()
    best_results_list = []
    for try_id, prog in enumerate(model_translations):
        script = lang_processor.detokenize_code(prog)
        script_path = f"{outfolder}/{i}.{EXT[lang]}"
        open(script_path, "w", encoding="utf-8").write(script)

        results_list = []
        for idx, (i_file, o_file) in enumerate(test_cases):
            run_pg = globals()[f"run_{lang}_program"]
            result = run_pg(script_path, i_file, o_file)
            if result[0] != "ignore":
                results_list.append({"io": test_case_ios[idx], "result": result})

        if len(results_list) == 0:
            continue

        is_passed = [r["result"][0] == "success" for r in results_list]
        if all(is_passed):
            return results_list, i
        elif len(best_results_list) == 0 or \
                sum(is_passed) > sum([r["result"][0] == "success" for r in best_results_list]):
            best_results_list = [r for r in results_list]

    return best_results_list, i


def main(params):
    TC_IN_OUT = dict()
    TC_FILE_IN_OUT = dict()
    tc_src_dir = os.path.join(params.testcases_dir, EVAL_SCRIPT_FOLDER[params.source])
    with open(params.input_test_cases) as f:
        for line in f:
            ex = json.loads(line)
            in_files = [os.path.join(tc_src_dir, tc_in) for tc_in in ex["inputs"]]
            out_files = [os.path.join(tc_src_dir, tc_out) for tc_out in ex["outputs"]]
            ins_outs = []
            file_ins_outs = []
            for idx, (i_f, o_f) in enumerate(zip(in_files, out_files)):
                if os.stat(i_f).st_size > 0 and os.stat(o_f).st_size > 0:
                    ins_outs.append((i_f, o_f))
                    file_ins_outs.append((ex["inputs"][idx], ex["outputs"][idx]))
            if ins_outs:
                TC_IN_OUT[ex["avatar_id"]] = ins_outs
                TC_FILE_IN_OUT[ex["avatar_id"]] = file_ins_outs

    reference_ids = [json.loads(line)["id"] for line in read_file_lines(params.ref_path)]
    translations = [json.loads(line)[params.target_lang] for line in read_file_lines(params.ref_path)]
    assert len(reference_ids) == len(translations)

    jobs = []
    executor = ProcessPoolExecutor()
    test_cases_not_found = 0
    for t, i in zip(translations, reference_ids):
        if i in TC_IN_OUT:
            jobs.append(
                executor.submit(
                    submit_programs,
                    t,
                    i,
                    params.target_lang,
                    params.outfolder,
                    TC_IN_OUT[i],
                    TC_FILE_IN_OUT[i]
                )
            )
        else:
            test_cases_not_found += 1

    results_stats = {
        "success": 0,
        "failure": 0,
        "error": 0,
        "timeout": 0
    }

    results = []
    for job in jobs:
        results_list, i = job.result()  # one problem evaluation output
        if len(results_list) == 0:
            test_cases_not_found += 1
            continue
        total_passed = sum([r["result"][0] == "success" for r in results_list])
        if total_passed == len(results_list):
            results_stats["success"] += 1
        elif any([r == "error" for r in results_list]):
            results_stats["error"] += 1
        elif any([r == "timeout" for r in results_list]):
            results_stats["timeout"] += 1
        else:
            results_stats["failure"] += 1

        results.append({
            "avatar_id": i,
            "inputs": [r["io"][0] for r in results_list if r["result"][0] == "success"],
            "outputs": [r["io"][1] for r in results_list if r["result"][0] == "success"]
        })

    results_stats["test_cases_not_found"] = test_cases_not_found
    results_stats["total"] = len(reference_ids)
    results_stats["total_evaluated"] = (len(reference_ids) - test_cases_not_found)
    results_stats = {k: results_stats[k] for k in sorted(results_stats.keys())}

    return results_stats, results


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--ref_path", type=str, required=True, help="Path to references")
    parser.add_argument("--testcases_dir", type=str, required=True, help="Path to sources")
    parser.add_argument("--outfolder", type=str, required=True, help="Output directory")
    parser.add_argument("--source", type=str, required=True,
                        choices=["atcoder", "codeforces"], help="Source of the references")
    parser.add_argument("--source_lang", type=str, required=True, help="Source language")
    parser.add_argument("--target_lang", type=str, required=True, help="Target language")
    parser.add_argument("--input_test_cases", type=str, required=True, help="Path to output file")
    parser.add_argument("--output_test_cases", type=str, default=None, help="Path to output file")
    parser.add_argument("--mode", type=str, required=True,
                        choices=["filter", "validate"], help="Source language")

    params = parser.parse_args()
    results_stats, results = main(params)

    log_string = "%s_to_%s" % (params.source_lang, params.target_lang)
    logger.info("Computation res %s : %s" % (log_string, json.dumps(results_stats)))
    comp_acc = results_stats['success'] / (
        results_stats['total_evaluated'] if results_stats['total_evaluated'] else 1)
    logger.info("%s_mt_comp_acc = %f" % (log_string, comp_acc))
    if params.mode == "filter":
        assert params.output_test_cases
        with open(params.output_test_cases, 'w', encoding='utf8') as fw:
            fw.write("\n".join([json.dumps(r) for r in results]))
