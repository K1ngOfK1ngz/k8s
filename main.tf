provider "aws" {
    region = "us-east-1"
}

terraform {
    backend "s3" {
        bucket = var.s3_backend_bucket
        key    = var.s3_backend_key
        region = "us-east-1"
    }
}

module kubernetes-cluster {
    source = "../modules/kubernetes_cluster"
}