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
oc policy add-role-to-user view --serviceaccount=default -n ${GUID}-parks-prod

# Provision mongodb statefulset 
oc new-app -f Infrastructure/templates/mongodb_statefulset.yaml -p GUID=bft \
	-p REPLICAS=3 -p MONGO_DATABASE=parks -p MONGO_USER=mongodb \
	-p VOLUME_CAPACITY=2G -p CPU_LIMITS=500m -p MEM_LIMITS=1Gi -n ${GUID}-parks-prod

# Setup deployments for applications
# MLBParks #
APP=mlbparks
PROJECT=${GUID}-parks-prod

# Setup Green Deployment (Default)
APPNAME="MLB Parks (Green)"

oc new-app ${GUID}-parks-dev/${APP}:0.0-0 --name=${APP}-green --allow-missing-imagestream-tags=true --allow-missing-images -n ${PROJECT}
oc set triggers dc/${APP}-green --remove-all -n ${PROJECT}
oc set resources dc/${APP}-green --limits=cpu=500m,memory=1Gi --requests=cpu=250m,memory=512Mi -n ${PROJECT}
oc set env dc/${APP}-green DB_HOST=mongodb DB_PORT=27017 DB_REPLICASET=rs0 -n ${PROJECT}
oc set env --from=secret/mongodb dc/${APP}-green -n ${PROJECT}
oc create configmap ${APP}-config-green --from-literal=APPNAME="${APPNAME}" -n ${PROJECT}
oc set env --from=configmap/${APP}-config-green dc/${APP}-green -n ${PROJECT}
oc set probe dc/${APP}-green -n ${PROJECT} --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/${APP}-green -n ${PROJECT} --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/
oc expose dc ${APP}-green --port 8080 -n ${PROJECT}
sleep 5
oc set deployment-hook dc/${APP}-green -n ${PROJECT} --post --failure-policy=abort -- sh -c "sleep 10 && curl -i -X GET http://$(oc get service ${APP}-green -o jsonpath='{ .spec.clusterIP }' -n ${PROJECT}):8080/ws/data/load/" 
oc label svc ${APP}-green type=parksmap-backend app=${APP} --overwrite -n ${PROJECT}


# Setup Blue Deployment
APPNAME="MLB Parks (Blue)"

oc new-app ${GUID}-parks-dev/${APP}:0.0-0 --name=${APP}-blue --allow-missing-imagestream-tags=true --allow-missing-images -n ${PROJECT}
oc set triggers dc/${APP}-blue --remove-all -n ${PROJECT}
oc set resources dc/${APP}-blue --limits=cpu=500m,memory=1Gi --requests=cpu=250m,memory=512Mi -n ${PROJECT}
oc set env dc/${APP}-blue DB_HOST=mongodb DB_PORT=27017 DB_REPLICASET=rs0 -n ${PROJECT}
oc set env --from=secret/mongodb dc/${APP}-blue -n ${PROJECT}
oc create configmap ${APP}-config-blue --from-literal=APPNAME="$APPNAME" -n ${PROJECT}
oc set env --from=configmap/${APP}-config-blue dc/${APP}-blue -n ${PROJECT}
oc set probe dc/${APP}-blue -n ${PROJECT} --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/${APP}-blue -n ${PROJECT} --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/
oc expose dc ${APP}-blue --port 8080 -n ${PROJECT}
sleep 5
oc set deployment-hook dc/${APP}-blue -n ${PROJECT} --post --failure-policy=abort -- sh -c "sleep 10 && curl -i -X GET http://$(oc get service ${APP}-blue -o jsonpath='{ .spec.clusterIP }' -n ${PROJECT}):8080/ws/data/load/" 
oc label svc ${APP}-blue app=${APP} --overwrite -n ${PROJECT}


# NationalParks #
APP=nationalparks
PROJECT=${GUID}-parks-prod

# Setup Green Deployment (Default)
APPNAME="National Parks (Green)"
oc new-app ${GUID}-parks-dev/${APP}:0.0-0 --name=${APP}-green --allow-missing-imagestream-tags=true --allow-missing-images -n ${PROJECT}
oc set triggers dc/${APP}-green --remove-all -n ${PROJECT}
oc set resources dc/${APP}-green --limits=cpu=500m,memory=1Gi --requests=cpu=250m,memory=512Mi -n ${PROJECT}
oc set env dc/${APP}-green DB_HOST=mongodb DB_PORT=27017 DB_REPLICASET=rs0 -n ${PROJECT}
oc set env --from=secret/mongodb dc/${APP}-green -n ${PROJECT}
oc create configmap ${APP}-config-green --from-literal=APPNAME="${APPNAME}" -n ${PROJECT}
oc set env --from=configmap/${APP}-config-green dc/${APP}-green -n ${PROJECT}
oc set probe dc/${APP}-green -n ${PROJECT} --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/${APP}-green -n ${PROJECT} --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/
oc expose dc ${APP}-green --port 8080 -n ${PROJECT}
sleep 5
oc set deployment-hook dc/${APP}-green -n ${PROJECT} --post --failure-policy=abort -- sh -c "sleep 10 && curl -i -X GET http://$(oc get service ${APP}-green -o jsonpath='{ .spec.clusterIP }' -n ${PROJECT}):8080/ws/data/load/" 
oc label svc ${APP}-green type=parksmap-backend app=${APP} --overwrite -n ${PROJECT}



