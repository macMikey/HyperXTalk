#!/usr/bin/env python
import os
import sys

os.environ['PATH'] = r'C:\Strawberry\perl\bin;C:\Program Files\Git\bin;' + os.environ.get('PATH', '')

script_dir = os.path.dirname(os.path.abspath(__file__))

sys.path.insert(0, os.path.join(script_dir, 'gyp', 'pylib'))

import gyp
sys.exit(gyp.script_main())