#!/bin/bash
# Flat pod networking test

# shellcheck disable=SC2128
#TUTORIAL_HOME=$(dirname "$BASH_SOURCE")

# Apply the yamls to create busybox test pods on all the clusters
echo "Creating test pods to run network tests"
kubectl apply -f "$TUTORIAL_HOME"/networking/network-test/busybox-central.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central
kubectl apply -f "$TUTORIAL_HOME"/networking/network-test/busybox-east.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl apply -f "$TUTORIAL_HOME"/networking/network-test/busybox-west.yaml --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west

# Get the busybox pod IPs from all the clusters
printf "\nGetting pod IPs of the test pods\n"
sleep 10
centralIP=$(kubectl get po busybox-0 -n central -o jsonpath='{.status.podIP}' --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central)
eastIP=$(kubectl get po busybox-0 -n east -o jsonpath='{.status.podIP}' --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east)
westIP=$(kubectl get po busybox-0 -n west -o jsonpath='{.status.podIP}' --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west)

printf "\nTesting connectivity from central to east\n"
kubectl exec -it busybox-0 -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central -- ping -c 3 "$eastIP"

printf "\nTesting connectivity from central to west\n"
kubectl exec -it busybox-0 -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central -- ping -c 3 "$westIP"

printf "\nTesting connectivity from east to central\n"
kubectl exec -it busybox-0 -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east -- ping -c 3 "$centralIP"

printf "\nTesting connectivity from east to west\n"
kubectl exec -it busybox-0 -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east -- ping -c 3 "$westIP"

printf "\nTesting connectivity from west to central\n"
kubectl exec -it busybox-0 -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west -- ping -c 3 "$centralIP"

printf "\nTesting connectivity from west to east\n"
kubectl exec -it busybox-0 -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west -- ping -c 3 "$eastIP"

printf "\nTesting Kubernetes DNS setup"
printf "\nTesting DNS forwarding from central to east\n"
kubectl exec -it busybox-0 -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central -- ping -c 3 busybox-0.busybox.east.svc.cluster.local

printf "\nTesting DNS forwarding from central to west\n"
kubectl exec -it busybox-0 -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central -- ping -c 3 busybox-0.busybox.west.svc.cluster.local

printf "\nTesting DNS forwarding from east to central\n"
kubectl exec -it busybox-0 -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east -- ping -c 3 busybox-0.busybox.central.svc.cluster.local

printf "\nTesting DNS forwarding from east to west\n"
kubectl exec -it busybox-0 -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east -- ping -c 3 busybox-0.busybox.west.svc.cluster.local

printf "\nTesting DNS forwarding from west to central\n"
kubectl exec -it busybox-0 -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west -- ping -c 3 busybox-0.busybox.central.svc.cluster.local

printf "\nTesting DNS forwarding from west to east\n"
kubectl exec -it busybox-0 -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west -- ping -c 3 busybox-0.busybox.east.svc.cluster.local

# Delete busybox pods
printf "\nTest complete. Deleting test pods\n"
kubectl delete -f "$TUTORIAL_HOME"/networking/network-test/busybox-central.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central
kubectl delete -f "$TUTORIAL_HOME"/networking/network-test/busybox-east.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl delete -f "$TUTORIAL_HOME"/networking/network-test/busybox-west.yaml --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west