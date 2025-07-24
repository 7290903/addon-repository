FROM envoyproxy/envoy:v1.29-latest

COPY envoy.yaml /etc/envoy/envoy.yaml
COPY run.sh /run.sh
RUN chmod +x /run.sh
CMD [ "/run.sh" ]