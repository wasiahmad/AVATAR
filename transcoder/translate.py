# Copyright (c) 2019-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
#
# Translate sentences from the input stream.
# The model will be faster is sentences are sorted by length.
# Input sentences must have the same tokenization and BPE codes than the ones used in the model.
#
# Usage:
#     python translate.py
#     --src_lang cpp --tgt_lang java \
#     --model_path trained_model.pth < input_code.cpp
#


import os
import torch
import argparse

from tqdm import tqdm
from logging import getLogger
from codegen.model.src.data.dictionary import (
    Dictionary,
    BOS_WORD,
    EOS_WORD,
    PAD_WORD,
    UNK_WORD,
    MASK_WORD
)
from codegen.preprocessing.bpe_modes.fast_bpe_mode import FastBPEMode
from codegen.preprocessing.bpe_modes.roberta_bpe_mode import RobertaBPEMode
from codegen.model.src.utils import (
    restore_roberta_segmentation_sentence,
    AttrDict,
    show_batch
)
from codegen.model.src.model import build_model

SUPPORTED_LANGUAGES = ['cpp', 'java', 'python']

logger = getLogger()


def get_parser():
    """
    Generate a parameters parser.
    """
    # parse parameters
    parser = argparse.ArgumentParser(description="Translate sentences")

    # model
    parser.add_argument("--model_path", type=str, default="", help="Model path")
    parser.add_argument(
        "--src_lang",
        type=str,
        default="",
        help=f"Source language, should be either {', '.join(SUPPORTED_LANGUAGES[:-1])} or {SUPPORTED_LANGUAGES[-1]}",
    )
    parser.add_argument(
        "--tgt_lang",
        type=str,
        default="",
        help=f"Target language, should be either {', '.join(SUPPORTED_LANGUAGES[:-1])} or {SUPPORTED_LANGUAGES[-1]}",
    )
    parser.add_argument(
        "--BPE_path",
        type=str,
        default="../codegen/bpe/cpp-java-python/codes",
        help="Path to BPE codes.",
    )
    parser.add_argument(
        "--beam_size",
        type=int,
        default=1,
        help="Beam size. The beams will be printed in order of decreasing likelihood.",
    )

    parser.add_argument("--input_file", type=str,
                        default="", help="Input file path")
    parser.add_argument("--output_file", type=str,
                        default="", help="Output file path")
    parser.add_argument("--batch_size", type=int, default=1, help="Batch size.")
    parser.add_argument("--show_example", action='store_true', help="show examples.")

    return parser


