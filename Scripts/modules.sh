#!/bin/bash
for file in $( ls /powershell/PowerCLI-Example-Scripts/Modules/ )
do
    mkdir "/root/.local/share/powershell/Modules/${file%.*}/"
    mv "/powershell/PowerCLI-Example-Scripts/Modules/$file" "/root/.local/share/powershell/Modules/${file%.*}/$file"
done
