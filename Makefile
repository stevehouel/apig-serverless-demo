SHELL:=/bin/bash
PY_VERSION := 3.8

BASE := $(shell /bin/pwd)
VENV_DIR := $(BASE)/.venv

PYTHON := $(shell /usr/bin/which python$(PY_VERSION))
VIRTUALENV := $(PYTHON) -m venv

export PYTHONUNBUFFERED := 1
export PATH := var:$(PATH):$(VENV_DIR)/bin
export DEBUG_LOG := true

export AWS_SAM_LOCAL := true
export WEBACL_ID := 769eb98f-bbf6-46a6-81a6-7e1c5a0fb172

.DEFAULT_GOAL := lint
.PHONY: lint test upload clean bootstrap

PROJECT_NAME ?= sample-app
STAGE_NAME ?= dev
AWS_REGION ?= eu-west-1
SWAGGER_FILE="specs/swagger.yaml"


PIPELINE_CFN_PARAMS := ProjectName=$(PROJECT_NAME) \
        StageName=$(STAGE_NAME) \

CFN_PARAMS := ProjectName=$(PROJECT_NAME) \
		StageName=$(STAGE_NAME) \
		DebugLog=$(DEBUG_LOG) \
		WebAclId=$(WEBACL_ID)

TAGS_PARAMS := "project"="${PROJECT_NAME}" \
        "owner"="houes" \
        "environment"=$(STAGE_NAME)

PIPELINE_TAGS_PARAMS := "project"="${PROJECT_NAME}-pipeline" \
        "owner"="houes" \
        "environment"=$(STAGE_NAME)

build:
	sam build

build-container:
	sam build --use-container

copy-specs:
	aws s3 cp ${SWAGGER_FILE} s3://s3-${AWS_REGION}-${PROJECT_NAME}-${STAGE_NAME}-build-resources/$(SWAGGER_FILE) \
		--region $(AWS_REGION)

package:
	sam package \
		--s3-bucket s3-${AWS_REGION}-${PROJECT_NAME}-${STAGE_NAME}-build-resources \
		--output-template-file packaged.yaml

deploy-pipeline:
	aws cloudformation deploy \
		--template-file cfn/pipeline.yaml \
		--stack-name ${PROJECT_NAME}-${STAGE_NAME}-pipeline \
		--parameter-overrides $(PIPELINE_CFN_PARAMS) \
		--capabilities CAPABILITY_NAMED_IAM \
		--region $(AWS_REGION) \
		--tags $(PIPELINE_TAGS_PARAMS)

deploy:
	sam deploy \
		--template-file packaged.yaml \
		--stack-name ${PROJECT_NAME}-${STAGE_NAME} \
		--parameter-overrides $(CFN_PARAMS) \
		--capabilities CAPABILITY_NAMED_IAM \
		--region $(AWS_REGION) \
		--tags $(TAGS_PARAMS)

delete:
	aws cloudformation delete-stack \
        --stack-name $(PROJECT_NAME)-${STAGE_NAME} \
        --region $(AWS_REGION)

release:
	@make build
	@make package
	@make deploy

output:
	aws cloudformation describe-stacks \
		--stack-name ${PROJECT_NAME}-${STAGE_NAME} \
		--query 'Stacks[].Outputs'
