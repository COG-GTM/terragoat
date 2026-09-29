# TerraGoat IaC remediation backlog (checkov + tfsec)

Scope: `terraform/` on `master` @ 729f8da, scanned with **checkov 3.3.20** and **tfsec v1.28.14**.
Full per-resource evidence: [`iac-findings-reconciled.md`](./iac-findings-reconciled.md) (generated).
Regenerate both scans + the evidence file with `tools/iac-scan/run_scans.sh`; the rule mapping lives in
`tools/iac-scan/crosswalk.py`.

## How this was built

1. Ran both tools over `terraform/` (checkov: terraform + secrets + dockerfile frameworks; tfsec: defaults).
2. Normalised each finding to `(file, resource)` and mapped rule IDs from both tools onto 25 shared
   **controls** (e.g. `public-database` = `CKV_AWS_17`, `CKV_AZURE_113`, ... ≈ `aws-rds-no-public-db-access`,
   `azure-database-no-public-access`, ...).
3. For every `(control, resource)` pair, recorded whether **both**, **checkov only** or **tfsec only** flagged it.
4. Priority = Sev 0–3 from the org bug-severity rubric, judged on impact if this were deployed, **not** on
   either tool's severity label (checkov gives no severity without a Prisma Cloud key; tfsec's are inconsistent, see below).

| | checkov | tfsec |
|---|---|---|
| Raw failed checks | 474 (467 terraform, 5 secrets, 2 Dockerfile) | 246 (19 CRITICAL / 90 HIGH / 89 MEDIUM / 48 LOW) |
| Resources with ≥1 finding | 104 | 85 |
| Mapped `(control, resource)` pairs | 251 | 160 |

Of 263 mapped control/resource pairs: **148 agreed, 103 checkov only, 12 tfsec only.**
66 checkov rule IDs (123 findings) have no tfsec equivalent at all; tfsec had none left over.

## Prioritized backlog

Priority P0 = Sev 0 (fix now: secret exposure / data open to internet / authz bypass), P1 = Sev 1, P2 = Sev 2, P3 = Sev 3.
"Agree" shows how many affected resources both tools flagged.

