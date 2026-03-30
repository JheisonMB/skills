# Driven Adapters Reference

Full catalog of `generateDrivenAdapter | gda` types.

## Types

| Type | Name | Parameters |
|------|------|-----------|
| `generic` | Empty Driven Adapter | `--name` (required) |
| `asynceventbus` | Async Event Bus | `--eda` (true/false, default: false), `--tech` (rabbitmq/kafka/rabbitmq,kafka, default: rabbitmq) |
| `binstash` | Bin Stash | `--cache-mode` (LOCAL/CENTRALIZED/HYBRID, default: LOCAL) |
| `cognitotokenprovider` | Cognito token generator | - |
| `dynamodb` | DynamoDB adapter | - |
| `jpa` | JPA Repository | `--secret` (true/false, default: false) |
| `kms` | AWS Key Management Service | - |
| `mongodb` | Mongo Repository | `--secret` (true/false, default: false) |
| `mq` | JMS MQ Client (send) | - |
| `r2dbc` | R2DBC PostgreSQL Client | - |
| `redis` | Redis | `--mode` (template/repository, default: template), `--secret` (true/false, default: false) |
| `restconsumer` | REST Client Consumer | `--url` (String), `--from-swagger` (file path, default: swagger.yaml) |
| `rsocket` | RSocket Requester | - |
| `s3` | AWS S3 | - |
| `secrets` | Secrets Manager | `--secrets-backend` (aws_secrets_manager/vault, default: aws_secrets_manager) |
| `secretskafkastrimzi` | Secrets for Kafka Strimzi | `--secret-name` (String) |
| `sqs` | SQS message sender | - |

## Generated Structure Example (JPA)

```
📦infrastructure/driven-adapters/jpa-repository/
┣ 📂src/main/java/[package]/jpa/
┃ ┣ 📂config/DBSecret.java
┃ ┣ 📂helper/AdapterOperations.java
┃ ┣ 📜JPARepository.java
┃ ┗ 📜JPARepositoryAdapter.java
┗ 📜build.gradle
```
