FROM python:3.12-slim

WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000
# Migrate, load reference data, then start the server
CMD ["sh", "-c", "alembic upgrade head && python -m app.seed ${SEED_ARGS} && uvicorn app.main:app --host 0.0.0.0 --port 8000"]
