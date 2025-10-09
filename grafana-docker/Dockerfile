# Use the official Grafana image from Docker Hub
FROM grafana/grafana:latest

# Set environment variables (optional)
ENV GF_SECURITY_ADMIN_USER=admin \
    GF_SECURITY_ADMIN_PASSWORD=admin \
    GF_SERVER_HTTP_PORT=3000

# Expose the Grafana port
EXPOSE 3000

# Optional: copy local configuration or provisioning files
# COPY ./provisioning /etc/grafana/provisioning
# COPY ./grafana.ini /etc/grafana/grafana.ini

# Run Grafana
CMD ["grafana-server", "--homepath=/usr/share/grafana"]
