import argparse
import datetime
import json
import os
import pathlib
import subprocess
import sys
import tempfile

# Constants for paths
USER = os.environ.get('USER')
DEFAULT_PATH = f'/home/{USER}/.config/logbook.md.gpg'
CONFIG_PATH = f'/home/{USER}/.config/logbook-config.json'

def ensure_file_extensions(path):
    """Ensure path has both .md and .gpg extensions."""
    if not path.endswith('.gpg'):
        if not path.endswith('.md'):
            path += '.md'
        path += '.gpg'
    elif not path[:-4].endswith('.md'):
        path = path[:-4] + '.md.gpg'
    return path

def get_gpg_recipients():
    """Get list of available GPG keys."""
    try:
        result = subprocess.run(
            ['gpg', '--list-keys', '--with-colons'],
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            print("Failed to list GPG keys")
            sys.exit(1)
        
        recipients = []
        for line in result.stdout.split('\n'):
            if line.startswith('uid:'):
                # Extract email from uid line
                parts = line.split(':')
                if len(parts) > 9:
                    uid = parts[9]
                    # Usually in format "Name <email@example.com>"
                    if '<' in uid and '>' in uid:
                        email = uid[uid.find('<')+1:uid.find('>')]
                        recipients.append(email)
        
        return recipients
    except subprocess.CalledProcessError as e:
        print(f"Error listing GPG keys: {e}")
        sys.exit(1)

def select_gpg_key():
    """Prompt user to select a GPG key."""
    recipients = get_gpg_recipients()
    
    if not recipients:
        print("No GPG keys found. Please create or import a key first.")
        sys.exit(1)
    
    if len(recipients) == 1:
        return recipients[0]
    
    print("\nAvailable GPG keys:")
    for i, recipient in enumerate(recipients, 1):
        print(f"{i}. {recipient}")
    
    while True:
        try:
            choice = input("\nSelect a key (number): ").strip()
            idx = int(choice) - 1
            if 0 <= idx < len(recipients):
                return recipients[idx]
            print("Invalid selection. Please try again.")
        except ValueError:
            print("Please enter a number.")

def get_config():
    """Get configuration including GPG key."""
    if os.path.exists(CONFIG_PATH):
        try:
            with open(CONFIG_PATH, 'r') as config_file:
                return json.load(config_file)
        except json.JSONDecodeError:
            print("Couldn't decode JSON. Exiting...")
            sys.exit(1)
    return {'path': DEFAULT_PATH}

def save_config(config):
    """Save configuration including GPG key."""
    with open(CONFIG_PATH, 'w') as config_file:
        json.dump(config, config_file, indent=4)

def get_date_tag():
    """Return the current date as a string in YY-MM-DD format."""
    return datetime.datetime.now().strftime('%y-%m-%d')

def decrypt_file(encrypted_path):
    """Decrypt the GPG file and return its contents."""
    content = ""
    try:
        result = subprocess.run(
            ['gpg', '--decrypt', encrypted_path],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            content = result.stdout
        else:
            print(f"Decryption failed: {result.stderr}")
            sys.exit(1)
    except subprocess.CalledProcessError as e:
        if "No such file or directory" not in str(e):
            print(f"Decryption error: {e}")
            sys.exit(1)
    return content

def encrypt_file(content, output_path, recipient):
    """Encrypt the content and save it to the specified path."""
    with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
        temp_file.write(content)
        temp_file_path = temp_file.name

    try:
        result = subprocess.run(
            ['gpg', '--yes', '--throw-keyids', '--encrypt', '--recipient', recipient, '--output', output_path, temp_file_path],
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            print(f"Encryption failed: {result.stderr}")
            sys.exit(1)
    finally:
        os.unlink(temp_file_path)

def get_logbook_path():
    """Retrieve the logbook path from the configuration or use the default."""
    config = get_config()
    return config.get('path', DEFAULT_PATH)

def initialize_logbook(path, recipient=None):
    """Ensure the logbook exists or prompt the user to create one."""
    if not os.path.exists(path):
        print(f"No logbook found at {path}")
        ans = input("Should I create a new one? (Y/n): ").strip().lower()
        if ans in ('y', 'yes', ''):
            try:
                if recipient is None:
                    recipient = select_gpg_key()
                    config = get_config()
                    config['gpg_key'] = recipient
                    save_config(config)
                
                encrypt_file("", path, recipient)
                print("Created new logbook.")
            except OSError:
                print("Couldn't create the logbook. Exiting...")
                sys.exit(1)
        else:
            print("Exiting...")
            sys.exit(1)

def add_entry(path, text, recipient):
    """Append a new entry to the logbook."""
    current_content = decrypt_file(path)
    updated_content = current_content + text + '\n'
    encrypt_file(updated_content, path, recipient)

def read_logbook(path):
    """Read and print all entries from the logbook."""
    print(f"Reading logbook at {path}")
    content = decrypt_file(path)
    print(content)

def set_logbook_path(new_path):
    """Update the logbook path in the configuration."""
    new_path = ensure_file_extensions(new_path)
    
    config = get_config()
    config['path'] = new_path
    save_config(config)
    print(f"Logbook path set to {new_path}")

def edit_logbook(path, recipient):
    """Open the decrypted logbook in the editor and re-encrypt after editing."""
    original_content = decrypt_file(path)
    
    with tempfile.NamedTemporaryFile(mode='w', suffix='.md', delete=False) as temp_file:
        temp_file.write(original_content)
        temp_file_path = temp_file.name
    
    try:
        editor = os.environ.get('EDITOR', 'nano')
        subprocess.run([editor, temp_file_path])
        
        with open(temp_file_path, 'r') as temp_file:
            new_content = temp_file.read()
        
        if new_content != original_content:
            encrypt_file(new_content, path, recipient)
    finally:
        os.unlink(temp_file_path)

def create_parser():
    """Create and return the argument parser."""
    parser = argparse.ArgumentParser(description='A simple encrypted command-line logbook.')
    parser.add_argument('message', nargs='*', help='Text to append to the logbook.')
    parser.add_argument('-t', '--tempfile', type=str, help='Set a temporary path for the logbook.')
    group = parser.add_mutually_exclusive_group()
    group.add_argument('-r', '--read', action='store_true', help='Display all logbook entries.')
    group.add_argument('-e', '--edit', action='store_true', help='Open the logbook in your system editor.')
    group.add_argument('-l', '--list', action='store_true', help='List the logbook path.')
    group.add_argument('-p', '--path', type=str, help='Set a new path for the logbook.')
    parser.add_argument('-k', '--key', type=str, help='Specify GPG key to use')
    return parser

def main():
    parser = create_parser()
    args = parser.parse_args()
    
    path = args.tempfile if args.tempfile else get_logbook_path()
    path = ensure_file_extensions(path)
    
    if args.path:
        set_logbook_path(args.path)
        return
    
    # Get or select GPG key
    config = get_config()
    recipient = args.key if args.key else config.get('gpg_key')
    
    if recipient is None:
        recipient = select_gpg_key()
        config['gpg_key'] = recipient
        save_config(config)
    
    initialize_logbook(path, recipient)
    
    if args.read:
        read_logbook(path)
    elif args.edit:
        edit_logbook(path, recipient)
    elif args.list:
        print(path)
    else:
        if args.message:
            add_entry(path, get_date_tag() + ' ' + ' '.join(args.message), recipient)
        else:
            print("No message provided. Exiting...")

if __name__ == '__main__':
    main()

