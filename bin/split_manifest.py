#!/usr/bin/python3
"""
Splits FASTQ manifest files into individual samples.
"""

from collections import Counter
from pathlib import Path
import argparse
import numpy as np
import pandas as pd


def split_manifest(
    inp_manifest: pd.DataFrame, out_dir: str, suffix_str: str, split_method: str
) -> None:
    """
    Splits manifest and saves to multiple output files.

    :param inp_manifest:
    :param out_dir:
    :param suffix_str:
    :param split_method:
    """

    if split_method == "sample":
        num_sections = len(inp_manifest.index)
    elif int(split_method) < len(inp_manifest.index):
        num_sections = int(split_method)
    else:
        print(
            f"More splits were requested ({split_method}) than there are "
            f"samples ({len(inp_manifest.index)}! Splitting per sample..."
        )
        num_sections = len(inp_manifest.index)

    split_list = np.array_split(inp_manifest, num_sections)
    split_dict = {df.iloc[0][0]: df for df in split_list}

    if not Path(out_dir).is_dir():
        Path(out_dir).mkdir()

    for sample_name, df in split_dict.items():
        df.to_csv(Path(out_dir) / f"{sample_name}{suffix_str}", sep="\t", index=False)


def filter_special_char(path_df: pd.DataFrame) -> dict:
    """
    Checks and replaces sample name to FASTQ path dictionary for special
    characters found.

    :param path_df:
    :return:
    """
    colname_list = path_df.columns.tolist()

    sample_dict = dict(
        zip(
            path_df.iloc[:, 0].values.tolist(),  # sample ID
            path_df.drop(path_df.columns[0], axis=1).values.tolist(),  # [path1, path2]
        )
    )

    # Checking sample names for special characters, as per QIIME 2 recommendations
    # https://docs.qiime2.org/2022.2/tutorials/metadata/#recommendations-for-identifiers
    sample_names = sample_dict.keys()
    special_name_dict = {name: check_special_char(name) for name in sample_names}
    special_name_count = Counter(special_name_dict.values())
    if special_name_count["fail"] > 0:
        print(
            f"Warning: A total of {special_name_count['fail']} sample names contain "
            f"# symbols, which are not permitted in manifest files! These samples have been "
            f"removed from further analysis."
        )

        failed_sample_list = [
            sample for sample, val in special_name_dict.items() if val == "fail"
        ]
        for sam in failed_sample_list:
            del sample_dict[sam]

    if special_name_count["warn"] > 0:
        print(
            f"Warning: A total of {special_name_count['warn']} sample names contain "
            f"non-alphanumeric characters! It is recommended to use only alphanumerics "
            f"or '-', '_', and '.' characters in sample identifiers."
        )

    # Checking file paths for '#' character, which will cause access to incorrect file paths
    # though will not throw a QIIME error
    path_names = [val for inner_list in sample_dict.values() for val in inner_list]
    special_path_dict = {fpath: check_special_char(fpath) for fpath in path_names}
    special_path_count = Counter(special_path_dict.values())

    if special_path_count["fail"] > 0:
        print(
            f"Warning: A total of {special_path_count['fail']} sample paths contain "
            f"# symbols, which are not permitted in manifest files! These samples have been "
            f"removed from further analysis."
        )

        failed_path_list = [
            fpath for fpath, val in special_path_dict.items() if val == "fail"
        ]
        for fpath in failed_path_list:
            sam = [
                key for key, val in sample_dict.items() if fpath in sample_dict.values()
            ]
            for s in sam:
                del sample_dict[s]

    new_df = pd.DataFrame.from_dict(sample_dict, orient="index")
    new_df.reset_index(inplace=True)
    new_df.columns = colname_list

    return new_df


def check_special_char(inp_str) -> str:
    """
    Establishes whether input strings adhere to QIIME 2 metadata formatting.
    Returns tags "pass", "fail", or "warn".

    :param inp_str:
    :return:
    """
    # Can return as a dict with val "pass", "warn", or "fail"
    if inp_str.isalnum():
        return "pass"
    elif "#" in inp_str:
        return "fail"

    non_alnum_ch = set([ch for ch in inp_str if not ch.isalnum()])
    if non_alnum_ch.issubset({".", "-"}):
        return "pass"
    else:
        return "warn"


def arg_parse():
    parser = argparse.ArgumentParser()

    # Required user-input arguments
    parser.add_argument(
        "-i",
        "--input_manifest",
        help="Path to input manifest file for splitting.",
        type=str,
        required=True,
    )
    parser.add_argument(
        "--suffix",
        help="Optional suffix to add to each split manifest.",
        type=str,
        required=True
    )

    # Optional user-input arguments
    parser.add_argument(
        "-o",
        "--output_dir",
        help="Location to print output files.",
        type=str,
        default=Path.cwd(),
    )
    parser.add_argument(
        "--split_method",
        help="Method to split input manifest. Options include 'sample' or an "
        "integer representing the number of output files.",
        type=str,
        default="sample",
    )

    args = parser.parse_args()
    return args


def main(args):
    assert Path(args.input_manifest).is_file()
    assert args.split_method == "sample" or args.split_method.isdigit()
    if Path(args.output_dir).resolve() != Path.cwd().resolve():
        assert not Path(args.output_dir).is_dir(), f"The directory " \
                                                   f"{args.output_dir} already " \
                                                   f"exists. Exiting..."
        Path.mkdir(args.output_dir)

    try:
        manifest_df = pd.read_csv(args.input_manifest, sep="\t")
        manifest_df.dropna(inplace=True)
        assert len(manifest_df.columns) == manifest_df.shape[1]
        assert len(manifest_df.index) > 0

    except FileNotFoundError:
        print(f"The input manifest file {args.input_manifest} was not found!")

    filt_df = filter_special_char(manifest_df)
    split_manifest(filt_df, args.output_dir, args.suffix, args.split_method)


if __name__ == "__main__":
    args = arg_parse()
    main(args)
