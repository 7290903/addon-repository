#!/bin/bash

CONFIG_PATH="/data/options.json"
ENVOY_CONFIG="/tmp/envoy.yaml"

echo "🧾 UID: $(id -u), GID: $(id -g)"
echo "📂 Содержимое /data:"
ls -la /data
echo "📄 Права на $CONFIG_PATH:"
ls -l "$CONFIG_PATH"

echo "🔧 Генерация envoy.yaml на основе UI-конфигурации..."

# Ждём, пока Home Assistant смонтирует конфиг
while [ ! -f "$CONFIG_PATH" ]; do
  echo "⏳ Ждём появления конфигурации Home Assistant ($CONFIG_PATH)..."
  sleep 1
done


# Получаем порт и список брокеров из options.json
PORT=$(jq -r '.port // 1883' "$CONFIG_PATH")
BROKERS=$(jq -r '.brokers[]' "$CONFIG_PATH")

if [[ -z "$PORT" || -z "$BROKERS" ]]; then
  echo "❌ Ошибка: не удалось получить настройки порта или брокеров."
  exit 1
fi

# Генерируем список кластеров
CLUSTERS=""
ENDPOINTS=""
INDEX=0
for BROKER in $BROKERS; do
  CLUSTER_NAME="mqtt_target_$INDEX"
  CLUSTERS+=$(cat <<EOF

  - name: $CLUSTER_NAME
    connect_timeout: 1s
    type: LOGICAL_DNS
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: $CLUSTER_NAME
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: $BROKER
                port_value: $PORT
EOF
)
  INDEX=$((INDEX+1))
done

# Генерируем envoy.yaml
cat > "$ENVOY_CONFIG" <<EOF
static_resources:
  listeners:
  - name: listener_0
    address:
      socket_address:
        address: 0.0.0.0
        port_value: $PORT
    filter_chains:
    - filters:
      - name: envoy.filters.network.tcp_proxy
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
          stat_prefix: mqtt_tcp
          cluster: mqtt_target_0
          weighted_clusters:
            clusters:
EOF

INDEX=0
for BROKER in $BROKERS; do
  echo "              - name: mqtt_target_$INDEX" >> "$ENVOY_CONFIG"
  echo "                weight: 1" >> "$ENVOY_CONFIG"
  INDEX=$((INDEX+1))
done

cat >> "$ENVOY_CONFIG" <<EOF

  clusters:
$CLUSTERS
EOF

echo "✅ envoy.yaml сгенерирован:"
cat "$ENVOY_CONFIG"

echo "🚀 Запуск Envoy Proxy..."
exec envoy --config-path "$ENVOY_CONFIG" --log-level info
