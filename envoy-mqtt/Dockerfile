FROM envoyproxy/envoy:v1.29-latest

# Копируем скрипт запуска
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Устанавливаем jq
RUN apt-get update && \
    apt-get install -y jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Выполняем от root
USER root

CMD ["/run.sh"]
