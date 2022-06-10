#!/usr/bin/python3
"""
Splits FASTQ manifest files into individual samples.
"""
import argparse
import pandas as pd


def split_manifest(inp_manifest: pd.DataFrame,
                   suffix_str: str):

    pass


def arg_parse():
    parser = argparse.ArgumentParser()

    # Required user-input arguments
    parser.add_argument(
        "-i", "--input_manifest",
        help="Path to input manifest file for splitting.",
        type=str,
        required=True,
    )
    parser.add_argument(
        "--suffix",
        help="Optional suffix to add to each split manifest.",
        type=str,
        default="_split.txt"
    )

    args = parser.parse_args()
    return args


def main(args):
    try:
        manifest_df = pd.read_csv(args.input_manifest,
                                  sep="\t")
    except FileNotFoundError:
        print(f"The input manifest file {args.input_manifest} was not found!")

    split_manifest(manifest_df, args.suffix_str)


if __name__ == "__main__":
    args = arg_parse()
    main(args)
