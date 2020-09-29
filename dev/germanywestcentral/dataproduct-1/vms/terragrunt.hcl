include {
  path = find_in_parent_folders()
}

terraform {
  // source = "${get_parent_terragrunt_dir()}/../../poc-tf-modules//az-vms"
  source = "git@github.com:nonauth/poc-tf-modules.git//az-vms?ref=${local.tfmodules_version}"
}

locals {
  current_dir       = get_terragrunt_dir()
  project           = basename(dirname(local.current_dir))
  location          = basename(dirname(dirname(local.current_dir)))
  environment       = basename(dirname(dirname(dirname(local.current_dir))))
  
  env_config = yamldecode(file(join("/", [
    get_parent_terragrunt_dir(),
    "config.yml"
  ])))
  
  versions_config = jsondecode(file(join("/", [
    get_parent_terragrunt_dir(),
    "..",
    "versions.json"
  ])))
  
  tfmodules_version   = local.versions_config[local.environment]["tfmodules"]["version"]
  dataproduct_version = local.versions_config[local.environment]["dataproducts"][local.project]["version"]

  tags = {
    TFModulesVersion   = local.tfmodules_version
    DataproductVersion = local.dataproduct_version
  }
}

dependencies {
  paths = [
    "../../common/subnets",
    "../../common/sg-remote-access",
    "../../common/key-vault-ssh",
    "../resource-groups",
    "../storage-accounts",
    "../public-ips"
  ]
}

dependency "subnet" {
  config_path = "../../common/subnets"
}

dependency "nsg" {
  config_path = "../../common/sg-remote-access"
}

dependency "ssh" {
  config_path = "../../common/key-vault-ssh"
}

dependency "rg" {
  config_path = "../resource-groups"
}

dependency "sa" {
  config_path = "../storage-accounts"
}

dependency "pip" {
  config_path = "../public-ips"
}

inputs = {
  resource_group_name = dependency.rg.outputs.rgs.main.name
  
  vms = {
    bastion = {
      subnet_id                     = dependency.subnet.outputs.subnets.main.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id          = dependency.pip.outputs.ips.main.id
      network_security_group_id     = dependency.nsg.outputs.sg.id
      size                          = "Standard_DS1_v2"
      
      image = {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
      }

      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = 30
      }

      admin_username      = local.env_config.default_admin_user
      secret_name         = dependency.ssh.outputs.secrets.main.name
      key_vault_id        = dependency.ssh.outputs.vault.id
      storage_account_uri = dependency.sa.outputs.accounts.logs.primary_blob_endpoint
      
      tags = {
        Tier = "Public"
      }
    }
  }
  
  tags                = local.tags
}
