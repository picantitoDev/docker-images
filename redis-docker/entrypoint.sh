#!/usr/bin/env sh
set -e

if [ -z "$REDIS_PASSWORD" ]; then
  echo "ERROR: REDIS_PASSWORD is not set. Exiting."
  exit 1
fi

envsubst < /usr/local/etc/redis/redis.conf.template > /usr/local/etc/redis/redis.conf

echo "Starting Redis with dynamic configuration..."
exec "$@"
