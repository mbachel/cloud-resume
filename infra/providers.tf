terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "resume-bachelder-tfstate"
    key    = "cloud-resume/terraform.tfstate"
    region = "us-east-1"
    profile = "terraform"
  }
}

provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}

provider "aws" {
  alias  = "us_east_2"
  region = "us-east-2"
  profile = "terraform"
}
