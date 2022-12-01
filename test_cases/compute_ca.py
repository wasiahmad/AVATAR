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
        errmsg = stderr.decode("utf-8", errors="replace")
        if errmsg:
            return "error", errmsg
        elif os.stat(model_out).st_size == 0:
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


def get_script_path(eid, lang, outfolder):
    if lang == "java":
        folder = f"{outfolder}/{eid}"
        Path(folder).mkdir(parents=True, exist_ok=True)
        return f"{folder}/Main.java"

    return f"{outfolder}/{eid}.{EXT[lang]}"


def submit_programs(
        model_translations,
        id,
        lang,
        outfolder,
        test_cases
):
    lang_processor = LangProcessor.processors[lang](root_folder=TREE_SITTER_ROOT)
    i = id.rstrip()
    best_results_list = []
    for try_id, prog in enumerate(model_translations):
        script = lang_processor.detokenize_code(prog)
        script_path = get_script_path(i, lang, outfolder)
        open(script_path, "w", encoding="utf-8").write(script)

        results_list = []
        for (i_file, o_file) in test_cases:
            run_pg = globals()[f"run_{lang}_program"]
            result = run_pg(script_path, i_file, o_file)
            results_list.append(result)

        is_passed = [r[0] == "success" for r in results_list]
        if all(is_passed):
            return results_list, i
        elif len(best_results_list) == 0 or \
                sum(is_passed) > sum([r[0] == "success" for r in best_results_list]):
            best_results_list = [r for r in results_list]

    return best_results_list, i


def main(params):
    TC_IN_OUT = dict()
    for pform in ["atcoder", "codeforces"]:
        tc_src_dir = os.path.join(params.testcases_dir, EVAL_SCRIPT_FOLDER[pform])
        with open(os.path.join(params.testcases_dir, f"{pform}_id2tests_filtered.jsonl")) as f:
            for line in f:
                ex = json.loads(line)
                in_files = [os.path.join(tc_src_dir, tc_in) for tc_in in ex["inputs"]]
                out_files = [os.path.join(tc_src_dir, tc_out) for tc_out in ex["outputs"]]
                ins_outs = [
                    (i_f, o_f) for i_f, o_f in zip(in_files, out_files)
                    if os.stat(i_f).st_size > 0 and os.stat(o_f).st_size > 0
                ]
                if ins_outs:
                    TC_IN_OUT[ex["avatar_id"]] = ins_outs

    logger.info(f"{len(TC_IN_OUT)} test cases loaded")
    reference_ids = [json.loads(line)["id"] for line in read_file_lines(params.ref_path)]
    translations = list(zip(*[read_file_lines(path) for path in params.hyp_paths]))
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
                    TC_IN_OUT[i]
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

    results = {}
    for job in jobs:
        results_list, i = job.result()  # one problem evaluation output
        assert len(results_list) != 0  # every program must be evaluated with >= 1 test cases
        total_passed = sum([r[0] == "success" for r in results_list])
        if total_passed == len(results_list):
            results_stats["success"] += 1
        elif any([r[0] == "error" for r in results_list]):
            results_stats["error"] += 1
        elif any([r[0] == "timeout" for r in results_list]):
            results_stats["timeout"] += 1
        else:
            results_stats["failure"] += 1

        results[i] = []
        for r, stderr in results_list:
            if stderr is not None:
                stderr = stderr.replace("\n", " ")
            else:
                stderr = "None"
            results[i].append(f"{r} : {stderr}")

    results_stats["test_cases_not_found"] = test_cases_not_found
    results_stats["total"] = len(reference_ids)
    results_stats["total_evaluated"] = (len(reference_ids) - test_cases_not_found)
    results_stats = {k: results_stats[k] for k in sorted(results_stats.keys())}

    return results_stats, results


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--ref_path", type=str, required=True, help="Path to references")
    parser.add_argument("--hyp_paths", nargs='+', type=str, required=True, help="Path to hypotheses")
    parser.add_argument("--testcases_dir", type=str, required=True, help="Path to sources")
    parser.add_argument("--outfolder", type=str, required=True, help="Output directory")
    parser.add_argument("--source_lang", type=str, required=True, help="Source language")
    parser.add_argument("--target_lang", type=str, required=True, help="Target language")

    params = parser.parse_args()
    results_stats, results = main(params)

    log_string = "%s_to_%s" % (params.source_lang, params.target_lang)
    logger.info("Computation res %s : %s" % (log_string, json.dumps(results_stats)))
    comp_acc = results_stats['success'] / (
        results_stats['total_evaluated'] if results_stats['total_evaluated'] else 1)
    logger.info("%s_mt_comp_acc = %f" % (log_string, comp_acc))
    filepath = os.path.join(params.outfolder, "{}.log".format(log_string))
    with open(filepath, 'w', encoding='utf8') as fw:
        json.dump(results, fw, ensure_ascii=False, indent=4)
