#!/usr/bin/python3
"""
Parses Cutadapt file to determine optimal sample use.
"""

from collections import Counter
from pathlib import Path
import argparse
import re

import numpy as np
import pandas as pd


def read_log(log_file: str):
    # Note: Each log represents a single primer (pair)
    # Split log by sample
    # Extract summary

    count_samples = 0
    with open(log_file) as f:
        # Find start log sample split based on header text:
        # "This is cutadapt 4.2 with Python 3.8.15"
        while True:  # needs to be modified
            line = f.readline()
            if not line:
                break

            # Start of new sample
            if re.match(r"This is cutadapt [0-9\.]+ with Python [0-9\.]+",
                        line):
                count_samples += 1
                in_sample = True
            while in_sample:

                pass
        pass


def arg_parse():
    parser = argparse.ArgumentParser()

    # Required user-input arguments
    parser.add_argument(
        "-i",
        "--input_log",
        help="Path to input Cutadapt log.",
        type=str,
        required=True,
    )

    # Optional user-input arguments
    parser.add_argument(
        "-o",
        "--output_dir",
        help="Location to print output files.",
        type=str,
        default=Path.cwd(),
    )

    args = parser.parse_args()
    return args


def main(args):
    assert Path(args.input_log).is_file()
    assert Path(args.output_dir).is_dir()

    read_log(args.input_log)
    pass


if __name__ == "__main__":
    args = arg_parse()
    main(args)
