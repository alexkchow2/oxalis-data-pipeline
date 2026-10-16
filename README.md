# Sales Data Pipeline

## Project Overview

This project implements an end-to-end sales data pipeline using Python, PostgreSQL, dbt, and Docker.

The pipeline ingests sales transaction data from a CSV file, loads it into PostgreSQL, validates and transforms the records, and produces an aggregated daily sales dataset for reporting and analysis.

The solution is designed to be reproducible, modular, and testable, with clear separation between data ingestion, transformation, and data-quality validation.

### Technology Stack

- **Python:** CSV ingestion, database loading, and ETL error handling
- **PostgreSQL:** Raw data storage and analytical transformations
- **dbt:** Data cleaning, validation, aggregation, and automated data-quality tests
- **Docker Compose:** Containerized execution and service management
- **PowerShell:** End-to-end pipeline orchestration

## Pipeline Architecture

The pipeline follows a layered architecture that separates data ingestion, cleaning, validation, and aggregation.

```text
CSV File
   |
   v
Python ETL
   |
   v
PostgreSQL: public.raw_sales
   |
   v
dbt Staging: analytics.stg_sales
   |
   v
dbt Intermediate: analytics.int_sales_validated
   |
   v
dbt Mart: analytics.fct_daily_sales
```

### Data Processing Layers

**1. Raw Layer — `public.raw_sales`**

The Python ETL reads the source CSV and loads its records into PostgreSQL. Source values are preserved as text to avoid losing information during ingestion.

**2. Staging Layer — `analytics.stg_sales`**

The staging model standardizes source fields, converts values into appropriate data types, and identifies potentially ambiguous transaction dates.

**3. Intermediate Layer — `analytics.int_sales_validated`**

The intermediate model applies business validation rules, identifies valid and invalid transactions, and calculates net revenue for valid records.

Net revenue is calculated as:

`quantity × unit_price × (1 - discount)`

Invalid records are retained for inspection but excluded from revenue calculations.

**4. Mart Layer — `analytics.fct_daily_sales`**

The final model aggregates valid transactions by transaction date and store, producing:

- Transaction count
- Units sold
- Total net revenue

This table is the reporting-ready output of the pipeline.

### Orchestration

The `run_pipeline.ps1` script executes the pipeline sequentially:

1. Run the Python ETL.
2. Execute the dbt transformations.
3. Run the dbt data-quality tests.

The script checks the exit status of each stage and stops if a stage fails, preventing subsequent steps from executing after a detected failure.

## Data Quality and Validation

The pipeline uses a combination of business validation rules and automated dbt tests to maintain data quality.

### Transaction Validation Rules

A transaction is considered valid only when all of the following conditions are met:

- Transaction ID is present and not blank.
- Transaction date can be parsed and is not flagged as ambiguous.
- Quantity is greater than zero.
- Unit price is greater than zero.
- Discount is between 0 and 1, inclusive.

Dates with ambiguous day/month ordering are conservatively excluded when detected rather than interpreted using an arbitrary convention.

Records failing validation remain in the intermediate model with `is_valid = FALSE`. Their `net_revenue` is set to `NULL`, and they are excluded from the final sales mart.

### Automated dbt Tests

Eight automated tests verify the pipeline's output:

| Test | Purpose |
|---|---|
| Raw row ID — unique | Ensures each raw record has a unique row identifier |
| Raw row ID — not null | Ensures raw records have row identifiers |
| Mart transaction date — not null | Ensures aggregated records have a date |
| Mart store ID — not null | Ensures aggregated records have a store |
| Mart net revenue — not null | Ensures aggregated records have revenue |
| Unique daily store | Prevents duplicate date/store combinations in the mart |
| Revenue reconciliation | Verifies total valid transaction revenue matches the mart |
| Invalid transaction revenue | Ensures invalid transactions never contribute revenue |

### Validation Results

The pipeline was tested against the supplied 51-row CSV dataset.

| Metric | Result |
|---|---:|
| Raw transactions | 51 |
| Valid transactions | 35 |
| Invalid transactions | 16 |
| Final daily/store records | 35 |
| Total net revenue | $20,676.57 |
| Automated tests passed | 8 of 8 |

These figures describe the supplied sample dataset, not a guarantee for other input files.

### Known Limitations

- Ambiguous date handling is intentionally conservative and may exclude otherwise valid transactions.
- Date parsing does not independently verify every calendar-date component.
- Duplicate nonblank transaction IDs are not explicitly rejected.
- The revenue reconciliation test compares overall totals rather than individual date/store groups.
- The orchestration script is designed for local execution rather than scheduled production deployment.

## Setup and Execution

### Prerequisites

- Docker Desktop with Docker Compose
- Windows PowerShell
- Git

Python, PostgreSQL, and dbt are installed inside Docker containers, so separate local installations are not required.

### 1. Clone the Repository

```bash
git clone https://github.com/alexkchow2/oxalis-data-pipeline.git
cd oxalis-data-pipeline
```

**Note:** This repository is private. You must have access to the repository to clone it.

### 2. Configure Environment Variables

Create a `.env` file in the project root using `.env.example` as the template:

```powershell
Copy-Item .env.example .env
```

The environment variables configure the PostgreSQL database name, username, and password.

The `.env` file is excluded from Git to avoid committing credentials.

### 3. Start PostgreSQL

Ensure Docker Desktop is running, then execute:

```powershell
docker compose up -d postgres
```

Docker Compose creates the PostgreSQL container and its persistent data volume.

### 4. Run the Complete Pipeline

Execute the orchestration script:

```powershell
.\run_pipeline.ps1
```

If PowerShell blocks script execution, enable it for the current terminal session:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Then rerun the script.

The pipeline performs three operations in sequence:

1. Load the CSV into PostgreSQL using Python.
2. Execute the dbt transformations.
3. Run the dbt data-quality tests.

A successful execution ends with:

```text
=== Pipeline Completed Successfully ===
```

### 5. Query the Results

To inspect the reporting-ready sales data:

```powershell
docker compose exec -T postgres psql -U sales_user -d sales_db -c "SELECT * FROM analytics.fct_daily_sales ORDER BY transaction_date, store_id LIMIT 10;"
```

### 6. Stop the Containers

```powershell
docker compose down
```

This stops and removes the containers while preserving the PostgreSQL data volume.
