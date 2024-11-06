#!/bin/bash

/devinfra/scripts/checks/githubactions/checkruns.py \
  --timeout-mins 60 \
  getsentry/snuba \
  ${GO_REVISION_SNUBA_REPO} \
  "Tests and code coverage (test)"
