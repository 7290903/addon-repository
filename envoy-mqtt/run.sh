#!/bin/bash
echo "Starting Envoy MQTT Proxy..."
/usr/local/bin/envoy -c /etc/envoy/envoy.yaml
