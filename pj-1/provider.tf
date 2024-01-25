terraform {
    backend "s3" {}
    required_version = "~> 1.7.0"
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.2.0"
        }
    }
}
