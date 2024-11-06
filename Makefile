.PHONY: venv
venv:
	python -m venv .venv
	source .venv/bina/activate
	pip install -r requirements.txt

.PHONY: render
render:
	jsonnet -J .venv/lib/python3.11/site-packages/static/vendor/ \
	./jsonnet_manifest/snuba.jsonnet

.PHONY: materialize
materialize:
	./render.sh

gocd:
	rm -rf ./gocd/generated-pipelines
	mkdir -p ./gocd/generated-pipelines
	cd ./gocd/templates && jb install && jb update
	cd ./gocd/templates && find . -type f \( -name '*.libsonnet' -o -name '*.jsonnet' \) -print0 | xargs -n 1 -0 jsonnetfmt -i
	cd ./gocd/templates && find . -type f \( -name '*.libsonnet' -o -name '*.jsonnet' \) -print0 | xargs -n 1 -0 jsonnet-lint -J ./vendor
	cd ./gocd/templates && jsonnet --ext-code output-files=true -J vendor -m ../generated-pipelines ./snuba.jsonnet
	cd ./gocd/generated-pipelines && find . -type f \( -name '*.yaml' \) -print0 | xargs -n 1 -0 yq -p json -o yaml -i
	# Remove elastic_profile_id from all yaml files in generated-pipelines to make things
	# work locally
	cd ./gocd/generated-pipelines && find . -name "*.yaml" -type f -print0 | xargs -0 -I {} sh -c 'grep -v "elastic_profile_id" "{}" > "{}.tmp" && mv "{}.tmp" "{}"'

.PHONY: gocd
