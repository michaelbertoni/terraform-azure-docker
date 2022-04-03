# About
Docker image for IaC/CD usage, contains Terraform, Python 3, Azure and SQL Server tools, based on Ubuntu.

The final image is based on Ubuntu 20.04.

It contains the following tools:
| Name                               | Version     |
|------------------------------------|-------------|
| Terraform                          | 1.1.7       |
| Python                             | 3.8         |
| Azure CLI                          | 2.34.1      |
| sqlpackage                         | 16.0.5400.1 |
| mssql-tools (contains sqlcmd, bcp) | 17.9.1.1-1  |

## Usage

```bash
docker pull ghcr.io/michaelbertoni/terraform-azure-docker
```