#!/usr/bin/env bash

AGENT_VERSION=0.0.1
REPO_DIR="$( cd "$(dirname $( dirname "${BASH_SOURCE[0]}" ))" &> /dev/null && pwd )"
BUILDER=''
BUILDER_VERSION=''

# default values
skipcompilation=false

while getopts s:b:u:v: flag
do
  case "${flag}" in
    s) skipcompilation=${OPTARG};;
    b) BUILDER=${OPTARG};;
    u) PACKER=${OPTARG};;
    v) BUILDER_VERSION=${OPTARG};;
  esac
done

[[ -n "$BUILDER" ]] || BUILDER='ocb'
[[ -n "$PACKER" ]] || PACKER='upx'
[[ -n "$BUILDER_VERSION" ]] || BUILDER_VERSION='0.116.0'

if [[ "$skipcompilation" = true ]]; then
  echo "Skipping the compilation, we'll only generate the sources."
fi

mkdir -p ${REPO_DIR}/distributions
pushd "${REPO_DIR}/distributions" > /dev/null

cat > ./builder-config.yaml <<-EOF
dist:
  name: accurate-scaler-otelcol-agent
  description: Basic OTel Collector Agent for AccurateScaler
  output_path: ./accurate-scaler-otelcol-agent
  version: $AGENT_VERSION
  debug_compilation: false
extensions:
  # Extension used for authentication purposes following a Client Credentials Grant OAuth flow.
  # See RFC 6479, section 4.4: https://datatracker.ietf.org/doc/html/rfc6749#section-4.4.
  - gomod: github.com/open-telemetry/opentelemetry-collector-contrib/extension/oauth2clientauthextension v$BUILDER_VERSION
receivers:
  # Receiver used to scrape Prometheus-compatible metrics' publishers.
  - gomod: github.com/open-telemetry/opentelemetry-collector-contrib/receiver/prometheusreceiver v$BUILDER_VERSION
processors:
  # Processor used to batch metric deliveries.
  - gomod: go.opentelemetry.io/collector/processor/batchprocessor v$BUILDER_VERSION
  # Processor used to add context information to collected metrics as labels.
  - gomod: github.com/open-telemetry/opentelemetry-collector-contrib/processor/metricstransformprocessor v$BUILDER_VERSION
exporters:
  # OTel Collector OTLP GRPC exporter.
  - gomod: go.opentelemetry.io/collector/exporter/otlpexporter v$BUILDER_VERSION
  # OTel Collector OTLP HTTP exporter.
  - gomod: go.opentelemetry.io/collector/exporter/otlphttpexporter v$BUILDER_VERSION
EOF

echo "Building AccurateScaler OTel Collector Agent"
echo "Using Builder: $(command -v "$BUILDER") ($($BUILDER version | head -1))"
echo "Using Go: $(command -v go) ($(go version | head -1))"
echo "Using Upx: $(command -v "$PACKER") ($($PACKER -V | head -1))"

if "$BUILDER" --skip-compilation=${skipcompilation} --config builder-config.yaml > build.log 2>&1; then
  if [[ "$skipcompilation" != true ]]; then
    if "$PACKER" --best ./accurate-scaler-otelcol-agent/accurate-scaler-otelcol-agent > pack.log 2>&1; then
      echo "✅ Agent successfully built and packed."
    else
      echo "❌ ERROR: failed to pack the agent executable."
      echo "🪵 Pack logs'"
      echo "----------------------"
      cat pack.log
      echo "----------------------"
      exit 1
    fi
  else
    echo "✅ Agent sources successfully generated."
  fi
else
  echo "❌ ERROR: failed to build the agent."
  echo "🪵 Build logs'"
  echo "----------------------"
  cat build.log
  echo "----------------------"
  exit 1
fi

popd > /dev/null
