#!/bin/bash

# Configuración de directorios
mkdir -p /var/lib/zookeeper /opt/kafka/logs
chown -R $(whoami) /var/lib/zookeeper /opt/kafka/logs

# Función para registrar logs
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /opt/kafka/logs/container.log
}

# Inicia Zookeeper con redirección de logs
log "Iniciando Zookeeper"
export KAFKA_HEAP_OPTS="-Xms512M -Xmx1G"
/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties >> /opt/kafka/logs/zookeeper.log 2>&1 &
ZOOKEEPER_PID=$!

# Espera conexión Zookeeper
log "Esperando conexión Zookeeper..."
while ! nc -z localhost 2181; do 
    sleep 1
    if ! ps -p $ZOOKEEPER_PID > /dev/null; then
        log "ERROR: Zookeeper falló al iniciar. Ver logs en /opt/kafka/logs/zookeeper.log"
        exit 1
    fi
done

# Inicia Kafka con redirección de logs
log "Iniciando Kafka"
export KAFKA_HEAP_OPTS="-Xms1G -Xmx2G"
/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties >> /opt/kafka/logs/server.log 2>&1 &
KAFKA_PID=$!

# Espera conexión Kafka
log "Esperando conexión Kafka..."
while ! nc -z localhost 9092; do 
    sleep 1
    if ! ps -p $KAFKA_PID > /dev/null; then
        log "ERROR: Kafka falló al iniciar. Ver logs en /opt/kafka/logs/server.log"
        exit 1
    fi
done

# Crea topic
log "Creando topic 'crimes'"
/opt/kafka/bin/kafka-topics.sh --create \
  --topic crimes \
  --bootstrap-server localhost:9092 \
  --config max.message.bytes=10485760 \
  --partitions 1 \
  --replication-factor 1 2>> /opt/kafka/logs/container.log || log "El topic ya existe"

# Inicia servicios Python con redirección de logs
log "Iniciando servicios Python"
python3 /opt/kafka/consumer.py >> /opt/kafka/logs/consumer.log 2>&1 &
python3 /opt/kafka/producer.py >> /opt/kafka/logs/producer.log 2>&1 &

# Monitoreo continuo
log "Sistema iniciado correctamente"
while true; do
    if ! ps -p $ZOOKEEPER_PID > /dev/null; then
        log "ERROR: Zookeeper se detuvo inesperadamente"
        exit 1
    fi
    if ! ps -p $KAFKA_PID > /dev/null; then
        log "ERROR: Kafka se detuvo inesperadamente"
        exit 1
    fi
    sleep 10
done
