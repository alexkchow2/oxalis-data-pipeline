import os
import psycopg
import csv
from pathlib import Path

# Locate the CSV relative to this script, not the terminal's directory.
PROJECT_ROOT = Path(__file__).resolve().parent.parent
CSV_PATH = PROJECT_ROOT / "data" / "example_sales_data.csv"
SCHEMA_PATH = PROJECT_ROOT / "sql" / "create_raw_tables.sql"

# Map original CSV headers to standardized database column names.
COLUMN_MAPPING = {
    "date": "transaction_date",
    "store ID": "store_id",
    "PRODUCT_NAME": "product_name",
    "quantity": "quantity",
    "Price": "unit_price",
    "customer_type": "customer_type",
    "Payment Method": "payment_method",
    "Transaction_ID": "transaction_id",
    "discount%": "discount",
    "region": "region",
}


def read_sales_csv():
    with CSV_PATH.open("r", encoding="utf-8-sig", newline="") as file:
        reader = csv.DictReader(file, skipinitialspace=True)

        actual_columns = reader.fieldnames
        expected_columns = list(COLUMN_MAPPING.keys())

        if actual_columns is None:
            raise ValueError("CSV file is empty or missing a header.")

        if set(actual_columns) != set(expected_columns):
            raise ValueError(
                f"Unexpected CSV columns.\n"
                f"Expected: {expected_columns}\n"
                f"Actual: {actual_columns}"
            )

        records = []

        for row_number, row in enumerate(reader, start=2):
            if None in row:
                raise ValueError(
                    f"Row {row_number} has more fields than expected."
                )

            if any(value is None for value in row.values()):
                raise ValueError(
                    f"Row {row_number} has fewer fields than expected."
                )

            record = {
                db_column: row[csv_column]
                for csv_column, db_column in COLUMN_MAPPING.items()
            }

            records.append(record)

    return records


def load_sales_to_postgres(records):
    connection_settings = {
        "host": os.environ["POSTGRES_HOST"],
        "port": os.environ["POSTGRES_PORT"],
        "dbname": os.environ["POSTGRES_DB"],
        "user": os.environ["POSTGRES_USER"],
        "password": os.environ["POSTGRES_PASSWORD"],
    }

    columns = list(COLUMN_MAPPING.values())

    insert_sql = f"""
        INSERT INTO raw_sales (
            {", ".join(columns)},
            source_file
        )
        VALUES (
            {", ".join(["%s"] * (len(columns) + 1))}
        )
    """

    with psycopg.connect(**connection_settings) as connection:
        with connection.cursor() as cursor:
            schema_sql = SCHEMA_PATH.read_text(encoding="utf-8")
            cursor.execute(schema_sql)

            cursor.execute("DELETE FROM raw_sales")

            for record in records:
                values = [record[column] for column in columns]
                values.append(CSV_PATH.name)
                cursor.execute(insert_sql, values)

    print(f"Successfully loaded {len(records)} records into raw_sales.")


if __name__ == "__main__":
    sales_records = read_sales_csv()
    print(f"Successfully read {len(sales_records)} sales records.")

    load_sales_to_postgres(sales_records)