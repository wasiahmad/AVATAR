##### Fine-tuning in one direction

For, java to python translation:

```
bash run.sh GPU_IDS java python
```

For, python to java translation:

```
bash run.sh GPU_IDS python java
```

##### Multilingual fine-tuning

For, multilingual translation fine-tuning on "java->python" and "python->java":

```
bash multilingual.sh GPU_IDS
```

#### Note

- We trained PLBART model on 2 GeForce RTX 2080 GPUs (11019MiB).
- For evaluation, 1 GPU is okay.
