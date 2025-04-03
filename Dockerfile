FROM ubuntu:22.04

# Instalar dependencias del sistema
RUN apt-get update && \
    apt-get install -y \
    default-jre \
    wget \
    curl \
    python3 \
    python3-pip \
    postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Instalar Kafka
RUN wget https://dlcdn.apache.org/kafka/3.7.2/kafka_2.12-3.7.2.tgz && \
    tar -xvf kafka_2.12-3.7.2.tgz && \
    rm kafka_2.12-3.7.2.tgz

# Instalar dependencias de Python
COPY requirements.txt .
RUN pip3 install -r requirements.txt

# Copiar scripts
COPY run_kafka.sh .
COPY producer.py .
COPY consumer.py .

# Configurar permisos
RUN chmod +x run_kafka.sh && \
    chmod +x kafka_2.12-3.7.2/bin/*.sh

# Puerto de Kafka
EXPOSE 9092

# Comando de inicio
CMD ["bash", "./run.sh"]
