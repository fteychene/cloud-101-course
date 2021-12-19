#!/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

BASE_DIR="$( cd "$( dirname "$0" )" && pwd )"

cd $SCRIPT_DIR

hugo

cd $SCRIPT_DIR/public

claat export $SCRIPT_DIR/codelabs/vagrant.md
claat export $SCRIPT_DIR/codelabs/ansible.md
claat export $SCRIPT_DIR/codelabs/kubernetes.md

cd $BASE_DIR


