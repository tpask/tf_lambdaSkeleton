
variable "region" {
  default = "us-west-2"
}

variable "useS3" {
  default = true
  type    = bool
}
variable "owner" {
  default = "tp"
}
variable "project" {
  default = "lambda"
}

variable "lambdaName" {
  type    = string
  default = "test_lambda"
}
variable "payload" {
  default = "./files/lambda.py"
}
variable "filesPath" {
  default = "./files"
}
variable "zippedFileName" {
  default = "lambda.zip"
}

variable "handler" { default = "lambda.handler" }
variable "lambdaZipFile" { default = "./files/lambda.zip" }
variable "runtime" { default = "python3.8" }
variable "memory_size" { default = "128" }
variable "concurrency" { default = "5" }
variable "lambda_timeout" { default = "15" }
variable "log_retention" { default = "1" }
#variable "" { default = "" }
#variable "" { default = "" }
