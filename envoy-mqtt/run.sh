#!/bin/bash

CONFIG_PATH="/data/options.json"
TMP_CONFIG="/tmp/options.json"
ENVOY_CONFIG="/tmp/envoy.yaml"

echo "🔧 Генерация envoy.yaml на основе UI-конфигурации..."

# Ждём, пока options.json появится
while [ ! -f "$CONFIG_PATH" ]; do
  echo "⏳ Ожидаем появления $CONFIG_PATH..."
  sleep 1
done

# Копируем файл во временное место
cp "$CONFIG_PATH" "$TMP_CONFIG"

# Чтение параметров
PORT=$(jq -r '.port' "$TMP_CONFIG")
BROKERS=$(jq -r '.brokers[]' "$TMP_CONFIG")

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
        - lb_endpoints:
EOF

for broker in $BROKERS; do
  cat >> "$ENVOY_CONFIG" <<EOF
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
