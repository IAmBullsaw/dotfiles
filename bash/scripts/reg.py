#! /usr/bin/python3

import sys
import argparse
import re

verbose=False

def debug(output):
    if verbose:
        print("[INFO]",output, file=sys.stderr)

def get_args():
    parser = argparse.ArgumentParser(description='Print matches to stdout')
    parser.add_argument('regex', type=str, help='The regex with at least one matching group')
    parser.add_argument('-f', '--file', nargs='+', help='File(s) to read from if not standard input')
    parser.add_argument('-v', '--verbose', action='store_true', help='Print all matches')
    return parser.parse_args()

def present(findings):
    for finding in findings:
        print(finding, end=" ")
    print()

def main(files, regex):
    findings = []
    if files:
        pass
    else:
        for line in sys.stdin:
            for match in regex.finditer(line):
                debug(match.groups())
                if match.groups():
                    for group in match.groups():
                        if group:
                            findings.append(group)
                else:
                    findings.append(match.group(0))
    present(findings)

if __name__ == '__main__':
    args = get_args()
    verbose = args.verbose
    regex = re.compile(args.regex)
    main(args.file , regex)
