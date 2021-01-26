#!/bin/bash

set -e

cd "$(dirname "$0")"

DIR=$PWD

function generate_proto() {
  protoc --go_out=plugins=grpc,paths=source_relative:. \
    -I . \
    -I ./third_party/googleapis \
    -I ./third_party/grpc-gateway \
    ./server/api/*.proto
}

function generate_grpcgateway() {
  protoc --grpc-gateway_out=logtostderr=true,paths=source_relative:. \
    -I . \
    -I ./third_party/googleapis \
    -I ./third_party/grpc-gateway \
    ./server/api/*.proto
}


function generate_swagger_json() {
  protoc --swagger_out=logtostderr=true:. \
    -I . \
    -I ./third_party/googleapis \
    -I ./third_party/grpc-gateway \
    ./server/api/*.proto
}

# Manually go-embed the swagger into a go file.
function generate_swagger_goembed() {
  # This is quite hacky -- we should use go-bindata or even go generate. For now,
  # it's mega simple. See https://github.com/otrego/clamshell/issues/40
  SWAG_GO="./server/api/api.swagger.go"
  SWAG_JSON="./server/api/api.swagger.json"
  echo '// ---- Do not edit! This file was autogenerated by regenerate-proto.sh ----' > "${SWAG_GO}"
  echo '' >> "${SWAG_GO}"
  echo 'package api' >> "${SWAG_GO}"
  echo '' >> "${SWAG_GO}"
  echo '// Swagger contains embedded swagger data.' >> "${SWAG_GO}"
  echo 'const Swagger = `' >> "${SWAG_GO}"
  cat "${SWAG_JSON}" | sed 's/`/'"'"'/g' >> "${SWAG_GO}"
  echo '`' >> "${SWAG_GO}"

  # Remove the swagger.json file; we don't need it since it's embedded in a
  # go-file.
  rm "${SWAG_JSON}"
}

generate_proto
generate_grpcgateway
generate_swagger_json
generate_swagger_goembed
