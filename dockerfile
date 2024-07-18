# Set the working directory in the container
FROM python:3.9-slim as builder
WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y build-essential libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Copying only the requirements allows to cache in case it hasn't changed
COPY requirements.txt .
RUN pip install -r requirements.txt
RUN pip install wheel
RUN pip wheel . -w /app/wheels

COPY . .

FROM python:3.9-slim
WORKDIR /app

RUN groupadd -g 1000 appuser && \
    useradd -u 1000 -g appuser -s /bin/bash -m appuser


COPY --from=builder /app/wheel /app/wheel
COPY requirements.txt .
RUN pip install --no-index --find-links=/app/wheels -r requirements.txt

COPY . .

RUN chown -R appuser:appuser /app

RUN apt-get remove -y build-essential && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /app/wheels

USER appuser
# Make port 80 available to the world outside this container
EXPOSE 8080
# Run script.py when the container launches
CMD ["python3", "pythonWeb.py"]