#!/usr/bin/python3
"""
Generates a manifest for FASTQ files based on file presence.
"""

from pathlib import Path
import argparse
import glob
import pandas as pd


HEADER_DICT = {"single": "sample-id\tabsolute-filepath",
               "paired": "sample-id\tforward-absolute-filepath\treverse"
                         "-absolute-filepath"}


def split_manifest(inp_manifest: pd.DataFrame,
                   out_dir: str,
                   suffix_str: str,
                   split_method: str) -> None:
    pass


def arg_parse():
    parser = argparse.ArgumentParser()

    # Required user-input arguments
    parser.add_argument(
        "-i", "--input_dir",
        help="Path to directory containing FASTQ files.",
        type=str,
        required=True,
    )
    parser.add_argument(
        "--read_type",
        help="Read type of FASTQ files, 'single' or 'paired'.",
        type=str,
        choices={"single", "paired"},
        required=True,
    )

    # Optional user-input arguments
    parser.add_argument(
        "-o", "--output_fname",
        help="File name of output manifest.",
        type=str,
        default="output_manifest.tsv"
    )
    parser.add_argument(
        "--suffix",
        help="Suffix for FASTQ files.",
        type=str,
        default="_R[1-2].fastq.gz"
    )
    parser.add_argument(
        "--r1_suffix",
        help="For paired-end samples, suffix for forward reads.",
        type=str,
        default="_R1.fastq.gz"
    )
    parser.add_argument(
        "--r2_suffix",
        help="For paired-end samples, suffix for reverse reads.",
        type=str,
        default="_R2.fastq.gz"
    )

    args = parser.parse_args()
    return args


def main(args):
    assert Path(args.input_dir).is_dir()
    assert Path(args.output_fname).parent.is_dir()


if __name__ == "__main__":
    args = arg_parse()
    main(args)
