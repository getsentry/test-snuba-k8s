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
	jsonnet -J .venv/lib/python3.11/site-packages/static/vendor/ \
	./jsonnet_manifest/snuba.jsonnet \
	> jsonnet_manifest/materialized/snuba.json
