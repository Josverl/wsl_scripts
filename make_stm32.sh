#!/bin/bash
# prep formatting
RED='\x1B[0;31m'
YELLOW='\x1B[0;33m'
GREEN='\x1B[0;32m'
CYAN='\x1B[0;36m'
NC='\x1B[0m' # No Color
echo -e  "${CYAN}STM32 build process${NC}"


case "$1" in 
    "--toolchain"|"-t")
        #needed for dfu_util to install to USB host based devices   
        sudo apt install python3-usb
        ;;
    *) 
        echo -e  "${CYAN}1. Setup ESP32 toolchain.\n"
        ;;
esac
