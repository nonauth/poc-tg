include {
  path = find_in_parent_folders()
}

terraform {
  // source = "${get_parent_terragrunt_dir()}/../../poc-tf-modules//az-virtual-networks"
  source = "git@github.com:nonauth/poc-tf-modules.git//az-virtual-networks?ref=${local.tfmodules_version}"
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
  
  tfmodules_version = local.versions_config[local.environment]["tfmodules"]["version"]

  tags = {
    TFModulesVersion = local.tfmodules_version
  }
  
  virtual_networks = {
    main = {
      location      = local.location
      address_space = local.env_config.vnet[local.location].address_space
      tags          = {}
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
  resource_group_name = dependency.rg.outputs.rgs.network.name
  virtual_networks    = local.virtual_networks
  tags                = local.tags
}
