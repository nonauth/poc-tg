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
  tfmodules_version = "master"
  
  resource_groups = {
    main = {
      location = local.location
      tags     = {}
    }
  }
}

inputs = {
  resource_groups = local.resource_groups
}
