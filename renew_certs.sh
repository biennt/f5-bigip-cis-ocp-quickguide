#!/bin/bash
su - cloud-user
while date ; do
  oc get nodes
  oc get csr --no-headers | grep Pending | awk '{print $1}' | xargs --no-run-if-empty oc  adm certificate approve
  sleep 5
done
