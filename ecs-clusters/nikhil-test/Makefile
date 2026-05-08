SHELL := /bin/bash

# Requires Terraform
ifeq (, $(shell which terraform))
$(error "Terraform Required! No terraform in $(PATH)")
endif

# Requires AWS CLI
ifeq (, $(shell which aws))
$(error "AWS CLI Required! No aws in $(PATH)")
endif

# Configuration
APPLICATION ?= nikhil-test
ENV ?= dev
AWS_REGION ?= us-east-1

# AWS Profile Configuration
# Override with: make apply ENV=dev AWS_PROFILE=your-profile
AWS_PROFILE ?= default

# S3 Backend Configuration
TFSTATE_PROFILE ?= default
TFSTATE_REGION ?= us-east-1
TFSTATE_BUCKET ?= backstage-terraform-state
TFSTATE_KEY ?= ecs-clusters/$(APPLICATION)/terraform.tfstate
TFSTATE_DYNAMODB_TABLE ?= backstage-terraform-locks

# Terraform Variables
TFVARS_FILE ?= environments/$(ENV).tfvars

# Tags for AWS resources
TAG_MANAGED_BY ?= Key=ManagedBy,Value=Backstage
TAG_APPLICATION ?= Key=Application,Value=$(APPLICATION)
TAG_ENVIRONMENT ?= Key=Environment,Value=$(ENV)

.PHONY: help
help:
	@echo "ECS Cluster Terraform Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make init                    - Initialize Terraform"
	@echo "  make plan ENV=<env>          - Plan Terraform changes"
	@echo "  make apply ENV=<env>         - Apply Terraform changes"
	@echo "  make destroy ENV=<env>       - Destroy Terraform resources"
	@echo "  make output                  - Show Terraform outputs"
	@echo "  make validate                - Validate Terraform configuration"
	@echo "  make fmt                     - Format Terraform files"
	@echo ""
	@echo "Backend Management:"
	@echo "  make create-backend          - Create S3 bucket and DynamoDB table"
	@echo "  make show-backend            - Show backend configuration"
	@echo ""
	@echo "Workspace Management:"
	@echo "  make show-workspace          - Show current workspace"
	@echo "  make list-workspaces         - List all workspaces"
	@echo "  make select-workspace ENV=<env> - Select workspace"
	@echo ""
	@echo "Environment: $(ENV)"
	@echo "Application: $(APPLICATION)"
	@echo "Region: $(AWS_REGION)"

.PHONY: show-workspace
show-workspace:
	@echo "Current workspace: $(shell terraform workspace show)"

.PHONY: list-workspaces
list-workspaces:
	@echo "Available workspaces:"
	@terraform workspace list

.PHONY: select-workspace
select-workspace:
	@echo "Selecting workspace: $(ENV)"
	@terraform workspace select $(ENV) || terraform workspace new $(ENV)

.PHONY: init
init: create-backend-config
	@echo "Initializing Terraform..."
	@terraform init -reconfigure

.PHONY: validate
validate:
	@echo "Validating Terraform configuration..."
	@terraform validate

.PHONY: fmt
fmt:
	@echo "Formatting Terraform files..."
	@terraform fmt -recursive

.PHONY: plan
plan: select-workspace
	@echo "Planning Terraform changes for $(ENV)..."
	@if [ -f "$(TFVARS_FILE)" ]; then \
		terraform plan -var-file="$(TFVARS_FILE)" -out=plan.tfplan; \
	else \
		echo "Warning: $(TFVARS_FILE) not found, using default values"; \
		terraform plan -out=plan.tfplan; \
	fi

.PHONY: apply
apply: select-workspace
	@echo "Applying Terraform changes for $(ENV)..."
	@if [ -f "$(TFVARS_FILE)" ]; then \
		terraform apply -auto-approve -var-file="$(TFVARS_FILE)"; \
	else \
		echo "Warning: $(TFVARS_FILE) not found, using default values"; \
		terraform apply -auto-approve; \
	fi

.PHONY: apply-plan
apply-plan: select-workspace
	@echo "Applying saved plan..."
	@terraform apply plan.tfplan

