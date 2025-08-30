# Makefile for Terraform AWS VPC + EC2 project

# Variables
TF=terraform

.PHONY: init fmt validate plan apply destroy check

# Initialise Terraform (downloads providers, sets up backend)
init:
	$(TF) init

# Format code for consistency
fmt:
	$(TF) fmt -recursive

# Validate syntax and catch errors
validate:
	$(TF) validate

# Show execution plan (after formatting + validation)
plan: fmt validate
	$(TF) plan

# Apply changes (build infra) - auto approve for speed
apply: fmt validate
	$(TF) apply -auto-approve

# Destroy infra (CLEANUP - always run after testing)
destroy:
	$(TF) destroy -auto-approve

# Pre-flight checks (for CI/CD or local dev)
# - check formatting
# - validate configuration
check:
	$(TF) fmt -check -recursive
	$(TF) validate
