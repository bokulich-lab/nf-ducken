#!/usr/bin/python3
"""
Parses Cutadapt file to determine optimal sample-primer pairs.
"""

from pathlib import Path
import argparse
import re


def read_log(log_file: str, read_type: str):
    # Note: Each log represents a single primer (pair)
    # Split log by sample
    # Extract summary

    count_samples = 0
    flag_dict = {"--front" : "R1",
                 "-g"      : "R1",
                 "-G"      : "R2"}

    read_dict = {"single" : 1,
                 "paired" : 2}

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

                        break   # Look for next sample

                pass
        pass


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

    # Add sample/FASTQ names for an added layer of cross-reference?

    # Optional user-input arguments
    parser.add_argument(
        "-o",
        "--output_dir",
        help="Location to print output files.",
        type=str,
        default=Path.cwd(),
    )
    parser.add_argument(
        "-f",
        "--fastq_suffix",
        help="Sample FASTQ file name suffix to remove in sample assignment; "
             "comma-delimited.",
        type=str,
        default="*_00_L001_R[1-2]_001.fastq.gz,*.fastq.gz",
    )

    args = parser.parse_args()
    return args


def main(args):
    assert Path(args.input_log).is_file()
    assert Path(args.output_dir).is_dir()

    read_log(args.input_log, args.read_type)


if __name__ == "__main__":
    args = arg_parse()
    main(args)
