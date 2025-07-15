#!/bin/bash

checks-googlecloud-check-cloudbuild \
  ${GO_REVISION_SNUBA_REPO} \
  sentryio \
  "us-central1-docker.pkg.dev/sentryio/snuba/image"
