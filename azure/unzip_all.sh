#!/bin/bash
set -e

output_dir=$1

echo "===========Start Unzip Files=========="
(cd $output_dir && for file in $(find . -name *.zip); do unzip -oq $file -d $(echo $file | rev | cut -d'/' -f2- | rev); done)
echo "===========Finish Unzip Files=========="
