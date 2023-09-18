#!/bin/bash
# Make sure to complete Kubernetes networking setup before running this script.

# shellcheck disable=SC2128
TUTORIAL_HOME=$(dirname "$BASH_SOURCE")

# # Create namespace
# kubectl create ns central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central
# kubectl create ns east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
# kubectl create ns west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west

# # Set up the Helm Chart
# helm repo add confluentinc https://packages.confluent.io/helm

# # Install Confluent For Kubernetes
# helm upgrade --install cfk-operator confluentinc/confluent-for-kubernetes -n central --kube-context arn:aws:eks:us-east-2:829250931565:cluster/citi-central
# helm upgrade --install cfk-operator confluentinc/confluent-for-kubernetes -n east --kube-context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
# helm upgrade --install cfk-operator confluentinc/confluent-for-kubernetes -n west --kube-context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west

# # Deploy OpenLdap
# helm upgrade --install -f "$TUTORIAL_HOME"/../../../assets/openldap/ldaps-rbac.yaml open-ldap "$TUTORIAL_HOME"/../../../assets/openldap -n central --kube-context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Configure service account
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/rack-awareness/service-account-rolebinding-central.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/rack-awareness/service-account-rolebinding-east.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/rack-awareness/service-account-rolebinding-west.yaml --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west

# Create CFK CA TLS certificates for auto generating certs
kubectl create secret tls ca-pair-sslcerts \
  --cert="$TUTORIAL_HOME"/../../secrets/ca.pem \
  --key="$TUTORIAL_HOME"/../../secrets/ca-key.pem \
  -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central
kubectl create secret tls ca-pair-sslcerts \
  --cert="$TUTORIAL_HOME"/../../secrets/ca.pem  \
  --key="$TUTORIAL_HOME"/../../secrets/ca-key.pem \
  -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl create secret tls ca-pair-sslcerts \
  --cert="$TUTORIAL_HOME"/../../secrets/ca.pem  \
  --key="$TUTORIAL_HOME"/../../secrets/ca-key.pem \
  -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west

# Configure credentials for Authentication and Authorization
kubectl create secret generic credential \
  --from-file=digest-users.json="$TUTORIAL_HOME"/confluent-platform/credentials/zk-users-server.json \
  --from-file=digest.txt="$TUTORIAL_HOME"/confluent-platform/credentials/zk-users-client.txt \
  --from-file=plain-users.json="$TUTORIAL_HOME"/confluent-platform/credentials/kafka-users-server.json \
  --from-file=plain.txt="$TUTORIAL_HOME"/confluent-platform/credentials/kafka-users-client.txt \
  --from-file=ldap.txt="$TUTORIAL_HOME"/confluent-platform/credentials/ldap-client.txt \
  -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central
kubectl create secret generic credential \
  --from-file=digest-users.json="$TUTORIAL_HOME"/confluent-platform/credentials/zk-users-server.json \
  --from-file=digest.txt="$TUTORIAL_HOME"/confluent-platform/credentials/zk-users-client.txt \
  --from-file=plain-users.json="$TUTORIAL_HOME"/confluent-platform/credentials/kafka-users-server.json \
  --from-file=plain.txt="$TUTORIAL_HOME"/confluent-platform/credentials/kafka-users-client.txt \
  --from-file=ldap.txt="$TUTORIAL_HOME"/confluent-platform/credentials/ldap-client.txt \
  -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl create secret generic credential \
  --from-file=digest-users.json="$TUTORIAL_HOME"/confluent-platform/credentials/zk-users-server.json \
  --from-file=digest.txt="$TUTORIAL_HOME"/confluent-platform/credentials/zk-users-client.txt \
  --from-file=plain-users.json="$TUTORIAL_HOME"/confluent-platform/credentials/kafka-users-server.json \
  --from-file=plain.txt="$TUTORIAL_HOME"/confluent-platform/credentials/kafka-users-client.txt \
  --from-file=ldap.txt="$TUTORIAL_HOME"/confluent-platform/credentials/ldap-client.txt \
  -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west

# Create Kubernetes secret object for MDS:
kubectl create secret generic mds-token \
  --from-file=mdsPublicKey.pem="$TUTORIAL_HOME"/../../secrets/mds-publickey.txt \
  --from-file=mdsTokenKeyPair.pem="$TUTORIAL_HOME"/../../secrets/mds-tokenkeypair.txt \
  -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central
kubectl create secret generic mds-token \
  --from-file=mdsPublicKey.pem="$TUTORIAL_HOME"/../../secrets/mds-publickey.txt \
  --from-file=mdsTokenKeyPair.pem="$TUTORIAL_HOME"/../../secrets/mds-tokenkeypair.txt\
  -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl create secret generic mds-token \
  --from-file=mdsPublicKey.pem="$TUTORIAL_HOME"/../../secrets/mds-publickey.txt \
  --from-file=mdsTokenKeyPair.pem="$TUTORIAL_HOME"/../../secrets/mds-tokenkeypair.txt \
  -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west

