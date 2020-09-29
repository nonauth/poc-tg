# poc-tg

## Creating container for tfstate
```bash
az group create \
    --name <rg_name> \
    --location <location>

az storage account create \
    --name <account_name> \
    --resource-group <rg_name> \
    --location <location> \
    --sku Standard_RAGRS \
    --kind StorageV2

az storage container create \
    --name <container_name> \
    --account-name <account_name>
```
