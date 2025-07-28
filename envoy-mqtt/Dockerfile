FROM envoyproxy/envoy:v1.29-latest

# Переключаемся на пользователя root для установки пакетов и доступа к /data
USER root

# Устанавливаем jq для разбора JSON (в базовом образе Envoy отсутствует). 
# Используем пакетный менеджер Alpine (apk):contentReference[oaicite:1]{index=1}, так как envoy:v1.29 основан на Alpine.
RUN apk --no-cache add jq

# Копируем скрипт запуска и даём ему права исполнения
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Определяем точку входа контейнера
ENTRYPOINT ["/run.sh"]
