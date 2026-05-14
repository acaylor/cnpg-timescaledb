# CNPG TimescaleDB

CloudNativePG-compatible PostgreSQL image with TimescaleDB installed.

Published image:

```text
ghcr.io/acaylor/cnpg-timescaledb:17.4-ts2.17
```

## Version Tags

Tags use this format:

```text
<postgres-version>-ts<timescaledb-version>
```

Example: `17.4-ts2.17` installs TimescaleDB `2.17.x` on the CloudNativePG PostgreSQL `17.4` base image.

## Build Locally

```bash
docker build \
  --build-arg PG_VERSION=17.4 \
  --build-arg PG_MAJOR=17 \
  --build-arg TIMESCALEDB_VERSION=2.17 \
  -t ghcr.io/acaylor/cnpg-timescaledb:17.4-ts2.17 .
```

## CloudNativePG Usage

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: timescaledb
spec:
  instances: 3
  imageName: ghcr.io/acaylor/cnpg-timescaledb:17.4-ts2.17
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

## Publishing

Images are published to GHCR by GitHub Actions.

To publish a new version, either run the `Publish image` workflow manually or push a tag matching the image tag format:

```bash
git tag 17.4-ts2.17
git push origin 17.4-ts2.17
```
