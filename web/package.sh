#!/usr/bin/env bash
cd ../src
zip -r ../web/MineSweeter.love * 
cd -
python build.py MineSweeter.love ../docs
echo "# This isn't actually the docs, this is the game, but github pages will only (realisitically) run from this folder without a headache so for now - good enough" > ../docs/README.md
