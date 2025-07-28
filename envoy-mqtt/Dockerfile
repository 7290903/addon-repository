FROM envoyproxy/envoy:v1.29-latest

# Копируем скрипт запуска
COPY run.sh /run.sh
RUN chmod +x /run.sh


# Выполняем от root
USER root

CMD ["/run.sh"]
