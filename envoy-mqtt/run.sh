#!/bin/bash

echo "🔧 Генерация envoy.yaml на основе UI-конфигурации..."

CONFIG_PATH=/data/options.json

PORT=$(jq -r '.port' "$CONFIG_PATH")
BROKER1=$(jq -r '.broker1' "$CONFIG_PATH")
BROKER2=$(jq -r '.broker2' "$CONFIG_PATH")
BROKER3=$(jq -r '.broker3' "$CONFIG_PATH")
BROKER4=$(jq -r '.broker4' "$CONFIG_PATH")

cat > /etc/envoy/envoy.yaml <<EOF
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
              - endpoint:
                  address:
                    socket_address:
                      address: ${BROKER1}
                      port_value: ${PORT}
              - endpoint:
                  address:
                    socket_address:
                      address: ${BROKER2}
                      port_value: ${PORT}
              - endpoint:
                  address:
                    socket_address:
                      address: ${BROKER3}
                      port_value: ${PORT}
              - endpoint:
                  address:
                    socket_address:
                      address: ${BROKER4}
                      port_value: ${PORT}

admin:
  access_log_path: "/tmp/envoy_admin.log"
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 9901
EOF

echo "✅ envoy.yaml сгенерирован"
echo "🚀 Запуск Envoy Proxy..."
exec envoy --config-path /etc/envoy/envoy.yaml --log-level info
echo "========== envoy.yaml =========="
cat /etc/envoy/envoy.yaml
