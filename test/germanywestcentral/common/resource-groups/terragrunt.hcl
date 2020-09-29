include {
  path = find_in_parent_folders()
}

terraform {
  // source = "${get_parent_terragrunt_dir()}/../../poc-tf-modules//az-resource-groups"
  source = "git@github.com:nonauth/poc-tf-modules.git//az-resource-groups?ref=${local.tfmodules_version}"
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
  
  resource_groups = {
    secrets = {
      location = local.location
      tags     = {}
    }
    network = {
      location = local.location
      tags     = {}
    }
  }
}

inputs = {
  resource_groups = local.resource_groups
  tags            = local.tags
}
