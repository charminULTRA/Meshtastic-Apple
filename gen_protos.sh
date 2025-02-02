#!/bin/bash

# simple sanity checking for repo
if [ ! -d "../protobufs/meshtastic" ]; then
  echo "Please check out the https://github.com/meshtastic/protobufs parent directory."
  exit
fi

# simple sanity checking for executable
if [ ! -x "`which protoc`" ]; then
  echo "Please install swift-protobuf by running: brew install swift-protobuf"
  exit
fi

if [ ! -x "`which gsed`" ]; then
  echo "Please install gnu-sed by running: brew install gnu-sed"
  exit
fi

pdir=$(realpath "../protobufs/meshtastic")
sdir=$(realpath "./Meshtastic/Protobufs")

gsed -i 's/import "meshtastic\//import "/g' ../protobufs/meshtastic/*
gsed -i 's/package meshtastic;//g' ../protobufs/meshtastic/*

echo "pdir:$pdir sdir:$sdir"
pfiles="admin.proto apponly.proto cannedmessages.proto channel.proto config.proto device_metadata.proto deviceonly.proto localonly.proto mesh.proto module_config.proto mqtt.proto portnums.proto remote_hardware.proto rtttl.proto storeforward.proto telemetry.proto xmodem.proto"
for pf in $pfiles
do
  echo "Generating $pf..."
  protoc --swift_out=${sdir} --proto_path=${pdir} $pf
done
echo "Done generating the swift files from the proto files."
echo "Build, test, and commit changes."

cd ../protobufs/meshtastic && git reset --hard
