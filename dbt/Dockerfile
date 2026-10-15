FROM python:3.12-slim

WORKDIR /app/dbt

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir "dbt-postgres>=1.9,<2.0"

COPY dbt/ /app/dbt/

ENV DBT_PROFILES_DIR=/app/dbt

ENTRYPOINT ["dbt"]