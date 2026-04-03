#!/usr/bin/env python3
"""Fix Python 2 to Python 3 compatibility in gyp directory."""

import os
import re
import sys

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    original = content
    
    # Fix print statements: print('xxx') -> print('xxx')
    # But be careful not to match print( already
    content = re.sub(r'\bprint\s+\'(.*?)\'', r"print('\1')", content)
    content = re.sub(r'\bprint\s+\"(.*?)\"', r'print("\1")', content)
    
    # Fix .items() -> .items()
    content = content.replace('.items()', '.items()')
    
    # Fix .keys() -> .keys()
    content = content.replace('.keys()', '.keys()')
    
    # Fix .values() -> .values()
    content = content.replace('.values()', '.values()')
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    gyp_dir = os.path.dirname(os.path.abspath(__file__))
    count = 0
    for root, dirs, files in os.walk(gyp_dir):
        for f in files:
            if f.endswith('.py'):
                filepath = os.path.join(root, f)
                if process_file(filepath):
                    count += 1
                    print(f"Fixed: {filepath}")
    print(f"Total files fixed: {count}")

if __name__ == '__main__':
    main()