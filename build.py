# Copyright (c) Microsoft Corporation. 
# Licensed under the MIT license.

from tree_sitter import Language

Language.build_library(
    # Store the library in the `build` directory
    'evaluation/CodeBLEU/parser/my-languages.so',

    # Include one or more languages
    [
        "third_party/tree-sitter-java",
        "third_party/tree-sitter-python"
    ]
)
