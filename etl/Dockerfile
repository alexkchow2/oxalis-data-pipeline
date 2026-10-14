FROM python:3.12-slim

WORKDIR /app

COPY etl/requirements.txt /app/requirements.txt

RUN pip install --no-cache-dir -r requirements.txt

COPY etl/ /app/etl/
COPY data/ /app/data/
COPY sql/ /app/sql/

CMD ["python", "etl/load_sales.py"]