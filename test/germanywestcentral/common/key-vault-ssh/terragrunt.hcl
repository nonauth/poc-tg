include {
  path = find_in_parent_folders()
}

terraform {
  // source = "${get_parent_terragrunt_dir()}/../../poc-tf-modules//az-key-vault-ssh"
  source = "git@github.com:nonauth/poc-tf-modules.git//az-key-vault-ssh?ref=${local.tfmodules_version}"
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
  
  public_keys = {
    main = {
      key  = file("keys/nonauth_az_main.pub")
      tags = {}
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
  name                = "ssh"
  resource_group_name = dependency.rg.outputs.rgs.secrets.name
  public_keys         = local.public_keys
  tags                = local.tags
}
