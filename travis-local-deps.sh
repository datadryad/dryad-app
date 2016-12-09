#!/usr/bin/env bash

BRANCH=$(git rev-parse --abbrev-ref HEAD)
ENGINES_DIR=../stash_engines

mkdir ${ENGINES_DIR} && \
  cd ${ENGINES_DIR} && \
  git clone https://github.com/CDLUC3/stash_engine.git && \
  cd stash_engine && \
  git checkout ${BRANCH}



