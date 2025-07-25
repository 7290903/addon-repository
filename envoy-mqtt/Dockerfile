FROM envoyproxy/envoy:v1.29-latest

# Копируем скрипты и конфигурации
COPY run.sh /run.sh

# Разрешим запуск
RUN chmod +x /run.sh

# Установим утилиту jq для чтения JSON
RUN apt-get update && \
    apt-get install -y jq bash && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Точка входа
USER root
CMD ["/run.sh"]

echo "🧾 UID: $(id -u), GID: $(id -g)"
ls -l "$CONFIG_PATH"