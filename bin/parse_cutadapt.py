#!/usr/bin/python3
"""
Parses Cutadapt file to determine optimal sample-primer pairs.
"""

from pathlib import Path
import argparse
import re
import pandas as pd


def read_log(log_file: str, read_type: str):
    # Note: Each log represents a single primer (pair)
    # Extract summary

    count_samples = 0
    flag_dict = {"--front" : "R1",
                 "-g"      : "R1",
                 "-G"      : "R2"}

    read_dict = {"single" : 1,
                 "paired" : 2}

    pct_list = []

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

                # Within the sample
                while in_sample:  # needs to be modified
                    line = f.readline()
                    if not line:
                        break

                    # Search for CLI params
                    if re.match(r"Command line parameters:", line):
                        cli_line = line
                        print(cli_line)

                        # Search for --p-front primer only
                        # (--front or -g) in Cutadapt
                        # OR
                        # Search for both --p-front-f and --p-front-r primers
                        # (--front or -g) and (-G) in Cutadapt
                        primer_list = re.findall(
                            r"\-\-front [A-Z]+|\-g [A-Z]+|\-G [A-Z]+", cli_line)
                        primer_dict = {flag_dict[param_set.split()[0]]:
                                       param_set.split()[1] for
                                       param_set in primer_list}

                        # Search for inp FASTQs, extract sample names
                        # Input FASTQs/FASTAs have no flag
                        # Output FASTQs/FASTAs are preceded by flags
                        # (--output or -o) and/or (--paired-output or -p)
                        fastq_list = re.findall(
                            r"\-[o|p] [\S]+\.fast[\S]+|[\S]+\.fast[\S]+",
                            cli_line)

                    # Search for adapter summary stats
                    if re.match(r"Total read pairs processed:", line):
                        r1_line = f.readline()
                        r2_line = f.readline()
                        rstats_list = [rline.strip() for rline in [r1_line,
                                                                   r2_line]
                                       if re.match(r"Read [1-2] with adapter:",
                                                   rline.strip())]
                        assert len(rstats_list) > 0, \
                            "The text 'Read 1/2 with adapter' could not be " \
                            "found in the Cutadapt log for this sample!"

                        if read_type == "single":
                            # sample, primer, trim_pct
                            pct_list.append([Path(fastq_list[0]).name,
                                             primer_dict["R1"],
                                             rstats_list[0]])
                        else:
                            # sample, primer_r1, pct_r1, primer_r2, pct_r2
                            pct_list.append([Path(fastq_list[0]).name,
                                             primer_dict["R1"],
                                             rstats_list[0],
                                             primer_dict["R2"],
                                             rstats_list[1]])
                        break   # Finish looking after one sample
            continue

    # After processing the entire set
    assert len(pct_list) > 0, "There were no results found!"
    if read_type == "single":
        pct_df = pd.DataFrame(pct_list, columns=["sample", "primer",
                                                 "trim_pct"])
    else:
        pct_df = pd.DataFrame(pct_list, columns=["sample", "primer_r1",
                                                 "trim_pct_r1", "primer_r2",
                                                 "trim_pct_r2"])

    return pct_df


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
    parser.add_argument(
        "-r",
        "--read_type",
        help="Read type of input FASTQs, either 'single' or 'paired'.",
        type=str,
        choices=["single", "paired"],
        required=True
    )
    parser.add_argument(
        "-s",
        "--sample_name",
        help="Sample name of the FASTQ file whose Cutadapt log we parse.",
        type=str,
        required=True
    )

    # Add sample/FASTQ names for an added layer of cross-reference?

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

    result_df = read_log(args.input_log, args.read_type)
    result_df.to_csv(f"cutadapt_parse_{args.sample_name}.csv",
                     index=None)


if __name__ == "__main__":
    args = arg_parse()
    main(args)
