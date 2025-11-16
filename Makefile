include Makefile.inc
SUDO=sudo
DOCKER=docker
BUNDLE=./bin/bundle
RAILS=./bin/rails
RUBY=ruby
COMPOSE_FILE=compose.dev.yml

all: help

setup:
	$(Q)echo "🧱 Installing dependencies..."
	$(Q)$(RUBY) ./bin/setup

up:
	$(Q)echo "🚀 Starting Docker environment..."
	$(Q)$(DOCKER) compose -f $(COMPOSE_FILE) up -d

down:
	$(Q)$(DOCKER) compose -f $(COMPOSE_FILE) down

dev:
	$(Q)echo "🚀 Starting the development environment..."
	$(Q)$(SHELL) ./bin/dev

lint:
	$(Q)$(BUNDLE) exec rubocop

test:
	$(Q)echo "🧪 Testing..."
	$(Q)$(RAILS) test

test-integration:
	$(Q)echo "🧪 Integration testing..."
	$(Q)$(RAILS) test:integration

test-system:
	$(Q)echo "🧪 System testing..."
	$(Q)$(RAILS) test:system

cisim:
	$(Q)echo "Simulating a CI run..."
	$(Q)act

help:
	@echo "up                 -   Start the Docker development environment"
	@echo "dev                -   Start the application in development mode"
	@echo "down               -   Stop the Docker development environment"
	@echo "lint               -   Lint the current source code"
	@echo "test               -   Run the unit tests"
	@echo "test-integration   -   Run the integration tests"
	@echo "test-system        -   Run the system tests"
	@echo "cisim              -   Run the CI locally for a proper CI simulation"

.PHONY: all up dev down test test-watch cisim help
