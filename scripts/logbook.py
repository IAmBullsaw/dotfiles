import argparse
import datetime
import json
import os
import pathlib
import subprocess
import sys

# Constants for paths
USER = os.environ.get('USER')
DEFAULT_PATH = f'/home/{USER}/.config/logbook.md'
CONFIG_PATH = f'/home/{USER}/.config/logbook-config.json'

def get_date_tag():
    """Return the current date as a string in YY-MM-DD format."""
    return datetime.datetime.now().strftime('%y-%m-%d')

def get_logbook_path():
    """Retrieve the logbook path from the configuration or use the default."""
    if os.path.exists(CONFIG_PATH):
        try:
            with open(CONFIG_PATH, 'r') as config_file:
                data = json.load(config_file)
                return data.get('path', DEFAULT_PATH)
        except json.JSONDecodeError:
            print("Couldn't decode JSON. Exiting...")
            sys.exit(1)
    return DEFAULT_PATH

def initialize_logbook(path):
    """Ensure the logbook exists or prompt the user to create one."""
    if not os.path.exists(path):
        print(f"No logbook found at {path}")
        ans = input("Should I create a new one? (Y/n): ").strip().lower()
        if ans in ('y', 'yes', ''):
            try:
                pathlib.Path(path).touch()
                print("Created new logbook.")
            except OSError:
                print("Couldn't create the logbook. Exiting...")
                sys.exit(1)
        else:
            print("Exiting...")
            sys.exit(1)

def add_entry(path, text):
    """Append a new entry to the logbook."""
    with open(path, 'a') as logbook_file:
        logbook_file.write(text + '\n')

def read_logbook(path):
    """Read and print all entries from the logbook."""
    print(f"Reading logbook at {path}")
    with open(path, 'r') as logbook_file:
        print(logbook_file.read())

def set_logbook_path(new_path):
    """Update the logbook path in the configuration."""
    if os.path.exists(CONFIG_PATH):
        try:
            with open(CONFIG_PATH, 'r') as config_file:
                data = json.load(config_file)
        except json.JSONDecodeError:
            print("Couldn't decode JSON. Exiting...")
            sys.exit(1)
    else:
        data = {}
    
    data['path'] = new_path
    with open(CONFIG_PATH, 'w') as config_file:
        json.dump(data, config_file, indent=4)
    print(f"Logbook path set to {new_path}")

def main():
    parser = argparse.ArgumentParser(description='A simple command-line logbook.')
    parser.add_argument('message', nargs='*', help='Text to append to the logbook.')
    parser.add_argument('-t', '--tempfile', type=str, help='Set a temporary path for the logbook.')
    group = parser.add_mutually_exclusive_group()
    group.add_argument('-r', '--read', action='store_true', help='Display all logbook entries.')
    group.add_argument('-e', '--edit', action='store_true', help='Open the logbook in your system editor.')
    group.add_argument('-l', '--list', action='store_true', help='List the logbook path.')
    group.add_argument('-p', '--path', type=str, help='Set a new path for the logbook.')

    args = parser.parse_args()
    path = None
    if args.tempfile:
        path = args.tempfile
    else:
        path = get_logbook_path()        

    if args.path:
        set_logbook_path(args.path)
        return

    initialize_logbook(path)


    if args.read:
        read_logbook(path)
    elif args.edit:
        editor = os.environ.get('EDITOR', 'nano')
        subprocess.run([editor, path])
    elif args.list:
        print(path)
    else:
        if args.message:
            add_entry(path, get_date_tag() + ' ' + ' '.join(args.message))
        else:
            print("No message provided. Exiting...")

if __name__ == '__main__':
    main()

