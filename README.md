# Azure Platform Lab

Hands-on project building a small Tomcat web app on Azure: dev and test
environments created with Terraform, deployed through CI/CD pipelines
(GitHub Actions and Azure DevOps), and moved onto Kubernetes (AKS).

**Status:** In progress, Week 0 (setup)

## Planned stack
- Azure (VNet, VMs, Storage, Container Registry, AKS)
- Terraform (modules, remote state)
- GitHub Actions and Azure DevOps pipelines
- Docker and Kubernetes

## Roadmap
- [ ] Week 1–2: Terraform environments (dev and test)
- [ ] Week 3: Configure Tomcat and deploy the sample app
- [ ] Week 4–5: CI/CD pipelines with an approval gate
- [ ] Week 6–8: Containers, AKS, and pipeline to AKS

## Cost note
Everything is torn down with `terraform destroy` after each session.
