#!/bin/bash

jsonnet -J .venv/lib/python3.11/site-packages/static/vendor/ \
	./jsonnet_manifest/snuba.jsonnet |\
	jq -c '.[]' | \
    while read -r resource; \
    do \
        echo "$resource" | yq -P; echo "---"; \
    done > ./jsonnet_manifest/materialized/snuba.yaml