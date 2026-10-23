# CNPG TimescaleDB

CloudNativePG-compatible PostgreSQL image with TimescaleDB installed.

Published image:

```text
ghcr.io/acaylor/cnpg-timescaledb:17.11-ts2.31.0
```

## Version Tags

Tags use this format:

```text
<postgres-major>.<postgres-minor>-ts<timescaledb-major>.<timescaledb-minor>.<timescaledb-patch>
```

Example: `17.11-ts2.31.0` installs exactly TimescaleDB `2.31.0` (extension and loader packages) on the CloudNativePG `17.11-system-bookworm` base image.

The PostgreSQL version in the tag is the version shipped in the image. The build holds the base image's `postgresql-17` package and fails if the requested TimescaleDB packages need a different PostgreSQL minor, rather than letting apt upgrade it.

The base image is `ghcr.io/cloudnative-pg/postgresql:<postgres-version>-<base-variant>`, with `system-bookworm` as the default variant. CloudNativePG's bare `<postgres-version>` tags are Debian bullseye, and TimescaleDB stopped publishing bullseye packages after `2.26.4`.

Images tagged `17.4-ts*` were built before this check existed: they are labelled 17.4 but contain PostgreSQL 17.10, because the TimescaleDB packages required `postgresql-17 (>= 17.9)` and apt upgraded the server during the build.

## Build Locally

```bash
docker build \
  --build-arg PG_VERSION=17.11 \
  --build-arg PG_BASE_VARIANT=system-bookworm \
  --build-arg PG_MAJOR=17 \
  --build-arg TIMESCALEDB_VERSION=2.31.0 \
  -t ghcr.io/acaylor/cnpg-timescaledb:17.11-ts2.31.0 .
```

## CloudNativePG Usage

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: timescaledb
spec:
  instances: 3
  imageName: ghcr.io/acaylor/cnpg-timescaledb:17.11-ts2.31.0
  postgresql:
    parameters:
      shared_preload_libraries: timescaledb
  bootstrap:
    initdb:
      database: app
      owner: app
      postInitSQL:
        - CREATE EXTENSION IF NOT EXISTS timescaledb;
```

After rolling an existing cluster onto a newer TimescaleDB, update the extension in each database that uses it, as the first command in a new session:

```bash
psql -X -d app -c "ALTER EXTENSION timescaledb UPDATE;"
```

## Publishing

Images are published to GHCR by GitHub Actions.

To publish a new version, either run the `Publish image` workflow manually or push a tag matching the image tag format:

```bash
git tag 17.11-ts2.31.0
git push origin 17.11-ts2.31.0
```

Tag-triggered builds use the `system-bookworm` base variant. To build on another variant, such as `standard-trixie`, run the workflow manually and set `base-variant`.
