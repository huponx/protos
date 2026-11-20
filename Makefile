# Generate the stubs into the local protogen checkout (../protogen) so that the services can
# use them through go.work without a release.
#
#   make go                  Go stubs -> ../protogen/go   (then go mod tidy there)
#   make all                 every language
#   make go PROTO_REF=v2.0.0 Go v2 layout -> ../protogen/go/v2
PROTOGEN_DIR ?= ../protogen
PROTO_REF    ?= v0.0.0
GO           ?= go

export PROTO_DIR := $(CURDIR)
export PROTOGEN_DIR
export PROTO_REF

.PHONY: help go java scala rust all lint tidy

help:
	@printf '%s\n' \
		'go     generate Go stubs into $(PROTOGEN_DIR)/go and go mod tidy' \
		'java   generate Java stubs' \
		'scala  generate Scala stubs' \
		'rust   generate Rust stubs' \
		'all    every language' \
		'lint   buf lint' \
		'tidy   go mod tidy in $(PROTOGEN_DIR)/go' \
		'' \
		'PROTOGEN_DIR=$(PROTOGEN_DIR)  PROTO_REF=$(PROTO_REF)'

lint:
	buf lint

go: lint
	scripts/generate.sh go
	$(MAKE) tidy

tidy:
	cd $(PROTOGEN_DIR)/go && $(GO) mod tidy

java scala rust: lint
	scripts/generate.sh $@

all: go java scala rust
