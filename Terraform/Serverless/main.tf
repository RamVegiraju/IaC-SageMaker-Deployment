provider "aws" {
  region = "us-east-1"
}

variable "sm-iam-role" {
    type = string
    default = "arn:aws:iam::474422712127:role/sagemaker-role-BYOC"
    description = "The IAM Role for SageMaker Endpoint Deployment"
}

variable "container-image" {
    type = string
    default = "683313688378.dkr.ecr.us-east-1.amazonaws.com/sagemaker-scikit-learn:0.23-1-cpu-py3"
    description = "The container you are utilizing for your SageMaker Model"
}

variable "model-data" {
    type = string
    default = "s3://sagemaker-us-east-1-474422712127/model.tar.gz"
    description = "The pre-trained model data/artifacts, replace this with your training job."
}

variable "instance-type" {
    type = string
    default = "ml.m5.xlarge"
    description = "The instance behind the SageMaker Real-Time Endpoint"
}

variable "memory-size" {
    type = number
    default = 4096
    description = "Memory size behind your Serverless Endpoint"
}

variable "concurrency" {
    type = number
    default = 2
    description = "Concurrent requests for Serverless Endpoint"
}



## Define your resources/building blocks here

# SageMaker Model Object
resource "aws_sagemaker_model" "sagemaker_model" {
  name = "sagemaker-model-sklearn-serverless"
  execution_role_arn = var.sm-iam-role

  primary_container {
    image = var.container-image
    mode = "SingleModel"
    model_data_url = var.model-data 
    environment = {
      "SAGEMAKER_PROGRAM" = "inference.py"
      "SAGEMAKER_SUBMIT_DIRECTORY" = var.model-data
    }
  }

  tags = {
    Name = "sagemaker-model-terraform"
  }
}


# Create SageMaker endpoint configuration
resource "aws_sagemaker_endpoint_configuration" "sagemaker_endpoint_configuration" {
  name = "sagemaker-endpoint-configuration-sklearn-serverless"

  production_variants {
    model_name = aws_sagemaker_model.sagemaker_model.name
    variant_name = "AllTraffic"
    serverless_config {
      memory_size_in_mb = var.memory-size
      max_concurrency = var.concurrency
    }
  }

  tags = {
    Name = "sagemaker-endpoint-configuration-terraform"
  }
}

# Create SageMaker Real-Time Endpoint
resource "aws_sagemaker_endpoint" "sagemaker_endpoint" {
  name = "sagemaker-endpoint-sklearn-serverless"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.sagemaker_endpoint_configuration.name

  tags = {
    Name = "sagemaker-endpoint-terraform"
  }

}
