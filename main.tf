terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

locals {
  common_tags = {
    Owner = "${var.owner}"
  }
  resource_group_name    = "${var.resource_group_name_prefix}-resource-group"
  storage_container_name = "${var.resource_group_name_prefix}-storage-container"
}

data "azurerm_storage_account" "dev" {
  name                = "${var.resource_group_name_prefix}storaccount"
  resource_group_name = local.resource_group_name
}

data "azurerm_virtual_machine" "dev" {
  name                = "${var.resource_group_name_prefix}-vm"
  resource_group_name = local.resource_group_name
}



resource "azurerm_recovery_services_vault" "dev" {
  name                = "${var.resource_group_name_prefix}-recovery-vault"
  location            = var.resource_group_location
  resource_group_name = local.resource_group_name
  sku                 = "Standard"

  soft_delete_enabled = false

  tags = merge(local.common_tags)
}

resource "azurerm_backup_policy_vm" "dev" {
  name                           = "${var.resource_group_name_prefix}-recovery-vault-policy"
  resource_group_name            = local.resource_group_name
  recovery_vault_name            = azurerm_recovery_services_vault.dev.name
  instant_restore_retention_days = 5
  timezone                       = "UTC"

  backup {
    frequency = "Weekly"
    time      = "00:00"
    weekdays  = ["Sunday"]
  }

  retention_weekly {
    weekdays = ["Sunday"]
    count    = 5
  }

  tags = merge(local.common_tags)
}

resource "azurerm_backup_protected_vm" "dev" {
  resource_group_name = local.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.dev.name
  source_vm_id        = data.azurerm_virtual_machine.dev.id
  backup_policy_id    = azurerm_backup_policy_vm.dev.id

  tags = merge(local.common_tags)
}

resource "azurerm_storage_share" "dev" {
  name                 = "${var.resource_group_name_prefix}-share"
  storage_account_name = data.azurerm_storage_account.dev.name
  quota                = 1
}

resource "azurerm_storage_blob" "dev" {
  name                   = "addShare.ps1"
  storage_account_name   = data.azurerm_storage_account.dev.name
  storage_container_name = local.storage_container_name
  type                   = "Block"
  source                 = "addShare.ps1"
}

resource "azurerm_virtual_machine_extension" "dev" {
  name                 = "InitialScript"
  virtual_machine_id   = data.azurerm_virtual_machine.dev.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {
        "fileUris": ["https://${data.azurerm_storage_account.dev.name}.blob.core.windows.net/${local.storage_container_name}/${azurerm_storage_blob.dev.name}"],
        "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.addShare.rendered)}')) | Out-File -filepath addShare.ps1\" && powershell -ExecutionPolicy Unrestricted -File addShare.ps1 -Storage_account_name ${data.template_file.addShare.vars.Storage_account_name} -Storage_account_key ${data.template_file.addShare.vars.Storage_account_key} -File_share_name ${data.template_file.addShare.vars.File_share_name}"
    }
  SETTINGS

}

data "template_file" "addShare" {
    template = "${file("addShare.ps1")}"
    vars = {
        Storage_account_name  = "${data.azurerm_storage_account.dev.name}"
        Storage_account_key   = "${data.azurerm_storage_account.dev.primary_access_key}"
        File_share_name       = "${azurerm_storage_share.dev.name}"
  }
}