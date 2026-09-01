ARG PG_VERSION=17.11
FROM ghcr.io/cloudnative-pg/postgresql:${PG_VERSION}

ARG PG_MAJOR=17
ARG TIMESCALEDB_VERSION=2.17

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates gnupg wget \
    && install -d -m 0755 /usr/share/keyrings \
    && wget -qO- https://packagecloud.io/timescale/timescaledb/gpgkey \
        | gpg --dearmor -o /usr/share/keyrings/timescaledb.gpg \
    && chmod 0644 /usr/share/keyrings/timescaledb.gpg \
    && . /etc/os-release \
    && printf 'deb [signed-by=/usr/share/keyrings/timescaledb.gpg] https://packagecloud.io/timescale/timescaledb/debian/ %s main\n' "$VERSION_CODENAME" \
        > /etc/apt/sources.list.d/timescaledb.list \
    && apt-get update \
    && package="timescaledb-2-postgresql-${PG_MAJOR}" \
    && loader_package="timescaledb-2-loader-postgresql-${PG_MAJOR}" \
    && apt-cache madison "$package" > /tmp/timescaledb-versions \
    && apt-cache madison "$loader_package" > /tmp/timescaledb-loader-versions \
    && version="" \
    && loader_version="" \
    && while read -r _ _ candidate _; do if [[ -z "$version" && "$candidate" == "${TIMESCALEDB_VERSION}"* ]]; then version="$candidate"; fi; done < /tmp/timescaledb-versions \
    && while read -r _ _ candidate _; do if [[ -z "$loader_version" && "$candidate" == "${TIMESCALEDB_VERSION}"* ]]; then loader_version="$candidate"; fi; done < /tmp/timescaledb-loader-versions \
    && test -n "$version" \
    && test -n "$loader_version" \
    && apt-get install -y --no-install-recommends --no-upgrade "$loader_package=$loader_version" "$package=$version" \
    && apt-get purge -y --auto-remove gnupg wget \
    && rm -rf /var/lib/apt/lists/*

USER postgres
