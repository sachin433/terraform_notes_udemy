locals {
  vpc_name = "${terraform.workspace == "dev" ? "javadevvpc" : "javaprodvpc"}"
}
