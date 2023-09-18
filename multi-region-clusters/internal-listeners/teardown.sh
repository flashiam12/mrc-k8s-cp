#!/bin/bash
# Make sure to complete Kubernetes networking setup before running this script.

# shellcheck disable=SC2128
TUTORIAL_HOME=$(dirname "$BASH_SOURCE")

# Destroy Control Center
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/controlcenter.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Destroy Schema Registry
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/schemaregistry/schemaregistry-west.yaml --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/schemaregistry/schemaregistry-east.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/schemaregistry/schemaregistry-central.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Delete Control Center role bindings
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/rolebindings/c3-rolebindings.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Delete Schema Registry role bindings
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/rolebindings/mrc-rolebindings.yaml -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/rolebindings/mrc-rolebindings.yaml -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/rolebindings/mrc-rolebindings.yaml -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Wait for internal role bindings to be deleted
echo "Waiting for role bindings to be deleted..."
kubectl wait cfrb --all --for=delete --timeout=-1s -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west
kubectl wait cfrb --all --for=delete --timeout=-1s -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl wait cfrb --all --for=delete --timeout=-1s -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Delete Kafka REST class
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/kafkarestclass.yaml -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/kafkarestclass.yaml -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/kafkarestclass.yaml -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Destroy Kafka
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/kafka/kafka-west.yaml --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/kafka/kafka-east.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/kafka/kafka-central.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Wait for Kafka to be destroyed
echo "Waiting for Kafka to be deleted..."
kubectl wait pod -l app=kafka --for=delete --timeout=-1s -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west
kubectl wait pod -l app=kafka --for=delete --timeout=-1s -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl wait pod -l app=kafka --for=delete --timeout=-1s -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Destroy Zookeeper
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/zookeeper/zookeeper-west.yaml --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/zookeeper/zookeeper-east.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/zookeeper/zookeeper-central.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Delete Kafka REST credential
kubectl delete secret kafka-rest-credential -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west
kubectl delete secret kafka-rest-credential -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl delete secret kafka-rest-credential -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Delete Control Center RBAC credential
kubectl delete secret c3-mds-client -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Delete Schema Registry RBAC credential
kubectl delete secret sr-mds-client -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west
kubectl delete secret sr-mds-client -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl delete secret sr-mds-client -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Delete Kafka RBAC credential
kubectl delete secret mds-client -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west
kubectl delete secret mds-client -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl delete secret mds-client -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Delete Kubernetes secret object for MDS:
kubectl delete secret mds-token -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west
kubectl delete secret mds-token -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl delete secret mds-token -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Delete credentials for Authentication and Authorization
kubectl delete secret credential -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west
kubectl delete secret credential -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl delete secret credential -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Delete CFK CA TLS certificates for auto generating certs
kubectl delete secret ca-pair-sslcerts -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west
kubectl delete secret ca-pair-sslcerts -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl delete secret ca-pair-sslcerts -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Delete service account
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/rack-awareness/service-account-rolebinding-west.yaml --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/rack-awareness/service-account-rolebinding-east.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl delete -f "$TUTORIAL_HOME"/confluent-platform/rack-awareness/service-account-rolebinding-central.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Uninstall Open LDAP
helm uninstall open-ldap -n central --kube-context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Uninstall CFK
helm uninstall cfk-operator -n west --kube-context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west
helm uninstall cfk-operator -n east --kube-context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
helm uninstall cfk-operator -n central --kube-context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Delete namespace
kubectl delete ns west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west
kubectl delete ns east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl delete ns central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central