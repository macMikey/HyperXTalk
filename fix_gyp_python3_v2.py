#!/usr/bin/env python3
"""Fix remaining Python 2 issues in gyp for Python 3."""

import os
import re
import sys

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    original = content
    
    # Fix except Exception, e: -> except Exception as e:
    content = re.sub(r'except (\w+), (\w+):', r'except \1 as \2:', content)
    
    # Fix raise GypError, message -> raise GypError(message) 
    # Be careful not to match raise GypError(
    content = re.sub(r'raise (GypError|[A-Z]\w*Error), (\w+)', r'raise \1(\2)', content)
    
    # Fix raise GypError, 'message' -> raise GypError('message')
    content = re.sub(r'raise (GypError|[A-Z]\w*Error), (\'[^\']*\')', r'raise \1(\2)', content)
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def fix_input_py():
    """Fix the compiler module import in input.py - use ast instead."""
    filepath = 'C:/Users/user/Documents/GitHub/HyperXTalk/gyp/pylib/gyp/input.py'
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    # Replace compiler imports with ast
    content = content.replace('from compiler.ast import Const', 'import ast as compiler_ast\nfrom compiler_ast import Const')
    content = content.replace('from compiler.ast import Dict', 'from compiler_ast import Dict')
    content = content.replace('from compiler.ast import Discard', 'from compiler_ast import Discard')
    content = content.replace('from compiler.ast import List', 'from compiler_ast import List')
    content = content.replace('from compiler.ast import Module', 'from compiler_ast import Module')
    content = content.replace('from compiler.ast import Node', 'from compiler_ast import Node')
    content = content.replace('from compiler.ast import Stmt', 'from compiler_ast import Stmt')
    
    # Replace compiler.parse with ast.parse
    content = content.replace('ast = compiler.parse(file_contents)', 'ast = compiler_ast.parse(file_contents)')
    
    # Replace other compiler usages - getChildren() -> body
    content = content.replace('.getChildren()', '.body')
    
    # Fix c1[0] is None -> c1[0] is None (Module has docstring as first element)
    # This is tricky - in Python ast, Module node has body attribute, not getChildren
    
    # Replace isinstance(ast, Module) - check for Module from ast
    content = content.replace('isinstance(ast, Module)', 'isinstance(ast, compiler_ast.Module)')
    content = content.replace('isinstance(c1[1], Stmt)', 'isinstance(c1[1], compiler_ast.FunctionDef)')
    content = content.replace('isinstance(c2[0], Discard)', 'isinstance(c2[0], compiler_ast.Expr)')
    content = content.replace('isinstance(c3[0], Dict)', 'isinstance(c3[0], compiler_ast.Dict)')
    content = content.replace('isinstance(c3[0], List)', 'isinstance(c3[0], compiler_ast.List)')
    content = content.replace('isinstance(c3[0], Const)', 'isinstance(c3[0], compiler_ast.Constant)')
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Fixed: {filepath}")

def fix_tabs():
    """Fix tabs in input.py at line 2816."""
    filepath = 'C:/Users/user/Documents/GitHub/HyperXTalk/gyp/pylib/gyp/input.py'
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    fixed_lines = []
    for i, line in enumerate(lines):
        # Lines 2816-2823 have tabs mixed with spaces - fix them
        if i >= 2815 and i <= 2823:
            # Replace tabs with 8 spaces
            fixed_lines.append(line.replace('\t', '        '))
        else:
            fixed_lines.append(line)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(fixed_lines)
    print(f"Fixed tabs in: {filepath}")

def main():
    gyp_dir = 'C:/Users/user/Documents/GitHub/HyperXTalk/gyp'
    count = 0
    for root, dirs, files in os.walk(gyp_dir):
        for f in files:
            if f.endswith('.py'):
                filepath = os.path.join(root, f)
                if process_file(filepath):
                    count += 1
                    print(f"Fixed: {filepath}")
    
    fix_input_py()
    fix_tabs()
    print(f"Total files fixed: {count}")

if __name__ == '__main__':
    main()