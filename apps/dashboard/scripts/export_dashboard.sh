#!/bin/bash
set -e
KIBANA_URL="${KIBANA_URL:-http://172.16.4.5/kibana}"
export_file=${1:-export.json}

obj="dashboard"
curl -sSL -X GET -H "Content-Type: application/json" -H "kbn-xsrf: true"  "${KIBANA_URL}/api/saved_objects/${obj}/"
dashboard_id=$(curl -sSL -X GET -H "Content-Type: application/json" -H "kbn-xsrf: true"  "${KIBANA_URL}/api/saved_objects/${obj}/" | jq -r '.saved_objects[].id')

if [ ! -z "$dashboard_id" ] ;then
         curl -sSL -X GET -H "Content-Type: application/json"  "${KIBANA_URL}/api/kibana/dashboards/export?dashboard=${dashboard_id}" -o $export_file && echo "}]}" >> $export_file
fi
