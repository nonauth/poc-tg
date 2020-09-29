remote_state {
  backend = "azurerm"
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  
  config = {
    // encrypt              = true
    resource_group_name  = local.resource_group_name
    storage_account_name = local.storage_account_name
    container_name       = local.container_name

    key = join("/", [
      local.environment,
      path_relative_to_include(),
      "terraform.tfstate",
    ])
  }
}


generate "azurerm" {
  path      = "versions.tf"
  if_exists = "overwrite"
  
  contents = <<-EOF
    terraform {
      required_version = "= ${local.terraform_version}"
    }

    provider "azurerm" {
      version = "= ${local.az_provider_version}"
      features {}
    }
  EOF
}


locals {
  current_dir = basename(get_parent_terragrunt_dir())
  environment = local.current_dir
  
  // Get common variables from relative path
  include_dirs = split("/", path_relative_to_include())
  location     = local.include_dirs.0
  project      = local.include_dirs.1

  // Global config for all environaments
  global_config = yamldecode(file(join("/", [
    get_parent_terragrunt_dir(),
    "..",
    "global.yml"
  ])))

  // Local config for current environment
  env_config = yamldecode(file(join("/", [
    get_parent_terragrunt_dir(),
    "config.yml"
  ])))

  resource_group_name  = local.env_config.resource_group_name
  storage_account_name = local.env_config.storage_account_name
  container_name       = local.env_config.container_name

  // Set terraform version
  terraform_version = lookup(
    local.env_config,
    "terraform_version",
    lookup(local.global_config, "terraform_version", "")
  )
  assert_terraform_version = local.terraform_version == "" ? file("ERROR: \"terraform_version\" variable is not set") : null

  // Set azure provider version
  az_provider_version = lookup(
    local.env_config,
    "az_provider_version",
    lookup(local.global_config, "az_provider_version", "")
  )
  assert_az_provider_version = local.az_provider_version == "" ? file("ERROR: \"az_provider_version\" variable is not set") : null

  // Define common tags
  env_tags    = try(local.env_config.tags, {})
  global_tags = try(local.global_config.tags, {})
  tags        = merge(
    local.global_tags,
    local.env_tags,
    {
      Environment = local.environment
      Project     = local.project
    }
  )
}


inputs = {
  environment = local.environment
  location    = local.location
  project     = local.project
  common_tags = local.tags
}