| # | P | Control | What to fix (resources) | Agree | Notes |
|---|---|---|---|---|---|
| 1 | P0 | Hard-coded secrets | AWS keys in `aws/providers.tf` provider block, `aws/lambda.tf` env vars, `aws/ec2.tf` user_data; DB admin passwords in `azure/sql.tf` (L15, L83) and `azure/mssql.tf` (×7). Rotate, then move to variables / Key Vault / Secrets Manager. | 1/7 | tfsec only sees the user_data case. **Neither tool** flags `azure/sql.tf:83` or the 7 `AdminPassword123!` literals in `mssql.tf` (found by manual grep). |
| 2 | P0 | Internet-open admin ports | `aws_security_group.web-node` (22, 80), `azurerm_network_security_group.bad_sg` (22, 3389), `google_compute_firewall.allow_all` (0-65535). | 3/3 | Full agreement. |
| 3 | P0 | Public object storage | 6 S3 buckets without public-access-block; `google_storage_bucket_iam_binding.allow_public_read` (allUsers); `google_bigquery_dataset.dataset` (allAuthenticatedUsers); 2 Azure storage accounts allowing blob public access; Ali OSS `bad_bucket` (public-read); OCI `secretsquirrel` (ObjectRead). | 8/13 | checkov-only on Azure storage public blobs, GCS public-access-prevention, Alicloud and OCI. |
| 4 | P0 | Public databases | `aws_db_instance.default` (publicly_accessible), 7 `azurerm_mssql_server`, Azure MySQL/Postgres/`azurerm_sql_server`, GCP `master_instance` (0.0.0.0/0 authorised network + public IP), Ali `seeme`. | 11/13 | tfsec rates the Azure ones MEDIUM and the AWS one CRITICAL for the same exposure; treat all as P0. |
| 5 | P0 | IAM over-privilege | `aws_iam_policy_document.policy` → ES domain policy grants `es:*` to Principal `*` (anonymous access to the domain); `aws_iam_user_policy.userpolicy` and `aws_iam_role_policy.ec2policy` (`s3:*`, `ec2:*` on `*`); `azurerm_role_definition.example` (`actions = ["*"]` at subscription scope = custom owner). | 2/4 | The two worst ones (anonymous ES access, custom subscription owner) are **checkov only**. |
| 6 | P1 | Public Kubernetes control planes | EKS (public endpoint, 0.0.0.0/0), AKS (no authorized IP ranges, not private), GKE (`master_authorized_networks` 0.0.0.0/0, no private nodes). | 3/3 | |
| 7 | P1 | Kubernetes authz | AKS RBAC disabled + dashboard enabled; GKE `enable_legacy_abac = true`. | 2/2 | checkov additionally flags AKS local admin and GKE client-cert auth. |
| 8 | P1 | Key Vault network | `azurerm_key_vault.example` default-allow network ACL, public network access. | 1/1 | |
| 9 | P1 | Metadata service | IMDSv1 on `web_host`, `db_app`; GKE legacy metadata on node pool. | 3/4 | |
| 10 | P1 | Encryption in transit | ES (no HTTPS enforcement / node-to-node), App Service TLS 1.1 + no HTTPS-only, Azure storage + MSSQL/MySQL/Postgres min TLS, GCP SQL `require_ssl`, ELB HTTP listener, App Gateway HTTP listener, RDS, Ali RDS. | 14/19 | See disagreements on `azurerm_sql_server`. |
| 11 | P1 | Encryption at rest | EBS volume + root devices, 9 Aurora clusters, RDS instance, Neptune cluster + snapshot, ES domain, EKS secrets, Azure managed disk + Windows VM, Lambda env. | 17/25 | tfsec's 5 S3 "not encrypted" findings are **downgraded** (see below). |
| 12 | P1 | VM authentication | Azure Linux VM password auth; GCE OS Login off / project SSH keys allowed. | 2/2 | |
| 13 | P2 | Network exposure | Public-IP subnets (EKS VPC ×2, web subnets), `0.0.0.0/0` egress, default SG not restricted, GCE public IP, ES outside VPC, App Gateway without WAF, subnet without NSG. | 7/13 | tfsec's `aws-elb-alb-not-public` on the web ELB is expected for a public web tier – accept/suppress. |
| 14 | P2 | Audit / flow logging | S3 access logs, EKS control plane logs, ES/Neptune/RDS/Aurora logs, VPC + subnet flow logs, Azure activity log profile, SQL auditing (×8), Postgres log params, GKE logging/monitoring `none`, Ali ActionTrail. | 24/46 | Large checkov-only tail (Aurora log exports ×9, Ali, app service logs). |
| 15 | P2 | Threat detection | Defender free tier, SQL threat alerts disabled / no email (×8), MySQL/Postgres threat detection. | 10/12 | |
| 16 | P2 | Backup / recovery | S3 versioning, RDS/Aurora backup retention (=0) + deletion protection, Neptune backups, Key Vault purge protection, GCP SQL backups, GCS/OSS/OCI versioning. | 8/22 | |
| 17 | P2 | DB authN | IAM DB auth on RDS / 9 Aurora / Neptune; AAD auth on 7 MSSQL + SQL server. | 1/19 | Almost entirely checkov-only; tfsec only checks `aws_db_instance`. |
| 18 | P2 | K8s network policy, GCE hardening, App Service authN, ECR scan/immutability | AKS/GKE network policy; GCE serial port + IP forwarding + shielded VM; app services without auth; ECR mutable tags + no scan-on-push. | 6/6 | |
| 19 | P3 | Customer-managed keys | S3, EBS, Aurora ×9, Neptune, ES, ECR, Azure storage/MySQL/disk, GCE disks, BigQuery, OSS, OCI. | 10/32 | Do after #11 – CMK only matters once encryption is on. |
| 20 | P3 | Key lifecycle + hygiene | KMS rotation, Key Vault key/secret expiry, SG descriptions, labels, HTTP/2, X-Ray, node auto-repair/upgrade, COS images, S3 lifecycle/event notifications, replication, Dockerfile HEALTHCHECK/USER, etc. | – | Bulk-fix or baseline; mostly single-tool best-practice checks. |

## Where the tools disagree

**checkov found, tfsec missed (checkov is right in every case I checked):**

- **Secrets.** checkov's secrets framework + `CKV_AWS_41/45` catch the AWS keys in the provider block and Lambda
  env vars and a DB password in `azure/sql.tf`; tfsec only scans EC2 `user_data`. Biggest single gap in tfsec.
