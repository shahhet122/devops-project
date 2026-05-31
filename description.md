# Project Part I – Infrastructure-as-Code Definition

## Description

The goal of this project is to build a cloud-based image storage and display application on Microsoft Azure. The application lets users upload images through a web interface and view all uploaded files with download links. All infrastructure is defined as code using Terraform, so the entire environment can be created and destroyed in a repeatable, automated way without any manual steps in the Azure Portal.

The infrastructure consists of three main Azure services:

- **Storage Account** – stores the uploaded images inside a blob container called `images`
- **Key Vault** – stores sensitive configuration (the storage connection string) so it never appears in plain text in the application code or pipeline
- **App Service** – hosts the web application that reads from the storage account and serves the two web pages

---

## Approach

The infrastructure is split into separate `.tf` files, each responsible for one concern. This keeps things readable and easy to change without touching unrelated parts.

A `random_integer` resource is used to append a 4-digit suffix to the storage account name, key vault name, and app service name. This is necessary because all three must be globally unique across all of Azure — not just within the subscription.

The storage connection string is written into the Key Vault as a secret by Terraform itself, directly after the storage account is created. The App Service then references that secret using a Key Vault reference in its app settings (`@Microsoft.KeyVault(...)`), so the application never handles the raw connection string.

The App Service is given a **System-Assigned Managed Identity**, which is the recommended way to let an Azure service authenticate to Key Vault without storing any credentials anywhere.

---

## Connections Between Resources

```
Resource Group
    │
    ├── Storage Account
    │       └── Blob Container: "images"
    │               │
    │               └── primary_connection_string
    │                           │
    ├── Key Vault ◄─────────────┘
    │       └── Secret: "storage-connection-string"
    │                           │
    └── App Service Plan        │
            └── App Service ────┘  (reads secret via Key Vault reference)
                    └── System-Assigned Managed Identity
```

The App Service reads the storage connection string at runtime through a Key Vault reference in its app settings. This means the connection string is never stored in code, environment files, or the pipeline — it lives only in Key Vault.

---

## Authentication / Identity Context

| Resource | How it authenticates |
|---|---|
| Terraform (local run) | Uses the logged-in Azure CLI session (`az login`) — the deployer's object ID is passed in via `DEPLOYER_OBJECT_ID` variable (retrieved with `az ad signed-in-user show --query id -o tsv`) |
| Key Vault access policy | Grants `Get`, `List`, `Set`, `Delete`, `Purge` on secrets to the deployer's object ID, so Terraform can create the connection string secret |
| App Service → Key Vault | System-Assigned Managed Identity — Azure manages the credential automatically, no passwords or keys needed |
| App Service → Storage | Via the connection string retrieved from Key Vault at runtime |

No credentials are hardcoded anywhere. The `main.tfvars` file contains the tenant ID, subscription ID, and the deployer's object ID — none of which are passwords or access keys.

---

## Repository Content (GIT)

```
Project/
└── terraform/
    ├── provider.tf       # Terraform and provider version requirements
    ├── variables.tf      # All input variable declarations
    ├── locals.tf         # Shared constant values (SKU, tier, replication type)
    ├── random.tf         # Random integer for globally unique name suffixes
    ├── rg.tf             # Resource Group
    ├── sa.tf             # Storage Account + images blob container
    ├── kv.tf             # Key Vault + storage connection string secret
    ├── appservice.tf     # App Service Plan + Web App with Managed Identity
    └── main.tfvars       # Variable values (fill in tenant/subscription IDs)
```

The `.terraform/` directory and any `.tfstate` files are not committed to Git — they are local only.

---

## Terraform Definition

### How to run

**Step 1 – Login to Azure**
```bash
az login
```

**Step 2 – Initialize Terraform**
```bash
terraform init
```

**Step 3 – Preview what will be created**
```bash
terraform plan -var-file="main.tfvars"
```

**Step 4 – Apply (create all resources)**
```bash
terraform apply -var-file="main.tfvars"
```

**Step 5 – Destroy when done**
```bash
terraform destroy -var-file="main.tfvars"
```

### Files overview

**`provider.tf`** — declares the required providers (`azurerm ~> 3.0.2` and `random ~> 3.0`) and configures the Azure provider with the subscription ID from variables.

**`variables.tf`** — declares all input variables: tenant ID, subscription ID, location, resource group name, storage name, key vault name, app service plan name, and app service name.

**`locals.tf`** — defines shared constant values used across multiple files: storage tier (`Standard`), replication type (`LRS`), HTTPS-only flag, container access type (`private`), Key Vault SKU (`standard`), and App Service plan tier/size (`Free / F1`).

**`random.tf`** — creates a `random_integer` between 1000 and 9999, used as a suffix on resource names that must be globally unique.

**`rg.tf`** — creates the Azure Resource Group that contains all other resources.

**`sa.tf`** — creates the Storage Account (name = variable + random suffix, Standard LRS, HTTPS only) and the `images` blob container inside it with private access.

**`kv.tf`** — creates the Key Vault in `francecentral`, sets an access policy for the deployer using the `DEPLOYER_OBJECT_ID` variable, and stores the storage account's primary connection string as a secret named `storage-connection-string`.

**`appservice.tf`** — creates the App Service Plan (Free tier) and the Web App. The web app is given a System-Assigned Managed Identity and two app settings: the Key Vault reference to the connection string, and the container name.
