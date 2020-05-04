## Add to .bashrc to include scipts folder 


# get userprofile on WSL
export USERPROFILE=$(wslpath $(cmd.exe /c "echo|set /p=%USERPROFILE%"))
# set PATH so it includes wsl_scripts if it exists
if [ -d "$USERPROFILE/wsl_scripts" ] ; then
    export PATH="$USERPROFILE/wsl_scripts:$PATH"
f