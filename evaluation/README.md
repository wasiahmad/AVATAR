# Computational Accuracy

Computational Accuracy (CA) refers to the fraction of translated functions that successfully pass a suit of test cases.

In order to evaluate computation accuracies of CodeBERT, GraphCodeBERT, and PLBART, we fine-tune them on 
**AVATAR-g4g-functions** dataset and perform the evaluation on the `GeeksforGeeks` dataset proposed in 
[Lachaux et al., 2020](https://arxiv.org/pdf/2006.03511.pdf). Note that, all the evaluation results reported here are 
based on the test split of the `GeeksforGeeks` dataset proposed in Lachaux et al., 2020 which is included in this 
[folder](https://github.com/wasiahmad/AVATAR/tree/main/data/transcoder_test_gfg).

**What is AVATAR-g4g-functions?** AVATAR is a parallel corpus of programs. We use the programs collected from 
GeeksforGeeks and extract the standalone functions from them and create a parallel corpus of Java-Python functions.
 

### Example

```
# codebert
bash run.sh java python codebert;
bash run.sh python java codebert;

# plbart-multilingual
bash run.sh java python plbart-multilingual;
bash run.sh python java plbart-multilingual;
```

#### Sample output

```
# bash run.sh java python codebert
08/28/2021 13:50:22 - INFO - __main__ -   Computation res test_java-python : {"error": 284, "failure": 121, "identical_gold": 21, "script_not_found": 484, "success": 46, "timeout": 13, "total": 948, "total_evaluated": 464}
08/28/2021 13:50:22 - INFO - __main__ -   test_java-python_mt_comp_acc = 0.099138
{
    "AttributeError": 2,
    "IndexError": 8,
    "KeyError": 2,
    "NameError": 59,
    "RecursionError": 2,
    "SyntaxError": 144,
    "TypeError": 34,
    "UnboundLocalError": 29,
    "ZeroDivisionError": 2,
    "other": 2,
    "total": 284
}

# bash run.sh python java codebert
08/28/2021 14:40:31 - INFO - __main__ -   Computation res test_python-java : {"error": 390, "failure": 54, "identical_gold": 10, "script_not_found": 466, "success": 36, "timeout": 2, "total": 948, "total_evaluated": 482}
08/28/2021 14:40:31 - INFO - __main__ -   test_python-java_mt_comp_acc = 0.074689
{
    "ArrayIndexOutOfBoundsException": 3,
    "BadOperand": 4,
    "CantFindSymbol": 27,
    "ElseWithoutIf": 0,
    "IllegalStartOfExpression": 3,
    "InvalidMethod": 2,
    "NoReturnStatement": 5,
    "NoSuitableMethodFound": 0,
    "NotAStatement": 4,
    "StackOverflowError": 1,
    "SyntaxError": 228,
    "TypeError": 60,
    "UnclosedStringLiteral": 1,
    "VariableAlreadyDefined": 52,
    "other": 0,
    "total": 390
}
{
    "Compilation Errors": 386,
    "Runtime Errors": 4
}
```


### Evaluation Results

- We set the `beam_size` to 5 while decoding with all the models.

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
            <td><a href="https://arxiv.org/pdf/2102.07492.pdf" target="_blank">TC-DOBF</a></td>
            <td align ="center">464</td>
            <td align ="center">127</td>
            <td align ="center">86</td>
            <td align ="center">242</td>
            <td align ="center">30</td>
            <td align ="center">9</td>
            <td align ="center">482</td>
            <td align ="center">177</td>
            <td align ="center">88</td>
            <td align ="center">212</td>
            <td align ="center">14</td>
            <td align ="center">5</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2102.07492.pdf" target="_blank">TC-DOBF-ft</a></td>
            <td align ="center">464</td>
            <td align ="center">44</td>
            <td align ="center">62</td>
            <td align ="center">353</td>
            <td align ="center">159</td>
            <td align ="center">5</td>
            <td align ="center">482</td>
            <td align ="center">79</td>
            <td align ="center">34</td>
            <td align ="center">364</td>
            <td align ="center">197</td>
            <td align ="center">5</td>
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
        <tr>
            <td><a href="https://arxiv.org/pdf/2109.00859.pdf" target="_blank">CodeT5</a></td>
            <td align ="center">464</td>
            <td align ="center">68</td>
            <td align ="center">101</td>
            <td align ="center">287</td>
            <td align ="center">68</td>
            <td align ="center">8</td>
            <td align ="center">482</td>
            <td align ="center">143</td>
            <td align ="center">53</td>
            <td align ="center">283</td>
            <td align ="center">77</td>
            <td align ="center">3</td>
        </tr>
    </tbody>
</table>  

- We categorize the errors into Compilation and Runtime errors. Check details 
[here](https://github.com/wasiahmad/AVATAR/blob/main/evaluation/TransCoder/classify_errors.py).
- Compilation and Runtime errors (in %) made by the models are reported below.

<table>
    <thead>
        <tr>
            <th rowspan=2 align ="left">Model</th>
            <th colspan=2 align ="center">Java to Python</th>
            <th colspan=2 align ="center">Python to Java</th>
        </tr>
        <tr>
            <th align ="center">Compilation</th>
            <th align ="center">Runtime</th>
            <th align ="center">Compilation</th>
            <th align ="center">Runtime</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><a href="https://arxiv.org/pdf/2006.03511.pdf" target="_blank">TransCoder</a></td>
            <td align ="center">0.0%</td>
            <td align ="center">30.6%</td>
            <td align ="center">31.5%</td>
            <td align ="center">9.5%</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2102.07492.pdf" target="_blank">TC-DOBF</a></td>
            <td align ="center">0.0%</td>
            <td align ="center">27.4%</td>
            <td align ="center">27.0%</td>
            <td align ="center">9.8%</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2102.07492.pdf" target="_blank">TC-DOBF-ft</a></td>
            <td align ="center">0.0%</td>
            <td align ="center">9.5%</td>
            <td align ="center">13.9%</td>
            <td align ="center">2.5%</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2002.08155.pdf" target="_blank">CodeBERT</a></td>
            <td align ="center">0.0%</td>
            <td align ="center">61.2%</td>
            <td align ="center">80.1%</td>
            <td align ="center">0.8%</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2009.08366.pdf" target="_blank">GraphCodeBERT</a></td>
            <td align ="center">0.0%</td>
            <td align ="center">59.5%</td>
            <td align ="center">78.6%</td>
            <td align ="center">0.6%</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2103.06333.pdf" target="_blank">PLBART<sub>mono</sub></a></td>
            <td align ="center">0.0%</td>
            <td align ="center">10.1%</td>
            <td align ="center">18.3%</td>
            <td align ="center">2.9%</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2103.06333.pdf" target="_blank">PLBART<sub>multi</sub></a></td>
            <td align ="center">0.0%</td>
            <td align ="center">49.4%</td>
            <td align ="center">63.7%</td>
            <td align ="center">2.9%</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2109.00859.pdf" target="_blank">CodeT5</a></td>
            <td align ="center">0.0%</td>
            <td align ="center">14.7%</td>
            <td align ="center">26.6%</td>
            <td align ="center">2.9%</td>
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
            <td align ="center">49.6</td>
            <td align ="center">72.4</td>
            <td align ="center">2.0</td>
            <td align ="center">58.6</td>
            <td align ="center">66.1</td>
            <td align ="center">68.7</td>
            <td align ="center">35.1</td>
            <td align ="center">65.3</td>
            <td align ="center">0.4</td>
            <td align ="center">72.7</td>
            <td align ="center">70.1</td>
            <td align ="center">70.7</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2102.07492.pdf" target="_blank">TC-DOBF</a></td>
            <td align ="center">52.2</td>
            <td align ="center">72.2</td>
            <td align ="center">3.9</td>
            <td align ="center">59.0</td>
            <td align ="center">64.4</td>
            <td align ="center">68.3</td>
            <td align ="center">44.0</td>
            <td align ="center">67.6</td>
            <td align ="center">1.8</td>
            <td align ="center">72.8</td>
            <td align ="center">68.4</td>
            <td align ="center">70.9</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2102.07492.pdf" target="_blank">TC-DOBF-ft</a></td>
            <td align ="center">76.1</td>
            <td align ="center"><b>86.5</b></td>
            <td align ="center"><b>29.9</b></td>
            <td align ="center"><b>75.7</b></td>
            <td align ="center"><b>76.5</b></td>
            <td align ="center"><b>81.9</b></td>
            <td align ="center"><b>75.5</b></td>
            <td align ="center"><b>86.6</b></td>
            <td align ="center"><b>34.5</b></td>
            <td align ="center"><b>85.1</b></td>
            <td align ="center"><b>77.6</b></td>
            <td align ="center"><b>84.0</b></td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2002.08155.pdf" target="_blank">CodeBERT</a></td>
            <td align ="center">9.9</td>
            <td align ="center">60.5</td>
            <td align ="center">2.7</td>
            <td align ="center">48.3</td>
            <td align ="center">52.3</td>
            <td align ="center">57.1</td>
            <td align ="center">7.5</td>
            <td align ="center">57.0</td>
            <td align ="center">1.3</td>
            <td align ="center">59.3</td>
            <td align ="center">30.2</td>
            <td align ="center">51.0</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2009.08366.pdf" target="_blank">GraphCodeBERT</a></td>
            <td align ="center">12.7</td>
            <td align ="center">61.2</td>
            <td align ="center">2.3</td>
            <td align ="center">50.5</td>
            <td align ="center">52.8</td>
            <td align ="center">57.8</td>
            <td align ="center">6.6</td>
            <td align ="center">55.3</td>
            <td align ="center">1.2</td>
            <td align ="center">58.6</td>
            <td align ="center">31.7</td>
            <td align ="center">50.5</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2103.06333.pdf" target="_blank">PLBART<sub>mono</sub></a></td>
            <td align ="center"><b>76.3</b></td>
            <td align ="center">84.1</td>
            <td align ="center">16.5</td>
            <td align ="center">72.1</td>
            <td align ="center">72.4</td>
            <td align ="center">78.9</td>
            <td align ="center">65.8</td>
            <td align ="center">82.9</td>
            <td align ="center">14.5</td>
            <td align ="center">81.2</td>
            <td align ="center">73.2</td>
            <td align ="center">80.1</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2103.06333.pdf" target="_blank">PLBART<sub>multi</sub></a></td>
            <td align ="center">17.7</td>
            <td align ="center">60.5</td>
            <td align ="center">6.1</td>
            <td align ="center">51.2</td>
            <td align ="center">53.8</td>
            <td align ="center">58.0</td>
            <td align ="center">13.7</td>
            <td align ="center">59.4</td>
            <td align ="center">4.8</td>
            <td align ="center">63.1</td>
            <td align ="center">41.3</td>
            <td align ="center">55.9</td>
        </tr>
        <tr>
            <td><a href="https://arxiv.org/pdf/2109.00859.pdf" target="_blank">CodeT5-base</a></td>
            <td align ="center">61.9</td>
            <td align ="center">81.6</td>
            <td align ="center">10.0</td>
            <td align ="center">67.7</td>
            <td align ="center">67.4</td>
            <td align ="center">75.2</td>
            <td align ="center">58.7</td>
            <td align ="center">81.9</td>
            <td align ="center">11.7</td>
            <td align ="center">79.7</td>
            <td align ="center">71.9</td>
            <td align ="center">78.9</td>
        </tr>
    </tbody>
</table> 
