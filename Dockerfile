FROM python:3.9-slim

WORKDIR /app

# Install dependencies once at build time (not every pod startup)
RUN pip install --no-cache-dir flask redis

# Copy app code into the image
COPY voter-app.py app.py

EXPOSE 5000

CMD ["python", "app.py"]
