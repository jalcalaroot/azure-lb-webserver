# azure-lb-webserver

N Nginx VMs in a single regional app subnet (`snet-app`, from the
`azure-virtual-network` project), exposed to the Internet through a
public Azure Application Gateway (Layer 7). Both the Gateway and the
VMs are spread across all 3 AZs via the `zones` argument - Azure
subnets are regional, so HA comes from zone-pinning the resources, not
from splitting subnets per AZ.

## Architecture

```
Internet
   |
   v
[Public IP + Application Gateway v2]  <- zones=[1,2,3], subnet: snet-appgw
   |  (HTTP:80 Listener -> Routing Rule -> Backend Pool)
   |
   +--> VM 1 - Nginx in snet-app, zone 1 - "I am instance 1"
   |
   +--> VM 2 - Nginx in snet-app, zone 2 - "I am instance 2"
```

Each VM serves a distinct HTML page ("I am instance N", plus its zone
and hostname) to visually confirm the Application Gateway is
distributing traffic across instances when refreshing the browser or
running multiple `curl` requests.

## Prerequisites

- Terraform >= 1.5.0, Azure CLI, an Azure subscription.
- `TF_VAR_subscription_id` set (the provider requires it explicitly -
  see `azure-virtual-network`'s CLAUDE.md for why `ARM_SUBSCRIPTION_ID`
  alone does not work here).
- `azure-virtual-network` already applied, with these in place:
  - `snet-app` - the shared regional app subnet
  - `snet-appgw` - dedicated subnet for the Application Gateway, plus its `nsg-appgw`
  - A rule in `nsg-private` allowing HTTP:80 from `snet-appgw`

## Project data

| Resource | Value |
|---|---|
| Resource Group | `rg-network` (owned by `azure-virtual-network`) |
| VNet | `vnet-ha` (`10.0.0.0/16`) |
| App subnet used | `snet-app` (`10.0.8.0/22`), shared by all instances |
| Application Gateway subnet | `snet-appgw`, created in `azure-virtual-network` |
| VM size | `Standard_D2s_v3` (same as the jumpbox project - reliable zonal capacity in `centralus`) |

## Remote state

Backend is the same shared Azure Blob Storage backend used by
`azure-virtual-network` and `azure-jumpbox-server` (provisioned by
`azure-tfstate-bootstrap`), key `lb-webserver/terraform.tfstate`.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
export TF_VAR_subscription_id=$(az account show --query id -o tsv)
terraform init
terraform plan
terraform apply
```

## Destroy

```bash
terraform destroy
```

No `prevent_destroy` lifecycle blocks here - this project owns no
shared/stateful resources (unlike `azure-virtual-network`'s resource
group and VNet), so a plain destroy is safe.

## HTTP only, no TLS yet

The listener is `Http` on port 80 - no certificate or public domain
configured yet. The Application Gateway resource still requires an
explicit `ssl_policy` block (Azure rejects the provider's old default
TLS policy), even with no HTTPS listener in use:

```hcl
ssl_policy {
  policy_type = "Predefined"
  policy_name = "AppGwSslPolicy20220101"
}
```

This only satisfies the platform requirement for the gateway engine
itself; it has no effect on the current HTTP-only traffic. It will
matter once a certificate and HTTPS listener are added.

## Enable WAF

Default SKU is `Standard_v2`. For `WAF_v2` with OWASP rules:

```hcl
enable_waf = true
```

## Test load balancing

```bash
for i in 1 2 3 4 5 6; do
  curl -s http://$(terraform output -raw application_gateway_public_ip) | grep "I am"
done
```

Application Gateway doesn't do strict round-robin like a Load
Balancer - it distributes based on backend health and availability, so
all instances should show up within a few requests.

## How traffic reaches the backend from the Internet

```
curl/browser -> Public IP (Application Gateway frontend, port 80)
             -> Listener + Routing Rule
             -> new connection to a healthy backend pool IP (10.0.8.x - 10.0.11.x)
             -> Nginx responds
```

The Application Gateway acts as a proxy: your connection terminates at
the gateway, which opens a separate connection to the chosen backend
VM over the private VNet. The VMs have no public IP and are
unreachable directly from the Internet - `nsg-private` only allows
inbound HTTP:80 from the `snet-appgw` CIDR. The health probe (`GET /`
every 30s) determines which backend IPs are eligible for traffic.

## Scaling to more instances

Increase `web_instance_count` - no subnet changes needed, since all
instances share the single `snet-app` subnet and are zone-assigned
automatically (cycling through zones 1/2/3).

## Security notes

- No TLS/HTTPS listener yet (see above) - traffic between client and
  gateway is unencrypted HTTP.
- Backend VMs have no public IP; only the Application Gateway is
  Internet-facing, and it can only reach the backends over
  `nsg-private`'s HTTP:80 allow-rule from `snet-appgw`.
- WAF is opt-in (`enable_waf`), off by default.

## Cost notes

Application Gateway `Standard_v2`/`WAF_v2` bills for capacity units
plus an hourly base fee even when idle - this is the most expensive
piece of this stack to leave running. `terraform destroy` when not
actively testing. VM cost scales linearly with `web_instance_count`
and `vm_size`.

## Dependencies

Reads `snet-app` and `snet-appgw` directly from the existing VNet by
name (data sources, not `terraform_remote_state`) - see
`azure-virtual-network`'s CLAUDE.md "Consumers" table. If those subnet
names or the resource group ever change there, this project breaks
until updated to match.

## Files

| File | Contents |
|---|---|
| `providers.tf` | AzureRM provider (`subscription_id` required) |
| `backend.tf` | Shared remote state backend |
| `variables.tf` | Variables, including `web_instance_count` and `app_subnet_name` |
| `data.tf` | References to existing RG/VNet/subnets (app + appgw) |
| `webserver.tf` | NICs + Nginx VMs, zone-assigned, instance-identifiable HTML |
| `application_gateway.tf` | Application Gateway with `zones=[1,2,3]` and dynamic backend pool |
| `outputs.tf` | Gateway public IP, VM IPs and names |
| `terraform.tfvars.example` | Ready-to-copy real values |
