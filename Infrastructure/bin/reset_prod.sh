#!/bin/bash
# Reset Production Project (initial active services: Blue)
# This sets all services to the Blue service so that any pipeline run will deploy Green
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Resetting Parks Production Environment in project ${GUID}-parks-prod to Green Services"

# Code to reset the parks production environment to make
# all the green services/routes active.
# This script will be called in the grading pipeline
# if the pipeline is executed without setting
# up the whole infrastructure to guarantee a Blue
# rollout followed by a Green rollout.

# To be Implemented by Student


# Switch MLBParks to green version
# Remove blue version backend label
oc label svc/mlb-parks-blue type- -n ${GUID}-parks-prod
# Add green version backend label
oc label svc/mlb-parks-green type=parks-backend -n ${GUID}-parks-prod


# Switch National Parks to green version
# Remove blue version backend label
oc label svc/national-parks-blue type- -n ${GUID}-parks-prod
# Add green version backend label
oc label svc/national-parks-green type=parks-backend -n ${GUID}-parks-prod


# Switch Parks Map to green version
oc patch route parks-map -n ${GUID}-parks-prod -p '{"spec":{"to":{"name":"parks-map-green"}}}'