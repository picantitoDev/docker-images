# ===============================
# PostgreSQL API Setup Image
# ===============================

FROM postgres:16

LABEL maintainer="Piero <your-email@example.com>"
LABEL description="PostgreSQL configured for API access on LAN"

# -------------------------------------------------
# Environment variables (you can override at build or runtime)
# -------------------------------------------------
ENV POSTGRES_USER=piero
ENV POSTGRES_PASSWORD=piero
ENV POSTGRES_DB=sgi
ENV SHADOW_DB=sgi_shadow

# -------------------------------------------------
# Copy configuration files
# -------------------------------------------------
# You’ll provide these in the same directory as this Dockerfile
COPY ./conf/postgresql.conf /etc/postgresql/postgresql.conf
COPY ./conf/pg_hba.conf /etc/postgresql/pg_hba.conf

# -------------------------------------------------
# Initialization SQL script — creates user, DBs, roles
# -------------------------------------------------
# This runs automatically when the container starts for the first time
COPY ./initdb.d/ /docker-entrypoint-initdb.d/

# -------------------------------------------------
# Expose PostgreSQL port
# -------------------------------------------------
EXPOSE 5432

# -------------------------------------------------
# Start PostgreSQL with your config file
# -------------------------------------------------
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
