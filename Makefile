PROJECT="github.com/nornir-automation/gornir"
GOLANGCI_LINT_VER="v1.17"
.DEFAULT_GOAL := help

.PHONY: tests lint godoc
tests: ## Run Go test tool
	go test -v ./... -coverprofile=coverage.txt -covermode=atomic

lint: ## Run Go linters in a Docker container
	docker run \
		--rm \
		-v $(PWD):/go/src/$(PROJECT) \
		-w /go/src/$(PROJECT) \
		-e GO111MODULE=on \
		-e GOPROXY=https://proxy.golang.org \
		golangci/golangci-lint:$(GOLANGCI_LINT_VER) \
			golangci-lint run

test-suite:
ifeq ($(TEST_SUITE),unit)
	make tests
else ifeq ($(TEST_SUITE),examples)
	make test-examples
else ifeq ($(TEST_SUITE),lint)
	make lint
else
	echo "I don't know what '$(TEST_SUITE)' means"
endif

start-dev-env: ## Create a development enviroment
	docker-compose up -d

stop-dev-env: ## Bring down the development enviroment
	docker-compose down

example: ## Run a given example
	docker-compose run gornir \
		go run /go/src/github.com/nornir-automation/gornir/examples/$(EXAMPLE)/main.go

godoc: ## Run Go Docs in a container in port 6060
	docker-compose run -p 6060:6060 gornir \
		godoc -http 0.0.0.0:6060 -v

test-example: ## Check example output changes
	docker-compose run gornir \
		go run /go/src/github.com/nornir-automation/gornir/examples/$(EXAMPLE)/main.go > examples/$(EXAMPLE)/output.txt
	git diff --exit-code examples/$(EXAMPLE)/output.txt

_test-examples:
	# not super proud but we run it twice because sometimes the order of the
	# auth methods change causing the error of dev5 to be slightly different
	make test-example EXAMPLE=1_simple || make test-example EXAMPLE=1_simple
	make test-example EXAMPLE=2_simple_with_filter || make test-example EXAMPLE=2_simple_with_filter
	make test-example EXAMPLE=2_simple_with_filter_bis || make test-example EXAMPLE=2_simple_with_filter_bis
	make test-example EXAMPLE=3_grouped_simple || make test-example EXAMPLE=3_grouped_simple
	make test-example EXAMPLE=4_advanced_1 || make test-example EXAMPLE=4_advanced_1
	make test-example EXAMPLE=5_advanced_2 || make test-example EXAMPLE=5_advanced_2

test-examples: start-dev-env _test-examples stop-dev-env

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
