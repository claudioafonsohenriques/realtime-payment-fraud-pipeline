# realtime-payment-fraud-pipeline
Real-time payment streaming and fraud detection using PostgreSQL CDC, Confluent Cloud and Flink SQL.



# Real-Time Payment Fraud Pipeline

Pipeline de processamento de pagamentos em tempo real, com PostgreSQL CDC, Apache Kafka, Confluent Cloud, Schema Registry e Flink SQL.

> **Estado:** Planeamento inicial. A infraestrutura e o processamento ponta a ponta ainda precisam de ser configurados e validados.

## Objetivos

- Criar dados sintéticos de contas e transações em PostgreSQL.
- Capturar alterações com Change Data Capture (CDC).
- Publicar eventos no Kafka e validar contratos com Schema Registry.
- Enriquecer transações com dados das contas usando Flink SQL.
- Detetar três ou mais transações do mesmo cartão num intervalo de 60 segundos.
- Documentar testes, permissões, métricas e custos.

## Arquitetura prevista

```text
PostgreSQL
    |
    v
CDC Connector
    |
    v
Kafka + Schema Registry
    |
    v
Flink SQL
    |
    +--> Transações enriquecidas
    |
    +--> Alertas de fraude
```

A arquitetura definitiva será escolhida após verificarmos os limites gratuitos, os requisitos de rede e os preços atuais dos serviços.

## Tecnologias

- PostgreSQL
- Apache Kafka
- Confluent Cloud
- Schema Registry
- Flink SQL
- SQL, JSON e GitHub

## Regras de segurança e custos

- Utilizar apenas dados sintéticos.
- Nunca publicar credenciais, tokens ou ficheiros `.env` preenchidos.
- Verificar os preços e os requisitos de faturação antes de criar recursos na cloud.
- Não ativar serviços potencialmente pagos sem autorização.
- Documentar como parar e eliminar os recursos criados.

## Estado do projeto

- [ ] Criar o esquema PostgreSQL e os dados de teste.
- [ ] Validar a estrutura e a qualidade dos dados.
- [ ] Confirmar as opções gratuitas e os requisitos de rede.
- [ ] Configurar CDC e Kafka.
- [ ] Registar e testar a evolução do schema.
- [ ] Implementar o processamento Flink SQL.
- [ ] Testar a regra de deteção de fraude.
- [ ] Recolher evidências reais dos testes.
- [ ] Documentar custos e limpeza dos recursos.

As evidências só serão adicionadas depois da execução real dos testes.