- **Resource-policy wildcards.** `aws/es.tf` grants `es:*` to Principal `*`. tfsec's `aws-iam-no-policy-wildcards`
  fired on the IAM user/role policies but not on this document, which is attached via
  `aws_elasticsearch_domain_policy` (likely: it doesn't follow resource policies). Same for the Azure custom
  role with `actions = ["*"]` (`CKV_AZURE_39`).
- **Azure storage public blob access** (`allow_nested_items_to_be_public` defaults to true in azurerm 3.x) – checkov only.
- **Provider coverage.** tfsec has no Alibaba Cloud or Oracle rules and no Dockerfile scanning: 7 resources
  (public OSS bucket, public Ali RDS, public OCI bucket, ...) are invisible to it.
- **Breadth.** checkov has ~66 rules with no tfsec counterpart (Aurora log exports/backtracking, IAM DB auth on
  clusters, App Gateway WAF, Neptune snapshots, ...). Many are P2/P3, but they are real gaps, not noise.

**tfsec found, checkov missed:**

- **`azurerm_sql_server.example`**: public network access + TLS version. checkov has no public-access/TLS checks for
  the (deprecated) `azurerm_sql_server` resource type, only for `azurerm_mssql_server`. **tfsec is right**;
  migrating to `azurerm_mssql_server` fixes both the finding and the checkov blind spot.
- **Postgres `log_connections`** on Azure – tfsec right, minor.
- **S3 bucket encryption** on `data`, `data_science`, `financials`, `operations`, `flowbucket` (HIGH in tfsec).
  checkov's `CKV_AWS_19` passes these, most likely because S3 has applied SSE-S3 by default to all new objects since
  January 2023. **Trust checkov**: these are not unencrypted; the real gap is CMK (`CKV_AWS_145`, P3).
- **`aws-elb-alb-not-public`** on the web ELB – technically true, but a public web LB is the intended design. Suppress.
- **`google-gke-enforce-pod-security-policy`** – PodSecurityPolicy was removed in Kubernetes 1.25, so the
  recommended fix is not available on current GKE. **Obsolete rule; trust checkov** (use Pod Security Admission /
  Policy Controller instead).

**Both missed:** hard-coded admin passwords in `azure/mssql.tf` (×7) and `azure/sql.tf:83`. checkov's entropy-based
secret detector caught only one of the nine literal passwords. Add a dedicated secret scanner (gitleaks/trufflehog)
or a custom checkov policy on `administrator_login_password` being a literal.

**Severity disagreements.** tfsec labels the same exposure differently across clouds (public RDS = CRITICAL,
public Azure SQL = MEDIUM; S3 missing CMK = HIGH, EBS missing CMK = LOW; Azure storage TLS 1.0 = CRITICAL).
checkov OSS reports no severity at all. Neither tool's labels should drive prioritisation directly; this backlog
re-scores them by impact.

## Which tool I'd trust

**checkov as the primary gate**, tfsec as a secondary signal:

- checkov had ~9x more unique true positives than tfsec (103 vs 12 single-tool pairs), and of tfsec's 12
  unique ones, 7 are false/obsolete (5 S3-encryption, ELB public, GKE PSP) and 2 are P3 (CMK on a GCS bucket,
  RDS Performance Insights).
- checkov covers secrets, more providers (Alibaba, OCI), Dockerfiles, and resource policies.
- checkov is actively developed; tfsec is in maintenance mode and folded into Trivy (`trivy config`).
- tfsec still earns its place: it's fast, has per-cloud severity to triage from, and caught the
  `azurerm_sql_server` blind spot. Keeping it (soft-fail) is cheap.

## Assumptions

- Findings are prioritised as if TerraGoat were deployed for real; the repo is intentionally vulnerable, so none
  of this is a fix request for upstream TerraGoat itself.
- The crosswalk is hand-built at the control level; a few mappings are judgement calls (e.g. IMDSv1 and GKE
  metadata under one control). Unmapped rules are listed at the end of the generated file.
- tfsec was added to CI as `soft_fail: true`, same non-blocking posture as the existing checkov job, since the
  repo fails hundreds of checks by design.
- tfsec v1.28.14 (last release) is used despite Trivy superseding it, because the request was for tfsec.
