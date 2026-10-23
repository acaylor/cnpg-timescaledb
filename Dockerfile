ARG PG_VERSION=17.11
ARG PG_BASE_VARIANT=standard-trixie
FROM ghcr.io/cloudnative-pg/postgresql:${PG_VERSION}-${PG_BASE_VARIANT}

ARG PG_VERSION
ARG PG_MAJOR=17
ARG TIMESCALEDB_VERSION=2.31.0

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# TimescaleDB packages depend on a minimum postgresql-${PG_MAJOR} version, and
# apt will silently upgrade the server to satisfy it. Hold the base image's
# PostgreSQL so the build fails instead of shipping a different version than
# the tag says, and install exactly TIMESCALEDB_VERSION.
RUN pg_package="postgresql-${PG_MAJOR}" \
    && pg_installed="$(dpkg-query -W -f='${Version}' "$pg_package")" \
    && if [[ "$pg_installed" != "${PG_VERSION}-"* ]]; then echo "base image has $pg_package $pg_installed, expected ${PG_VERSION}" >&2; exit 1; fi \
    && apt-mark hold "$pg_package" \
    && apt-get update \
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
    && find_version() { apt-cache madison "$1" | awk -v want="${TIMESCALEDB_VERSION}~" 'index($3, want) == 1 { print $3; exit }'; } \
    && version="$(find_version "$package")" \
    && loader_version="$(find_version "$loader_package")" \
    && if [[ -z "$version" || -z "$loader_version" ]]; then echo "TimescaleDB ${TIMESCALEDB_VERSION} not available for $VERSION_CODENAME" >&2; exit 1; fi \
    && apt-get install -y --no-install-recommends "$loader_package=$loader_version" "$package=$version" \
    && test "$(dpkg-query -W -f='${Version}' "$pg_package")" == "$pg_installed" \
    && test -f "/usr/lib/postgresql/${PG_MAJOR}/lib/timescaledb-${TIMESCALEDB_VERSION}.so" \
    && apt-mark unhold "$pg_package" \
    && apt-get purge -y --auto-remove gnupg wget \
    && rm -rf /var/lib/apt/lists/*

USER 26
