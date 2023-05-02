FROM bitnami/redis:4.0
COPY ./deps.sh /usr/local/bin/kubernetes-vault-wrapper-deps.sh
RUN /usr/local/bin/kubernetes-vault-wrapper-deps.sh

COPY ./wrapper.sh /usr/local/bin/kubernetes-vault-wrapper.sh
ENTRYPOINT
CMD
