FROM eclipse-temurin:17-jre-jammy

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    curl \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

ENV KAFKA_VERSION=3.7.2
ENV SCALA_VERSION=2.12
RUN wget -q https://dlcdn.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
    tar -xzf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
    rm kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
    mv kafka_${SCALA_VERSION}-${KAFKA_VERSION} /opt/kafka

COPY zookeeper.properties /opt/kafka/config/
COPY server.properties /opt/kafka/config/
COPY run.sh /opt/kafka/

WORKDIR /app

COPY producer /app/producer
RUN pip install -r /app/producer/requirements.txt

COPY consumer /app/consumer
RUN pip install -r /app/consumer/requirements.txt

EXPOSE 9092 2181
CMD ["/bin/bash", "/opt/kafka/run.sh"]
