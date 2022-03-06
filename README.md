# DevOps Internship: Azure Task 2
## Hometask

1. Create a Recovery Services vault.
2. Configure a backup of VM, created at 1st day with automatic backup each Saturday at 00:00 GMT.
3. Create Azure File Share.
4. Connect new File Share as drive X: to VM, created at 1st day, using Custom script extension.

## Warning

Before starting, make sure that the virtual machine does not have Microsoft.Compute.CustomScriptExtension added.

## Solution

The task is completely solved with the help of Terraform
Components:
* Recovery services vault
* Backup:
    * Policy vm
    * Protected vm
* Storage:
    * share
    * blob
* Virtual machine extension
* Template file

## Terraform Commands
### Azure Authentication

```bash
az login
```

### Create
```bash
terraform init
terraform plan -out main.tfplan
terraform apply main.tfplan
```

### Destroy
```bash
terraform plan -destroy -out main.destroy.tfplan
terraform apply main.destroy.tfplan
```