# azure-appgw-webserver

2 Nginx VMs, one in `snet-app-az1` and one in `snet-app-az2` (from
the `azure-virtual-network` project), exposed to the Internet through
a public Azure Application Gateway (Layer 7). The Gateway itself
spans all 3 AZs (`zones = [1, 2, 3]`); the backend VMs currently live
in 2 of those AZs.

## Architecture

```
Internet
   |
   v
[Public IP + Application Gateway v2]  <- zones=[1,2,3], subnet: snet-appgw
   |  (HTTP:80 Listener -> Routing Rule -> Backend Pool)
   |
   +--> VM 1 - Nginx in snet-app-az1 (10.0.11.x) - "I am instance 1"
   |
   +--> VM 2 - Nginx in snet-app-az2 (10.0.12.x) - "I am instance 2"
```

Each VM serves a distinct HTML page ("I am instance 1" / "I am
instance 2", plus its zone and hostname) to visually confirm the
Application Gateway is distributing traffic across both when
refreshing the browser or running multiple `curl` requests.

## Prerequisites

`azure-virtual-network` must already have these applied:
- `snet-appgw` - dedicated subnet for the Application Gateway
- `nsg-appgw` - its NSG
- A rule in `nsg-private` allowing HTTP:80 from `snet-appgw`

## Project data

| Resource | Value |
|---|---|
| Resource Group | `johan` |
| VNet | `vnet-ha` (`10.0.0.0/16`) |
| App subnets used | `snet-app-az1` (`10.0.11.0/24`), `snet-app-az2` (`10.0.12.0/24`) |
| Application Gateway subnet | `snet-appgw` (`10.0.40.0/24`, created in `azure-virtual-network`) |
| VM size | `Standard_D2s_v3` (same as jumpbox - reliable zonal capacity in `centralus`) |

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## HTTP only, no TLS yet

The listener is `Http` on port 80 - no certificate or public domain
configured yet. The Application Gateway resource still requires an
explicit `ssl_policy` block (Azure rejects the provider's old
default TLS policy), even with no HTTPS listener in use:

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
Balancer - it distributes based on backend health and availability,
so both instances should show up within a few requests.

## How traffic reaches the backend from the Internet

```
curl/browser -> Public IP (Application Gateway frontend, port 80)
             -> Listener + Routing Rule
             -> new connection to a healthy backend pool IP (10.0.11.x / 10.0.12.x)
             -> Nginx responds
```

The Application Gateway acts as a proxy: your connection terminates
at the gateway, which opens a separate connection to the chosen
backend VM over the private VNet. The VMs have no public IP and are
unreachable directly from the Internet - `nsg-private` only allows
inbound HTTP:80 from the `snet-appgw` CIDR. The health probe (`GET /`
every 30s) determines which backend IPs are eligible for traffic.

## Scaling to more instances

Increase `web_instance_count` and add the matching subnet name to
`app_subnet_names` (e.g. `snet-app-az3` for a third instance).

## Files

| File | Contents |
|---|---|
| `providers.tf` | AzureRM provider |
| `variables.tf` | Variables, including `web_instance_count` and `app_subnet_names` |
| `data.tf` | References to existing RG/VNet/subnets (app x N + appgw) |
| `webserver.tf` | NICs + Nginx VMs, one per AZ, instance-identifiable HTML |
| `application_gateway.tf` | Application Gateway with `zones=[1,2,3]` and dynamic backend pool |
| `outputs.tf` | Gateway public IP, VM IPs and names |
| `terraform.tfvars.example` | Ready-to-copy real values |
