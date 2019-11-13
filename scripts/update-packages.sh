#!/usr/bin/env bash

set -u -e -o pipefail

readonly currentDir=$(
    cd $(dirname $0)
    pwd
)
readonly scriptsLocation=$currentDir
readonly rootDir="${currentDir}/../.."

TRAVIS=${TRAVIS:-}

VERBOSE=false
TRACE=false

source ${currentDir}/ci/_travis-fold.sh
source ${currentDir}/ci/util-functions.sh
source ${currentDir}/functions.sh

logInfo "Set git config user.name and user.email"
git config user.name SuperITMan
git config user.email "admin@superitman.com"

logInfo "============================================="
logInfo "Updating listed applications"
logInfo "============================================="

FDROID_INDEX_URL="https://f-droid.org/repo/index-v1.jar"
logTrace "FDROID_INDEX_URL: ${FDROID_INDEX_URL}" 1

FDROID_DOWNLOAD_BASE_URL="https://f-droid.org/repo"
logTrace "FDROID_DOWNLOAD_BASE_URL: ${FDROID_DOWNLOAD_BASE_URL}" 1

travisFoldStart "Downloading latest version of index-v1.json on F-Droid website" "no-xtrace"
logInfo "Downloading index-v1.jar in /tmp/index-v1.zip" 1
curl -o /tmp/index-v1.zip $FDROID_INDEX_URL
logInfo "Unzip the file" 1
unzip /tmp/index-v1.zip -d /tmp/index-v1 > /dev/null
logInfo "Copy index-v1.json file in ${currentDir}" 1
yes | cp /tmp/index-v1/index-v1.json ${currentDir}/index-v1.json
travisFoldEnd "Downloading latest version of index-v1.json on F-Droid website"

logInfo "Downloading GPG Key Signature: gpg --batch --recv-keys 41E7044E1DBA2E89"
gpg --batch --recv-keys 41E7044E1DBA2E89 # See https://forum.f-droid.org/t/apk-verification-instructions/6047/20

travisFoldStart "Checking every application present in scripts/packages.js" "no-xtrace"

index=0
appName=$(getApplicationName $index)

while [ "${appName}" != "" ]; do
    appPackageName=$(getApplicationPackageName $index)
    appType=$(getApplicationType $index)
    logInfo "Application index: ${index}" 1
    logInfo "Application name: ${appName}" 1
    logInfo "Application package name: ${appPackageName}" 1
    logInfo "Application type: ${appType}" 1

    currentPackageVersion=$(getCurrentPackageVersion $appName $appPackageName $rootDir)
    logTrace "Current package version: ${currentPackageVersion}" 1

    availablePackageVersion=$(getApplicationApkName "$appPackageName")
    logTrace "Available package version: ${availablePackageVersion}" 1

    if [[ "${appType}" == "gitlab" ]]; then
        logInfo "GitLab applications not yet supported."
    fi

    if [[ "${availablePackageVersion}" != "" && "${currentPackageVersion}" != "${availablePackageVersion}" ]]; then
        travisFoldStart "Downloading new version available for ${appPackageName}" "no-xtrace"
        isDownloadValid=false

        if [[ "${appType}" == "fdroid" ]]; then
            logInfo "Download apk from: ${FDROID_DOWNLOAD_BASE_URL}/${availablePackageVersion}"
            curl -o /$rootDir/$appName/$availablePackageVersion "${FDROID_DOWNLOAD_BASE_URL}/${availablePackageVersion}"
            logInfo "Download apk signature from: ${FDROID_DOWNLOAD_BASE_URL}/${availablePackageVersion}.asc"
            curl -o /tmp/signature.asc "${FDROID_DOWNLOAD_BASE_URL}/${availablePackageVersion}.asc"
            logInfo "Verify the apk thanks to GPG"
            gpg --verify /tmp/signature.asc $rootDir/$appName/$availablePackageVersion

            if [[ $? -eq 0 ]]; then
                isDownloadValid=true
            fi
        elif [[ "${appType}" == "gitlab" ]]; then
            logInfo "GitLab applications not yet supported."
        else
            logInfo "Type of the application invalid. Please set it as 'gitlab' or 'fdroid'"
        fi

        if [[ $isDownloadValid ]]; then
            travisFoldStart "Adding new package to Git project" "no-xtrace"
            logInfo "Remove previous apk: ${currentPackageVersion}"
            rm $rootDir/$appName/$currentPackageVersion
            logInfo "Adapt content of Android.mk to be in sync with the new file"
            PACKAGE_NAME_STR="${currentPackageVersion//\./\\\.}"
            PATTERN="LOCAL\_SRC\_FILES\ \:\=\ ${PACKAGE_NAME_STR}"
            REPLACEMENT="LOCAL_SRC_FILES := ${availablePackageVersion}"
            logTrace "PATTERN: ${PATTERN}" 1
            perl -p -i -e "s/$PATTERN/$REPLACEMENT/g" $rootDir/$appName/Android.mk

            logInfo "Add the 3 changes to the Git repository"
            git add $rootDir/$appName/.
            logInfo "Commit the changes"
            git commit -m "ci - update application ${appName} with ${appPackageName}"
            travisFoldEnd "Adding new package to Git project"
        else
            logInfo "Remove wrong downloaded package from the repo"
            rm $rootDir/$appName/$availablePackageVersion
        fi

        travisFoldEnd "Downloading new version available for ${appPackageName}"
    else
        logInfo "No update available for ${appPackageName}"
    fi

    index=$((index + 1))
    appName=$(getApplicationName $index)
done
