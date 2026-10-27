# Real-Time Payment Fraud Pipeline

Pipeline local de processamento de pagamentos e deteção de padrões suspeitos, construído com PostgreSQL, Apache Kafka e Apache Flink SQL.

## Estado atual

- [x] Ambiente local definido com Docker Compose.
- [x] Esquema PostgreSQL para contas, cartões e transações.
- [x] Dados sintéticos para cenários positivo e de controlo.
- [x] Regra SQL de deteção em PostgreSQL.
- [x] Processamento batch Kafka → Flink SQL → Kafka implementado.
- [x] Processamento contínuo Kafka → Flink SQL → Kafka executado.
- [x] Cenário positivo de streaming: três pagamentos aprovados numa janela de 60 segundos produziram alertas.
- [x] Cenário de controlo: pagamentos separados por 80 segundos sem alertas encontrados para o cartão de teste.
- [x] Evidências de streaming guardadas em `evidence/flink-fraud-alerts.jsonl`: seis alertas JSON válidos, distribuídos por dois cartões de teste.
- [ ] Validar recuperação do job após falha e reinício.
- [ ] Testar carga, duplicados e eventos atrasados.
- [ ] Rever e consolidar testes automatizados e evidências.
- [ ] Configurar e validar CDC, se vier a ser necessário.
- [ ] Avaliar Schema Registry; não está configurado nesta versão.

Os testes positivos e negativos são evidência dos cenários executados, não uma garantia de deteção de fraude em produção.

## Arquitetura local

```text
PostgreSQL
  └── contas, cartões e transações sintéticas
       └── scripts SQL para análise batch

Kafka: payments.raw
  └── Flink SQL
       ├── Batch → payments.fraud-alerts
       └── Streaming → payments.fraud-alerts-stream
```

O seed PostgreSQL não publica automaticamente os seus dados no Kafka. Os scripts de teste de Kafka são um caminho separado.

## Tecnologias

- PostgreSQL 16
- Apache Kafka 3.9.1 em modo KRaft
- Apache Flink 1.20.2
- Conector Flink SQL Kafka 3.3.0-1.20
- Docker Compose
- SQL, JSON e Git

## Pré-requisitos

- Docker com Docker Compose.
- Git.
- Ficheiro `.env` local com as variáveis obrigatórias:
  - `POSTGRES_DB`
  - `POSTGRES_USER`
  - `POSTGRES_PASSWORD`
- JAR do conector em `lib/flink-sql-connector-kafka-3.3.0-1.20.jar`.

Nunca publiques o `.env`, passwords, tokens ou outras credenciais.

## Iniciar os serviços

Valida a configuração e inicia os serviços:

```bash
docker compose config --quiet
docker compose up -d
docker compose ps
```

A interface Flink fica disponível na porta local `8081`. O PostgreSQL está exposto apenas em `127.0.0.1:5432`. Kafka está acessível aos restantes serviços através de `kafka:9092`.

## Preparar o PostgreSQL

Executa os scripts pela ordem indicada:

```bash
docker compose exec -T postgres sh -lc \
  'psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
  < sql/01_schema.sql

docker compose exec -T postgres sh -lc \
  'psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
  < sql/02_seed_data.sql
```

Executa a regra batch em PostgreSQL:

```bash
docker compose exec -T postgres sh -lc \
  'psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
  < sql/03_fraud_detection.sql
```

Os scripts de seed usam `ON CONFLICT DO NOTHING` para evitar inserir novamente registos existentes com as mesmas chaves.

## Kafka e Flink SQL

Os tópicos utilizados são:

- `payments.raw`: eventos de entrada em JSON.
- `payments.fraud-alerts`: alertas do pipeline batch Flink.
- `payments.fraud-alerts-stream`: alertas do pipeline contínuo Flink.

Os tópicos devem existir antes da execução dos jobs. Para criar os tópicos de teste:

```bash
for topic in payments.raw payments.fraud-alerts payments.fraud-alerts-stream; do
  docker compose exec -T kafka \
    /opt/kafka/bin/kafka-topics.sh \
    --bootstrap-server kafka:9092 \
    --create --if-not-exists \
    --topic "$topic" \
    --partitions 1 \
    --replication-factor 1
done
```

### Pipeline batch

O ficheiro `sql/04_flink_fraud_alerts.sql` lê os eventos disponíveis no tópico de entrada, calcula a contagem de pagamentos aprovados e publica os alertas em `payments.fraud-alerts`.

