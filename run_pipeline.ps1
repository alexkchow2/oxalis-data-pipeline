$ErrorActionPreference = "Stop"

Write-Host "`n=== Starting Sales Data Pipeline ===" -ForegroundColor Cyan

Write-Host "`n[1/3] Running Python ETL..." -ForegroundColor Yellow
docker compose run --rm --build etl

if ($LASTEXITCODE -ne 0) {
    throw "ETL failed with exit code $LASTEXITCODE"
}

Write-Host "`n[2/3] Running dbt transformations..." -ForegroundColor Yellow
docker compose run --rm --build dbt run

if ($LASTEXITCODE -ne 0) {
    throw "dbt transformations failed with exit code $LASTEXITCODE"
}

Write-Host "`n[3/3] Running dbt tests..." -ForegroundColor Yellow
docker compose run --rm dbt test

if ($LASTEXITCODE -ne 0) {
    throw "dbt tests failed with exit code $LASTEXITCODE"
}

Write-Host "`n=== Pipeline Completed Successfully ===" -ForegroundColor Green