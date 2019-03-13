#!/bin/bash
set -e
KIBANA_URL="${KIBANA_URL:-http://172.16.4.5/kibana}"
export_file=${1:-export.json}
# get object id
objects="search visualization dashboard"

[[ -f $export_file ]] || exit 1

#
# get id
#
echo "# GET id"
for obj in $objects ; do
        eval $(echo "${obj}_id=\"\"" )
done
for obj in $objects ; do
        echo "# GET /api/saved_objects/${obj}/"
        val=$(curl -sSL -X GET -H "Content-Type: application/json" -H "kbn-xsrf: true"  "${KIBANA_URL}/api/saved_objects/${obj}/" | jq -r '.saved_objects[].id')
        eval $(echo "${obj}_id=\"${val}\"" )
done

echo "search_id: $search_id"
echo "visualization_id: $visualization_id"
echo "dashboard_id: $dashboard_id"

# index id
obj="index-pattern"
val=$(curl -sSL -X GET -H "Content-Type: application/json" -H "kbn-xsrf: true"  "${KIBANA_URL}/api/saved_objects/${obj}/" | jq -r '.saved_objects[].id')
index_pattern_id=${val}

echo "index_pattern_id: ${index_pattern_id}"
#
# delete id
#
echo "# DELETE id"
for obj in $objects ; do
        id=$(eval echo "$""${obj}_id")
        for s in $id ; do
                echo "# DELETE /api/saved_objects/${obj}/${s}"
                val=$(curl -sSL -X DELETE -H "Content-Type: application/json" -H "kbn-xsrf: true"  "${KIBANA_URL}/api/saved_objects/${obj}/${s}")
                echo $val
        done
done

echo "# DELETE index id"
obj="index-pattern"
for s in $index_pattern_id ; do
        echo "# DELETE /api/saved_objects/${obj}/${s}"
        val=$(curl -sSL -X DELETE -H "Content-Type: application/json" -H "kbn-xsrf: true"  "${KIBANA_URL}/api/saved_objects/${obj}/${s}")
        echo $val
done
#
# import
#
echo "Import all dashboard"
val=$(curl -sSL -X POST -H "Content-Type: application/json" -H "kbn-xsrf: true" -d @${export_file} ${KIBANA_URL}/api/kibana/dashboards/import)
echo "$val" | jq -r .
ret=$?
echo $ret
exit $ret

