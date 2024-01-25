// 変数
// ------------------------------------------------
variable vpc_cidr {
  type = string
  description = "(optional) describe your variable"
}
variable public_subnets {
  type = map(object({
    cidr_block   = string
    tag = string
  }))
  description = "(optional) describe your variable"
}
variable private_subnets {
  type = map(object({
    cidr_block   = string
    tag = string
  }))
  description = "(optional) describe your variable"
}
// ------------------------------------------------


// リソース
// ------------------------------------------------
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.key
  tags = {
    Name = each.value.tag
  }
}
resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.key
  tags = {
    Name = each.value.tag
  }
}
// ------------------------------------------------