#!/bin/bash

YAML_CONFIG="/config/envoy_mqtt.yaml"
ENVOY_CONFIG="/tmp/envoy.yaml"

echo "🔧 Генерация envoy.yaml на основе $YAML_CONFIG"

# Ждём, пока появится конфиг
while [ ! -f "$YAML_CONFIG" ]; do
  echo "⏳ Ждём появления $YAML_CONFIG..."
  sleep 1
done

# UID для отладки
echo "🧾 UID: $(id -u), GID: $(id -g)"
ls -l "$YAML_CONFIG"

# Извлекаем порт и брокеров с помощью yq
PORT=$(yq eval '.port // 1883' "$YAML_CONFIG")
BROKERS=$(yq eval '.brokers[]' "$YAML_CONFIG")

if [[ -z "$PORT" || -z "$BROKERS" ]]; then
  echo "❌ Ошибка: не удалось получить настройки порта или брокеров."
  exit 1
fi

# Генерация envoy.yaml
cat > "$ENVOY_CONFIG" <<EOF
static_resources:
  listeners:
  - name: listener_0
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
    type: STRICT_DNS
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: mqtt_cluster
      endpoints:
EOF

for broker in $BROKERS; do
  cat >> "$ENVOY_CONFIG" <<EOF
        - lb_endpoints:
          - endpoint:
              address:
                socket_address:
                  address: $broker
                  port_value: 1883
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
exec envoy -c "$ENVOY_CONFIG" --log-level info
