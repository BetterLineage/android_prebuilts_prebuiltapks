#!/usr/bin/env bash

set -u -e -o pipefail

getCurrentPackageVersion() {
    name=$1
    packageName=$2
    location=$3
    echo $(ls ${3}/${1} | grep $2_)
}

#######################################
# Echo the FDroid application name of the application in the array based on the index.
# Arguments:
#   param1 - application index
#   param2 - scripts 
#######################################
getApplicationName() {
    echo $(node -e "require('$scriptsLocation/index.js').getApplicationName($1)")
}

getApplicationPackageName() {
    echo $(node -e "require('$scriptsLocation/index.js').getApplicationPackageName($1)")
}

getApplicationApkName() {
    echo $(node -e "require('$scriptsLocation/index.js').getPackageApkVersion('$1')")
}

getApplicationType() {
    echo $(node -e "require('$scriptsLocation/index.js').getApplicationType($1)")
}