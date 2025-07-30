FROM envoyproxy/envoy:v1.29-latest

# Копируем скрипт
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Устанавливаем Python3 и yq (на Python)
RUN apt-get update && \
    apt-get install -y python3 python3-pip curl && \
    pip3 install yq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Запускаем от root
USER root

CMD ["/run.sh"]

