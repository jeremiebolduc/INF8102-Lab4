output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = [
    aws_subnet.public_az1.id,
    aws_subnet.public_az2.id,
  ]
}

output "private_subnets" {
  value = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id,
  ]
}

output "security_group_id" {
  value = aws_security_group.polystudent_sg.id
}
