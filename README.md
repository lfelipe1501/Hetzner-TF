# Terraform for Ubuntu on Hetzner Cloud :sunglasses:
<img src="https://raw.githubusercontent.com/lfelipe1501/lfelipe-projects/master/Terraform/TerraFUbuntu.svg" alt="tfubn-logo" width="256" />

This repository contains Terraform configurations to deploy and manage Ubuntu servers on Hetzner Cloud. It includes automated server setup, network configuration, firewall rules, and SSH security hardening.

## Features

- Automated Ubuntu server deployment
- Custom SSH port and security configuration
- Firewall setup with fail2ban
- Private network configuration
- Cloud-init for initial server setup
- Conditional SSH password authentication
- Custom hostname configuration
- Wait for cloud-init completion before showing connection details

## Requirements

- Terraform >= 1.0.0
- Hetzner Cloud account
- Hetzner Cloud API token
- SSH key pair

## File Structure

- `main.tf`: Main resource configuration
- `variables.tf`: Variable definitions
- `terraform.tfvars.template`: Template for variable values (copy to terraform.tfvars)
- `outputs.tf`: Deployment outputs
- `provider.tf`: Provider configuration
- `versions.tf`: Required versions and providers
- `scripts/cloud-init-ubuntu.yaml`: Cloud-init configuration for server setup

## Quick Start

1. Clone this repository:

   ```bash
   git clone git@github.com:lfelipe1501/Hetzner-TF.git
   cd terraform-hetzner-ubuntu
   ```

2. Create your configuration file from the template:

   ```bash
   cp terraform.tfvars.template terraform.tfvars
   ```

3. Configure your variables in `terraform.tfvars`:
   - Set your Hetzner Cloud API token
   - Configure SSH settings (path to public key, port)
   - Set username, password, and hostname
   - Adjust server specifications as needed
   - Configure network settings
   - Update allowed SSH IPs for better security

4. Initialize Terraform:

   ```bash
   terraform init
   ```

5. Plan the deployment:

   ```bash
   terraform plan
   ```

6. Apply the configuration:

   ```bash
   terraform apply
   ```

7. Connect to your server using the connection details provided in the output.

8. To destroy the infrastructure:

   ```bash
   terraform destroy
   ```

## Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `hcloud_token` | Hetzner Cloud API token | - |
| `ubuntu_instances_count` | Number of Ubuntu instances to deploy | 1 |
| `ssh_public_key_path` | Path to SSH public key file | ~/.ssh/id_rsa.pub |
| `ssh_port` | Custom SSH port | 2255 |
| `ssh_password_authentication` | Enable/disable SSH password authentication | false |
| `username` | Username for the server | useradm |
| `password` | Password for the user | - |
| `hostname` | Custom hostname for the server | "" (uses server name) |
| `servers` | Server configuration (type, image, location) | See terraform.tfvars.template |
| `allowed_ssh_ips` | IPs allowed to connect via SSH | ["0.0.0.0/0"] |

## Outputs

After deployment, Terraform will display:

- `ubuntu_server_ips`: Public IPs of the servers
- `ubuntu_server_status`: Status of the servers
- `ubuntu_server_dns`: DNS names of the servers
- `ssh_connection_strings`: Ready-to-use SSH connection commands
- `connection_instructions`: Detailed connection instructions

## Security Considerations

- The default configuration disables SSH password authentication (key-based only)
- Custom SSH port (2255) is used instead of the default port 22
- Firewall is configured to allow only necessary connections
- fail2ban is installed to protect against brute force attacks
- **Important**: Update the `allowed_ssh_ips` in your `terraform.tfvars` to restrict SSH access to your IP addresses only

## Customization

You can customize the deployment by modifying:

1. `terraform.tfvars` for basic configuration (copy from terraform.tfvars.template)
2. `variables.tf` to add new variables or change defaults
3. `scripts/cloud-init-ubuntu.yaml` for server initialization tasks

## Troubleshooting

- If you can't connect to the server, check that:
  - Your SSH key is correctly configured
  - The server has finished initializing (cloud-init complete)
  - Your IP is allowed in the firewall rules
  - You're using the correct SSH port

- To check cloud-init logs on the server:

  ```bash
  sudo cat /var/log/cloud-init-output.log
  ```
  
