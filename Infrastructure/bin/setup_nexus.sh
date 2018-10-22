#!/bin/bash
# Setup Nexus Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Nexus in project $GUID-nexus"

# Code to set up the Nexus. It will need to
# * Create Nexus
# * Set the right options for the Nexus Deployment Config
# * Load Nexus with the right repos
# * Configure Nexus as a docker registry
# Hint: Make sure to wait until Nexus if fully up and running
#       before configuring nexus with repositories.
#       You could use the following code:
# while : ; do
#   echo "Checking if Nexus is Ready..."
#   oc get pod -n ${GUID}-nexus|grep '\-2\-'|grep -v deploy|grep "1/1"
#   [[ "$?" == "1" ]] || break
#   echo "...no. Sleeping 10 seconds."
#   sleep 10
# done

# Ideally just calls a template
# oc new-app -f ../templates/nexus.yaml --param .....

# To be Implemented by Student

##################################################################



# Ensure that we are creating the objects in the correct project
oc project ${GUID}-nexus

# Call template to provision nexus objects
oc new-app -f Infrastructure/templates/nexus3.yaml -p GUID=${GUID} -p CPU_LIMITS=1000m -p MEM_REQUESTS=1Gi -p MEM_LIMITS=2Gi -p VOLUME_CAPACITY=2G -n ${GUID}-nexus

# Wait for nexus to start before we configure it
while : ; do
  echo "Checking if Nexus is Ready..."
  oc get pod -n ${GUID}-nexus|grep -v deploy|grep "1/1"
  [[ "$?" == "1" ]] || break
  echo "...no. Sleeping 10 seconds."
  sleep 10
done

#Make sure that route has started routing traffic, so sleep a little longer
sleep 5

# Run configuration script to configure redhat maven repos, create release repo, configure proxy for maven, setup docker registry repo
curl -o config_nexus_tmp.sh -s https://raw.githubusercontent.com/bentaljaard/rh_appdev_homework/master/Infrastructure/bin/config_nexus3.sh
chmod +x config_nexus_tmp.sh
./config_nexus_tmp.sh admin admin123 http://$(oc get route nexus3 --template='{{ .spec.host }}' -n ${GUID}-nexus)
rm config_nexus_tmp.sh

echo "************************"
echo "Nexus setup complete"
echo "************************"

exit 0



