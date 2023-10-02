#!/usr/bin/env bash
# NOTE: This bash script will be placed on the host which will run the CI Testing.
# CAPTURE START TIME

# Get environment variables from files in ./.env/*
APP_PATH="$(dirname "$(readlink -f "$0")")"
FILES="${APP_PATH}/.env/*"
for f in $FILES; do
    export $(grep -v '^#' ${f} | xargs)
done


export RESULTS_START=$(date +%Y-%m-%d_%H-%M-%S)

# Setup Variables
# RESULTS_DIR should be owned by the user running the tests and can be set with
# the environment variable TEST_RESULTS with the default being /results/ci
export RESULTS_DIR="${TEST_RESULTS:-/ci/results}"
export RESULTS_PATH="${RESULTS_DIR}/${RESULTS_START}"
export RESULTS_COV="${RESULTS_PATH}/coverage"
export RESULTS_LOG="${RESULTS_PATH}/log"
export RESULTS_FINISH="${RESULTS_PATH}/finished"
export RESULTS_LATEST="${RESULTS_DIR}/latest"


# Check if RESULTS_DIR exists and create directory structure if it does not exist.
if [ ! -d "${RESULTS_PATH}" ]; then
    mkdir -p "${RESULTS_PATH}" "${RESULTS_PATH}/log" || \
        { echo "Cannot create ${RESULTS_DIR}"; exit 1; }
fi

# Delete old copy of repository in case of a previous failure
if [ -d "/ci/.blogindex" ]; then
    rm -rf /ci/.blogindex
fi

git clone https://github.com/blogindex/blogindex.xyz /ci/.blogindex
cd /ci/.blogindex
cp /ci/.env /ci/.blogindex/
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt | tee ${RESULTS_LOG}/pip.txt
./test.sh | tee ${RESULTS_LOG}/pytest.txt || \
    { echo "PyTest Failed"; exit 1; }

if [ -d "./htmlcov" ]; then
    echo "Copying htmlcov to $RESULTS_COV"
    mv htmlcov "${RESULTS_COV}"
fi

if [ -f "/ci/results/lastrun-log.txt" ]; then
    cp /ci/results/lastrun-log.txt ${RESULTS_LOG}/full.txt
fi

if [ -d "${RESULTS_COV}" ]; then
    echo "results are available at https://results.blogindex.dev/${RESULTS_COV}"
else
    echo "An unknown error has occurred. Coverage Test Results are not available for this test."
fi
rm -rf /ci/.blogindex