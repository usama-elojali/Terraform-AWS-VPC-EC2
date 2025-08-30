# outputs.tf

# Show the instance public IP after apply
output "instance_public_ip" {
  description = "Public IP of the web instance"
  value       = aws_instance.web.public_ip
}

# Convenient HTTP URL to click
output "nginx_url" {
  description = "HTTP URL to reach the Nginx default page"
  value       = "http://${aws_instance.web.public_ip}"
}
