# quote-engine-infra (DEMO)

GCP Terraform for the quote-engine backend (GKE app, Cloud SQL for quotes and
policies, GCS for policy documents, KMS, networking, IAM, BigQuery, DNS,
monitoring).

> This is **demo infrastructure with an intentionally mixed security posture.**
> It exists so an IaC security scan (KICS, terraform platform) produces a
> realistic mix of passing and failing controls. Do not deploy it.

## Reading the resource names

Resource names encode the intent so findings are easy to map in PR comments:

- `*_compliant` resources are configured to the secure default (the control
  has passing instances).
- `*_legacy`, `*_open`, `*_insecure`, `*_public` resources are intentionally
  misconfigured (the control produces a finding).

For most controls there is **both** a compliant and a non-compliant resource,
so each control shows up as a real-world mix rather than all-or-nothing.

## Files

| File            | Theme                                              |
| --------------- | -------------------------------------------------- |
| `versions.tf`   | terraform + google provider constraints, providers |
| `variables.tf`  | project_id, region, zone, labels                   |
| `network.tf`    | VPC, subnets, firewall, NAT, private service access |
| `gke.tf`        | hardened vs insecure GKE clusters + node pools     |
| `database.tf`   | Cloud SQL (SSL, public IP, backups)                |
| `storage.tf`    | GCS buckets (logging, versioning, public access)   |
| `kms.tf`        | KMS keys (rotation period, public access)          |
| `iam.tf`        | service accounts + IAM bindings                    |
| `compute.tf`    | VMs (shielded, OS login, serial port, public IP)   |
| `bigquery.tf`   | datasets (public access, CMEK)                     |
| `dns.tf`        | managed zones (DNSSEC)                             |
| `monitoring.tf` | secrets, pub/sub, log sink, metric + alert         |

## Controls exercised (mixed pass/fail)

Cloud SQL SSL, Cloud SQL public IP, Cloud SQL backups; GCS logging,
versioning, uniform bucket-level access, public/anonymous access; KMS key
rotation period and key public access; GKE network policy, shielded nodes,
legacy ABAC, basic auth / client cert, private cluster, node auto-repair;
Compute shielded VM, OS Login, serial port, IP forwarding, default SA + full
scope, public IP, disk CMEK; firewall 0.0.0.0/0 to SSH/RDP/all; subnet private
Google access + flow logs; auto-create-subnetworks; DNSSEC; IAM primitive/admin
roles, user (not group) members, token creator / SA user, SA keys; BigQuery
public dataset; Secret Manager / Pub/Sub public IAM.
