#!/usr/bin/python3
"""
Generates a manifest for FASTQ files based on file presence.
"""

from pathlib import Path
import argparse
import logging
import pandas as pd
import re


HEADER_DICT = {"single": ["sample-id", "absolute-filepath"],
               "paired": ["sample-id, forward-absolute-filepath",
                          "reverse-absolute-filepath"]}

NUM_DICT = {"single": 1,
            "paired": 2}


def get_sample_ids(inp_dir: str,
                   read_type: str,
                   suffix: str) -> pd.DataFrame:
    """
    Retrieves FASTQ file paths per sample ID.

    :param inp_dir:
    :param read_type:
    :param suffix:
    :return:
    """
    fastq_path_list = sorted(Path(inp_dir).resolve().glob(f"*{suffix}"))
    assert len(list(fastq_path_list)) > 0, \
        f"No files were found in {inp_dir} matching the suffix {suffix}! " \
        f"Exiting..."

    # Get all FASTQs
    fname_df = pd.DataFrame(fastq_path_list,
                            index=None,
                            columns=["file_path"])
    fname_df["sample_id"] = fname_df["file_path"].apply(
        lambda x: re.search(f"(\w+)({suffix})", str(x)).group(1)
    )

    # Group by sample ID
    group = fname_df.groupby("sample_id")
    sample_df = group.aggregate(list)

    # Filter out samples with incorrect number of FASTQs
    sample_df["num_fastq"] = sample_df.iloc[:, 0].apply(len)
    num_mismatch_fq = sum(sample_df["num_fastq"] != NUM_DICT[read_type])
    if num_mismatch_fq > 0:
        logging.warning(f"There is/are {num_mismatch_fq} sample(s) with the "
                        f"incorrect number of FASTQs!")
    assert num_mismatch_fq != sample_df.shape[0], \
        f"There are no FASTQs matching read type {read_type}! Exiting..."

    sample_df = sample_df[sample_df["num_fastq"] == NUM_DICT[read_type]]
    sample_df.sort_values(inplace=True)

    return sample_df


def assign_fastqs_per_sample(sample_fastq_df: pd.DataFrame,
                             suffix_dict: dict):

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
        default="fastq_manifest.tsv"
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

    logging.basicConfig(filename=Path(args.output_fname).parent /
                                 "manifest.log")

    suffix_dict = {"single": [args.suffix],
                   "paired": [args.r1_suffix, args.r2_suffix]}

    sample_df = get_sample_ids(args.inp_dir, args.read_type, args.suffix)
    sample_fastq_df = assign_fastqs_per_sample(sample_df, suffix_dict)


if __name__ == "__main__":
    args = arg_parse()
    main(args)
