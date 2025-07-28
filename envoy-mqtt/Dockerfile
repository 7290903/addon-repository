FROM envoyproxy/envoy:v1.29-latest

# Копируем скрипты
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Устанавливаем jq и yq
RUN apt-get update && \
    apt-get install -y jq curl && \
    curl -sL https://github.com/mikefarah/yq/releases/download/v4.43.1/yq_linux_amd64 -o /usr/bin/yq && \
    chmod +x /usr/bin/yq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Переходим на root-пользователя
USER root

CMD ["/run.sh"]
