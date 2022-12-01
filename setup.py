#!/usr/bin/env python3
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

from setuptools import setup, find_packages

with open('README.md') as f:
    readme = f.read()

with open('LICENSE') as f:
    license = f.read()

with open('requirements.txt') as f:
    reqs = f.read()

setup(
    name='program-translator',
    version='0.1.0',
    description='Java-Python Program Translator',
    long_description=readme,
    license=license,
    python_requires='>=3.6',
    packages=find_packages(exclude=('data')),
    install_requires=reqs.strip().split('\n'),
)

{"id": "codeforces_981_A", "java": [{"id": "2",
                                     "code": "import java . util . * ; import java . util . jar . JarOutputStream ; \u00a0 public class Practise { \u00a0 public static int [ ] [ ] dp ; \u00a0 public static void main ( String [ ] args ) {",
                                     "functions_standalone": [], "functions_class": []}, {"id": "3",
                                                                                          "code": "import java . util . * ; import java . util . jar . JarOutputStream ; \u00a0 public class Practise { \u00a0 public static int [ ] [ ] dp ; \u00a0 public static void main ( String [ ] args ) {",
                                                                                          "functions_standalone": [],
                                                                                          "functions_class": []},
                                    {"id": "4",
                                     "code": "import java . util . * ; public class Check2 { public static void main ( String [ ] args ) { Scanner sc = new Scanner ( System . in ) ;",
                                     "functions_standalone": [["main",
                                                               "public static void main ( String [ ] args ) { Scanner sc = new Scanner ( System . in ) ;"]],
                                     "functions_class": []}, {"id": "1",
                                                              "code": "import java . util . * ; public class Check2 { public static void main ( String [ ] args ) { Scanner sc = new Scanner ( System . in ) ;",
                                                              "functions_standalone": [["main",
                                                                                        "public static void main ( String [ ] args ) { Scanner sc = new Scanner ( System . in ) ;"]],
                                                              "functions_class": []}],
 "python": [{"id": "1",
             "code": "s = input ( ) c = len ( s ) for i in range ( len ( s ) - 1 , 0 , - 1 ) : k = s [ 0 : i + 1 ] if ( k != k [ : : - 1 ] ) : print ( c ) exit ( ) c -= 1 if ( c == 1 ) : print ( \"0\" ) NEW_LINE",
             "functions_standalone": [],
             "functions_class": []},
            {"id": "5",
             "code": "pal = lambda s : s != s [ : : - 1 ] s = input ( ) a = [ ] for i in range ( len ( s ) ) : for j in range ( i + 1 ) : if pal ( s [ j : i + 1 ] ) : a . append ( len ( s [ j : i + 1 ] ) ) if len ( a ) > 0 : print ( max ( a ) ) else : print ( 0 ) NEW_LINE",
             "functions_standalone": [],
             "functions_class": []},
            {"id": "4",
             "code": "s = input ( ) if ( s != s [ : : - 1 ] ) : print ( len ( s ) ) exit ( 0 ) p = s [ 0 ] * len ( s ) if p == s : print ( 0 ) ; exit ( 0 ) print ( len ( s ) - 1 ) NEW_LINE",
             "functions_standalone": [],
             "functions_class": []},
            {"id": "3",
             "code": "s = list ( input ( ) ) \u00a0 \u00a0 if s == s [ : : - 1 ] : if len ( set ( s ) ) == 1 : print ( 0 ) else : print ( len ( s ) - 1 ) \u00a0 else : print ( len ( s ) )   \u00a0 NEW_LINE",
             "functions_standalone": [],
             "functions_class": []},
            {"id": "2",
             "code": "def isPal ( string ) : if string [ : : - 1 ] == string : return True else : return False string = input ( ) length = len ( string ) max_len = len ( string ) found = False \u00a0 while ( max_len != 0 ) : for i in range ( length - max_len + 1 ) : temp = string [ i : i + max_len ] if not isPal ( temp ) : found = True break if found : break else : max_len -= 1 \u00a0 print ( max_len ) NEW_LINE",
             "functions_standalone": [],
             "functions_class": []}]}
