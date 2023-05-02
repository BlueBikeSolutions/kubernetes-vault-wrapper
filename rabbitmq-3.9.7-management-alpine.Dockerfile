FROM rabbitmq:3.9.7-management-alpine
COPY ./deps.sh /usr/local/bin/kubernetes-vault-wrapper-deps.sh
RUN /usr/local/bin/kubernetes-vault-wrapper-deps.sh

COPY ./wrapper.sh /usr/local/bin/kubernetes-vault-wrapper.sh
ENTRYPOINT
CMD
