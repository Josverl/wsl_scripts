#!/bin/bash
if [ -z $1 ]; then
    BOARD=JOSV_SPIRAM
else
    BOARD=$1
fi

echo "Start to Build $BOARD {$1:-DEFAULT}"
