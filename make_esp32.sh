#!/bin/bash
# prep formatting
RED='\x1B[0;31m'
YELLOW='\x1B[0;33m'
GREEN='\x1B[0;32m'
CYAN='\x1B[0;36m'
NC='\x1B[0m' # No Color
echo -e  "${CYAN}ESP build process${NC}"

#Locations 
ESP_DIR=$HOME/esp32

export MPY_DIR=/mnt/c/develop/MyPython/micropython
export ESPIDF=$ESP_DIR/idf                      # Or any path you like.
export ESPTOOLS=$ESP_DIR/xtensa-esp32-elf/bin     # xtensa toolchain

export ESPIDF_HASH=9e70825d1e1cbf7988cf36981774300066580ea7

FIRMWARES=/mnt/c/develop/MyPython/FIRMWARE

#Add some defaults 
if [ -z $2 ]; then
    BOARD=JOSV_SPIRAM
else
    BOARD=$2
fi

# Add to path 
# pathadd path/to/add [after]
pathadd() {
    newelement=${1%/}
    if [ -d "$1" ] && ! echo $PATH | grep -E -q "(^|:)$newelement($|:)" ; then
        if [ "$2" = "after" ] ; then
            PATH="$PATH:$newelement"
        else
            PATH="$newelement:$PATH"
        fi
    fi
}

# do a build of a port 
# arg1 - description
# arg2 - board as defined in esp\board\xxxx

function do_build() {
    DESCR=$1
    BOARD=$2
    DEST=$3
    shift
    shift
    shift
    echo "building $DESCR $BOARD"

    #temporary build dir 
    # build_dir=/tmp/stm-build-$board
    # make -B $@ BOARD=$board BUILD=$build_dir || exit 1
    # mv $build_dir/firmware.dfu $dest_dir/$descr-$date-$git_tag.dfu
    # rm -rf $build_dir
    cd $MPY_DIR/ports/esp32
    #prepend to path 
    pathadd $ESPTOOLS
    
    # dotsource the ESPDIF environment if not yet imported
    if [ -z ${IDF_TOOLS_INSTALL_CMD+x} ]; then 
        source $ESPIDF/export.sh
    fi

    make submodules j=4
    
    if make BOARD=$BOARD j=4;
    then 
        echo -e  "${GREEN}- Build Completed{NC}"
        cp ./build-$BOARD/firmware.bin $FIRMWARES/${DESCR,,}.bin --verbose
    else
        echo -e  "${RED}Error during Build${NC}"
    fi
}
# # build the versions
# do_build pybv3 PYBV3
# do_build pybv3-network PYBV3 MICROPY_PY_WIZNET5K=1 MICROPY_PY_CC3K=1
# do_build pybv10 PYBV10


case "$1" in 
    1|"hash")
        echo -e  "${CYAN}1. Setup ESP32 toolchain.\n"
        echo -e  "${CYAN}    This will print the supported hashes, copy the one you want.${NC}"
        cd $MPY_DIR
        cd ports/esp32
        make ESPIDF=
        ;;
        
    2|"toolchain")   
        echo -e  "${CYAN}2. Fetch the required ESP IDF form git using the hash."
        echo -e "${GREEN}   HASH : $ESPIDF_HASH ${NC}"

        if [ ! -d $ESPIDF ]; then
            mkdir -p $ESPIDF
            cd $ESPIDF
            git clone https://github.com/espressif/esp-idf.git $ESPIDF
        else
            echo ""
        fi
        # assume the repo is already there 
        cd $ESPIDF
        # ? should we fetch a recent ?
        git checkout $ESPIDF_HASH 
        git submodule update --init --recursive
        ;;     
        
    3|"venv")
        echo -e  "${CYAN}3. Set up a Python virtual environment from scratch ${NC}"
        cd $MPY_DIR
        cd ports/esp32
        #if no venv3, create it 
        if [ ! -d "build-venv" ]; then
            echo -e  "${GREEN} create new virtual environment from scratch ${NC}"
            python3 -m venv build-venv
            source build-venv/bin/activate
            # pip3 install --upgrade pip
            # ESP IDF v3 python Toolchain 
            pip3 install -r $ESPIDF/requirements.txt

            #elftools needed for native dynamic modules
            pip3 install numpy elftools pyelftools
        else
            echo -e  "${GREEN} use existing 'build-venv' virtual environment ${NC}"
            source build-venv/bin/activate
        fi
        ;;
    4)  
        echo -e  "${CYAN}4. Download ESPIDF toolchain ${NC}"
        echo -e  "${CYAN} [sudo] Install PreReqs to $ESP_DIR ${NC}"
        # Ubuntu and Debian
        sudo apt-get install gcc git wget make libncurses-dev flex bison gperf python python-pip python-setuptools python-serial python-cryptography python-future python-pyparsing libffi-dev libssl-dev

        # download 
        mkdir -p ~/downloads
        cd ~/downloads
        wget https://dl.espressif.com/dl/xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0.tar.gz
        # Extract tar/zip to xtensatools folder
        mkdir -p $ESP_DIR
        cd $ESP_DIR
        tar -xzf ~/downloads/xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0.tar.gz
        # prepend to path 
        pathadd $ESPTOOLS
        export PATH
        ;;

    5|"build")
        echo -e  "${CYAN}5. Make ESP32${NC}"
        cd $MPY_DIR
        cd ports/esp32

        # do_build "mpy_jos_esp32_spiram" GENERIC_SPIRAM $FIRMWARES
        # do_build "mpy_josv_esp32_spiram" JOSV_SPIRAM $FIRMWARES
        do_build "mpy_esp32_${BOARD,,}" $BOARD $FIRMWARES
        ;;
    # 6)
    #     echo -e  "${CYAN}5. flash ESP32${NC}"
    #     cd $MPY_DIR
    #     cd ports/esp32

    #     #prepend to path 
    #     export PATH="$HOME/esp/xtensa-esp32-elf/bin:$PATH"
        
    #     export PORT=/dev/tty8
    #     #test if permission ?
    #     sudo chmod 666 $PORT
    #     make deploy 
    #     ;;

    9)
        echo -e  "${CYAN}9. Make native .mpy module ${NC}"
        cd $MPY_DIR
        cd examples/natmod/factorial_101

        #prepend to path 
        export PATH="$HOME/esp/xtensa-esp32-elf/bin:$PATH"
        source $MPY_DIR/ports/esp32/build-venv/bin/activate
        make clean
        if make MPY_DIR=$MPY_DIR ARCH=xtensawin;
        then 
            echo -e  "${GREEN}- Native module created${NC}"
        else
            echo -e  "${RED}Error compiling native module${NC}"
        fi
        ;;
 


    *) 
        echo -e  "${CYAN}1. Setup ESP32 toolchain.\n"
        echo -e  "${CYAN}2. Fetch the required ESP IDF form git using the hash."
        echo -e  "${CYAN}3. Set up a Python virtual environment from scratch ${NC}"
        echo -e  "${CYAN}4. Download ESPDIF toolchain ${NC}"
        echo -e  "${CYAN}5. Make ESP32${NC}"
esac

echo -e  "${GREEN}done...${NC}"


