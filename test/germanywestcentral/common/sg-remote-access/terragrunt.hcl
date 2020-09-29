include {
  path = find_in_parent_folders()
}

terraform {
  // source = "${get_parent_terragrunt_dir()}/../../poc-tf-modules//az-network-security-group"
  source = "git@github.com:nonauth/poc-tf-modules.git//az-network-security-group?ref=${local.tfmodules_version}"
}

locals {
  current_dir       = get_terragrunt_dir()
  project           = basename(dirname(local.current_dir))
  location          = basename(dirname(dirname(local.current_dir)))
  environment       = basename(dirname(dirname(dirname(local.current_dir))))
  name              = replace(basename(local.current_dir), "/^sg-/", "")
  
  env_config = yamldecode(file(join("/", [
    get_parent_terragrunt_dir(),
    "config.yml"
  ])))
  
  versions_config = jsondecode(file(join("/", [
    get_parent_terragrunt_dir(),
    "..",
    "versions.json"
  ])))
  
  tfmodules_version = local.versions_config[local.environment]["tfmodules"]["version"]

  tags = {
    TFModulesVersion = local.tfmodules_version
  }
  
  security_rules = {
    ssh = {
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = 22
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
    web = {
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = 80
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

dependencies {
  paths = [
    "../resource-groups",
  ]
}

dependency "rg" {
  config_path = "../resource-groups"
}

inputs = {
  name                = local.name
  resource_group_name = dependency.rg.outputs.rgs.network.name
  security_rules      = local.security_rules
  tags                = local.tags
}
