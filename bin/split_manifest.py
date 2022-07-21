#!/usr/bin/python3
"""
Splits FASTQ manifest files into individual samples.
"""

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
        print(f"More splits were requested ({split_method}) than there are "
              f"samples ({len(inp_manifest.index)}! Splitting per sample...")
        num_sections = len(inp_manifest.index)

    split_list = np.array_split(inp_manifest, num_sections)
    split_dict = {df.iloc[0][0]: df for df in split_list}

    if not Path(out_dir).is_dir():
        Path(out_dir).mkdir()

    for sample_name, df in split_dict.items():
        df.to_csv(Path(out_dir) / f"{sample_name}{suffix_str}", sep="\t", index=False)


def filter_special_char(path_df):
    """
    Checks and replaces sample name to FASTQ path dictionary for special
    characters found.

    :param path_df:
    :return:
    """
    # TODO: should also check file paths, not just sample names!
    # Check input dir path separately, since these should be the same across file path list

    sample_dict = dict(
        zip(
            path_df.iloc[:, 0].values.tolist(),
            path_df.drop(path_df.columns[0], axis=1).values.tolist(),
        )
    )
    sample_names = sample_dict.keys()
    special_char_dict = {ch: check_special_char(ch) for ch in sample_names}
    #special_char_names = [name for name in sample_names if not name.isalnum()]

    if len(special_char_names) > 0:
        # Also permitted: period ["."], dash ["-"], and underscore ["_"]
        # Also permitted: leading/trailing whitespace, which are stripped by default
        # Definitely not permitted and must be removed: pound ["#"]

        print(
            f"Warning: A total of {len(special_char_names)} sample names contain "
            f"non-alphanumeric characters! It is recommended to use only characters"
            f"within [a-zA-Z0-9_-\.]."
        )

    names_to_change = _rename_samples(special_char_names, sample_names)
    new_dict = {
        changed_name: sample_dict[name]
        for name, changed_name in names_to_change.items()
    }
    new_dict.update(
        {
            key: val
            for key, val in sample_dict.items()
            if key not in names_to_change.keys()
        }
    )

    if len(path_df.columns) == 2:
        new_df_list = [[key] + [val] for key, val in new_dict.items()]
    elif len(path_df.columns) == 3:
        new_df_list = [[key] + val for key, val in new_dict.items()]
    new_df = pd.DataFrame(new_df_list, columns=path_df.columns)
    return new_df


def check_special_char(inp_str):
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

    # Optional user-input arguments
    parser.add_argument(
        "-o",
        "--output_dir",
        help="Location to print output files.",
        type=str,
        default=Path.cwd(),
    )
    parser.add_argument(
        "--suffix",
        help="Optional suffix to add to each split manifest.",
        type=str,
        default="_split.tsv",
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
    assert Path(args.output_dir).is_dir()
    assert args.split_method == "sample" or args.split_method.isdigit()

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
