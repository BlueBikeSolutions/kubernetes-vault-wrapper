COPY ./deps.sh /usr/local/bin/kubernetes-vault-wrapper-deps.sh
USER root
RUN /usr/local/bin/kubernetes-vault-wrapper-deps.sh

COPY ./wrapper.sh /usr/local/bin/kubernetes-vault-wrapper.sh
