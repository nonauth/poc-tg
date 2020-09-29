include {
  path = find_in_parent_folders()
}

terraform {
  // source = "${get_parent_terragrunt_dir()}/../../poc-tf-modules//az-subnets"
  source = "git@github.com:nonauth/poc-tf-modules.git//az-subnets?ref=${local.tfmodules_version}"
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
}

dependencies {
  paths = [
    "../virtual-networks",
  ]
}

dependency "vnets" {
  config_path = "../virtual-networks"
}

inputs = {
  subnets = {
    main = {
      resource_group_name  = dependency.vnets.outputs.virtual_networks.main.resource_group_name
      virtual_network_name = dependency.vnets.outputs.virtual_networks.main.name
      address_prefixes     = local.env_config.vnet[local.location].address_prefixes
    }
  }
  
  tags = local.tags
}