# Create Kafka RBAC credential
kubectl create secret generic mds-client \
  --from-file=bearer.txt="$TUTORIAL_HOME"/confluent-platform/credentials/mds-client.txt \
  -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central
kubectl create secret generic mds-client \
  --from-file=bearer.txt="$TUTORIAL_HOME"/confluent-platform/credentials/mds-client.txt \
  -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl create secret generic mds-client \
  --from-file=bearer.txt="$TUTORIAL_HOME"/confluent-platform/credentials/mds-client.txt \
  -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west

# Create Schema Registry RBAC credential
kubectl create secret generic sr-mds-client \
  --from-file=bearer.txt="$TUTORIAL_HOME"/confluent-platform/credentials/sr-mds-client.txt \
  -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central
kubectl create secret generic sr-mds-client \
  --from-file=bearer.txt="$TUTORIAL_HOME"/confluent-platform/credentials/sr-mds-client.txt \
  -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl create secret generic sr-mds-client \
  --from-file=bearer.txt="$TUTORIAL_HOME"/confluent-platform/credentials/sr-mds-client.txt \
  -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west

# Create Control Center RBAC credential
kubectl create secret generic c3-mds-client \
  --from-file=bearer.txt="$TUTORIAL_HOME"/confluent-platform/credentials/c3-mds-client.txt \
  -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Create Kafka REST credential
kubectl create secret generic kafka-rest-credential \
  --from-file=bearer.txt="$TUTORIAL_HOME"/confluent-platform/credentials/mds-client.txt \
  -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central
kubectl create secret generic kafka-rest-credential \
  --from-file=bearer.txt="$TUTORIAL_HOME"/confluent-platform/credentials/mds-client.txt \
  -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl create secret generic kafka-rest-credential \
  --from-file=bearer.txt="$TUTORIAL_HOME"/confluent-platform/credentials/mds-client.txt \
  -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west

# Deploy Zookeeper cluster
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/zookeeper/zookeeper-central.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/zookeeper/zookeeper-east.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/zookeeper/zookeeper-west.yaml --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west

# Wait until Zookeeper is up
echo "Waiting for Zookeeper to be Ready..."
kubectl wait pod -l app=zookeeper --for=condition=Ready --timeout=-1s -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central
kubectl wait pod -l app=zookeeper --for=condition=Ready --timeout=-1s -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl wait pod -l app=zookeeper --for=condition=Ready --timeout=-1s -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west

# Deploy Kafka cluster
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/kafka/kafka-central.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/kafka/kafka-east.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/kafka/kafka-west.yaml --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west

# Wait until Kafka is up
echo "Waiting for Kafka to be Ready..."
kubectl wait pod -l app=kafka --for=condition=Ready --timeout=-1s -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central
kubectl wait pod -l app=kafka --for=condition=Ready --timeout=-1s -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl wait pod -l app=kafka --for=condition=Ready --timeout=-1s -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west

# Create Kafka REST class
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/kafkarestclass.yaml -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/kafkarestclass.yaml -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/kafkarestclass.yaml -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west

# Create role bindings for Schema Registry
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/rolebindings/mrc-rolebindings.yaml -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/rolebindings/mrc-rolebindings.yaml -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/rolebindings/mrc-rolebindings.yaml -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west

# Create role bindings for Control Center
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/rolebindings/c3-rolebindings.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Deploy Schema Registry cluster
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/schemaregistry/schemaregistry-central.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/schemaregistry/schemaregistry-east.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/schemaregistry/schemaregistry-west.yaml --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west

# Wait until Schema Registry is up
echo "Waiting for Schema Registry to be Ready..."
kubectl wait pod -l app=schemaregistry --for=condition=Ready --timeout=-1s -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central
kubectl wait pod -l app=schemaregistry --for=condition=Ready --timeout=-1s -n east --context arn:aws:eks:us-east-2:829250931565:cluster/citi-east
kubectl wait pod -l app=schemaregistry --for=condition=Ready --timeout=-1s -n west --context arn:aws:eks:ca-central-1:829250931565:cluster/citi-west

# Deploy Control Center
kubectl apply -f "$TUTORIAL_HOME"/confluent-platform/controlcenter.yaml --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central

# Wait until Control Center is up
echo "Waiting for Control Center to be Ready..."
sleep 2
kubectl wait pod -l app=controlcenter --for=condition=Ready --timeout=-1s -n central --context arn:aws:eks:us-east-2:829250931565:cluster/citi-central