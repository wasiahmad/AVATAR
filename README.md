# AVATAR

- Official code of our work, [AVATAR: A Parallel Corpus for Java-Python Program Translation](https://arxiv.org/abs/2108.11590). 
- AVATAR stands for *j**AVA**-py**T**hon progr**A**m t**R**anslation*. 
- AVATAR is a corpus of **8,475** programming problems and their solutions written in Java and Python. 

<!--
<p align='justify'>
Official code of our work, <a href="" target="_blank">AVATAR: A Parallel Corpus for Java-Python Program Translation</a>. AVATAR stands for <q>j<b>AVA</b>-py<b>T</b>hon progr<b>A</b>m t<b>R</b>anslation</q>. In this work, we present a corpus of <b>8,475</b> programming problems and their solutions written in two popular languages, Java and Python. We collect the dataset from competitive programming sites, online platforms, and open source repositories. We present several baselines, including models trained from scratch or pre-trained on large-scale source code collection and fine-tuned on our proposed dataset.
<p align='justify'>
!-->

  
## Table of Contents

- [AVATAR](#AVATAR)
  - [Table of Contents](#table-of-contents)
  - [Dataset](#dataset)
  - [Models](#models)
  - [Training & Evaluation](#training--evaluation)
  - [Benchmarks](#benchmarks)
  - [License](#license)
  - [Citation](#citation)

## Dataset

We have collected the programming problems and their solutions from competitive programming sites, online platforms, and open source repositories. We list the sources below.

- CodeForces
- AtCoder 
- CodeJam 
- GeeksforGeeks
- LeetCode
- ProjectEuler

Data collected can be downloaded by following:

```
cd data
bash download.sh
``` 

To prepare the data, we perform the following steps.

- Removing docstrings, comments, etc.
- Use baseline models' tokenizer to perform tokenization.
- Filter data based on length threshold (~512).
- Perform de-duplication. (remove examples that are duplicates)

To perform the preparation, run:

```
cd data
bash prepare.sh
```


## Models

We studied 8 models for program translation.

#### Models trained from scratch

- [Seq2Seq+Attn.]() [1Lx512H]
- [Transformer](https://papers.nips.cc/paper/2017/file/3f5ee243547dee91fbd053c1c4a845aa-Paper.pdf) [6Lx512H]

#### Pre-trained models

- [CodeGPT](https://arxiv.org/abs/2102.04664)
- [CodeGPT-adapted](https://arxiv.org/abs/2102.04664)
- [CodeBERT](https://www.aclweb.org/anthology/2020.findings-emnlp.139/)
- [GraphCoderBERT](https://openreview.net/pdf?id=jLoC4ez43PZ)
- [PLBART](https://arxiv.org/abs/2103.06333)
- [TransCoder](https://papers.nips.cc/paper/2020/hash/ed23fbf18c2cd35f8c7f8de44f85c08d-Abstract.html) (unsupervised approach)


## Training & Evaluation

To train and evaluate a model, go to the corresponding model directory and execute the **run.sh** script.

```
# Seq2Seq+Attn.
cd seq2seq
bash rnn.sh GPU_ID LANG1 LANG2

# Transformer
cd seq2seq
bash transformer.sh GPU_ID LANG1 LANG2

# CodeGPT
cd codegpt
bash run.sh GPU_ID LANG1 LANG2 CodeGPT

# CodeGPT-adapted
cd codegpt
bash run.sh GPU_ID LANG1 LANG2

# CodeBERT
cd codebert
bash run.sh GPU_ID LANG1 LANG2

# GraphCoderBERT
cd graphcodebert
bash run.sh GPU_ID LANG1 LANG2

# PLBART
cd plbart
# fine-tuning either for Java->Python or Python-Java
bash run.sh GPU_ID LANG1 LANG2
# multilingual fine-tuning
bash multilingual.sh GPU_ID

# Naive Copy
cd naivecopy
bash run.sh
```

- Here, `LANG1 LANG2=Java Python` or `LANG1 LANG2=Python Java`.
- Download pre-trained PLBART, GraphCodeBERT, and Transcoder model files by running 
[download.sh](https://github.com/wasiahmad/AVATAR/blob/main/download.sh) script.
- We trained the models on GeForce RTX 2080 ti GPUs (11019MiB).
 

## Benchmarks
  
We evaluate the models' performances on the test set in terms of Compilation Accuracy (CA), BLEU, Syntax Match (SM), Dataflow Match (DM), CodeBLEU (CB), Exact Match (EM). We report the model performances below.
  
<table>
    <thead>
        <tr>
            <th rowspan=2 align ="left">Training</th>
            <th rowspan=2 align ="left">Models</th>
            <th colspan=6>Java to Python</th>
            <th colspan=6>Python to Java</th>
        </tr>
        <tr>
            <th>CA</th>
            <th>BLEU</th>
            <th>SM</th>
            <th>DM</th>
            <th>CB</th>
            <th>EM</th>
            <th>CA</th>
            <th>BLEU</th>
            <th>SM</th>
            <th>DM</th>
            <th>CB</th>
            <th>EM</th>
        </tr>
    </thead>
    <tbody>
        <tr>
          <td rowspan=2>None</td>
          <td>Naive Copy</td>
          <td>-</td>
          <td>23.4</td>
          <td>-</td>
          <td>-</td>
          <td>-</td>
          <td>0.0</td>
          <td>-</td>
          <td>26.9</td>
          <td>-</td>
          <td>-</td>
          <td>-</td>
          <td>0.0</td>
      </tr>
      <tr>
          <td>TransCoder</td>
          <td><b>76.9</b></td>
          <td>36.8</td>
          <td>31.0</td>
          <td>17.1</td>
          <td>29.1</td>
          <td>0.1</td>
          <td><b>100</b></td>
          <td>49.4</td>
          <td>37.6</td>
          <td>18.5</td>
          <td>31.9</td>
          <td>0.0</td>
      </tr>
      <tr>
          <td rowspan=2>From Scratch</td>
          <td>Seq2Seq+Attn.</td>
          <td>66.5</td>
          <td>56.3</td>
          <td>39.1</td>
          <td>18.4</td>
          <td>37.9</td>
          <td>1.0</td>
          <td>71.8</td>
          <td>62.7</td>
          <td>46.6</td>
          <td>28.5</td>
          <td>43.0</td>
          <td>0.8</td>
      </tr>
      <tr>
          <td>Transformer</td>
          <td>61.5</td>
          <td>38.9</td>
          <td>34.2</td>
          <td>16.5</td>
          <td>29.1</td>
          <td>0.0</td>
          <td>67.4</td>
          <td>45.6</td>
          <td>45.7</td>
          <td>26.4</td>
          <td>37.4</td>
          <td>0.1</td>
      </tr>
      <tr>
          <td rowspan=6>Pre-trained</td>
          <td>CodeGPT</td>
          <td>47.3</td>
          <td>38.2</td>
          <td>32.5</td>
          <td>11.5</td>
          <td>26.1</td>
          <td>1.1</td>
          <td>71.2</td>
          <td>44.0</td>
          <td>38.8</td>
          <td>26.7</td>
          <td>33.8</td>
          <td>0.1</td>
      </tr>
      <tr>
          <td>CodeGPT-adapted</td>
          <td>48.1</td>
          <td>38.2</td>
          <td>32.5</td>
          <td>12.1</td>
          <td>26.2</td>
          <td>1.2</td>
          <td>68.6</td>
          <td>42.4</td>
          <td>37.2</td>
          <td>27.2</td>
          <td>33.1</td>
          <td>0.5</td>
      </tr>
      <tr>
          <td>CodeBERT</td>
          <td>62.3</td>
          <td>59.3</td>
          <td>37.7</td>
          <td>16.2</td>
          <td>36.7</td>
          <td>0.5</td>
          <td>74.7</td>
          <td>55.3</td>
          <td>38.4</td>
          <td>22.5</td>
          <td>36.1</td>
          <td>0.6</td>
      </tr>
      <tr>
          <td>GraphCodeBERT</td>
          <td>65.7</td>
          <td>59.7</td>
          <td>38.9</td>
          <td>16.4</td>
          <td>37.1</td>
          <td>0.7</td>
          <td>57.2</td>
          <td>60.6</td>
          <td>48.4</td>
          <td>20.6</td>
          <td>40.1</td>
          <td>0.4</td>
      </tr>
      <tr>
          <td>PLBART<sub>mono</sub></td>
          <td>76.4</td>
          <td><b>67.1</b></td>
          <td><b>42.6</b></td>
          <td><b>19.3</b></td>
          <td><b>43.3</b></td>
          <td><b>2.4</b></td>
          <td>34.4</td>
          <td>69.1</td>
          <td><b>57.1</b></td>
          <td>34.0</td>
          <td>51.4</td>
          <td><b>1.2</b></td>
      </tr>
      <tr>
          <td>PLBART<sub>multi</sub></td>
          <td>70.4</td>
          <td><b>67.1</b></td>
          <td>42.0</td>
          <td>17.6</td>
          <td>42.4</td>
          <td><b>2.4</b></td>
          <td>30.8</td>
          <td><b>69.4</b></td>
          <td>56.6</td>
          <td><b>34.5</b></td>
          <td><b>51.8</b></td>
          <td>1.0</td>
      </tr>
    </tbody>
</table>  


## License

This dataset is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-sa/4.0/) license, see the LICENSE file for details.


## Citation

```
@article{ahmad-etal-2021-avatar,
  title={AVATAR: A Parallel Corpus for Java-Python Program Translation},
  author={Ahmad, Wasi Uddin and Tushar, Md Golam Rahman and Chakraborty, Saikat and Chang, Kai-Wei},
  journal={arXiv preprint arXiv:2108.11590},
  year={2021}
}
```
