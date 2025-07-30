#!/bin/bash
echo "🧹 Очистка предыдущих временных файлов..."
rm -f /tmp/envoy.yaml
rm -f /tmp/options.json

CONFIG_FILE="/config/envoy_mqtt.yaml"
ENVOY_CONFIG="/tmp/envoy.yaml"

echo "🔧 Генерация envoy.yaml на основе $CONFIG_FILE"
echo "🧾 UID: $(id -u), GID: $(id -g)"

# Проверяем наличие конфигурационного файла
while [ ! -f "$CONFIG_FILE" ]; do
  echo "⏳ Ждём появления $CONFIG_FILE..."
  sleep 2
done

ls -l "$CONFIG_FILE"

# Получаем настройки из YAML-файла
PORT=$(yq '.port' "$CONFIG_FILE")
BROKERS=$(yq '.brokers[]' "$CONFIG_FILE")

if [[ -z "$PORT" || -z "$BROKERS" ]]; then
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

export LD_PRELOAD=""  # <== сброс preload-библиотек

echo "🚀 Запуск Envoy Proxy..."
exec envoy -c "$ENVOY_CONFIG" --log-level info


echo "📦 Версия Envoy:"
envoy --version || echo "⚠️ Не удалось определить версию Envoy"

export LD_PRELOAD=""