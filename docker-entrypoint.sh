#!/usr/bin/env bash

set -ex

# use the user provided 1st parameter as the repo name, if not use: apache
CASSANDRA_REPO=${1}
[ -z "$CASSANDRA_REPO" ] && CASSANDRA_REPO='apache'

# use the user provided 2nd parameter as the branch name, if not use: trunk
CASSANDRA_BRANCH=${2}
[ -z "$CASSANDRA_BRANCH" ] && CASSANDRA_BRANCH='trunk'

# run a specific dtest, if defined
# if a specific dtest is not requested, also run in-Cassandra-source unit tests
SPECIFIC_DTEST=${3}
[ -z "$SPECIFIC_DTEST" ] && RUN_UNIT_TESTS='test'

# if only running unit tests, activate the unit tests
[[ -v ONLY_UNIT_TESTS ]] && RUN_UNIT_TESTS='test'

# shallow clone the Github repo
git clone https://github.com/${CASSANDRA_REPO}/cassandra.git \
    --branch ${CASSANDRA_BRANCH} \
    --single-branch \
    --depth 1

# build the jar and optionally run the in-Cassandra-source unit tests
cd ${CASSANDRA_DIR}
time ant \
    clean \
    jar \
    ${RUN_UNIT_TESTS}

if [[ ! ${ONLY_UNIT_TESTS} ]]
then
    # run vnode and non-vnode dtests
    cd ${WORKDIR}/cassandra-dtest
    PRINT_DEBUG=true
    time nosetests -x -s -v --with-flaky \
        ${SPECIFIC_DTEST}
    time ./run_dtests.py \
        --vnodes false \
        --nose-options "-x -s -v" \
        ${SPECIFIC_DTEST}
fi