# Dataset

### Data Sources

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

### Data Preparation

The following steps are executed.

- Removing docstrings, comments, etc.
- Use baseline models' tokenizer to perform tokenization.
- Filter data based on length threshold (~512).
- Perform de-duplication. (remove examples that are duplicates)

To perform the above steps, run:

```
cd data
bash prepare.sh
```
