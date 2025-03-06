variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "ubuntu_instances_count" {
  description = "Number of Ubuntu instances to deploy"
  type        = number
  default     = 1
}

variable "enable_ipv6" {
  description = "Enable or disable IPv6 for servers"
  type        = bool
  default     = false
}

variable "base_ip" {
  description = "Base IP for automatically assigning static IPs (last octets will be incremented)"
  type        = string
  default     = "10.0.1.2"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "timezone" {
  description = "Timezone for servers"
  type        = string
  default     = "UTC"
}

variable "username" {
  description = "Username for servers"
  type        = string
  default     = "useradm"
}

variable "password" {
  description = "Password for user (in production use a more secure method)"
  type        = string
  default     = "Us3rADM1234"
  sensitive   = true
}

variable "servers" {
  description = "Configuration of Ubuntu servers to deploy"
  type = list(object({
    name        = string
    server_type = string
    image       = string
    location    = string
    use_static_ip = bool
    static_ip   = optional(string)
    labels      = map(string)
  }))
  default = [
    {
      name        = "ubuntu-server"
      server_type = "cpx11"
      image       = "ubuntu-24.04"
      location    = "nbg1"
      use_static_ip = true
      labels      = { role = "web" }
    }
  ]
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "myproyect"
}

variable "network_cidr" {
  description = "CIDR range for private network"
  type        = string
  default     = "10.0.0.0/23"
}

variable "subnet_cidr" {
  description = "CIDR range for subnet"
  type        = string
  default     = "10.0.1.0/28"
}

variable "network_zone" {
  description = "Network zone in Hetzner"
  type        = string
  default     = "eu-central"
}

variable "allowed_ssh_ips" {
  description = "Allowed IPs for SSH connection"
  type        = list(string)
  default     = ["0.0.0.0/0"] # We recommend restricting this in production
}

variable "ssh_port" {
  description = "Custom SSH port"
  type        = number
  default     = 2255
}

variable "enable_http" {
  description = "Enable or disable HTTP port (80)"
  type        = bool
  default     = true
}

variable "enable_https" {
  description = "Enable or disable HTTPS port (443)"
  type        = bool
  default     = true
}

variable "custom_firewall_rules" {
  description = "Additional custom firewall rules"
  type = list(object({
    enabled    = bool
    direction  = string
    protocol   = string
    port       = string
    source_ips = list(string)
    description = string
  }))
  default = []
}

variable "ssh_password_authentication" {
  description = "Enable or disable SSH password authentication"
  type        = bool
  default     = false
}

variable "hostname" {
  description = "Hostname for the server (if not specified, the server name will be used)"
  type        = string
  default     = ""
} 