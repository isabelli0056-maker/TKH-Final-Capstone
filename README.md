# Hardened AWS Web Stack with DevSecOps CI/CD Gate

> *"Security isn't an afterthought; it's compiled into the infrastructure from line one."*

## Architectural Core

This repository contains a modular Infrastructure as Code (IaC) deployment that provisions a hardened, isolated cloud host on AWS. 

By integrating continuous security analysis directly into the software development lifecycle, this pipeline automatically analyzes every Terraform pull request and commit. Infrastructure configurations that violate security baseline policies are automatically flagged and blocked prior to cloud deployment.

## System Workflow & Topology

```text
               +----------------------------------+
               |  Developer Commit / Pull Request |
               +----------------------------------+
                                |
                                v
               +----------------------------------+
               | GitHub Actions Security Pipeline |
               |  * Code Formatting Check         |
               |  * HCL Syntax Validation         |
               |  * tfsec Vulnerability Audit     |
               +----------------------------------+
                                |
                   [ Passed Security Audit ]
                                |
                                v
+-----------------------------------------------------------------+
| AWS Cloud Environment (Region: us-east-1)                       |
|                                                                 |
|  Virtual Private Cloud (VPC) Subnet: 10.0.0.0/16                |
|  +-----------------------------------------------------------+  |
|  | Public Gateway Subnet: 10.0.1.0/24                       |  |
|  |                                                           |  |
|  |  +-----------------------------------------------------+  |  |
|  |  | Stateful Ingress/Egress Firewall Rule Set          |  |  |
|  |  |  * Allow TCP Port 80 (Web Traffic)                  |  |  |
|  |  |  * Allow TCP Port 22 (Restricted Source IP Only)    |  |  |
|  |  +-----------------------------------------------------+  |  |
|  |                            |                              |  |
|  |                            v                              |  |
|  |  +-----------------------------------------------------+  |  |
|  |  | EC2 Instance (Amazon Linux 2023)                   |  |  |
|  |  |  * Automated Apache/HTTPD Bootstrapping Script     |  |  |
|  |  +-----------------------------------------------------+  |  |
|  +-----------------------------------------------------------+  |
+-----------------------------------------------------------------+

Security Posture & Engineering Principles
Automated Static Security Gates: Implements automated static analysis via tfsec within GitHub Actions to discover configuration vulnerabilities during code creation rather than post-deployment.

Restricted Network Perimeter: Disallows universal administrative access (0.0.0.0/0 on SSH) by strictly binding administrative access rules to designated single-host CIDR blocks.

Dedicated VPC Segmentation: Avoids default AWS networking resources in favor of an independently configured VPC, route table, and subnet layout.

Declarative Host Bootstrapping: Employs stateless initialization scripts (user_data) to automatically install, configure, and launch web services upon EC2 instantiation.

File Hierarchy
.github/workflows/security-scan.yml — CI/CD automation definition executing linting checks and SAST scans.

main.tf — Primary HCL resource definitions for networking, compute, and access boundaries.

variables.tf — Input variable declarations for network subnets, instance types, and region targeting.

outputs.tf — Output declarations exporting public networking details upon completion.

.gitignore — Exclusion patterns preventing local state files (.tfstate) and keys from being committed.

README.md — Technical reference documentation.

Deployment Instructions

System Requirements
Terraform Binary (>= 1.0.0)
Authenticated AWS CLI session
Git Client

Command Sequence
# Initialize working directory and fetch dependencies
terraform init

# Validate configuration structure and syntax
terraform validate

# Provision resources into target AWS account
terraform apply -auto-approve

# Test HTTP endpoint connectivity
curl http://<INSTANCE_PUBLIC_IP>

# Tear down provisioned cloud resources
terraform destroy -auto-approve

Maintainer
Isabelli Duran — Cloud & DevSecOps Engineer