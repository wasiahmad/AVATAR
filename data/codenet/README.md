## Dataset statistics

The dataset comprises 13,916,868 submissions, divided into 4053 problems (of which 5 are empty). Of the submissions
53.6% (7,460,588) are accepted, 29.5% are marked as wrong answer and the remaining suffer from one of the possible
rejection causes. The data contains submissions in 55 different languages, although 95% of them are coded in the six
most common languages (C++, Python, Java, C, Ruby, C#). C++ is the most common language with 8,008,527 submissions (57%
of the total) of which 4,353,049 are accepted.

## Directory structure

``` 
Project_CodeNet
├── data
├── derived
├── metadata
├── problem_descriptions
└── README.md
```

In the 'Project_CodeNet/data' directory, we have 4053 directories associated with a programming problem (either from
AtCoder or AIZU). Every problem directory has sub-directories for each language associated with a submission. For
example,

``` 
Project_CodeNet/data/p04050
├── Bash
├── C
├── C#
├── C++
├── D
├── Haskell
├── Java
├── Kotlin
├── Nim
├── Python
├── Ruby
└── Rust
```

Problem id=`p04050` has submissions in 12 languages. Note that, problems may not have submissions in a particular
language. Every directory associated with a language contains files with all submissions. For
example, `Project_CodeNet/data/p04050/Python` has 27 python files that represent individual submissions.

``` 
Project_CodeNet/data/p04050/Python
├── s065079131.py
├── s104198375.py
├── s213815438.py
├── s252919422.py
├── s257283179.py
├── s287463219.py
├── s292125822.py
├── s347349727.py
├── s498481701.py
├── s499016448.py
├── s571339864.py
├── s607817470.py
├── s637050993.py
├── s678667268.py
├── s701292968.py
├── s709919279.py
├── s743351234.py
├── s747140087.py
├── s799170240.py
├── s818812976.py
├── s931854329.py
├── s934501506.py
├── s943528127.py
├── s950372139.py
├── s952339729.py
├── s960682356.py
└── s965943795.py
```

Every problem is associated with a meta-data file (csv) file. For example, `Project_CodeNet/data/p04050` problem is
associated with `Project_CodeNet/metadata/p04050.csv` meta-data file. The meta-data includes information
described [here](https://github.com/IBM/Project_CodeNet#metadata-at-the-problem-level).

#### Example of meta-data records

```
s127352617,p04050,u168026006,1600301172,C++,C++ (GCC 9.2.1),cpp,Accepted,5,3644,3394,
s915937048,p04050,u072274941,1600216887,C++,C++ (GCC 9.2.1),cpp,Accepted,10,3624,2292,
s901593433,p04050,u072274941,1600215047,C++,C++ (GCC 9.2.1),cpp,Wrong Answer,8,3640,2127,
s078430203,p04050,u072274941,1600214605,C++,C++ (GCC 9.2.1),cpp,Wrong Answer,8,3568,2127,
s628138022,p04050,u072274941,1600213614,C++,C++ (GCC 9.2.1),cpp,Wrong Answer,8,3616,1103,
s719524303,p04050,u700218970,1600121226,C++,C++ (GCC 9.2.1),cpp,Accepted,7,3624,2703,
```

