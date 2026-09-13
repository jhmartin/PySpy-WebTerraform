variable "region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-west-2"
}

variable "pyspy_intel_source_bucket" {
  description = "S3 bucket containing the DynamoDB import source data for the pyspy-intel and pyspyv3-intel tables"
  type        = string
}

variable "pyspy_intel_key_prefix" {
  description = "S3 key prefix for the DynamoDB import source data for the pyspy-intel table"
  type        = string
}

variable "pyspyv3_intel_key_prefix" {
  description = "S3 key prefix for the DynamoDB import source data for the pyspyv3-intel table"
  type        = string
}

variable "tfc_aws_dynamic_credentials" {
  description = "Object containing AWS dynamic credentials configuration"
  type = object({
    default = object({
      shared_config_file = string
    })
    aliases = map(object({
      shared_config_file = string
    }))
  })
}