# Setup Blue Deployment
APPNAME="National Parks (Blue)"

oc new-app ${GUID}-parks-dev/${APP}:0.0-0 --name=${APP}-blue --allow-missing-imagestream-tags=true --allow-missing-images -n ${PROJECT}
oc set triggers dc/${APP}-blue --remove-all -n ${PROJECT}
oc set resources dc/${APP}-blue --limits=cpu=500m,memory=1Gi --requests=cpu=250m,memory=512Mi -n ${PROJECT}
oc set env dc/${APP}-blue DB_HOST=mongodb DB_PORT=27017 DB_REPLICASET=rs0 -n ${PROJECT}
oc set env --from=secret/mongodb dc/${APP}-blue -n ${PROJECT}
oc create configmap ${APP}-config-blue --from-literal=APPNAME="$APPNAME" -n ${PROJECT}
oc set env --from=configmap/${APP}-config-blue dc/${APP}-blue -n ${PROJECT}
oc set probe dc/${APP}-blue -n ${PROJECT} --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/${APP}-blue -n ${PROJECT} --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/
oc expose dc ${APP}-blue --port 8080 -n ${PROJECT}
sleep 5
oc set deployment-hook dc/${APP}-blue -n ${PROJECT} --post --failure-policy=abort -- sh -c "sleep 10 && curl -i -X GET http://$(oc get service ${APP}-blue -o jsonpath='{ .spec.clusterIP }' -n ${PROJECT}):8080/ws/data/load/" 
oc label svc ${APP}-blue app=${APP} --overwrite -n ${PROJECT}



# ParksMap #
APP=parksmap
PROJECT=${GUID}-parks-prod

APPNAME="ParksMap (Green)"

oc new-app ${GUID}-parks-dev/${APP}:0.0-0 --name=${APP}-green --allow-missing-imagestream-tags=true --allow-missing-images -n ${PROJECT}
oc set triggers dc/${APP}-green --remove-all -n ${PROJECT}
oc set resources dc/${APP}-green --limits=cpu=500m,memory=1Gi --requests=cpu=250m,memory=512Mi -n ${PROJECT}
oc create configmap ${APP}-config-green --from-literal=APPNAME="${APPNAME}" -n ${PROJECT}
oc set env --from=configmap/${APP}-config-green dc/${APP}-green -n ${PROJECT}
oc set probe dc/${APP}-green -n ${PROJECT} --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/${APP}-green -n ${PROJECT} --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/
oc expose dc ${APP}-green --port 8080 -n ${PROJECT}
oc expose service ${APP}-green --name=${APP} -n ${PROJECT}

APPNAME="ParksMap (Blue)"

oc new-app ${GUID}-parks-dev/${APP}:0.0-0 --name=${APP}-blue --allow-missing-imagestream-tags=true --allow-missing-images -n ${PROJECT}
oc set triggers dc/${APP}-blue --remove-all -n ${PROJECT}
oc set resources dc/${APP}-blue --limits=cpu=500m,memory=1Gi --requests=cpu=250m,memory=512Mi -n ${PROJECT}
oc create configmap ${APP}-config-blue --from-literal=APPNAME="${APPNAME}" -n ${PROJECT}
oc set env --from=configmap/${APP}-config-blue dc/${APP}-blue -n ${PROJECT}
oc set probe dc/${APP}-blue -n ${PROJECT} --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
oc set probe dc/${APP}-blue -n ${PROJECT} --readiness --failure-threshold 3 --initial-delay-seconds 30 --get-url=http://:8080/ws/healthz/
oc expose dc ${APP}-blue --port 8080 -n ${PROJECT}


while : ; do
  echo "Checking if MongoDB_PROD is Ready..."
  count=$(oc get pod -n ${GUID}-parks-prod|grep mongodb|grep -v deploy|grep -v build|grep "1/1"|wc -l)
  #Check that at least one node is up, environment is crappy, so not all of them can start (should normally check for 3)
  [[ "$count" != "1" ]] || break
  echo "...no. Sleeping 10 seconds."
  sleep 10
done

echo "****************************************"
echo "Production Environment setup complete"
echo "****************************************"

exit 0