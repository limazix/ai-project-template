SHELL:=/bin/bash
PYTHON_RUNNER=poetry run

MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
ROOT_DIR := $(dir $(MAKEFILE_PATH))

IMAGE_NAME=hub
CONTAINER_RUNNER=podman

PYTHON_TOOLS=tools
PYTHON_TESTS=tests
PYTHON_SCRIPTS=$(PYTHON_TOOLS) $(PYTHON_TESTS)

install:
	@poetry install

update:
	@poetry update

clean:
	@poetry cache clean

lint:
	@$(PYTHON_RUNNER) black $(PYTHON_SCRIPTS) --check
	@$(PYTHON_RUNNER) flake8 $(PYTHON_SCRIPTS) --statistics

test:
	@$(PYTHON_RUNNER) pytest

test-watch:
	@$(PYTHON_RUNNER) pytest -f

coverage:
	@$(PYTHON_RUNNER) pytest --cov=$(PYTHON_TOOLS)

serve-docs:
	@$(PYTHON_RUNNER) pydoc-markdown --server --open

build-docs:
	@$(PYTHON_RUNNER) pydoc-markdown --build --site-dir=gh-pages

deploy-docs:
	@mv ./build/docs/gh-pages .
	@git add .
	@git commit -am"it generates github static page"
	@git push origin `git subtree split --prefix gh-pages main`:gh-pages --force
	@git reset --hard HEAD~

build-hub:
	@poetry export -f requirements.txt -o requirements.txt
	@$(CONTAINER_RUNNER) build -f docker/jupyter-lab.dockerfile -t $(IMAGE_NAME) .
	@rm requirements.txt
	
run-hub:
	@$(CONTAINER_RUNNER) run -it --rm -p 8888:8888 \
		-v $(ROOT_DIR)/notebooks/:/home/jovyan/work/notebooks \
		-v $(ROOT_DIR)/data/:/home/jovyan/work/data \
		-v $(ROOT_DIR)/tools/:/home/jovyan/work/tools \
		-w /home/jovyan/work \
		--security-opt label=desable \
		$(IMAGE_NAME) jupyter lab

serve:
	@mkdir -p ./build/s3
	@mkdir -p ./build/dbdata
	@poetry run podman-compose down
	@poetry run podman-compose build
	@poetry run podman-compose up