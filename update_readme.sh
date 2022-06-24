#!/bin/sh

cd $(git rev-parse --show-toplevel)

AUTO_PLUGIN_NAME=$(ls kong/plugins)

PLUGIN_NAME=${1:-$AUTO_PLUGIN_NAME}
KONG_SCHEMA_ENDPOINT=${2:-http://172.17.0.1:8001/schemas/plugins/}
KONG_PLUGIN_METADATA_ENDPOINT=${3:-http://172.17.0.1:7999}

BEGIN=$(nl -ba README.md | grep 'BEGINNING OF KONG-PLUGIN DOCS HOOK' | awk '{print $1}')
END=$(nl -ba README.md | grep 'END OF KONG-PLUGIN DOCS HOOK' | awk '{print $1}')

head -n${BEGIN} README.md > README-B
tail -n +${END} README.md > README-E

podman run --rm leandrocarneiro/kong-plugin-schema-to-markdown:next ${PLUGIN_NAME} ${KONG_SCHEMA_ENDPOINT} ${KONG_PLUGIN_METADATA_ENDPOINT} >> README-B

cat README-B README-E > README.md
rm -f README-B README-E

cd - 2>&1 > /dev/null