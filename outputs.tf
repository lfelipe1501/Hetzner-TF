output "ubuntu_server_ips" {
  description = "Public IPs of Ubuntu servers"
  value = {
    for name, server in hcloud_server.ubuntu_servers : name => server.ipv4_address
  }
  depends_on = [null_resource.check_cloud_init]
}

output "ubuntu_server_status" {
  description = "Status of Ubuntu servers"
  value = {
    for name, server in hcloud_server.ubuntu_servers : name => server.status
  }
  depends_on = [null_resource.check_cloud_init]
}

output "ubuntu_server_dns" {
  description = "DNS names of Ubuntu servers"
  value = {
    for name, server in hcloud_server.ubuntu_servers : name => "${server.name}.${server.datacenter}.hetzner.com"
  }
  depends_on = [null_resource.check_cloud_init]
}

output "ubuntu_network_info" {
  description = "Private network information for Ubuntu"
  value = {
    network_id   = hcloud_network.private_network.id
    network_name = hcloud_network.private_network.name
    subnet_id    = hcloud_network_subnet.private_subnet.id
    subnet_range = hcloud_network_subnet.private_subnet.ip_range
  }
  depends_on = [null_resource.check_cloud_init]
}

output "ssh_connection_strings" {
  description = "SSH connection strings for each server"
  value = {
    for name, server in hcloud_server.ubuntu_servers : name => "ssh -p ${var.ssh_port} ${var.username}@${server.ipv4_address}"
  }
  depends_on = [null_resource.check_cloud_init]
}

output "connection_instructions" {
  description = "Instructions for connecting to the servers"
  value = <<-EOT
    =====================================================================
    SERVER CONNECTION
    =====================================================================
    
    To connect to your servers, use the following commands:
    
    ${join("\n    ", [
      for name, server in hcloud_server.ubuntu_servers : 
      "* ${name}: ssh -p ${var.ssh_port} ${var.username}@${server.ipv4_address}"
    ])}
    
    Password authentication: ${var.ssh_password_authentication ? "ENABLED" : "DISABLED"}
    ${var.ssh_password_authentication ? "You can use the configured password to log in." : "You can only connect using your private SSH key."}
    
    =====================================================================
  EOT
  depends_on = [null_resource.check_cloud_init]
} 