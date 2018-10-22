#!/bin/bash
# Setup Sonarqube Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Sonarqube in project $GUID-sonarqube"

# Code to set up the SonarQube project.
# Ideally just calls a template
# oc new-app -f ../templates/sonarqube.yaml --param .....

# To be Implemented by Student
################################################################

# Ensure that we are creating the objects in the correct project
oc project ${GUID}-sonarqube

# Call template to provision nexus objects

##TODO: Add more parameters

oc new-app -f Infrastructure/templates/sonarqube.yaml -p GUID=${GUID} #-p MEM_REQUESTS=1Gi -p MEM_LIMITS=2Gi -p VOLUME_CAPACITY=2G

echo "************************"
echo "SonarQube setup complete"
echo "************************"

exit 0
