# azure-appgw-webserver

2 VMs con Nginx, una en `snet-app-az1` y otra en `snet-app-az2`
(proyecto `azure-virtual-network`), expuestas a Internet a traves de
un Azure Application Gateway (Capa 7) publico, repartido entre las 3
AZs.

## Arquitectura

```
Internet
   |
   v
[Public IP + Application Gateway v2]  <- zones=[1,2,3], subnet: snet-appgw
   |  (Listener HTTP:80 -> Routing Rule -> Backend Pool)
   |
   +--> VM 1 - Nginx en snet-app-az1 (zone 1) - "Soy la instancia 1"
   |
   +--> VM 2 - Nginx en snet-app-az2 (zone 2) - "Soy la instancia 2"
```

Cada VM sirve una pagina HTML distinta ("Soy la instancia 1" / "Soy
la instancia 2", con su zona y hostname) para poder confirmar
visualmente que el Application Gateway esta repartiendo trafico
entre ambas al refrescar el navegador o hacer varios `curl`.

## Pre-requisitos

Antes de este repo, `azure-virtual-network` debe tener aplicados los
parches que agregan:
- `snet-appgw` (subnet dedicada del Application Gateway)
- `nsg-appgw` (su NSG)
- La regla en `nsg-private` que permite HTTP:80 desde `snet-appgw`

## Datos reales del proyecto

| Recurso | Valor |
|---|---|
| Resource Group | `johan` |
| VNet | `vnet-ha` (`10.0.0.0/16`) |
| App subnets usadas | `snet-app-az1` (`10.0.11.0/24`), `snet-app-az2` (`10.0.12.0/24`) |
| Subnet Application Gateway | `snet-appgw` (`10.0.40.0/24`, creada en `azure-virtual-network`) |

## Uso

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Habilitar WAF

Por defecto SKU `Standard_v2`. Para `WAF_v2` con reglas OWASP:

```hcl
enable_waf = true
```

## Prueba de balanceo

```bash
# Correr varias veces - deberia alternar entre instancia 1 y 2
for i in 1 2 3 4 5 6; do
  curl -s http://$(terraform output -raw application_gateway_public_ip) | grep "Soy la"
done
```

Nota: Application Gateway no tiene "round robin puro" configurable
como Load Balancer - reparte segun disponibilidad y salud de las
instancias del backend pool, asi que en pocas requests deberias ver
ambas apareciendo.

## Escalar a mas instancias

Subir `web_instance_count` y agregar el nombre de subnet
correspondiente a `app_subnet_names` (ej. `snet-app-az3` para una
tercera instancia).

## Archivos

| Archivo | Contenido |
|---|---|
| `providers.tf` | Provider AzureRM |
| `variables.tf` | Variables, incluye `web_instance_count` y `app_subnet_names` |
| `data.tf` | Referencias a RG/VNet/subnets existentes (app x N + appgw) |
| `webserver.tf` | NICs + VMs Nginx, una por AZ, HTML identificable por instancia |
| `application_gateway.tf` | Application Gateway con `zones=[1,2,3]` y backend pool dinamico |
| `outputs.tf` | IP publica del gateway, IPs y nombres de las VMs |
| `terraform.tfvars.example` | Valores reales listos para copiar |