```bash
docker compose exec -T jobmanager \
  bash -lc '/opt/flink/bin/sql-client.sh' \
  < sql/04_flink_fraud_alerts.sql
```

### Pipeline contínuo

O ficheiro `sql/06_flink_streaming_fraud_alerts.sql` configura um job contínuo com:
- watermark de 5 segundos;
- janelas deslizantes de 60 segundos;
- avanço de janela de 10 segundos;
- limiar de três pagamentos aprovados por cartão;
- grupo Kafka configurado como `fraud-alert-stream-v2`;
- arranque em `latest-offset`, pelo que os eventos anteriores ao arranque não são relidos por um novo consumidor.

```bash
docker compose exec -T jobmanager \
  bash -lc '/opt/flink/bin/sql-client.sh' \
  < sql/06_flink_streaming_fraud_alerts.sql
```

O cliente SQL pode terminar depois de submeter o `INSERT`; o job pode continuar ativo no cluster. Confirma o estado na interface Flink ou pela API REST:

```bash
docker compose exec -T jobmanager \
  curl -fsS http://localhost:8081/jobs
```

O modo `latest-offset` do consumidor de streaming significa que o job começa a ler a partir dos offsets mais recentes quando é iniciado. Para testar, inicia o job antes de publicar os eventos de teste.

## Verificar os alertas

Lê os alertas do tópico de streaming:

```bash
docker compose exec -T kafka \
  /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server kafka:9092 \
  --topic payments.fraud-alerts-stream \
  --from-beginning \
  --timeout-ms 5000
```

Um alerta esperado contém `alert_type` igual a `POTENTIAL_FRAUD`, o identificador do cartão e a contagem de transações na janela.

O consumidor pode terminar com timeout quando não recebe mensagens novas durante o intervalo configurado. Avalia também a quantidade de mensagens processadas e o estado do job antes de concluir que ocorreu uma falha.

### Evidências registadas

- `evidence/flink-fraud-alerts.jsonl`: seis alertas JSON lidos do tópico de saída e validados. Os resultados incluem dois cartões de teste, com três transações aprovadas por janela.
- `evidence/flink-fraud-alerts-consumer.log`: saída de diagnóstico do consumidor, incluindo o timeout após a leitura das mensagens disponíveis.

Estas evidências representam mensagens acumuladas no tópico durante os testes; não significam que os seis alertas tenham sido produzidos numa única execução. O timeout do consumidor, isoladamente, não prova uma falha do job.

## Scripts do projeto

| Ficheiro | Finalidade |
|---|---|
| `sql/01_schema.sql` | Criar as tabelas PostgreSQL |
| `sql/02_seed_data.sql` | Inserir dados sintéticos |
| `sql/03_fraud_detection.sql` | Detetar padrões em PostgreSQL |
| `sql/04_flink_fraud_alerts.sql` | Pipeline batch Kafka → Flink → Kafka |
| `sql/05_control_test.sql` | Consulta de controlo sobre eventos Kafka |
| `sql/06_flink_streaming_fraud_alerts.sql` | Deteção contínua com janelas temporais |
| `evidence/flink-fraud-alerts.jsonl` | Alertas JSON registados durante os testes |
| `evidence/flink-fraud-alerts-consumer.log` | Registo de execução do consumidor Kafka |
| `compose.yaml` | Serviços e configuração local |

## Limitações conhecidas

- O projeto utiliza um broker Kafka e um único slot Flink: é um ambiente de desenvolvimento, não uma configuração de alta disponibilidade.
- Não há CDC PostgreSQL → Kafka configurado nesta versão.
- Não há Schema Registry configurado nesta versão.
- A deteção é uma regra demonstrativa, não um sistema antifraude completo nem uma decisão automática de bloqueio.
- A consulta batch e as janelas de streaming têm semânticas temporais diferentes.
- O tratamento de duplicados, eventos atrasados, recuperação e carga ainda precisa de testes específicos.

## Segurança e custos

- Utiliza apenas dados sintéticos.
- Não coloques credenciais no Git.
- Os serviços definidos neste Compose são executados localmente; não é necessário contratar serviços cloud para os testes descritos.
- Os volumes `postgres_data` e `kafka_data` preservam dados entre reinícios.

## Encerrar

Para parar os serviços sem apagar os dados persistidos:

```bash
docker compose down
```

Não uses `docker compose down -v` se pretendes preservar os volumes de dados.
