#!/usr/bin/python3
"""
Generates a manifest for FASTQ files based on file presence.
"""

from pathlib import Path
import argparse
import logging
import numpy as np
import pandas as pd
import re


HEADER_DICT = {
    "single": ["sample-id", "absolute-filepath"],
    "paired": ["sample-id", "forward-absolute-filepath",
               "reverse-absolute-filepath"],
}

NUM_DICT = {"single": 1, "paired": 2}


def match_fastq_suffix(file_path: str, suffix: str) -> str:
    """

    :param file_path:
    :param suffix:
    :return:
    """
    suffix_search = re.search(f"(\w+)({suffix})", str(file_path))
    if suffix_search:
        return suffix_search.group(1)

    # Try relaxing query to allow non-alphanumerics
    if re.search(f"(\S+)({suffix})", str(file_path.name)):
        logging.warning(f"There are non-alphanumeric characters in your file "
                        f"name {file_path}! These will be excluded from "
                        f"further analysis.")
        return np.NaN

    # Too late, there is no hope
    return np.NaN


def get_sample_ids(inp_dir: str, read_type: str, suffix: str) -> pd.DataFrame:
    """
    Retrieves FASTQ file paths per sample ID.

    :param inp_dir:
    :param read_type:
    :param suffix:
    :return:
    """
    fastq_path_list = sorted(Path(inp_dir).resolve().glob(f"*{suffix}"))

    assert (
        len(list(fastq_path_list)) > 0
    ), f"No files were found in {inp_dir} matching the suffix {suffix}! " \
       f"Exiting..."

    # Get all FASTQs
    fname_df = pd.DataFrame(fastq_path_list, index=None, columns=["file_path"])

    fname_df["sample_id"] = fname_df["file_path"].apply(match_fastq_suffix, suffix=suffix)
    nonmatch_fq = fname_df[fname_df["sample_id"].isnull()]["sample_id"].tolist()

    logging.warning(f"The following FASTQ files were removed from further "
                    f"analysis due to non-alphanumerics in the file names:"
                    f"{nonmatch_fq}")

    fname_df = fname_df[~fname_df["sample_id"].isnull()]

    # Group by sample ID
    group = fname_df.groupby("sample_id")
    sample_df = group.aggregate(list)

    # Filter out samples with incorrect number of FASTQs
    sample_df["num_fastq"] = sample_df.iloc[:, 0].apply(len)
    num_mismatch_fq = sum(sample_df["num_fastq"] != NUM_DICT[read_type])
    num_mismatch_names = sample_df[sample_df["num_fastq"] != NUM_DICT[
        read_type]]["sample_id"]
    if num_mismatch_fq > 0:
        logging.warning(
            f"There is/are {num_mismatch_fq} sample(s) with the "
            f"incorrect number of FASTQs!"
        )
        logging.warning(f"The following FASTQs had the incorrect number of "
                        f"FASTQs: {num_mismatch_names}")
    assert (
        num_mismatch_fq != sample_df.shape[0]
    ), f"There are no FASTQs matching read type {read_type}! Exiting..."

    sample_df = sample_df[sample_df["num_fastq"] == NUM_DICT[read_type]]
    sample_df.sort_values(by="file_path", inplace=True)

    return sample_df.drop("num_fastq", axis=1)


def assign_fastqs_per_sample(
    sample_fastq_df: pd.DataFrame, read_type: str, suffix_dict: dict
) -> pd.DataFrame:
    """
    Convert sample ID-list association to

    :param sample_fastq_df:
    :param read_type:
    :param suffix_dict:
    :return:
    """
    if read_type == "single":
        fastq_df = sample_fastq_df["file_path"].apply(lambda x: x[0])
        fastq_df.reset_index(inplace=True)
        fastq_df.columns = HEADER_DICT[read_type]

    elif read_type == "paired":
        head_sam, head_fwd, head_rev = HEADER_DICT[read_type]
        fwd_suffix, rev_suffix = suffix_dict[read_type]

        fastq_df = pd.DataFrame(None, columns=HEADER_DICT[read_type])
        fastq_df[head_sam] = sample_fastq_df.index

        dir_path = Path(sample_fastq_df["file_path"][0][0]).resolve().parent
        fastq_df[head_fwd] = sample_fastq_df.index.map(
            lambda x: dir_path / (x + fwd_suffix)
        )
        fastq_df[head_rev] = sample_fastq_df.index.map(
            lambda x: dir_path / (x + rev_suffix)
        )
    else:
        raise ValueError

    return fastq_df


def arg_parse():
    parser = argparse.ArgumentParser()

    # Required user-input arguments
    parser.add_argument(
        "-i",
        "--input_dir",
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
        "-o",
        "--output_fname",
        help="File name of output manifest.",
        type=str,
        default="fastq_manifest.tsv",
    )
    parser.add_argument(
        "--suffix", help="Suffix for FASTQ files.", type=str, default="_R[1-2].fastq.gz"
    )
    parser.add_argument(
        "--r1_suffix",
        help="For paired-end samples, suffix for forward reads.",
        type=str,
        default="_R1.fastq.gz",
    )
    parser.add_argument(
        "--r2_suffix",
        help="For paired-end samples, suffix for reverse reads.",
        type=str,
        default="_R2.fastq.gz",
    )

    args = parser.parse_args()
    return args


def main(args):
    assert Path(args.input_dir).is_dir()
    assert Path(args.output_fname).parent.is_dir()

    logging.basicConfig(filename=Path(args.output_fname).parent / "manifest.log")

    suffix_dict = {"single": [args.suffix], "paired": [args.r1_suffix, args.r2_suffix]}

    sample_df = get_sample_ids(args.input_dir, args.read_type, args.suffix)
    sample_fastq_df = assign_fastqs_per_sample(sample_df, args.read_type, suffix_dict)
    sample_fastq_df.to_csv(args.output_fname, sep="\t", index=False)


if __name__ == "__main__":
    args = arg_parse()
    main(args)
