#!/bin/sh
echo "=== Envoy MQTT Add-on Startup ==="
echo "Running as user: $(id) (UID $(id -u), GID $(id -g))"

# Проверяем доступность файла опций
CONFIG_PATH="/data/options.json"
if [ ! -f "$CONFIG_PATH" ]; then
  echo "ERROR: $CONFIG_PATH not found!"; exit 1
fi
if [ ! -r "$CONFIG_PATH" ]; then
  echo "ERROR: $CONFIG_PATH is not readable (permission denied)."; ls -la /data; exit 1
fi

echo "Found $CONFIG_PATH, permissions OK."
echo "--- /data directory listing ---"
ls -la /data
echo "--- options.json content ---"
cat "$CONFIG_PATH"
echo "-----------------------------"

# Читаем настройки пользователя (port и brokers) с помощью jq
MQTT_PORT=$(jq -r '.port // 1883' "$CONFIG_PATH")
BROKERS=$(jq -r '.brokers[]' "$CONFIG_PATH")

# Проверяем, что указан хотя бы один брокер
if [ -z "$BROKERS" ]; then
  echo "ERROR: No MQTT brokers specified in options!"; exit 1
fi

# Задаём порт брокеров (предполагаем, что все брокеры слушают MQTT на 1883)
BROKER_PORT=1883

# Выводим полученные параметры
echo "Configured Envoy listener port: $MQTT_PORT"
echo "Configured MQTT brokers (forward targets) on port $BROKER_PORT:"
for B in $BROKERS; do echo " - $B"; done

# Формируем конфигурационный файл Envoy (/static_resources/)
CONFIG_FILE="/tmp/envoy.yaml"
echo "Generating Envoy config at $CONFIG_FILE ..."

cat > "$CONFIG_FILE" <<EOF
static_resources:
  listeners:
    - name: mqtt_listener
      address:
        socket_address:
          address: 0.0.0.0
          port_value: ${MQTT_PORT}
      filter_chains:
        - filters:
            - name: envoy.filters.network.tcp_proxy
              typed_config:
                "@type": "type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy"
                stat_prefix: mqtt_proxy
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

# Добавляем список брокеров в конфиг (каждый как endpoint)
for BROKER in $BROKERS; do
cat >> "$CONFIG_FILE" <<EOF
              - endpoint:
                  address:
                    socket_address:
                      address: ${BROKER}
                      port_value: ${BROKER_PORT}
EOF
done

# Дополняем конфиг разделом admin (для отладки Envoy) и завершаем EOF
cat >> "$CONFIG_FILE" <<EOF

admin:
  access_log_path: "/tmp/envoy_admin.log"
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 9901
EOF

echo "Envoy configuration generated:"
echo "---------------------"
cat "$CONFIG_FILE"
echo "---------------------"

# Устанавливаем переменную, чтобы Envoy не понижал права (останется root внутри контейнера)
export ENVOY_UID=0
echo "Starting Envoy proxy (envoy UID=$ENVOY_UID)..."
exec envoy -c "$CONFIG_FILE" --log-level info
