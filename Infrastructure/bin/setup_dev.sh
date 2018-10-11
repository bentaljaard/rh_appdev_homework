#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Code to set up the parks development project.

# To be Implemented by Student

MONGODB_USER=mongodb
MONGODB_PASSWORD=mongodb
MONGODB_DATABASE=parks

# Ensure we are on the correct project
oc project ${GUID}-parks-dev

# Add role to jenkins service account in order to modify objects
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-dev

# Setup mongoDB for parks backends
oc new-app --template=mongodb-persistent --param=MONGODB_USER=${MONGODB_USER} \
	--param=MONGODB_PASSWORD=${MONGODB_PASSWORD} \
	--param=MONGODB_DATABASE=${MONGODB_DATABASE}

# Setup deployments for applications
# MLBParks #
oc new-build --binary=true --name="mlb-parks" jboss-eap70-openshift:1.7 -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/mlb-parks:0.0-0 --name=mlb-parks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc set triggers dc/mlb-parks --remove-all -n ${GUID}-parks-dev
oc set env dc/mlb-parks DB_HOST=mongodb DB_PORT=27017 DB_USERNAME=${MONGODB_USER} DB_PASSWORD=${MONGODB_PASSWORD} DB_NAME=${MONGODB_DATABASE}
oc create configmap mlb-parks-config --from-literal=APPNAME="MLB Parks (Dev)"
oc set env --from=configmap/mlb-parks-config dc/mlb-parks

oc set probe dc/mlb-parks --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/mlb-parks --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/

# Wait for pod to be started and then call /ws/data/load/ as post deploy hook to populate the db
oc set deployment-hook dc/mlb-parks --post -- sh "curl -i -X GET http://mlb-parks.${GUID}-parks-dev.svc.cluster.local:8080/ws/data/load/" 

oc expose dc mlb-parks --port 8080 -n ${GUID}-parks-dev -l type=parksmap-backend

# MLBParks setup complete #

# NationalParks #
oc new-build --binary=true --name="national-parks" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/national-parks:0.0-0 --name=national-parks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc set triggers dc/national-parks --remove-all -n ${GUID}-parks-dev
oc set env dc/national-parks DB_HOST=mongodb DB_PORT=27017 DB_USERNAME=${MONGODB_USER} DB_PASSWORD=${MONGODB_PASSWORD} DB_NAME=${MONGODB_DATABASE}
oc create configmap national-parks-config --from-literal=APPNAME="National Parks (Dev)"
oc set env --from=configmap/national-parks-config dc/national-parks
oc set probe dc/national-parks --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/national-parks --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/

# Wait for pod to be started and then call /ws/data/load/ as post deploy hook to populate the db
oc set deployment-hook dc/national-parks --post -- sh "curl -i -X GET http://national-parks.${GUID}-parks-dev.svc.cluster.local:8080/ws/data/load/" 

oc expose dc national-parks --port 8080 -n ${GUID}-parks-dev -l type=parksmap-backend

# NationalParks setup complete#

# ParksMap #
oc policy add-role-to-user view --serviceaccount=default
oc new-build --binary=true --name="parks-map" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/parks-map:0.0-0 --name=parks-map --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc set triggers dc/parks-map --remove-all -n ${GUID}-parks-dev
oc create configmap parks-map-config --from-literal=APPNAME="ParksMap (Dev)"
oc set env --from=configmap/parks-map-config dc/parks-map
oc set probe dc/parks-map --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/parks-map --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/

oc expose dc parks-map --port 8080 -n ${GUID}-parks-dev
oc expose service parks-map

# ParksMap setup complete#


