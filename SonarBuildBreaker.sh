#!/bin/bash

set -e

############################################
##### function to display script usage #####
############################################
function usage() {
    echo "########################################################"
    echo " Usage: $0 "
    echo "    --branch=<GIT_BRANCH> --sonar-token=<SONAR_TOKEN>"
    echo "    --sonar-url=<SONAR_URL> --project-key=<PROJECT_KEY>"
    echo "########################################################"
    exit 0
}

###################################
##### function to exit script #####
###################################
function die() {
    local message=$1
    [ -z "$message" ] && message="Died"
    echo -e "$message at ${BASH_SOURCE[1]}:${FUNCNAME[1]} line ${BASH_LINENO[0]}." >&2
    exit 1
}

###########################################
##### function to Qualtiy Gate Status #####
###########################################
function QualityGateStatus() {
    qualityGatesStatus=$(curl -s -u "${SONAR_TOKEN}": "$SONAR_URL/api/qualitygates/project_status?analysisId=${analysisID}" | jq -r .projectStatus.status)
    # Report the Status
    echo "QualityGate status: $qualityGatesStatus"
    case $qualityGatesStatus in
    OK | ok)
        echo "==> Sonar analysis ID for branch $GIT_BRANCH is: $analysisID"
        echo "SONAR QUALITY GATE STATUS ==> Sonar Qualtiy Gate Status for branch $GIT_BRANCH in project $analysisProject is PASSED"
        ;;
    ERROR | error)
        echo "==> Sonar analysis ID for branch $GIT_BRANCH is: $analysisID"
        echo "QUALITY GATE STATUS ==> Sonar Quality Gate for branch $GIT_BRANCH in project $analysisProject is FAILED, failing the Build..."
        die
        ;;
    esac
}

function retryAnalysisID() {
    if [ "$analysisID" == "null" ]; then
        echo "Current analysis id value is $analysisID"
        echo "=> Fetching the SonarQube Qualtiy Gates Status based on the previous successful Analysis..."
        sleep 3
        aID=$(curl -s -u "${SONAR_TOKEN}": "$SONAR_URL/api/ce/activity?component=${PROJECT_KEY}" | jq '.tasks[] | "\(.branch) \(.id) \(.analysisId)"' | grep "$GIT_BRANCH" | awk '{print $NF}')
        for anID in $aID; do
            anID=$(echo "$anID" | tr -d "\"\`'")
            analysisID=$anID
            if [ "$anID" != "null" ]; then
                break
            fi
        done
    fi
}

############################################
##### function to check sonar analysis #####
############################################
function sonarAnalysisStatus() {
    echo "==> validating current analysis status, please wait..."
    # Get the status
    n=0
    until [ "$n" -ge 5 ] || [ ! -z "$analysisStatus" ]; do
        analysis=$(curl -s -u "${SONAR_TOKEN}": "$SONAR_URL/api/ce/activity?component=${PROJECT_KEY}" | jq '.tasks[] | "\(.branch) \(.status)"' | grep "$GIT_BRANCH" | head -1 | awk '{print $NF}')
        analysisStatus=$(echo "$analysis" | tr -d "\"\`'")
        Project=$(curl -s -u "${SONAR_TOKEN}": "$SONAR_URL/api/ce/activity?component=${PROJECT_KEY}" | jq '.tasks[] | "\(.branch) \(.componentName)"' | grep "$GIT_BRANCH" | head -1 | awk '{print $NF}')
        analysisProject=$(echo "$Project" | tr -d "\"\`'")
        n=$((n + 1))
        sleep 60
    done

    case $analysisStatus in
    SUCCESS)
        analysisID=$(curl -s -u "${SONAR_TOKEN}": "$SONAR_URL/api/ce/activity?component=${PROJECT_KEY}" | jq '.tasks[] | "\(.branch) \(.id) \(.analysisId)"' | grep "$GIT_BRANCH" | head -1 | awk '{print $NF}')
        analysisID=$(echo "$analysisID" | tr -d "\"\`'")
        echo "Project $analysisProject is successfully analyzed against SonarQube Server => status : $analysisStatus"
        sleep 1
        echo "=> Fetching the SonarQube Qualtiy Gates Status based on the current Analysis..."
        sleep 2
        QualityGateStatus
        ;;
    CANCELED)
        analysisID=$(curl -s -u "${SONAR_TOKEN}": "$SONAR_URL/api/ce/activity?component=${PROJECT_KEY}" | jq '.tasks[] | "\(.branch) \(.id) \(.analysisId)"' | grep "$GIT_BRANCH" | head -1 | awk '{print $NF}')
        analysisID=$(echo "$analysisID" | tr -d "\"\`'")
        echo "Project $analysisProject SonarQube analysis has been cancelled against SonarQube Server => Analysis ID is $analysisID"
        sleep 1
        echo "=> Fetching the SonarQube Qualtiy Gates Status based on the Analysis..."
        retryAnalysisID
        sleep 2
        QualityGateStatus
        ;;
    FAILED)
        analysisID=$(curl -s -u "${SONAR_TOKEN}": "$SONAR_URL/api/ce/activity?component=${PROJECT_KEY}" | jq '.tasks[] | "\(.branch) \(.id) \(.analysisId)"' | grep "$GIT_BRANCH" | head -1 | awk '{print $NF}')
        analysisID=$(echo "$analysisID" | tr -d "\"\`'")
        echo "Project $analysisProject SonarQube Analysis has been failed against SonarQube Server => Analysis ID is $analysisID"
        sleep 1
        echo "=> Fetching the SonarQube Qualtiy Gates Status based on the Analysis..."
        retryAnalysisID
        sleep 2
        QualityGateStatus
        ;;
    *)
        echo "Analysis Status: $analysisStatus"
        echo "Project Status: $analysisProject"
        echo "=> Value of Analysis ID and Project Status is Null"
        RED='\033[0;31m'
        echo -e "${RED}   Possible Reasons for no action: 
              1. SonarQube build Scan is not scanned against the Same sonar project key defined in this action
              2. Sonar publishing the scan report against sonar server failed, please verify"
        ;;
    esac
}

for i in "$@"; do
    case $i in
    --sonar-url=*)
        SONAR_URL="${i#*=}"
        shift
        ;;
    --project-key=*)
        PROJECT_KEY="${i#*=}"
        shift
        ;;
    --sonar-token=*)
        SONAR_TOKEN="${i#*=}"
        shift
        ;;
    --branch=*)
        GIT_BRANCH="${i#*=}"
        shift
        ;;
    --help)
        usage
        ;;
    *)
        die "$i is not a supported option, exiting..."
        ;;
    esac
done

[ -z "$SONAR_URL" ] && die "pass SONAR_URL with --sonar-url=<SONAR_URL> switch, exiting...."
[ -z "$SONAR_TOKEN" ] && die "pass SONAR_TOKEN with --sonar-token=<SONAR_TOKEN> switch, exiting...."
[ -z "$PROJECT_KEY" ] && die "pass PROJECT_KEY with --project-key=<PROJECT_KEY> switch, exiting...."
[ -z "$GIT_BRANCH" ] && die "pass GIT_BRANCH with --branch=<GIT_BRANCH> switch, exiting..."

sonarAnalysisStatus
