@echo off
REM Run configure and save output to file
cd /d C:\Users\user\Documents\GitHub\HyperXTalk
python3 config.py --platform win-x86_64 > configure_output.txt 2>&1
echo DONE >> configure_output.txt