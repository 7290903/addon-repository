#!/bin/bash

set -e

echo "🧹 Очистка предыдущих временных файлов..."
rm -f /tmp/envoy.yaml

CONFIG_PATH="/config/envoy_mqtt.yaml"

echo "🔧 Генерация envoy.yaml на основе ${CONFIG_PATH}"

# Проверка доступности yq и jq
if ! command -v yq >/dev/null || ! command -v jq >/dev/null; then
  echo "❌ Ошибка: yq или jq не установлены или недоступны."
  exit 1
fi

# Ожидание появления конфигурационного файла
for i in {1..30}; do
  if [ -f "$CONFIG_PATH" ]; then
    break
  fi
  echo "⏳ Ждём появления ${CONFIG_PATH}..."
  sleep 1
done

if [ ! -f "$CONFIG_PATH" ]; then
  echo "❌ Не удалось найти ${CONFIG_PATH}"
  exit 1
fi

echo "🧾 UID: $(id -u), GID: $(id -g)"
ls -l "$CONFIG_PATH"

# Извлечение параметров
PORT=$(yq '.port' "$CONFIG_PATH")
BROKERS=$(yq '.brokers[]' "$CONFIG_PATH")

if [ -z "$PORT" ] || [ -z "$BROKERS" ]; then
  echo "❌ Ошибка: не удалось получить настройки порта или брокеров."
  exit 1
fi

echo "📦 Настройки:"
echo "🛠️  Порт: $PORT"
echo "🌐 Брокеры:"
for broker in $BROKERS; do
  echo "  - $broker"
done

# Генерация envoy.yaml
cat <<EOF > /tmp/envoy.yaml
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
$(for broker in $BROKERS; do
  echo "        - lb_endpoints:"
  echo "            - endpoint:"
  echo "                address:"
  echo "                  socket_address:"
  echo "                    address: $broker"
  echo "                    port_value: 1883"
done)
admin:
  access_log_path: "/tmp/envoy_admin.log"
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 9901
EOF

echo "✅ envoy.yaml сгенерирован:"
cat /tmp/envoy.yaml

echo "🚀 Запуск Envoy Proxy..."
exec envoy -c /tmp/envoy.yaml