.PHONY: destroy
destroy: select-workspace
	@echo "Destroying Terraform resources for $(ENV)..."
	@if [ -f "$(TFVARS_FILE)" ]; then \
		terraform destroy -auto-approve -var-file="$(TFVARS_FILE)"; \
	else \
		terraform destroy -auto-approve; \
	fi

.PHONY: output
output: select-workspace
	@terraform output

.PHONY: output-json
output-json: select-workspace
	@terraform output -json

.PHONY: refresh
refresh: select-workspace
	@echo "Refreshing Terraform state..."
	@if [ -f "$(TFVARS_FILE)" ]; then \
		terraform refresh -var-file="$(TFVARS_FILE)"; \
	else \
		terraform refresh; \
	fi

.PHONY: show
show: select-workspace
	@terraform show

.PHONY: create-backend-config
create-backend-config:
	@echo "Creating backend configuration..."
	@echo 'terraform {' > backend.tf
	@echo '  backend "s3" {' >> backend.tf
	@echo '    profile        = "$(TFSTATE_PROFILE)"' >> backend.tf
	@echo '    region         = "$(TFSTATE_REGION)"' >> backend.tf
	@echo '    bucket         = "$(TFSTATE_BUCKET)"' >> backend.tf
	@echo '    key            = "$(TFSTATE_KEY)"' >> backend.tf
	@echo '    dynamodb_table = "$(TFSTATE_DYNAMODB_TABLE)"' >> backend.tf
	@echo '    encrypt        = true' >> backend.tf
	@echo '  }' >> backend.tf
	@echo '}' >> backend.tf
	@echo "Backend configuration created in backend.tf"

.PHONY: show-backend
show-backend:
	@echo "Backend Configuration:"
	@echo "  Profile: $(TFSTATE_PROFILE)"
	@echo "  Region: $(TFSTATE_REGION)"
	@echo "  Bucket: $(TFSTATE_BUCKET)"
	@echo "  Key: $(TFSTATE_KEY)"
	@echo "  DynamoDB Table: $(TFSTATE_DYNAMODB_TABLE)"

.PHONY: create-backend
create-backend:
	@echo "Creating S3 backend infrastructure..."
	@echo "Creating S3 bucket: $(TFSTATE_BUCKET)"
	@aws s3api create-bucket \
		--profile "$(TFSTATE_PROFILE)" \
		--region "$(TFSTATE_REGION)" \
		--bucket "$(TFSTATE_BUCKET)" \
		--create-bucket-configuration LocationConstraint=$(TFSTATE_REGION) \
		|| echo "Bucket may already exist"
	@echo "Enabling versioning on S3 bucket..."
	@aws s3api put-bucket-versioning \
		--profile "$(TFSTATE_PROFILE)" \
		--region "$(TFSTATE_REGION)" \
		--bucket "$(TFSTATE_BUCKET)" \
		--versioning-configuration Status=Enabled
	@echo "Enabling encryption on S3 bucket..."
	@aws s3api put-bucket-encryption \
		--profile "$(TFSTATE_PROFILE)" \
		--region "$(TFSTATE_REGION)" \
		--bucket "$(TFSTATE_BUCKET)" \
		--server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
	@echo "Creating DynamoDB table: $(TFSTATE_DYNAMODB_TABLE)"
	@aws dynamodb create-table \
		--profile "$(TFSTATE_PROFILE)" \
		--region "$(TFSTATE_REGION)" \
		--table-name "$(TFSTATE_DYNAMODB_TABLE)" \
		--attribute-definitions AttributeName=LockID,AttributeType=S \
		--key-schema AttributeName=LockID,KeyType=HASH \
		--billing-mode PAY_PER_REQUEST \
		--tags $(TAG_MANAGED_BY) $(TAG_APPLICATION) $(TAG_ENVIRONMENT) \
		|| echo "Table may already exist"
	@echo "Backend infrastructure created successfully!"

.PHONY: clean
clean:
	@echo "Cleaning up temporary files..."
	@rm -f plan.tfplan
	@rm -f backend.tf
	@echo "Clean complete"

.PHONY: full-deploy
full-deploy: init plan apply
	@echo "Full deployment complete!"
	@make output
