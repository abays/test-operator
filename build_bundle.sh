#!/bin/bash

VERSION=${1:-"latest"}
REPO=${2:-"quay.io/abays"}
OP_NAME=${3:-"test-operator"}
IMG="$REPO/$OP_NAME":$VERSION
BUNDLE_IMG=$IMG
INDEX_IMG="$REPO/$OP_NAME-index:$VERSION"

make manager
make manifests
make generate
VERSION=${VERSION} IMG=${IMG} make bundle
yq '. | .spec.installModes=[{"type":"OwnNamespace","supported":true},{"type":"SingleNamespace","supported":true},{"type":"MultiNamespace","supported":true},{"type":"AllNamespaces","supported":true}]' \
config/manifests/bases/${OP_NAME}.clusterserviceversion.yaml -yri
VERSION=${IMG} BUNDLE_IMG=${BUNDLE_IMG} make bundle-build
podman push ${BUNDLE_IMG}
yq '. | .spec.replaces=""'  bundle/manifests/${OP_NAME}.clusterserviceversion.yaml -yri
opm index add --bundles ${BUNDLE_IMG} --tag ${INDEX_IMG} -u podman
podman push ${INDEX_IMG}