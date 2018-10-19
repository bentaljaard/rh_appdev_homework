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
APP=mlbparks
PROJECT=${GUID}-parks-prod

# Setup Green Deployment (Default)
APPNAME="MLB Parks (Green)"

oc new-app ${GUID}-parks-dev/${APP}:0.0-0 --name=${APP}-green --allow-missing-imagestream-tags=true -n ${PROJECT}
oc set triggers dc/${APP}-green --remove-all -n ${PROJECT}
# Set environment variables for db connection
oc set env dc/${APP}-green DB_HOST=mongodb DB_PORT=27017
oc set env --from=secret/mongodb dc/${APP}-green

oc create configmap ${APP}-config-green --from-literal=APPNAME="${APPNAME}"
oc set env --from=configmap/${APP}-config-green dc/${APP}-green

oc set probe dc/${APP}-green --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/${APP}-green --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/

oc set deployment-hook dc/${APP}-green --post -- sh "curl -i -X GET http://${APP}.${PROJECT}.svc.cluster.local:8080/ws/data/load/" 

oc expose dc ${APP}-green --port 8080 -n ${PROJECT}
oc label svc ${APP} type=parksmap-backend app=${APP} --overwrite


# Setup Blue Deployment
APPNAME="MLB Parks (Blue)"

oc new-app ${GUID}-parks-dev/${APP}:0.0-0 --name=${APP}-blue --allow-missing-imagestream-tags=true -n ${PROJECT}
oc set triggers dc/${APP}-blue --remove-all -n ${PROJECT}

# Set environment variables for db connection
oc set env dc/${APP}-blue DB_HOST=mongodb DB_PORT=27017
oc set env --from=secret/mongodb dc/${APP}-blue

oc create configmap ${APP}-config-blue --from-literal=APPNAME="$APPNAME"
oc set env --from=configmap/${APP}-config-blue dc/${APP}-blue

oc set probe dc/${APP}-blue --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/${APP}-blue --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/

oc set deployment-hook dc/${APP}-blue --post -- sh "curl -i -X GET http://${APP}.${PROJECT}.svc.cluster.local:8080/ws/data/load/" 

# Create initial service without label (passive deployment), will need to set it in the pipeline to switch active deployment
oc expose dc ${APP}-blue --port 8080 -n ${PROJECT}
oc label svc ${APP} app=${APP} --overwrite


# NationalParks #
APP=nationalparks
PROJECT=${GUID}-parks-prod

# Setup Green Deployment (Default)
APPNAME="National Parks (Green)"
oc new-app ${GUID}-parks-dev/${APP}:0.0-0 --name=${APP}-green --allow-missing-imagestream-tags=true -n ${PROJECT}
oc set triggers dc/${APP}-green --remove-all -n ${PROJECT}
# Set environment variables for db connection
oc set env dc/${APP}-green DB_HOST=mongodb DB_PORT=27017
oc set env --from=secret/mongodb dc/${APP}-green

oc create configmap ${APP}-config-green --from-literal=APPNAME="${APPNAME}"
oc set env --from=configmap/${APP}-config-green dc/${APP}-green

oc set probe dc/${APP}-green --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/${APP}-green --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/

oc set deployment-hook dc/${APP}-green --post -- sh "curl -i -X GET http://${APP}.${PROJECT}.svc.cluster.local:8080/ws/data/load/" 

oc expose dc ${APP}-green --port 8080 -n ${PROJECT}
oc label svc ${APP} type=parksmap-backend app=${APP} --overwrite



# Setup Blue Deployment
APPNAME="National Parks (Blue)"

oc new-app ${GUID}-parks-dev/${APP}:0.0-0 --name=${APP}-blue --allow-missing-imagestream-tags=true -n ${PROJECT}
oc set triggers dc/${APP}-blue --remove-all -n ${PROJECT}

# Set environment variables for db connection
oc set env dc/${APP}-blue DB_HOST=mongodb DB_PORT=27017
oc set env --from=secret/mongodb dc/${APP}-blue

oc create configmap ${APP}-config-blue --from-literal=APPNAME="$APPNAME"
oc set env --from=configmap/${APP}-config-blue dc/${APP}-blue

oc set probe dc/${APP}-blue --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/${APP}-blue --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/

oc set deployment-hook dc/${APP}-blue --post -- sh "curl -i -X GET http://${APP}.${PROJECT}.svc.cluster.local:8080/ws/data/load/" 

# Create initial service without label (passive deployment), will need to set it in the pipeline to switch active deployment
oc expose dc ${APP}-blue --port 8080 -n ${PROJECT}
oc label svc ${APP} app=${APP} --overwrite



# ParksMap #
APP=parksmap
PROJECT=${GUID}-parks-prod

APPNAME="ParksMap (Green)"

oc new-app ${GUID}-parks-dev/${APP}:0.0-0 --name=${APP}-green --allow-missing-imagestream-tags=true -n ${PROJECT}
oc set triggers dc/${APP}-green --remove-all -n ${PROJECT}
oc create configmap ${APP}-config-green --from-literal=APPNAME="${APPNAME}"
oc set env --from=configmap/${APP}-config-green dc/${APP}-green
oc set probe dc/${APP}-green --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/${APP}-green --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/

oc expose dc ${APP}-green --port 8080 -n ${PROJECT}
oc expose service ${APP}-green --name=${APP}

APPNAME="ParksMap (Blue)"

oc new-app ${GUID}-parks-dev/${APP}:0.0-0 --name=${APP}-blue --allow-missing-imagestream-tags=true -n ${PROJECT}
oc set triggers dc/${APP}-blue --remove-all -n ${PROJECT}
oc create configmap ${APP}-config-blue --from-literal=APPNAME="${APPNAME}"
oc set env --from=configmap/${APP}-config-blue dc/${APP}-blue
oc set probe dc/${APP}-blue --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/${APP}-blue --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/

oc expose dc ${APP}-blue --port 8080 -n ${PROJECT}
