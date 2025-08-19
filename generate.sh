#!/bin/sh

set -e 

mint bootstrap
protoc --plugin="$(mint which apple/swift-protobuf)" ./Sources/VarioqubAppMetricaAdapter/Protobuf/*.proto  --swift_out  .
