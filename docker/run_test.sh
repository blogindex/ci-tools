#!/usr/bin/env bash
# NOTE: This bash script will be placed on the host which will run the CI Testing.
env_start=$(env)
# CAPTURE START TIME
export RESULTS_START=$(date +%Y-%m-%d_%H-%M-%S)

# Set some ENV variables to make it succeed.
OLD_HOME="${HOME}"
export HOME="/home/beardedtek"
OLD_TERM="${TERM}"
export TERM=xterm-256color
OLD_SHLVL="${SHLVL}"
export SHLVL=2
export SSH_TTY="/dev/pts/1"

cd /ci/blogindex || \
    { echo "ci/blogindex does not exist"; exit 1; }

# Setup Variables
# RESULTS_DIR should be owned by the user running the tests and can be set with
# the environment variable TEST_RESULTS with the default being /results/ci
export RESULTS_DIR="${TEST_RESULTS:-/ci/results}"
export RESULTS_PATH="${RESULTS_DIR}/${RESULTS_START}"
export RESULTS_COV="${RESULTS_PATH}/coverage"
export RESULTS_LOG="${RESULTS_PATH}/log"
export RESULTS_FINISH="${RESULTS_PATH}/finished"
export RESULTS_LATEST="${RESULTS_DIR}/latest"

echo "#########################################"
echo "#########################################"
echo "#########################################"
echo "RESULTS_START: ${RESULTS_START}"
echo "RESULTS_PATH: ${RESULTS_PATH}"
echo "RESULTS_COV: ${RESULTS_COV}"
echo "RESULTS_LOG: ${RESULTS_LOG}"
echo "RESULTS_FINISH: ${RESULTS_FINISH}"
echo "RESULTS_LATEST:${RESULTS_LATEST}"
echo "#########################################"
echo "#########################################"
echo "#########################################"

# Check if RESULTS_DIR exists and create directory structure if it does not exist.
if [ ! -d "${RESULTS_PATH}" ]; then
    mkdir -p "${RESULTS_PATH}" || \
        { echo "Cannot create ${RESULTS_DIR}"; exit 1; }
fi
echo $env_start | tee ${RESULTS_LOG}-env_start.txt
env | tee ${RESULTS_LOG}-env_pre-docker-compose.txt

# Make sure old containers are not running
echo "Shutting down old instances and removing orphan containers."
docker compose down
# Build container to contain the latest code
echo "Building test container"
docker compose build
# Start container and output logs to stdout and RESULTS_LOG
echo "Starting test container"
docker compose up -d
docker compose logs -f &
# CI Contaner will create RESULTS_FINISH upon completion of testing
# Wait for it and bring it all down
while [ ! -f "${RESULTS_FINISH}" ]; do
    sleep 5
done
docker compose logs apitest_db | tee ${RESULTS_LOG}-db.txt
docker compose logs apitest | tee ${RESULTS_LOG}-api.txt
env | tee ${RESULTS_LOG}-env_end.txt
docker compose down

# Set back old ENV Vars
export 