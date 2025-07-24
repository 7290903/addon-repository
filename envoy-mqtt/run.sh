#!/usr/bin/env bash
echo "🚀 Starting Envoy MQTT Proxy..."
exec envoy -c /etc/envoy/envoy.yaml --log-level info