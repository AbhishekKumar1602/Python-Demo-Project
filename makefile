# Settings for Docker Image and Deployment
IMAGE_REG ?= docker.io
IMAGE_REPO ?= abhishekkumar1602/flask-demo-web-application
IMAGE_TAG ?= latest

# AWS Elastic Beanstalk Deployment Settings
AWS_REGION ?= us-east-1
AWS_APP_NAME ?= python-app
AWS_ENV_NAME ?= python-app-env
AWS_BUCKET ?= your-s3-bucket-name

# Settings for API Testing
TEST_HOST ?= localhost:5000

# Directory Where Source Code is Located
SRC_DIR := src

# Define Phony Targets
.PHONY: help lint lint-fix image push run deploy undeploy clean test test-report test-api venv .EXPORT_ALL_VARIABLES
.DEFAULT_GOAL := help

# Display Help Information
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Run Linting Checks
lint: venv
	. $(SRC_DIR)/.venv/bin/activate && black --check $(SRC_DIR) && flake8 $(SRC_DIR)/app/ && flake8 $(SRC_DIR)/run.py

# Fix Linting Issues
lint-fix: venv
	. $(SRC_DIR)/.venv/bin/activate && black $(SRC_DIR)

# Build Docker Image
image:
	docker build . --file build/Dockerfile --tag $(IMAGE_REG)/$(IMAGE_REPO):$(IMAGE_TAG)

# Push Docker Image to Registry
push:
	docker push $(IMAGE_REG)/$(IMAGE_REPO):$(IMAGE_TAG)

# Run the Application Locally
run: venv
	. $(SRC_DIR)/.venv/bin/activate && python $(SRC_DIR)/run.py

# Deploy Application to AWS Elastic Beanstalk
deploy:
	aws s3 cp build/Dockerfile s3://$(AWS_BUCKET)/Dockerfile
	aws elasticbeanstalk create-application-version --application-name $(AWS_APP_NAME) \
		--version-label $(IMAGE_TAG) \
		--source-bundle S3Bucket=$(AWS_BUCKET),S3Key=Dockerfile \
		--region $(AWS_REGION)
	aws elasticbeanstalk update-environment --application-name $(AWS_APP_NAME) \
		--environment-name $(AWS_ENV_NAME) \
		--version-label $(IMAGE_TAG) \
		--region $(AWS_REGION)
	@echo "Application Deployed Successfully: https://$(AWS_ENV_NAME).elasticbeanstalk.com/"

# Undeploy Application from AWS Elastic Beanstalk
undeploy:
	@echo "WARNING! Terminating Environment: $(AWS_ENV_NAME)"
	aws elasticbeanstalk terminate-environment --environment-name $(AWS_ENV_NAME) --region $(AWS_REGION)
	@echo "WARNING! Deleting Application: $(AWS_APP_NAME)"
	aws elasticbeanstalk delete-application --application-name $(AWS_APP_NAME) --region $(AWS_REGION)

# Run Tests
test: venv
	. $(SRC_DIR)/.venv/bin/activate && pytest -v

# Generate Test Report in JUnit XML Format
test-report: venv
	. $(SRC_DIR)/.venv/bin/activate && pytest -v --junitxml=test-results.xml

# Run API Tests Using Newman
test-api: .EXPORT_ALL_VARIABLES
	cd tests && npm install newman && ./node_modules/.bin/newman run ./postman_collection.json --env-var apphost=$(TEST_HOST)

# Clean Up Generated Files and Directories
clean:
	rm -rf $(SRC_DIR)/.venv
	rm -rf tests/node_modules
	rm -rf tests/package*
	rm -rf test-results.xml
	rm -rf $(SRC_DIR)/app/__pycache__
	rm -rf $(SRC_DIR)/app/tests/__pycache__
	rm -rf .pytest_cache
	rm -rf $(SRC_DIR)/.pytest_cache

# Create Python Virtual Environment
venv: $(SRC_DIR)/.venv/touchfile

$(SRC_DIR)/.venv/touchfile: $(SRC_DIR)/requirements.txt
	@echo "Creating Python Virtual Environment..."
	python -m venv $(SRC_DIR)/.venv
	. $(SRC_DIR)/.venv/bin/activate && pip install -r $(SRC_DIR)/requirements.txt
	touch $(SRC_DIR)/.venv/touchfile
