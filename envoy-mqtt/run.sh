#!/bin/bash

echo "🔧 Генерация envoy.yaml на основе UI-конфигурации..."

CONFIG_PATH=/data/options.json
ENVOY_CONFIG=/etc/envoy/envoy.yaml

PORT=$(jq -r '.port' "$CONFIG_PATH")
BROKERS=$(jq -r '.brokers[]' "$CONFIG_PATH")
BROKER_PORT=1883  # Порты брокеров фиксированные

mkdir -p /etc/envoy

cat > "$ENVOY_CONFIG" <<EOF
static_resources:
  listeners:
    - name: mqtt_listener
      address:
        socket_address:
          address: 0.0.0.0
          port_value: ${PORT}
      filter_chains:
        - filters:
            - name: envoy.filters.network.tcp_proxy
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
                stat_prefix: mqtt
                cluster: mqtt_cluster

  clusters:
    - name: mqtt_cluster
      connect_timeout: 1s
      type: strict_dns
      lb_policy: ROUND_ROBIN
      health_checks:
        - timeout: 1s
          interval: 5s
          unhealthy_threshold: 2
          healthy_threshold: 2
          tcp_health_check: {}
      load_assignment:
        cluster_name: mqtt_cluster
        endpoints:
          - lb_endpoints:
EOF

for addr in $BROKERS; do
cat >> "$ENVOY_CONFIG" <<EOF
              - endpoint:
                  address:
                    socket_address:
                      address: ${addr}
                      port_value: ${BROKER_PORT}
EOF
done

cat >> "$ENVOY_CONFIG" <<EOF

admin:
  access_log_path: "/tmp/envoy_admin.log"
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 9901
EOF

echo "✅ envoy.yaml сгенерирован:"
cat "$ENVOY_CONFIG"

echo "🚀 Запуск Envoy Proxy..."
exec envoy --config-path "$ENVOY_CONFIG" --log-level info
