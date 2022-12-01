<div align="center">

<h1>AVATAR</h1>

Official code release of our
work, [AVATAR: A Parallel Corpus for Java-Python Program Translation](https://arxiv.org/abs/2108.11590).

<p align="center">
  <a href="#setup">Setup</a> •
  <a href="#dataset">Dataset</a> •
  <a href="#models">Models</a> •
  <a href="#training--evaluation">Training & Evaluation</a> •
  <a href="#benchmarks">Benchmarks</a> •
  <a href="#license">License</a> • 
  <a href="#citation">Citation</a>
</p>

</div>

## :mega: Notice related to a dataset bug (:bug:) fix :point_left:

There was a major bug in the AVATAR dataset as raised in this [issue](https://github.com/wasiahmad/AVATAR/issues/5). We observed that while crawling data from different sources, in many examples, new lines were missing. In Python data, we also observed missing indentation. As a result, programs were not parse-able. We re-crawled data and ensured every program we store is parse-able. The :bug: has been fixed, so you can continue using the dataset seamlessly. 


## What is AVATAR?

- AVATAR stands for *j**AVA**-py**T**hon progr**A**m t**R**anslation*.
- AVATAR is a corpus of **9,515** programming problems and their solutions written in Java and Python.
- AVATAR offers a collection of **3,391** parallel standalone functions, see details [here](https://github.com/wasiahmad/AVATAR/tree/main/data).
- AVATAR presents evaluation results of finetuned pre-trained LMs.
- AVATAR performs execution based evaluation of program translation, see details [here](https://github.com/wasiahmad/AVATAR/tree/main/test_cases).

## Setup

```
conda create --name avatar_env python==3.8
conda activate avatar_env
pip install -r requirements.txt

mkdir -p third_party
cd third_party
git clone https://github.com/tree-sitter/tree-sitter-java.git
git clone https://github.com/tree-sitter/tree-sitter-python.git

# optional (for fp16 training)
git clone https://github.com/NVIDIA/apex
cd apex
pip install -v --disable-pip-version-check --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" .
cd ..

# building tree-sitter library
python build.py
```

## Dataset

The dataset details is provided [here](https://github.com/wasiahmad/AVATAR/blob/main/data/README.md#dataset). You can download the data by following:

```
cd data
bash download.sh
``` 

To prepare the data, we perform the following steps.

- Removing docstrings, comments, etc.
- Use baseline models' tokenizer to perform tokenization.
- Filter data based on length threshold (~512).
- Perform de-duplication. (remove examples that are duplicates)

If you want to perform the preparation of your own, run:

```
cd data
bash prepare.sh
```

## Models

We studied 11 models for program translation.

**[Models trained from scratch]** 
- Seq2Seq+Attn. [1Lx512H], [Transformer](https://papers.nips.cc/paper/2017/file/3f5ee243547dee91fbd053c1c4a845aa-Paper.pdf) [6Lx512H]

**[Pre-trained models]** 
- [CodeGPT](https://arxiv.org/abs/2102.04664), [CodeGPT-adapted](https://arxiv.org/abs/2102.04664), [CodeBERT](https://www.aclweb.org/anthology/2020.findings-emnlp.139/), [GraphCoderBERT](https://openreview.net/pdf?id=jLoC4ez43PZ), [PLBART](https://arxiv.org/abs/2103.06333), [CodeT5](https://arxiv.org/abs/2109.00859), [TransCoder](https://papers.nips.cc/paper/2020/hash/ed23fbf18c2cd35f8c7f8de44f85c08d-Abstract.html), [TransCoder-DOBF](https://arxiv.org/abs/2102.07492), [TransCoder-ST](https://arxiv.org/pdf/2110.06773.pdf)

## Training & Evaluation

To train and evaluate a model, go to the corresponding model directory and execute the **run.sh** script.

```
# Seq2Seq+Attn, Transformer
cd seq2seq
bash rnn.sh GPU_ID SOURCE_LANG TARGET_LANG
bash transformer.sh GPU_ID SOURCE_LANG TARGET_LANG

# CodeBERT, GraphCoderBERT, CodeT5, PLBART
cd [codebert|graphcodebert|codet5|plbart]
bash run.sh GPU_ID SOURCE_LANG TARGET_LANG

# CodeGPT, CodeGPT-adapted
cd codegpt
bash run.sh GPU_ID SOURCE_LANG TARGET_LANG [CodeGPT|adaptedCodeGPT]

# Transcoder, Transcoder-DOBF, Transcoder-ST 
cd transcoder
bash zero_shot.sh GPU_ID SOURCE_LANG TARGET_LANG [transcoder|transcoder-dobf|transcoder-st]
```

- Here, `SOURCE_LANG=[java|python]` or `TARGET_LANG=[java|python]`.
- Download pre-trained PLBART and Transcoder model checkpoints by running
  [download.sh](https://github.com/wasiahmad/AVATAR/blob/main/download.sh) script.

## Benchmarks

- We perform n-gram and execution based evaluation of program and function translation.
- We report the model performances in this [spreadsheet](https://docs.google.com/spreadsheets/d/12aFLXDrR3nTXCI_GmG8qqoMKmdSsWkxECKTleQkq5ZU/edit#gid=0).
- For function translation error analysis, we categorize the errors, see details 
[here](https://github.com/wasiahmad/AVATAR/blob/main/evaluation/classify_errors.py).

## License

This dataset is licensed under
a [Creative Commons Attribution-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-sa/4.0/) license,
see the LICENSE file for details.

## Citation

```
@article{ahmad-etal-2021-avatar,
  title={AVATAR: A Parallel Corpus for Java-Python Program Translation},
  author={Ahmad, Wasi Uddin and Tushar, Md Golam Rahman and Chakraborty, Saikat and Chang, Kai-Wei},
  journal={arXiv preprint arXiv:2108.11590},
  year={2021}
}
```
