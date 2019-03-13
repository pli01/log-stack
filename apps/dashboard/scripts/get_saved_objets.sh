#!/bin/bash
KIBANA_URL="http://172.16.4.5/kibana"
# get object id
objects="search visualization dashboard index-pattern"
for obj in $objects ; do 
local val=$(curl -sSL -X GET -H "Content-Type: application/json" -H "kbn-xsrf: true"  "${KIBANA_URL}/api/saved_objects/${obj}/" | jq -r '.saved_objects[]| "\(.type + " " + .id  + " \"" + .attributes.title + "\"")"')
eval $(echo "${obj}_id=\"${obj}_id ${val}\"" )
done