class Translator:
    def __init__(self, params):
        reloaded = torch.load(params.model_path, map_location='cpu')
        # change params of the reloaded model so that it will
        # relaod its own weights and not the MLM or DOBF pretrained model
        reloaded["params"]["reload_model"] = ",".join([params.model_path] * 2)
        reloaded["params"]["lgs_mapping"] = ""
        reloaded["params"]["reload_encoder_for_decoder"] = False
        self.reloaded_params = AttrDict(reloaded["params"])

        # build dictionary / update parameters
        self.dico = Dictionary(
            reloaded['dico_id2word'], reloaded['dico_word2id'], reloaded['dico_counts']
        )
        assert self.reloaded_params.n_words == len(self.dico)
        assert self.reloaded_params.bos_index == self.dico.index(BOS_WORD)
        assert self.reloaded_params.eos_index == self.dico.index(EOS_WORD)
        assert self.reloaded_params.pad_index == self.dico.index(PAD_WORD)
        assert self.reloaded_params.unk_index == self.dico.index(UNK_WORD)
        assert self.reloaded_params.mask_index == self.dico.index(MASK_WORD)

        # build model / reload weights (in the build_model method)
        encoder, decoder = build_model(self.reloaded_params, self.dico)
        self.encoder = encoder[0]
        self.decoder = decoder[0]
        self.encoder.cuda()
        self.decoder.cuda()
        self.encoder.eval()
        self.decoder.eval()

        # reload bpe
        if getattr(self.reloaded_params, "roberta_mode", False):
            self.bpe_model = RobertaBPEMode()
        else:
            self.bpe_model = FastBPEMode(
                codes=os.path.abspath(params.BPE_path), vocab_path=None
            )

    def translate(
            self,
            batch_input,
            lang1,
            lang2,
            n=1,
            beam_size=1,
            sample_temperature=None,
            device='cuda:0',
            max_tokens=None,
            show_example=False,
    ):
        assert lang1 in {'python', 'java', 'cpp'}, lang1
        assert lang2 in {'python', 'java', 'cpp'}, lang2

        if (lang1 + '_sa') in self.reloaded_params.lang2id:
            lang1 += '_sa'
            lang2 += '_sa'

        lang1_id = self.reloaded_params.lang2id[lang1]
        lang2_id = self.reloaded_params.lang2id[lang2]

        input_lengths = []
        input_ids = []
        for input in batch_input:
            tokens = input.split()
            tokens = self.bpe_model.apply_bpe(" ".join(tokens)).split()
            if max_tokens is not None and len(tokens) > max_tokens - 2:
                tokens = tokens[:max_tokens - 2]
                logger.info(f"[Warning] truncated long input sequence of size {len(tokens)}")

            tokens = ['</s>'] + tokens + ['</s>']
            input_ids.append([self.dico.index(w) for w in tokens])
            input_lengths.append(len(tokens))

        max_length = max(input_lengths)
        for i in range(len(batch_input)):
            num_pad_tokens = max_length - input_lengths[i]
            if num_pad_tokens > 0:
                input_ids[i].extend([self.reloaded_params.pad_index] * num_pad_tokens)

        len1 = torch.tensor(input_lengths, dtype=torch.long).to(device)
        x1 = torch.tensor(input_ids, dtype=torch.long).to(device)
        x1 = x1.transpose(0, 1)
        langs1 = x1.clone().fill_(lang1_id)

        # `x` LongTensor(slen, bs), containing word indices
        # `lengths` LongTensor(bs), containing the length of each sentence
        # `causal` Boolean, if True, the attention is only done over previous hidden states
        # `positions` LongTensor(slen, bs), containing word positions
        # `langs` LongTensor(slen, bs), containing language IDs
        enc1 = self.encoder('fwd', x=x1, lengths=len1, langs=langs1, causal=False)
        # move back batch size to dimension 0
        enc1 = enc1.transpose(0, 1)
        if n > 1:
            enc1 = enc1.repeat(n, 1, 1)
            len1 = len1.expand(n)

        if beam_size == 1:
            x2, len2 = self.decoder.generate(
                enc1,
                len1,
                lang2_id,
                max_len=int(
                    min(self.reloaded_params.max_len, 3 * len1.max().item() + 10)
                ),
                sample_temperature=sample_temperature
            )
            x2 = x2.unsqueeze(1)  # seq-len, 1, bsz
        else:
            x2, len2, _ = self.decoder.generate_beam(
                enc1,
                len1,
                lang2_id,
                max_len=int(
                    min(self.reloaded_params.max_len, 3 * len1.max().item() + 10)
                ),
                early_stopping=False,
                length_penalty=1.0,
                beam_size=beam_size,
            )

        # x2 = seq-len, beam-size, bsz -> bsz, seq-len, beam-size
        x2 = x2.permute(2, 0, 1).cpu().numpy()

        if show_example:
            show_batch(
                logger,
                [
                    ("source", x1.transpose(0, 1)),
                    ("target", x2[:, :, 0].transpose(0, 1))
                ],
                self.dico,
                False,
                f"Eval {lang1}-{lang2}",
            )

        batch_result = []
        for idx in range(x2.shape[0]):
            beam_outputs = []
            for i in range(x2.shape[2]):
                wid = [self.dico[x2[idx, j, i]] for j in range(len(x2[idx]))][1:]
                wid = wid[:wid.index(EOS_WORD)] if EOS_WORD in wid else wid
                if getattr(self.reloaded_params, "roberta_mode", False):
                    beam_outputs.append(restore_roberta_segmentation_sentence(" ".join(wid)))
                else:
                    beam_outputs.append(" ".join(wid).replace("@@ ", "").rstrip("@@"))
            batch_result.append(beam_outputs)

        return batch_result


if __name__ == '__main__':
    # generate parser / parse parameters
    parser = get_parser()
    params = parser.parse_args()

    # check parameters
    assert os.path.isfile(params.model_path), f"The path to the model checkpoint is incorrect: {params.model_path}"
    assert os.path.isfile(params.BPE_path), f"The path to the BPE tokens is incorrect: {params.BPE_path}"
    assert params.src_lang in SUPPORTED_LANGUAGES, f"The source language should be in {SUPPORTED_LANGUAGES}."
    assert params.tgt_lang in SUPPORTED_LANGUAGES, f"The target language should be in {SUPPORTED_LANGUAGES}."

    # Initialize translator
    translator = Translator(params)

    inputs_in_batches = []
    with open(params.input_file, encoding='utf8') as f:
        input_lines = []
        for idx, line in enumerate(f):
            input_lines.append(line.strip())
            if (idx + 1) % params.batch_size == 0:
                inputs_in_batches.append(input_lines)
                input_lines = []

        if input_lines:
            inputs_in_batches.append(input_lines)

    with open(params.output_file, 'w', encoding='utf8') as fw:
        for batch_input in tqdm(inputs_in_batches, total=len(inputs_in_batches)):
            with torch.no_grad():
                output = translator.translate(
                    batch_input,
                    lang1=params.src_lang,
                    lang2=params.tgt_lang,
                    beam_size=params.beam_size,
                    max_tokens=1024,
                    show_example=params.show_example,
                )
                for single_out in output:
                    assert len(single_out) == params.beam_size
                    fw.write(single_out[0] + '\n')
