# PySpy-WebTerraform


[![Maintainability](https://api.codeclimate.com/v1/badges/1e6857a46d1de3a384b5/maintainability)](https://codeclimate.com/github/jhmartin/PySpy-WebTerraform/maintainability)

Terraform code for the AWS component of PySpy. Provisions:

* CDN
* API Gateway
* S3 bucket
* Lambda
* DynamoDB Table
* Roles/Permissions for the above

Deployed via HCP Terraform.

The Lambda is a thin layer that fetches intel rows from DynamoDB. The data is cached at the CDN to reduce load on the lambda/DDB table.
