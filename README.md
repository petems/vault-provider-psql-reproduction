# Reproduction of Postgres Issue with Vault Provider

https://github.com/terraform-providers/terraform-provider-vault/issues/384

## Pre-reqs 

Have the following installed:

- docker-compose
- terraform
- vault

## Usage

### Warning

This is for testing only, there are hardcoded passwords and tokens everywhere.

### Set Environment Variables

```bash
export VAULT_TOKEN="TEST"
export VAULT_ADDR="http://0.0.0.0:8200"
```

### Starting up docker-compose

```bash
docker-compose up
```

### Terraform

Run: 

```bash 
terraform init
terraform apply
```

### Check dynamic role statement creation

```
vault read database/creds/myrole
```

Currently the statement from the example in the Github issue isnt valid, but it appears to give a different error message than the one before from non-escaped PSQL statements:

```
Error reading database/creds/myrole: Error making API request.

URL: GET http://0.0.0.0:8200/v1/database/creds/myrole
Code: 500. Errors:

* 1 error occurred:
  * pq: syntax error at or near "AS"

```

With Vault 1.4.3:

```
Error reading database/creds/myrole: Error making API request.

URL: GET http://0.0.0.0:8200/v1/database/creds/myrole
Code: 500. Errors:

* 1 error occurred:
  * pq: unterminated dollar-quoted string at or near "$Q$ DECLARE result text"
```

Which was the original reported issue