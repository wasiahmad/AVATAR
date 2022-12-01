# Copyright (c) Microsoft Corporation. 
# Licensed under the MIT license.

# -*- coding:utf-8 -*-
import os
import json
import argparse
from pathlib import Path
from evaluation.CodeBLEU import (
    bleu,
    weighted_ngram_match,
    syntax_match,
    dataflow_match
)

root_directory = Path(__file__).parents[2]


def python_process(tokens):
    new_tokens = []
    indent_count = 0
    num_tokens = len(tokens)
    tidx = 0
    while tidx < num_tokens:
        tok = tokens[tidx]
        tok = tok.strip()
        if tok in ["NEW_LINE"]:
            new_tokens.append("\n")
            if tidx + 1 < num_tokens:
                next_token = tokens[tidx + 1]
                if next_token == "INDENT":
                    indent_count += 1
                    tidx += 1
                elif next_token == "DEDENT":
                    indent_count -= 1
                    tidx += 1
            for ic in range(indent_count):
                new_tokens.append("\t")
        else:
            new_tokens.append(tok)
        tidx += 1
    return new_tokens
    pass


def php_process(tokens):
    new_tokens = []
    num_tokens = len(tokens)
    tidx = 0
    while tidx < num_tokens:
        tok = tokens[tidx]
        tok = tok.strip()
        if tok == "$":
            if tidx + 1 < num_tokens:
                tok += tokens[tidx + 1].strip()
                tidx += 1
                pass
            pass
        tidx += 1
        new_tokens.append(tok)
    return new_tokens


def language_specific_processing(tokens, lang):
    if lang == 'python':
        return python_process(tokens)
    elif lang == 'php':
        return php_process(tokens)
    else:
        return tokens


def get_codebleu(
        ref,
        hyp,
        lang,
        params='0.25,0.25,0.25,0.25',
        txt_ref=False,
        keyword_dir=None
):
    lang = 'javascript' if lang == 'js' else lang
    alpha, beta, gamma, theta = [float(x) for x in params.split(',')]

    # preprocess inputs
    if txt_ref:
        references = [[x.strip()] for x in open(ref, 'r', encoding='utf-8').readlines()]
    else:
        references = [json.loads(x.strip())[lang] for x in open(ref, 'r', encoding='utf-8').readlines()]
    hypothesis = [x.strip() for x in open(hyp, 'r', encoding='utf-8').readlines()]

    assert len(hypothesis) == len(references)

    # calculate ngram match (BLEU)
    tokenized_hyps = [language_specific_processing(x.split(), lang) for x in hypothesis]
    tokenized_refs = [[language_specific_processing(x.split(), lang) for x in reference] for reference in references]

    ngram_match_score = bleu.corpus_bleu(tokenized_refs, tokenized_hyps)

    # calculate weighted ngram match
    if keyword_dir is None:
        keyword_dir = root_directory.joinpath("evaluation/CodeBLEU/keywords")

    kw_file = os.path.join(keyword_dir, '{}.txt'.format(lang))
    keywords = [x.strip() for x in open(kw_file, 'r', encoding='utf-8').readlines()]

    def make_weights(reference_tokens, key_word_list):
        return {token: 1 if token in key_word_list else 0.2 for token in reference_tokens}

    tokenized_refs_with_weights = [
        [
            [reference_tokens, make_weights(reference_tokens, keywords)] for reference_tokens in reference
        ] for reference in tokenized_refs
    ]

    weighted_ngram_match_score = weighted_ngram_match.corpus_bleu(tokenized_refs_with_weights, tokenized_hyps)

    # calculate syntax match
    syntax_match_score = syntax_match.corpus_syntax_match(references, hypothesis, lang)

    # calculate dataflow match
    dataflow_match_score = dataflow_match.corpus_dataflow_match(references, hypothesis, lang)

    print(
        'Ngram match:\t%.2f\nWeighted ngram:\t%.2f\nSyntax match:\t%.2f\nDataflow match:\t%.2f' %
        (ngram_match_score * 100, weighted_ngram_match_score * 100,
         syntax_match_score * 100, dataflow_match_score * 100)
    )

    code_bleu_score = alpha * ngram_match_score \
                      + beta * weighted_ngram_match_score \
                      + gamma * syntax_match_score \
                      + theta * dataflow_match_score

    return code_bleu_score


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--ref', type=str, required=True, help='reference file')
    parser.add_argument('--hyp', type=str, required=True, help='hypothesis file')
    parser.add_argument('--txt_ref', action='store_true', help='reference file is a txt file')
    parser.add_argument('--lang', type=str, required=True,
                        choices=['java', 'js', 'c_sharp', 'php', 'go', 'python', 'ruby'],
                        help='programming language')
    parser.add_argument('--params', type=str, default='0.25,0.25,0.25,0.25', help='alpha, beta and gamma')

    args = parser.parse_args()

    code_bleu_score = get_codebleu(args.ref, args.hyp, args.lang, args.params, args.txt_ref)
    print('CodeBLEU score: %.2f' % (code_bleu_score * 100.0))
