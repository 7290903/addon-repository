FROM envoyproxy/envoy:v1.29-latest

# Копируем скрипты и конфигурации
COPY run.sh /run.sh

# Разрешим запуск
RUN chmod +x /run.sh

# Установим утилиту jq для чтения JSON
RUN apt-get update && \
    apt-get install -y jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Точка входа
CMD ["/run.sh"]
