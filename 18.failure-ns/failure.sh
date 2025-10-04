#!/bin/bash
NODE=$1

if [ -z "$NODE" ]; then
  echo "Usage: $0 <node-name>"
  exit 1
fi

echo "Tainting node $NODE..."
kubectl taint nodes $NODE key=value:NoSchedule

echo "Draining node $NODE..."
kubectl drain $NODE --ignore-daemonsets --delete-emptydir-data

echo "Sleeping 30s to simulate failure..."
sleep 30

echo "Uncordoning node $NODE..."
kubectl uncordon $NODE

echo "Removing taint..."
kubectl taint nodes $NODE key:NoSchedule-
