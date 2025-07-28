FROM envoyproxy/envoy:v1.29-latest

# Копируем скрипты
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Устанавливаем утилиту jq
RUN apt-get update && \
    apt-get install -y jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Выполняем от root (нужно для чтения /data/options.json)
USER root

CMD ["/run.sh"]
