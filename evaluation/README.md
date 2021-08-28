# Computational Accuracy

Computational Accuracy (CA) refers to the fraction of translated functions that successfully pass a suit of test cases.

In order to evaluate computation accuracies of CodeBERT, GraphCodeBERT, and PLBART, we fine-tune them on 
**AVATAR-g4g-functions** dataset and perform the evaluation on the `GeeksforGeeks` dataset proposed in 
[Lachaux et al., 2020](https://arxiv.org/pdf/2006.03511.pdf). Note that, all the evaluation results reported here are 
based on the test split of the `GeeksforGeeks` dataset proposed in [Lachaux et al., 2020] which is included in this 
repository (at `./TransCoder/[test|valid].java-python.[id|java|python]`).

**What is AVATAR-g4g-functions?** AVATAR is a parallel corpus of programs. We use the programs collected from 
GeeksforGeeks and extract the standalone functions from them and create a parallel corpus of Java-Python functions.
 

### Example

```
cd  TransCoder;

# codebert
bash run.sh java python codebert;
bash run.sh python java codebert;

# plbart-multilingual
bash run.sh java python plbart-multilingual;
bash run.sh python java plbart-multilingual;
```


### Evaluation Results

<table>
    <thead>
        <tr>
            <th rowspan=2 align ="left">Model</th>
            <th colspan=6 align ="center">Java to Python</th>
            <th colspan=6 align ="center">Python to Java</th>
        </tr>
        <tr>
            <th align ="center">#tests</th>
            <th align ="center">Error</th>
            <th align ="center">Failure</th>
            <th align ="center">Success</th>
            <th align ="center">EM</th>
            <th align ="center">Timeout</th>
            <th align ="center">#tests</th>
            <th align ="center">Error</th>
            <th align ="center">Failure</th>
            <th align ="center">Success</th>
            <th align ="center">EM</th>
            <th align ="center">Timeout</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><a href="https://arxiv.org/pdf/2006.03511.pdf" target="_blank">TransCoder</a></td>
            <td align ="center">464</td>
            <td align ="center">142</td>
            <td align ="center">88</td>
            <td align ="center">230</td>
            <td align ="center">18</td>
            <td align ="center">4</td>
            <td align ="center">482</td>
            <td align ="center">198</td>
            <td align ="center">107</td>
            <td align ="center">169</td>
            <td align ="center">4</td>
            <td align ="center">8</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2002.08155.pdf" target="_blank">CodeBERT</a></td>
            <td align ="center">464</td>
            <td align ="center">284</td>
            <td align ="center">121</td>
            <td align ="center">46</td>
            <td align ="center">21</td>
            <td align ="center">13</td>
            <td align ="center">482</td>
            <td align ="center">390</td>
            <td align ="center">54</td>
            <td align ="center">36</td>
            <td align ="center">10</td>
            <td align ="center">2</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2009.08366.pdf" target="_blank">GraphCodeBERT</a></td>
            <td align ="center">464</td>
            <td align ="center">276</td>
            <td align ="center">120</td>
            <td align ="center">59</td>
            <td align ="center">18</td>
            <td align ="center">9</td>
            <td align ="center">482</td>
            <td align ="center">382</td>
            <td align ="center">63</td>
            <td align ="center">32</td>
            <td align ="center">9</td>
            <td align ="center">5</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2103.06333.pdf" target="_blank">PLBART<sub>mono</sub></a></td>
            <td align ="center">464</td>
            <td align ="center">47</td>
            <td align ="center">61</td>
            <td align ="center">354</td>
            <td align ="center">103</td>
            <td align ="center">2</td>
            <td align ="center">482</td>
            <td align ="center">102</td>
            <td align ="center">60</td>
            <td align ="center">317</td>
            <td align ="center">103</td>
            <td align ="center">3</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2103.06333.pdf" target="_blank">PLBART<sub>multi</sub></a></td>
            <td align ="center">464</td>
            <td align ="center">229</td>
            <td align ="center">143</td>
            <td align ="center">82</td>
            <td align ="center">44</td>
            <td align ="center">10</td>
            <td align ="center">482</td>
            <td align ="center">321</td>
            <td align ="center">93</td>
            <td align ="center">66</td>
            <td align ="center">36</td>
            <td align ="center">2</td>
        </tr>
    </tbody>
</table>  

- Computational Accuracy (CA) is defined as `Success / #tests`.
- PLBART<sub>mono</sub> outperforms all the baselines in terms of all the evaluation metrics.

<table>
    <thead>
        <tr>
            <th rowspan=2 align ="left">Model</th>
            <th colspan=6 align ="center">Java to Python</th>
            <th colspan=6 align ="center">Python to Java</th>
        </tr>
        <tr>
            <th align ="center">CA</th>
            <th align ="center">BLEU</th>
            <th align ="center">EM</th>
            <th align ="center">SM</th>
            <th align ="center">DM</th>
            <th align ="center">CB</th>
            <th align ="center">CA</th>
            <th align ="center">BLEU</th>
            <th align ="center">EM</th>
            <th align ="center">SM</th>
            <th align ="center">DM</th>
            <th align ="center">CB</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><a href="https://arxiv.org/pdf/2006.03511.pdf" target="_blank">TransCoder</a></td>
            <td align ="center">49.6%</td>
            <td align ="center">72.4</td>
            <td align ="center">2.0</td>
            <td align ="center">58.6</td>
            <td align ="center">66.1</td>
            <td align ="center">68.7</td>
            <td align ="center">35.1%</td>
            <td align ="center">65.3</td>
            <td align ="center">0.4</td>
            <td align ="center">72.7</td>
            <td align ="center">70.1</td>
            <td align ="center">70.7</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2002.08155.pdf" target="_blank">CodeBERT</a></td>
            <td align ="center">9.9%</td>
            <td align ="center">60.5</td>
            <td align ="center">2.7</td>
            <td align ="center">48.3</td>
            <td align ="center">52.3</td>
            <td align ="center">57.1</td>
            <td align ="center">7.5%</td>
            <td align ="center">57.0</td>
            <td align ="center">1.3</td>
            <td align ="center">59.3</td>
            <td align ="center">30.2</td>
            <td align ="center">51.0</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2009.08366.pdf" target="_blank">GraphCodeBERT</a></td>
            <td align ="center">12.7%</td>
            <td align ="center">61.2</td>
            <td align ="center">2.3</td>
            <td align ="center">50.5</td>
            <td align ="center">52.8</td>
            <td align ="center">57.8</td>
            <td align ="center">6.6%</td>
            <td align ="center">55.3</td>
            <td align ="center">1.2</td>
            <td align ="center">58.6</td>
            <td align ="center">31.7</td>
            <td align ="center">50.5</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2103.06333.pdf" target="_blank">PLBART<sub>mono</sub></a></td>
            <td align ="center"><b>76.3%</b></td>
            <td align ="center"><b>84.1</b></td>
            <td align ="center"><b>16.5</b></td>
            <td align ="center"><b>72.1</b></td>
            <td align ="center"><b>72.4</b></td>
            <td align ="center"><b>78.9</b></td>
            <td align ="center"><b>65.8%</b></td>
            <td align ="center"><b>82.9</b></td>
            <td align ="center"><b>14.5</b></td>
            <td align ="center"><b>81.2</b></td>
            <td align ="center"><b>73.2</b></td>
            <td align ="center"><b>80.1</b></td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2103.06333.pdf" target="_blank">PLBART<sub>multi</sub></a></td>
            <td align ="center">17.7%</td>
            <td align ="center">60.5</td>
            <td align ="center">6.1</td>
            <td align ="center">51.2</td>
            <td align ="center">53.8</td>
            <td align ="center">58.0</td>
            <td align ="center">13.7%</td>
            <td align ="center">59.4</td>
            <td align ="center">4.8</td>
            <td align ="center">63.1</td>
            <td align ="center">41.3</td>
            <td align ="center">55.9</td>
        </tr>
    </tbody>
</table> 
