# azure-lb-webserver

Nginx VMs behind a public Azure Application Gateway, consuming subnets from the sibling `azure-virtual-network` project.

## Design decisions worth knowing before changing anything

- **Single regional `snet-app` subnet, not per-AZ.** This project originally targeted `snet-app-az1`/`snet-app-az2` from an older `azure-virtual-network` design that has since been retired (see that repo's CLAUDE.md - "one subnet per tier, not one per AZ"). If you see per-AZ subnet names anywhere, that's stale; HA here comes from the `zones` argument on the VMs (cycling through 1/2/3 via `count.index % 3`), not from separate subnets.
- **No `backend.tf` originally** - this project used local state until it was migrated to the shared remote backend (key `lb-webserver/terraform.tfstate`), matching `azure-virtual-network` and `azure-jumpbox-server`.

## `subscription_id`

Same rule as the other two projects: set it with `TF_VAR_subscription_id`, not `ARM_SUBSCRIPTION_ID` - the provider block passes `subscription_id = var.subscription_id` explicitly.

## Dependency on `azure-virtual-network`

This project reads `snet-app` and `snet-appgw` by name via data sources (no `terraform_remote_state`) - it has no way to detect if those names or the resource group (`rg-network`) change upstream. If `azure-virtual-network`'s subnet layout changes again, this project's `terraform plan` will start failing with "not found" errors on the data sources - check that repo's current `subnets.tf`/`variables.tf` before assuming this project's defaults are still correct.

## No `prevent_destroy`

Unlike `azure-virtual-network`, this project owns no shared/stateful resources - a plain `terraform destroy` is safe here.

## Git remotes

- `origin` → `github.com:xstratus/azure-lb-webserver` (public)
- `jalcalaroot` → `github.com:jalcalaroot/azure-lb-webserver` (public)

Push to both after every commit, same as the sibling repos.
