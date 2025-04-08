# File existence check for SSH key
locals {
  ssh_key_exists = fileexists(pathexpand(var.ssh_public_key_path))
}

# Data source to fetch existing SSH key (if using existing key)
data "hcloud_ssh_key" "existing" {
  count = (!var.ssh_key_create && local.ssh_key_exists) ? 1 : 0
  name  = var.ssh_key_name
}

# SSH key creation - for keys that SHOULD be destroyed with terraform destroy
resource "hcloud_ssh_key" "terraform_managed" {
  count      = (var.ssh_key_create && local.ssh_key_exists) ? 1 : 0
  name       = var.ssh_key_name
  public_key = file(pathexpand(var.ssh_public_key_path))
  
  # No prevent_destroy needed as we want these to be destroyed
}

# Local function to generate incremental IPs
locals {
  # Split the base IP into its components
  ip_parts = split(".", var.base_ip)
  
  # Generate a map of static IPs based on the number of instances
  generated_ips = {
    for idx in range(var.ubuntu_instances_count) :
    idx == 0 ? var.servers[0].name : "${var.servers[0].name}-${idx}" => 
    "${local.ip_parts[0]}.${local.ip_parts[1]}.${local.ip_parts[2]}.${tonumber(local.ip_parts[3]) + idx}"
  }
}

# Creation of Ubuntu servers
resource "hcloud_server" "ubuntu_servers" {
  for_each = {
    for idx in range(var.ubuntu_instances_count) :
    idx == 0 ? var.servers[0].name : "${var.servers[0].name}-${idx}" => {
      name        = idx == 0 ? var.servers[0].name : "${var.servers[0].name}-${idx}"
      server_type = var.servers[0].server_type
      image       = var.servers[0].image
      location    = var.servers[0].location
      use_static_ip = var.servers[0].use_static_ip
      labels      = var.servers[0].labels
    }
  }
  
  name        = each.value.name
  server_type = each.value.server_type
  image       = each.value.image
  location    = each.value.location
  ssh_keys    = local.ssh_key_exists ? (
                  var.ssh_key_create ? 
                  [hcloud_ssh_key.terraform_managed[0].id] : 
                  [data.hcloud_ssh_key.existing[0].id]
                ) : []
  
  public_net {
    ipv6_enabled = var.enable_ipv6
  }
  
  # Cloud-init for Ubuntu using templatefile() instead of template_file
  user_data = templatefile("${path.module}/scripts/cloud-init-ubuntu.yaml", {
    ssh_key = local.ssh_key_exists ? file(pathexpand(var.ssh_public_key_path)) : ""
    ssh_port = var.ssh_port
    timezone = var.timezone
    username = var.username
    password = var.password
    ssh_password_authentication = var.ssh_password_authentication || !local.ssh_key_exists
    hostname = var.hostname != "" ? var.hostname : each.value.name
  })

  # Tags for organization
  labels = merge(
    each.value.labels,
    {
      environment = var.environment
      project     = var.project_name
      os          = "ubuntu"
    }
  )

  # Apply firewall only if enabled
  firewall_ids = var.enable_firewall ? [hcloud_firewall.ubuntu_firewall[0].id] : []
  
  # Assign to network after it's created
  depends_on = [hcloud_network_subnet.private_subnet]
}

# Assign servers to the network
resource "hcloud_server_network" "ubuntu_server_network" {
  for_each = hcloud_server.ubuntu_servers
  
  server_id  = each.value.id
  network_id = hcloud_network.private_network.id
  ip         = lookup(local.generated_ips, each.value.name, null)
}

# Private network
resource "hcloud_network" "private_network" {
  name     = "${var.project_name}-ubuntu-network"
  ip_range = var.network_cidr
}

# Subnet
resource "hcloud_network_subnet" "private_subnet" {
  network_id   = hcloud_network.private_network.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.subnet_cidr
}

# Firewall
resource "hcloud_firewall" "ubuntu_firewall" {
  count = var.enable_firewall ? 1 : 0
  
  name = "${var.project_name}-ubuntu-firewall"

  # Rule for custom SSH
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = var.ssh_port
    source_ips = var.allowed_ssh_ips
    description = "Custom SSH on port ${var.ssh_port}"
  }

  # Rule for HTTP (optional)
  dynamic "rule" {
    for_each = var.enable_http ? [1] : []
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = "80"
      source_ips = ["0.0.0.0/0", "::/0"]
      description = "HTTP - Port 80"
    }
  }

  # Rule for HTTPS (optional)
  dynamic "rule" {
    for_each = var.enable_https ? [1] : []
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = "443"
      source_ips = ["0.0.0.0/0", "::/0"]
      description = "HTTPS - Port 443"
    }
  }

  # Additional custom rules
  dynamic "rule" {
    for_each = [for r in var.custom_firewall_rules : r if r.enabled]
    content {
      direction  = rule.value.direction
      protocol   = rule.value.protocol
      port       = rule.value.port
      source_ips = rule.value.source_ips
      description = rule.value.description
    }
  }
}

# Wait for cloud-init to complete
resource "time_sleep" "wait_for_cloud_init" {
  depends_on = [hcloud_server.ubuntu_servers]
  
  # Wait for 1 minute and 30 seconds to allow cloud-init to complete
  create_duration = "90s"
}

# Verify cloud-init completion
resource "null_resource" "check_cloud_init" {
  for_each = local.ssh_key_exists ? hcloud_server.ubuntu_servers : {}
  
  depends_on = [
    time_sleep.wait_for_cloud_init,
    hcloud_server_network.ubuntu_server_network
  ]

  # This will try to connect to the server and check if cloud-init has completed
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.username
      host        = each.value.ipv4_address
      port        = var.ssh_port
      private_key = file(replace(pathexpand(var.ssh_public_key_path), ".pub", ""))
      timeout     = "40s"
    }

    inline = [
      "cloud-init status --wait || echo 'Cloud-init still running, but connection successful'",
      "echo 'Server ${each.value.name} is ready!'"
    ]
  }
}

# Output warning if SSH key file doesn't exist
resource "null_resource" "ssh_key_warning" {
  count = local.ssh_key_exists ? 0 : 1

  provisioner "local-exec" {
    command = <<-EOT
      echo "⚠️ WARNING: SSH key file not found at ${var.ssh_public_key_path}"
      echo "Please create an SSH key pair using the following command:"
      echo "ssh-keygen -t rsa -b 4096 -f ${pathexpand(replace(var.ssh_public_key_path, ".pub", ""))}"
      echo "After creating the key, you may need to add it manually to your Hetzner Cloud account."
      echo "Set ssh_key_create=false and ssh_key_name to the name of your manually added key in terraform.tfvars."
    EOT
  }
} 