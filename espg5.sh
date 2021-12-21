#!/usr/bin/bash
# Copyright (c) 2021 Norwegian Labour and Welfare Administration, Thomas Kristoffersen and Torsten Kirschner
# ES - point this at your RINA 2019 ElasticSearch 
ES_FQDN='<2019 ELASTICSEARCH HOST>'
ES_PORT='<2019 ELASTICSEARCH PORT>'
for type in "open" "closed" "archived" "removed" ; do
  eval "$type=$(curl -sS "http://${ES_FQDN}:${ES_PORT}/cases/casestructuredmetadata/_count?pretty" -d'{ "query": { "term": { "status": { "value": "'${type}'" } } } }' \
        | grep "count" | awk -F: '{print $2}' | sed 's/,*\r*$//' | xargs)" # It's some kind of maaaagic
done
# RINA 2020 PostgreSQL - set this to your rina DB user and password, etc.
PGUSERNAME=rina
export PGPASSWORD='RiNa123$%^' # psql uses this variable if present instead of prompting for the password if needed
RINA_DB_FQDN='<2020 POSTGRESQL HOST>'
RINA_DB_PORT=<2020 POSTGRESQL PORT>
RINA_DB_NAME=rina
psql -h ${RINA_DB_FQDN} -p ${RINA_DB_PORT} -U ${PGUSERNAME} -d ${RINA_DB_NAME} << EOF
WITH cases2019 AS ( SELECT ${open} AS case_count, 'OPEN' AS status UNION ALL SELECT ${closed}, 'CLOSED' UNION ALL SELECT ${removed}, 'REMOVED' UNION ALL SELECT ${archived}, 'ARCHIVED'),
     cases2020 AS ( SELECT COUNT(DISTINCT rc.business_id) AS case_count, rc.status FROM rina.rina_case rc GROUP BY rc.status)
SELECT COALESCE(c20.case_count, 0) AS "2020 cases", c19.case_count AS "2019 cases", c19.status
FROM cases2020 c20
RIGHT OUTER JOIN cases2019 c19 ON c20.status = c19.status
EOF