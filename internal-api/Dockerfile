FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Non-root user
RUN useradd -m -u 1000 apiuser
USER apiuser

EXPOSE 8080

CMD ["python", "app.py"]
