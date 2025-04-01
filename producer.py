import requests
from kafka import KafkaProducer
import json
import time

def create_producer():
    """Crea un productor Kafka optimizado para mensajes JSON medianos"""
    return KafkaProducer(
        bootstrap_servers='localhost:9092',
        value_serializer=lambda v: json.dumps(v).encode('utf-8'),
        max_request_size=10485760,
        batch_size=32768,
        linger_ms=500,
        compression_type='gzip',
        retries=3,
        request_timeout_ms=30000
    )

def fetch_data(url):
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        return response
    except requests.RequestException as e:
        print(f"Error al obtener datos: {e}")
        return None

def send_to_kafka(producer, topic, response):
    batch_size = 10  # Mensajes por lote
    batch = []
    
    for line in response.iter_lines():
        if line:
            try:
                crime = json.loads(line)
                batch.append(crime)
                
                if len(batch) >= batch_size:
                    for record in batch:
                        producer.send(topic, record)
                    producer.flush()
                    print(f"Enviado lote de {len(batch)} registros")
                    batch = []
                    
            except json.JSONDecodeError as e:
                print(f"Error en línea: {e}")
    
    # Enviar los últimos registros restantes
    if batch:
        for record in batch:
            producer.send(topic, record)
        producer.flush()
        print(f"Enviado último lote de {len(batch)} registros")

def main():
    url = "https://raw.githubusercontent.com/IngEnigma/StreamlitSpark/refs/heads/master/results/male_crimes/data.jsonl"
    topic = 'crimes'
    
    producer = create_producer()
    response = fetch_data(url)
    
    if response:
        send_to_kafka(producer, topic, response)
    
    producer.close()

if __name__ == "__main__":
    main()
