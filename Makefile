.PHONY: validate secret deploy verify evidence

validate:
	python3 tools/validate_manifests.py

secret:
	./scripts/create-secret.sh

deploy:
	./scripts/deploy.sh

verify:
	./scripts/verify.sh

evidence:
	./scripts/collect-evidence.sh

