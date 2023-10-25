#!/bin/bash

set -e

abspath=$(cd "${0%/*}" && echo "$PWD"/"${0##*/}")
init_dir=$(dirname "$abspath")

### python version printed
function version_info {
    echo "---------------------------  python3.9 version information  ----------------------------"
    which python && python --version || true
    which pip && pip --version || true
    which virtualenv && virtualenv --version || true
    echo "-----------------------------  pip3.9 libraries installed  -----------------------------"
    pip freeze || true
}

### setup python3.9 virtualenv if empty and does
if [ ! -d "$init_dir"/.virt_env ]; then
    echo
    echo ----------------------------- python3 virtualenv setup -----------------------------
    virtualenv "$init_dir"/.virt_env/ --python=python3.9  --pip=23.3.1
    version_info
else
    echo ----------------------------- python3 virtualenv exists -----------------------------
fi

echo
echo ----------------------------- grabbing pip3 requirements -----------------------------
source "$init_dir"/.virt_env/bin/activate
pip3 install -q -r "$init_dir"/requirements.txt

## check ansible install
ansible-galaxy collection install community.aws --force

# Explicitly handle errors
set +e

echo
echo ---------------------------------------------------------------------------------------
echo
