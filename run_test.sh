#!/usr/bin/env bash
# NOTE: This bash script will be placed on the host which will run the CI Testing.

COMPOSE_FILE=/ci/blogindex/docker-compose.yml
echo "Using ${COMPOSE_FILE}"

cd /ci/blogindex || \

    { echo "ci/blogindex does not exist"; exit 1; }

# Setup Variables

# RESULTS_DIR should be owned by the user running the tests and can be set with
# the environment variable TEST_RESULTS with the default being /results/ci
export RESULTS_DIR="${TEST_RESULTS:-/ci/results}"
export RESULTS_START=$(date +%Y-%m-%d_%H-%M-%S)
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
docker compose down