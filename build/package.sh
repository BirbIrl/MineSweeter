#!/usr/bin/env bash
#love
cd ../src
rm ../build/VoidSweeper.love
zip -r ../build/VoidSweeper.love * 
#web
cd ../web
python build.py ../build/VoidSweeper.love ../docs
echo "# This isn't actually the docs, this is the game, but github pages will only (realisitically) run from this folder without a headache so for now - good enough" > ../docs/README.md
cd ../build
#windows
cp -r ../windows ./VoidSweeper
cat ./VoidSweeper/love.exe ./VoidSweeper.love > ./VoidSweeper/VoidSweeper.exe
cd VoidSweeper
rm ./love.exe
rm ../VoidSweeperWin64.zip 
zip -r ../VoidSweeperWin64.zip *
cd ..
rm -r ./VoidSweeper
#android
ln -f VoidSweeper.love ../mobile/assets/game.love
apktool b -o unverified.apk ../mobile
apksigner sign --ks ~/.keystore --out VoidSweeper.apk unverified.apk
rm unverified.apk
rm VoidSweeper.apk.idsig
