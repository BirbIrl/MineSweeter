#!/usr/bin/env bash
cd ../src
zip -r ../web/MineSweeter.love * 
cd -
python build.py MineSweeter.love build
