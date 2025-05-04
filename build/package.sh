#!/usr/bin/env bash
cd ../src
rm ../build/game.love
zip -r ../build/game.love * 
cd ../web
python build.py ../build/game.love ../docs
echo "# This isn't actually the docs, this is the game, but github pages will only (realisitically) run from this folder without a headache so for now - good enough" > ../docs/README.md
cd ../build
ln -f game.love ../mobile/assets/game.love
apktool b -o unverified.apk ../mobile
apksigner sign --ks ~/.keystore --out VoidSweeper.apk unverified.apk
rm unverified.apk
rm VoidSweeper.apk.idsig
