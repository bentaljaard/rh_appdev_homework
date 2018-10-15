#!/bin/bash
# Setup Production Project (initial active services: Green)
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Production Environment in project ${GUID}-parks-prod"

# Code to set up the parks production project. It will need a StatefulSet MongoDB, and two applications each (Blue/Green) for NationalParks, MLBParks and Parksmap.
# The Green services/routes need to be active initially to guarantee a successful grading pipeline run.

# To be Implemented by Student

# Ensure we are on the correct project
oc project ${GUID}-parks-prod

# Add role to jenkins service account in order to modify objects
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-prod
# Add role to allow images to be pulled from dev environment
oc policy add-role-to-group system:image-puller system:serviceaccounts:${GUID}-parks-prod -n ${GUID}-parks-dev
# Add role to discover backend services
oc policy add-role-to-user view --serviceaccount=default

# Provision mongodb statefulset 
oc new-app -f ../templates/mongodb_statefulset.yaml -p GUID=bft \
	-p REPLICAS=3 -p MONGO_DATABASE=parks -p MONGO_USER=mongodb \
	-p VOLUME_CAPACITY=2G -p CPU_LIMITS=1000m -p MEM_LIMITS=1Gi

# Setup deployments for applications
# MLBParks #

# Setup Green Deployment (Default)
oc new-app ${GUID}-parks-dev/mlb-parks:0.0-0 --name=mlb-parks-green --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/mlb-parks-green --remove-all -n ${GUID}-parks-prod

# Set environment variables for db connection
oc set env dc/mlb-parks-green DB_HOST=mongodb DB_PORT=27017
oc set env --from=secret/mongodb dc/mlb-parks-green

oc create configmap mlb-parks-config-green --from-literal=APPNAME="MLB Parks (Green)"
oc set env --from=configmap/mlb-parks-config-green dc/mlb-parks-green

oc set probe dc/mlb-parks-green --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/mlb-parks-green --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/

# //TODO: What to do with migration???
# Wait for pod to be started and then call /ws/data/load/ as post deploy hook to populate the db
oc set deployment-hook dc/mlb-parks-green --post -- sh "curl -i -X GET http://mlb-parks.${GUID}-parks-dev.svc.cluster.local:8080/ws/data/load/" 

oc expose dc mlb-parks-green --port 8080 -n ${GUID}-parks-prod -l type=parksmap-backend


# Setup Blue Deployment
oc new-app ${GUID}-parks-dev/mlb-parks:0.0-0 --name=mlb-parks-blue --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/mlb-parks-blue --remove-all -n ${GUID}-parks-prod

# Set environment variables for db connection
oc set env dc/mlb-parks-blue DB_HOST=mongodb DB_PORT=27017
oc set env --from=secret/mongodb dc/mlb-parks-blue

oc create configmap mlb-parks-config-blue --from-literal=APPNAME="MLB Parks (Blue)"
oc set env --from=configmap/mlb-parks-config-blue dc/mlb-parks-blue

oc set probe dc/mlb-parks-blue --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/mlb-parks-blue --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/

#TODO: What to do with migration???
# Wait for pod to be started and then call /ws/data/load/ as post deploy hook to populate the db
oc set deployment-hook dc/mlb-parks-blue --post -- sh "curl -i -X GET http://mlb-parks.${GUID}-parks-dev.svc.cluster.local:8080/ws/data/load/" 

# Create initial service without label (passive deployment), will need to set it in the pipeline to switch active deployment
oc expose dc mlb-parks-blue --port 8080 -n ${GUID}-parks-prod


# NationalParks #

# Setup Green Deployment (Default)
oc new-app ${GUID}-parks-dev/national-parks:0.0-0 --name=national-parks-green --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/national-parks-green --remove-all -n ${GUID}-parks-prod

# Set environment variables for db connection
oc set env dc/national-parks-green DB_HOST=mongodb DB_PORT=27017
oc set env --from=secret/mongodb dc/national-parks-green

oc create configmap national-parks-config-green --from-literal=APPNAME="National Parks (Green)"
oc set env --from=configmap/national-parks-config-green dc/national-parks-green

oc set probe dc/national-parks-green --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/national-parks-green --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/

# //TODO: What to do with migration???
# Wait for pod to be started and then call /ws/data/load/ as post deploy hook to populate the db
oc set deployment-hook dc/national-parks-green --post -- sh "curl -i -X GET http://national-parks.${GUID}-parks-dev.svc.cluster.local:8080/ws/data/load/" 

oc expose dc national-parks-green --port 8080 -n ${GUID}-parks-prod -l type=parksmap-backend


# Setup Blue Deployment
oc new-app ${GUID}-parks-dev/national-parks:0.0-0 --name=national-parks-blue --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/national-parks-blue --remove-all -n ${GUID}-parks-prod

# Set environment variables for db connection
oc set env dc/national-parks-blue DB_HOST=mongodb DB_PORT=27017
oc set env --from=secret/mongodb dc/national-parks-blue

oc create configmap national-parks-config-blue --from-literal=APPNAME="National Parks (Blue)"
oc set env --from=configmap/national-parks-config-blue dc/national-parks-blue

oc set probe dc/national-parks-blue --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/national-parks-blue --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/

# //TODO: What to do with migration???
# Wait for pod to be started and then call /ws/data/load/ as post deploy hook to populate the db
oc set deployment-hook dc/national-parks-blue --post -- sh "curl -i -X GET http://national-parks.${GUID}-parks-dev.svc.cluster.local:8080/ws/data/load/" 

# Create initial service without label (passive deployment), will need to set it in the pipeline to switch active deployment
oc expose dc national-parks-blue --port 8080 -n ${GUID}-parks-prod

# ParksMap #

oc new-app ${GUID}-parks-dev/parks-map:0.0-0 --name=parks-map-green --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/parks-map-green --remove-all -n ${GUID}-parks-prod
oc create configmap parks-map-config-green --from-literal=APPNAME="ParksMap (Green)"
oc set env --from=configmap/parks-map-config-green dc/parks-map-green
oc set probe dc/parks-map-green --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/parks-map-green --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/

oc expose dc parks-map-green --port 8080 -n ${GUID}-parks-prod
oc expose service parks-map-green


oc new-app ${GUID}-parks-dev/parks-map:0.0-0 --name=parks-map-blue --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/parks-map-blue --remove-all -n ${GUID}-parks-prod
oc create configmap parks-map-config-blue --from-literal=APPNAME="ParksMap (Blue)"
oc set env --from=configmap/parks-map-config-blue dc/parks-map-blue
oc set probe dc/parks-map-blue --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/parks-map-blue --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/

oc expose dc parks-map-blue --port 8080 -n ${GUID}-parks-prod
