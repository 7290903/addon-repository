#!/bin/bash

echo "🔧 Генерация envoy.yaml на основе переменных окружения..."
echo "🧾 UID: $(id -u), GID: $(id -g)"

PORT="${PORT:-1883}"

# Сбор брокеров из переменных окружения BROKERS_0, BROKERS_1, ...
BROKERS=()
i=0
while true; do
    broker_var="BROKERS_$i"
    val="${!broker_var}"
    if [ -z "$val" ]; then
        break
    fi
    BROKERS+=("$val")
    i=$((i+1))
done

if [[ -z "$PORT" || ${#BROKERS[@]} -eq 0 ]]; then
  echo "❌ Ошибка: переменные PORT или BROKERS не заданы."
  exit 1
fi

echo "🌐 PORT: $PORT"
echo "🧩 BROKERS: ${BROKERS[*]}"

ENVOY_CONFIG="/tmp/envoy.yaml"

# Генерация envoy.yaml
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
    type: STRICT_DNS
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: mqtt_cluster
      endpoints:
        - lb_endpoints:
EOF

for broker in "${BROKERS[@]}"; do
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
echo "🧾 Переменные окружения:"
env | sort