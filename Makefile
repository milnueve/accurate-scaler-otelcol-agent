OTELCOL_BUILDER_VERSION ?= 0.116.0
UPX_PACKER_VERSION ?= 4.2.4
BIN_DIR ?= ${HOME}/bin
OTELCOL_BUILDER ?= ${BIN_DIR}/ocb
UPX_PACKER ?= ${BIN_DIR}/upx

ci: build
	@./test/test.sh

build: go ocb upx
	@./bin/build.sh -b ${OTELCOL_BUILDER} -u ${UPX_PACKER} -v ${OTELCOL_BUILDER_VERSION}

generate-sources: go ocb upx
	@./bin/build.sh -s true -b ${OTELCOL_BUILDER} -u ${UPX_PACKER} -v ${OTELCOL_BUILDER_VERSION}

.PHONY: ocb
ocb:
ifeq (, $(shell command -v ocb 2>/dev/null))
	@{ \
	[ ! -x '$(OTELCOL_BUILDER)' ] || exit 0; \
	set -e ;\
	os=$$(uname | tr A-Z a-z) ;\
	machine=$$(uname -m) ;\
	[ "$${machine}" != x86_64 ] || machine=amd64 ;\
	echo "Installing ocb ($${os}/$${machine}) at $(BIN_DIR)" ;\
	mkdir -p $(BIN_DIR) ;\
	curl -sLo $(OTELCOL_BUILDER) "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/cmd/builder/v${OTELCOL_BUILDER_VERSION}/ocb_${OTELCOL_BUILDER_VERSION}_$${os}_$${machine}" ;\
	chmod +x $(OTELCOL_BUILDER) ;\
	}
else
OTELCOL_BUILDER=$(shell command -v ocb)
endif

.PHONY: upx
upx:
ifeq (, $(shell command -v upx 2>/dev/null))
	@{ \
	[ ! -x '$(UPX_PACKER)' ] || exit 0; \
	set -e ;\
	os=$$(uname | tr A-Z a-z) ;\
	machine=$$(uname -m) ;\
	[ "$${machine}" != x86_64 ] || machine=amd64 ;\
	echo "Installing upx ($${os}/$${machine}) at $(BIN_DIR)" ;\
	mkdir -p $(BIN_DIR) ;\
	curl -sLo "upx-${UPX_PACKER_VERSION}-$${machine}_$${os}.tar.xz" "https://github.com/upx/upx/releases/download/v${UPX_PACKER_VERSION}/upx-${UPX_PACKER_VERSION}-$${machine}_$${os}.tar.xz" ;\
	tar xfJ "upx-${UPX_PACKER_VERSION}-$${machine}_$${os}.tar.xz" ;\
	mv "upx-${UPX_PACKER_VERSION}-$${machine}_$${os}/upx" "${BIN_DIR}" ;\
	rm -rf "upx-${UPX_PACKER_VERSION}-$${machine}_$${os}" "upx-${UPX_PACKER_VERSION}-$${machine}_$${os}.tar.xz" ;\
	chmod +x $(UPX_PACKER) ;\
	}
else
UPX_PACKER=$(shell command -v upx)
endif

.PHONY: go
go:
	@{ \
		if ! command -v go >/dev/null 2>/dev/null; then \
			echo >&2 'go command not found. Please install golang. https://go.dev/doc/install'; \
			exit 1; \
		fi \
	}
