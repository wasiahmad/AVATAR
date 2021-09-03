import os
import sys
import json
import logging
import argparse

from codegen.model.src.utils import (
    bool_flag,
    eval_function_output,
    vizualize_translated_files
)

logging.basicConfig(
    format='%(asctime)s - %(levelname)s - %(name)s -   %(message)s',
    datefmt='%m/%d/%Y %H:%M:%S',
    level=logging.INFO, stream=sys.stdout
)
logger = logging.getLogger(__name__)

EVAL_SCRIPT_FOLDER = {
    "test": "../data/transcoder_evaluation_gfg",
    "valid": "../data/transcoder_evaluation_gfg"
}


# https://github.com/facebookresearch/TransCoder/issues/10#issuecomment-677515085
def main(params):
    # Lets say we want to evaluate computation accuracy for Python -> Cpp.
    # 
    # ref_path is the absolute path to the tokenized cpp references i.e ground truths (also called gold functions),
    # one function per line. We give the references in order to compute the "identical to gold" score.
    # These tokenized references are given in the raw data we provide here. In the raw data your have
    # function_id | tokenized_function
    #
    # hyp_paths is the list of paths of the generated functions. len(hyp_paths) = beam size. If you generate only one
    # hypothesis per function, len(hyp_paths) = 1. You have one function per line.
    #
    # id_path is the path to the function ID. You have a one function ID per line. We give the functions id to find
    # the dedicated evaluation scripts with the ID.
    #
    # lang2 -> target language. For python -> CPP, LANG2='cpp'
    #
    # outfolder -> Folder where the unit test scripts will be stored and run
    #
    # script_folder -> 'g4g_successful_test_scripts/cpp/' folder to unit test
    # scipt that have to be fed with the generated function.
    #
    # retry_mismatching_types -> if True the unit tests are more robust. They try several input types for the functions.
    # When set to True it is slowert to evaluate but more robust. In our scores are given with True.

    func_run_stats, func_run_out = eval_function_output(
        params.ref_path,
        params.hyp_paths,
        params.id_path,
        params.target_lang,
        params.outfolder,
        EVAL_SCRIPT_FOLDER[params.split],
        params.retry_mismatching_types,
        roberta_mode=False
    )
    log_string = "%s_%s-%s" % (params.split, params.source_lang, params.target_lang)
    logger.info("Computation res %s : %s" % (log_string, json.dumps(func_run_stats)))
    comp_acc = func_run_stats['success'] / (
        func_run_stats['total_evaluated'] if func_run_stats['total_evaluated'] else 1)
    logger.info("%s_mt_comp_acc = %f" % (log_string, comp_acc))
    filepath = os.path.join(params.outfolder, "{}.log".format(log_string))
    with open(filepath, 'w', encoding='utf8') as fw:
        fw.write('\n'.join([str(item) for item in func_run_out]))

    out_paths = []
    success_for_beam_number = [0 for _ in range(len(params.hyp_paths))]
    for beam_number in range(len(success_for_beam_number)):
        out_name = "hyp.{0}-{1}.{2}_beam{3}.out.txt".format(
            params.source_lang,
            params.target_lang,
            params.split,
            beam_number
        )
        hyp_file_dir = os.path.dirname(params.hyp_paths[beam_number])
        out_path = os.path.join(hyp_file_dir, out_name)
        out_paths.append(out_path)
        with open(out_path, "w", encoding="utf-8") as f:
            for results_list in func_run_out:
                result_for_beam = (
                    results_list[beam_number]
                    if beam_number < len(results_list)
                    else ""
                )
                if result_for_beam.startswith("success"):
                    success_for_beam_number[beam_number] += 1
                f.write((result_for_beam) + "\n")
            f.write("\n")

    vizualize_translated_files(
        params.source_lang,
        params.target_lang,
        params.src_path,
        params.hyp_paths,
        params.id_path,
        params.ref_path,
        out_file=out_paths,
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--src_path", type=str, required=True, help="Path to sources")
    parser.add_argument("--ref_path", type=str, required=True, help="Path to references")
    parser.add_argument("--id_path", type=str, required=True, help="Path to identities")
    parser.add_argument("--hyp_paths", nargs='+', type=str, required=True, help="Path to hypotheses")
    parser.add_argument("--split", type=str, default='test', help="Dataset split")
    parser.add_argument("--outfolder", type=str, required=True, help="Output directory")
    parser.add_argument("--source_lang", type=str, required=True, help="Source language")
    parser.add_argument("--target_lang", type=str, required=True, help="Target language")
    parser.add_argument("--retry_mismatching_types", type=bool_flag, default=False,
                        help="Retry with wrapper at eval time when the types do not match")

    params = parser.parse_args()
    main(params)
