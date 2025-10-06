FROM redis:6-alpine

RUN apk add --no-cache gettext

COPY redis.conf.template /usr/local/etc/redis/redis.conf.template
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV REDIS_PASSWORD=change_me
ENV REDIS_PORT=6379
ENV REDIS_BIND=0.0.0.0
ENV REDIS_PROTECTED_MODE=yes

EXPOSE ${REDIS_PORT}
VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]
