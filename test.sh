#!/bin/bash
docker exec -e IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $1) nmt3 /bin/sh /test1.sh
