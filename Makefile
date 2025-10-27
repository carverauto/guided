# Helper targets for building images and deploying Guided.dev

REPO_ROOT := $(CURDIR)

# Image tags
STAGING_TAG ?= staging
PROD_TAG ?= prod

GHCR_IMAGE := ghcr.io/carverauto/guided/web
PG_IMAGE := ghcr.io/carverauto/guided/postgres-age

.PHONY: image-build-staging image-build-prod image-push-staging image-push-prod
image-build-staging:
	./scripts/docker/build_release_image.sh $(STAGING_TAG)

image-build-prod:
	./scripts/docker/build_release_image.sh $(PROD_TAG)

image-push-staging:
	./scripts/docker/build_release_image.sh $(STAGING_TAG) --push

image-push-prod:
	./scripts/docker/build_release_image.sh $(PROD_TAG) --push

.PHONY: postgres-image-build postgres-image-push
postgres-image-build:
	./scripts/docker/build_postgres_age_image.sh latest

postgres-image-push:
	./scripts/docker/build_postgres_age_image.sh latest --push

.PHONY: seal-staging seal-prod
seal-staging:
	./scripts/k8s/seal_secrets.sh staging

seal-prod:
	./scripts/k8s/seal_secrets.sh prod

.PHONY: deploy-dev deploy-staging deploy-prod
deploy-dev:
	kubectl apply -k k8s/dev

deploy-staging:
	kubectl apply -k k8s/staging

deploy-prod:
	kubectl apply -k k8s/prod

.PHONY: smoke-staging smoke-prod
smoke-staging:
	./scripts/k8s/smoke_mcp.sh --ingress-host staging.guided.dev

smoke-prod:
	./scripts/k8s/smoke_mcp.sh --ingress-host guided.dev

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  image-build-staging   Build the staging release image"
	@echo "  image-build-prod      Build the production release image"
	@echo "  image-push-staging    Build and push staging image to GHCR"
	@echo "  image-push-prod       Build and push production image to GHCR"
	@echo "  seal-staging          Generate sealed secrets for staging"
	@echo "  seal-prod             Generate sealed secrets for production"
	@echo "  deploy-dev            Apply dev overlay to current kube-context"
	@echo "  deploy-staging        Apply staging overlay"
	@echo "  deploy-prod           Apply production overlay"
	@echo "  smoke-staging         Run MCP smoke test against staging"
	@echo "  smoke-prod            Run MCP smoke test against production"
