#!/usr/bin/python3
"""
Generates a manifest for FASTQ files based on file presence.
"""

from pathlib import Path
import argparse
import itertools
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
NEWLINE = "\n"


def match_fastq_suffix(file_path: str, 
                       suff_list: list,
                       sam_regex: str = None) -> str:
    """
    Retrieves sample ID from FASTQ file path and suffix.

    :param file_path:
    :param suff_list:
    :return:
    """
    if len(suff_list) == 1:
        suffix = suff_list[0]
    else:
        suffix = "|".join(suff_list)

    if sam_regex:        
        suffix_search = re.search(fr'^({sam_regex})([\w\.-]+)({suffix})', str(file_path.name))
    else:
        suffix_search = re.search(fr'^([\w\.-]+)({suffix})', str(file_path.name))

    if suffix_search:
        return suffix_search.group(1)

    return np.NaN


def get_sample_ids(inp_dir: str,
                   read_type: str,
                   suff_list: list,
                   sam_regex: str = None) -> pd.DataFrame:
    """
    Retrieves FASTQ file paths per sample ID.

    :param inp_dir:
    :param read_type:
    :param suff_list:
    :return:
    """
    fastq_path_chain = [Path(inp_dir).resolve().glob(f"*{suf}")
                        for suf in suff_list]
    fastq_path_list = sorted(itertools.chain.from_iterable(
        fastq_path_chain))

    assert (len(list(fastq_path_list)) > 0), \
        f"No files were found in {inp_dir} matching the suffix(es) " \
        f"{'/'.join(suff_list)}! Exiting..."

    # Get all FASTQs
    fname_df = pd.DataFrame(fastq_path_list, index=None, columns=["file_path"])

    fname_df["sample_id"] = fname_df["file_path"].apply(match_fastq_suffix,
                                                        suff_list=suff_list,
                                                        sam_regex=sam_regex)
    nonmatch_fq = fname_df[fname_df["sample_id"].isnull()]["file_path"].tolist()
    nonmatch_fq = [str(fpath) for fpath in nonmatch_fq]
    if len(nonmatch_fq) > 0:
        logging.info(f"The following FASTQ files were removed from further "
                     f"analysis due to non-permitted characters in the file "
                     f"names:{NEWLINE}{NEWLINE.join(nonmatch_fq)}")

    fname_df = fname_df[~fname_df["sample_id"].isnull()]

    # Group by sample ID
    group = fname_df.groupby("sample_id")
    sample_df = group.aggregate(list)

    # Filter out samples with incorrect number of FASTQs
    sample_df["num_fastq"] = sample_df.iloc[:, 0].apply(len)

    num_mismatch_fq = sum(sample_df["num_fastq"] != NUM_DICT[read_type])
    num_mismatch_names = sample_df[sample_df["num_fastq"] != NUM_DICT[
        read_type]].reset_index()

    if num_mismatch_fq > 0:
        logging.warning(
            f"There is/are {num_mismatch_fq} sample(s) with the "
            f"incorrect number of FASTQs!"
        )
        logging.info(f"The following samples had the incorrect number of "
                     f"associated FASTQs:{NEWLINE}"
                     f"{NEWLINE.join([f'Sample {row.sample_id} has {row.num_fastq} FASTQ file(s): {[str(fpath) for fpath in row.file_path]}' for i, row in num_mismatch_names.iterrows()])}")

    assert (
            num_mismatch_fq != sample_df.shape[0]
    ), f"There are no FASTQs matching read type {read_type}! Exiting..."

    sample_df = sample_df[sample_df["num_fastq"] == NUM_DICT[read_type]]
    sample_df.sort_values(by="file_path", inplace=True)

    return sample_df.drop("num_fastq", axis=1)


def assign_fastqs_per_sample(
        sample_fastq_df: pd.DataFrame, read_type: str, suff_list: list
) -> pd.DataFrame:
    """
    Convert sample ID-list association to

    :param sample_fastq_df:
    :param read_type:
    :param suff_list:
    :return:
    """
    if read_type == "single":
        fastq_df = sample_fastq_df["file_path"].apply(lambda x: x[0])
        fastq_df.reset_index(inplace=True)
        fastq_df.columns = HEADER_DICT[read_type]

    elif read_type == "paired":
        head_sam, head_fwd, head_rev = HEADER_DICT[read_type]
        fwd_suffix, rev_suffix = suff_list

        fastq_df = pd.DataFrame(None, columns=HEADER_DICT[read_type])
        fastq_df[head_sam] = sample_fastq_df.index

        dir_path = Path(sample_fastq_df["file_path"].iloc[0][0]).resolve(

        ).parent


        fastq_df[head_fwd] = sample_fastq_df.index.map(
            lambda x: dir_path.glob(fr'^({x})([\w\.-]+)({fwd_suffix})'
                                    )[0]
        )

        fastq_df[head_rev] = sample_fastq_df.index.map(
            lambda x: dir_path.glob(fr'^({x})([\w\.-]+)({rev_suffix})'
                                    )[0]
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
        required=False
    )
    parser.add_argument(
        "--sample_regex", help="Optional sample regex for FASTQ files; accommodates regex.",
        type=str,
        default=None,
        required=False
    )    
    parser.add_argument(
        "--suffix", help="Optional suffix for FASTQ files; accommodates regex.",
        type=str,
        required=False
    )
    parser.add_argument(
        "--r1_suffix",
        help="For paired-end samples, suffix for forward reads; "
             "accommodates regex.",
        type=str,
        required=False
    )
    parser.add_argument(
        "--r2_suffix",
        help="For paired-end samples, suffix for reverse reads; "
             "accommodates regex.",
        type=str,
        required=False
    )

    args = parser.parse_args()
    return args


def main(args):
    assert Path(args.input_dir).is_dir()
    assert Path(args.output_fname).parent.is_dir()

    logging.basicConfig(filename=Path(args.output_fname).parent /
                                 f"{Path(args.output_fname).stem}.log")
    logger = logging.getLogger()
    logger.setLevel("INFO")

    if args.suffix and args.read_type == "single":
        suffix_list = [args.suffix]
    elif (args.r1_suffix and args.r2_suffix) and args.read_type == "paired":
        suffix_list = [args.r1_suffix, args.r2_suffix]
    elif not args.suffix and not (args.r1_suffix or args.r2_suffix):
        logging.warning("No suffix flags provided! FASTQ suffixes are set to "
                     "defaults based on read type.")
        if args.read_type == "single":
            suffix_list = ["_R[1-2].fastq.gz"]
        else:
            suffix_list = ["_R1.fastq.gz", "_R2.fastq.gz"]
    else:
        logging.warning("The appropriate suffix flag was not included for the "
                     "read type. FASTQ suffixes are set to defaults based on "
                     "read type.")
        if args.read_type == "single":
            suffix_list = ["_R[1-2].fastq.gz"]
        else:
            suffix_list = ["_R1.fastq.gz", "_R2.fastq.gz"]

    sample_df = get_sample_ids(args.input_dir, args.read_type, suffix_list,
                               args.sample_regex)
    sample_fastq_df = assign_fastqs_per_sample(sample_df, args.read_type,
                                               suffix_list)
    sample_fastq_df.to_csv(args.output_fname, sep="\t", index=False)


if __name__ == "__main__":
    args = arg_parse()
    main(args)
