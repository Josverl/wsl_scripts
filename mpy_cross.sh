#!/bin/bash
echo "Start to Build the micropython cross compiler"
cd /mnt/c/develop/MyPython/micropython
cd ./mpy-cross

make V=1 n=4

echo "done..."


