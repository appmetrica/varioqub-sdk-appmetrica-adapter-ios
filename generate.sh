#!/bin/sh

set -e 

protoc ./Sources/VarioqubAppMetricaAdapter/Protobuf/*.proto  --swift_out  .
