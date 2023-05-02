FROM postgres:13.3-alpine
COPY ./deps.sh /usr/local/bin/kubernetes-vault-wrapper-deps.sh
RUN /usr/local/bin/kubernetes-vault-wrapper-deps.sh

COPY ./wrapper.sh /usr/local/bin/kubernetes-vault-wrapper.sh
ENTRYPOINT ["/usr/local/bin/kubernetes-vault-wrapper.sh","docker-entrypoint.sh"]
CMD ["postgres"]
