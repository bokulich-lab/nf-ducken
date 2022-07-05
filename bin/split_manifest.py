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

    split_list = np.array_split(inp_manifest, num_sections)
    split_dict = {df.iloc[0][0]: df for df in split_list}

    if not Path(out_dir).is_dir():
        Path(out_dir).mkdir()

    for sample_name, df in split_dict.items():
        df.to_csv(Path(out_dir) / f"{sample_name}{suffix_str}", sep="\t", index=False)


def check_special_char(path_df):
    """
    Checks and replaces sample name to FASTQ path dictionary for special
    characters.

    :param path_df:
    :return:
    """

    sample_dict = dict(
        zip(
            path_df.iloc[:, 0].values.tolist(),
            path_df.drop(path_df.columns[0], axis=1).values.tolist(),
        )
    )
    sample_names = sample_dict.keys()
    special_char_names = [name for name in sample_names if not name[0].isalnum()]

    if len(special_char_names) > 0:
        print(
            f"A total of {len(special_char_names)} sample names begin with "
            f"non-alphanumeric characters!"
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


def _rename_samples(samples_to_rename, all_samples, change_dict={}):
    """
    Renames samples by prefixing. Recurses to ensure no duplicate sample
    names are generated.

    :param samples_to_rename:
    :param all_samples:
    :param change_dict:
    :return:
    """
    renamed_samples = {name: "o" + name for name in samples_to_rename}
    changes = change_dict.copy()
    changes.update(renamed_samples)

    name_overlap = set(renamed_samples.values()) & set(all_samples)
    if any(name_overlap):
        return _rename_samples(name_overlap, all_samples, changes)
    return changes


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
        help="Method to split input manifest. Options include 'sample'.",
        type=str,
        choices={"sample"},
        default="sample",
    )

    args = parser.parse_args()
    return args


def main(args):
    assert Path(args.input_manifest).is_file()
    assert Path(args.output_dir).is_dir()

    try:
        manifest_df = pd.read_csv(args.input_manifest, sep="\t")
        manifest_df.dropna(inplace=True)
        assert len(manifest_df.columns) == manifest_df.shape[1]
        assert len(manifest_df.index) > 0

    except FileNotFoundError:
        print(f"The input manifest file {args.input_manifest} was not found!")

    renamed_df = check_special_char(manifest_df)
    split_manifest(renamed_df, args.output_dir, args.suffix, args.split_method)


if __name__ == "__main__":
    args = arg_parse()
    main(args)
