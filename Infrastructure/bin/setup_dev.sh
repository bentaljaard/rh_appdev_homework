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
APP=mlbparks
APPNAME="MLB Parks (Dev)"
PROJECT=${GUID}-parks-dev
BASEIMAGE=jboss-eap70-openshift:1.7

oc new-build --binary=true --name="${APP}" ${BASEIMAGE} -n ${PROJECT}
oc new-app ${PROJECT}/${APP}:0.0-0 --name=${APP} --allow-missing-imagestream-tags=true -n ${PROJECT}
oc set triggers dc/${APP} --remove-all -n ${PROJECT}
oc set env dc/${APP} DB_HOST=mongodb DB_PORT=27017 DB_USERNAME=${MONGODB_USER} DB_PASSWORD=${MONGODB_PASSWORD} DB_NAME=${MONGODB_DATABASE}
oc create configmap ${APP}-config --from-literal=APPNAME="${APPNAME}"
oc set env --from=configmap/${APP}-config dc/${APP}
oc set probe dc/${APP} --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/${APP} --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/
# Wait for pod to be started and then call /ws/data/load/ as post deploy hook to populate the db
oc set deployment-hook dc/${APP} --post --failure-policy=abort -- sh -c "sleep 10 && curl -i -X GET http://$(oc get service ${APP} -o jsonpath='{ .spec.clusterIP }'):8080/ws/data/load/" 
oc expose dc ${APP} --port 8080 -n ${PROJECT}
oc label svc ${APP} type=parksmap-backend app=${APP} --overwrite
# MLBParks setup complete #

# NationalParks #
APP=nationalparks
APPNAME="National Parks (Dev)"
PROJECT=${GUID}-parks-dev
BASEIMAGE=redhat-openjdk18-openshift:1.2

oc new-build --binary=true --name="${APP}" ${BASEIMAGE} -n ${PROJECT}
oc new-app ${PROJECT}/${APP}:0.0-0 --name=${APP} --allow-missing-imagestream-tags=true -n ${PROJECT}
oc set triggers dc/${APP} --remove-all -n ${PROJECT}
oc set env dc/${APP} DB_HOST=mongodb DB_PORT=27017 DB_USERNAME=${MONGODB_USER} DB_PASSWORD=${MONGODB_PASSWORD} DB_NAME=${MONGODB_DATABASE}
oc create configmap ${APP}-config --from-literal=APPNAME="${APPNAME}"
oc set env --from=configmap/${APP}-config dc/${APP}
oc set probe dc/${APP} --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/${APP} --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/
# Wait for pod to be started and then call /ws/data/load/ as post deploy hook to populate the db
oc set deployment-hook dc/${APP} --post --failure-policy=abort -- sh -c "sleep 10 && curl -i -X GET http://$(oc get service ${APP} -o jsonpath='{ .spec.clusterIP }'):8080/ws/data/load/" 
oc expose dc ${APP} --port 8080 -n ${PROJECT}
oc label svc ${APP} type=parksmap-backend app=${APP} --overwrite

# NationalParks setup complete#

# ParksMap #
APP=parksmap
APPNAME="ParksMap (Dev)"
PROJECT=${GUID}-parks-dev
BASEIMAGE=redhat-openjdk18-openshift:1.2

oc policy add-role-to-user view --serviceaccount=default

oc new-build --binary=true --name="${APP}" ${BASEIMAGE} -n ${PROJECT}
oc new-app ${PROJECT}/${APP}:0.0-0 --name=${APP} --allow-missing-imagestream-tags=true -n ${PROJECT}
oc set triggers dc/${APP} --remove-all -n ${PROJECT}
oc create configmap ${APP}-config --from-literal=APPNAME="${APPNAME}"
oc set env --from=configmap/${APP}-config dc/${APP}
oc set probe dc/${APP} --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/${APP} --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/
oc expose dc ${APP} --port 8080 -n ${PROJECT}
oc expose service ${APP}
# ParksMap setup complete#


