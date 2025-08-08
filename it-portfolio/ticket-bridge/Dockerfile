# syntax=docker/dockerfile:1

FROM python:3.12-slim AS builder

WORKDIR /wheels
COPY requirements.txt ./
RUN pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

FROM python:3.12-slim AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Create non-root user
RUN addgroup --system app && adduser --system --ingroup app app

WORKDIR /app

# Install runtime dependencies from wheels
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir /wheels/*

# Copy application code (build context is it-portfolio/ticket-bridge)
COPY . /app/

USER app
EXPOSE 8080

# Use gunicorn to run the app factory
# Module path is app:create_app when WORKDIR contains app.py
CMD ["gunicorn", "-b", "0.0.0.0:8080", "app:create_app()"]