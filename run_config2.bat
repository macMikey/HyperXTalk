@echo off
set PATH=C:\Strawberry\perl\bin;C:\Program Files\Git\cmd;%PATH%
set GYP_MSVS_VERSION=2022
cd C:\Users\user\Documents\GitHub\HyperXTalk
python3 config.py --platform win-x86_64 > configure.log 2>&1
echo DONE >> configure.log