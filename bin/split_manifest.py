#!/usr/bin/python3
"""
Splits FASTQ manifest files into individual samples.
"""

from pathlib import Path
import argparse
import numpy as np
import pandas as pd


def split_manifest(inp_manifest: pd.DataFrame,
                   out_dir: str,
                   suffix_str: str,
                   split_method: str) -> None:
    """
    Splits manifest and saves to multiple output files.

    :param inp_manifest:
    :param out_dir:
    :param suffix_str:
    :param split_method:
    """

    if split_method == "sample":
        num_sections = len(inp_manifest.index)

    split_list = np.array_split(inp_manifest, num_sections)
    split_dict = {df.iloc[0][0]: df for df in split_list}
    for sample_name, df in split_dict.items():
        df.to_csv(Path(out_dir) / f"{sample_name}{suffix_str}",
                  sep="\t",
                  index=False)


def arg_parse():
    parser = argparse.ArgumentParser()

    # Required user-input arguments
    parser.add_argument(
        "-i", "--input_manifest",
        help="Path to input manifest file for splitting.",
        type=str,
        required=True,
    )

    # Optional user-input arguments
    parser.add_argument(
        "-o", "--output_dir",
        help="Location to print output files.",
        type=str,
        default=Path.cwd()
    )
    parser.add_argument(
        "--suffix",
        help="Optional suffix to add to each split manifest.",
        type=str,
        default="_split.tsv"
    )
    parser.add_argument(
        "--split_method",
        help="Method to split input manifest. Options include 'sample'.",
        type=str,
        choices={"sample"},
        default="sample"
    )

    args = parser.parse_args()
    return args


def main(args):
    assert Path(args.output_dir).is_dir()

    try:
        manifest_df = pd.read_csv(args.input_manifest,
                                  sep="\t")
        manifest_df.dropna(inplace=True)
        assert len(manifest_df.columns) == manifest_df.shape[1]
        assert len(manifest_df.index) > 0

    except FileNotFoundError:
        print(f"The input manifest file {args.input_manifest} was not found!")

    split_manifest(manifest_df, args.output_dir, args.suffix, args.split_method)


if __name__ == "__main__":
    args = arg_parse()
    main(args)
