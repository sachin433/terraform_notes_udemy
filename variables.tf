variable "vpc_cidr" {
  description = "choose value for cidr"
  default     = "10.20.0.0/16"
  type        = string
}

variable "region" {
  default = "us-east-1"
  type    = string

}
