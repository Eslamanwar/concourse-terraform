module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=terraform011"
  name = "secmon"

  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a","us-east-1b","us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    Name = "public_subnet"
  }

  private_subnet_tags = {
    Name = "private_subnet"
  }
}

module "secmonkey" {
  source = "git::https://github.com/Eslamanwar/secmonkey.git"
  monkey_name = "secmon"
  environment = "prod"

  route53_zone_id = "Z1A5MKV99TLTT9"
  dns_name = "secmonkey"

  keypair_name = "secmonkey"

  alarm_actions = "secmonkey"
  ok_actions = "secmonkey"

  db_pwd = "ABC12345678"

  ami_id = "ami-06585729d6994bbfd"

  private_subnets = "${module.vpc.private_subnets}"
  public_subnets = "${module.vpc.public_subnets}"
  vpc_id = "${module.vpc.vpc_id}"
}
