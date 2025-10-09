# Use the official RabbitMQ image
FROM rabbitmq:management

# Expose RabbitMQ ports
EXPOSE 5672 15672

# Optional environment variables for credentials
ENV RABBITMQ_DEFAULT_USER=admin \
    RABBITMQ_DEFAULT_PASS=admin

# Start RabbitMQ server
CMD ["rabbitmq-server"]
