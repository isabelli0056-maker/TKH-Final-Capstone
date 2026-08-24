# Hardened AWS Web Stack with DevSecOps CI/CD Gate

> *"Security isn't an afterthought; it's compiled into the infrastructure from line one."*

## Architectural Core

This repository contains a modular Infrastructure as Code (IaC) deployment that provisions a hardened, isolated cloud host on AWS. 

By integrating continuous security analysis directly into the software development lifecycle, this pipeline automatically analyzes every Terraform pull request and commit. Infrastructure configurations that violate security baseline policies are automatically flagged and blocked prior to cloud deployment.

## Technologies Used

* **Cloud & Infrastructure:** AWS (VPC, Subnets, Internet Gateway, Security Groups, EC2), HashiCorp Terraform (HCL)
* **DevSecOps & CI/CD:** GitHub Actions, Automated Security Gates
* **Security & Compliance:** tfsec SAST Scanner, Network Isolation, Restricted Administrative Port (SSH) Hardening

---

## Pipeline Architecture & Workflow

* **Step 1: Code Quality & Security Gate:** Automated Terraform format check (`terraform fmt`), syntax validation (`terraform validate`), and static application security testing (SAST) via `tfsec`.
* **Step 2: Network & Firewall Provisioning:** Automated creation of a dedicated VPC (`10.0.0.0/16`), custom public subnet (`10.0.1.0/24`), and stateful security group restricting administrative access.
* **Step 3: Zero-Touch Host Deployment:** Automated provisioning of an Amazon Linux 2023 EC2 web host bootstrapped via `user_data` to auto-launch Apache (`httpd`).

---

## Security Posture & Engineering Principles

* **Automated Static Security Gates:** Implements automated static analysis via `tfsec` within GitHub Actions to discover configuration vulnerabilities during code creation rather than post-deployment.
* **Restricted Network Perimeter:** Disallows universal administrative access (`0.0.0.0/0` on SSH) by strictly binding administrative access rules to designated single-host CIDR blocks.
* **Dedicated VPC Segmentation:** Avoids default AWS networking resources in favor of an independently configured VPC, route table, and subnet layout.
* **Declarative Host Bootstrapping:** Employs stateless initialization scripts (`user_data`) to automatically install, configure, and launch web services upon EC2 instantiation.

---

## File Hierarchy

* `.github/workflows/security-scan.yml` — CI/CD automation definition executing linting checks and SAST scans.
* `main.tf` — Primary HCL resource definitions for networking, compute, and access boundaries.
* `variables.tf` — Input variable declarations for network subnets, instance types, and region targeting.
* `outputs.tf` — Output declarations exporting public networking details upon completion.
* `.gitignore` — Exclusion patterns preventing local state files (`.tfstate`) and keys from being committed.
* `README.md` — Technical reference documentation.

---

## Deployment Instructions

### System Requirements
* Terraform Binary (`>= 1.0.0`)
* Authenticated AWS CLI session
* Git Client

### Command Sequence

```bash
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

#Maintainer
Isabelli Duran — Cloud & DevSecOps Engineer
