# AWS Multi-Region Resilient Architecture

A Warm Standby disaster recovery architecture across two AWS regions, built with modular Terraform. Capstone project for a 60-day AWS Solutions Architect / Cloud Engineer study program.

## Business framing

A revenue-critical web application needs to survive a full regional AWS outage. Leadership's constraint: downtime measured in minutes, not hours, and no meaningful data loss — but without the cost and operational complexity of an Active-Active setup.

## Architecture

**Warm Standby**, chosen over the other three DR tiers by elimination:
- **Backup & Restore** — rejected, RTO too slow (rebuilding infra from backups takes hours)
- **Pilot Light** — rejected, still requires bringing the application tier online during failover
- **Active-Active** — meets the requirement, but adds cost/complexity this scenario doesn't justify
- **Warm Standby** — scaled-down full stack already running in the secondary region, fast promotion, right cost/RTO balance

**Steady state:**
- `us-east-1` (primary): full VPC, ALB, ASG at production capacity (3 instances), Aurora Global Database writer cluster
- `us-west-2` (secondary): identical VPC/ALB stack, ASG scaled down to 1 instance, Aurora secondary cluster continuously replicating

**Failover sequence:** Route 53 health check detects primary failure → new traffic routed to secondary ALB → Aurora secondary cluster promoted to writer → ASG scales from 1 to production capacity → new instances pass health checks → traffic served from `us-west-2`, reading/writing through the now-promoted database.

## Repo layout

```
modules/
  vpc/        — reusable VPC module (public/private subnets, IGW, NAT, route tables)
  alb-asg/    — ALB + Auto Scaling Group + security groups + launch template + IAM
regions/
  us-east-1/  — primary region root config
  us-west-2/  — secondary region root config
database/     — Aurora Global Database (single root, dual AWS providers — see below)
dns/          — Route 53 private-zone failover routing (single root, global service)
```

Each region is an **independent root config with its own state**, since VPC and ALB/ASG resources in one region have zero coupling with the other. The database layer is different: Aurora Global Database is one logical resource spanning both regions with a strict creation-order dependency (secondary cluster can't join until the primary/global cluster exists), so it's built as a **single root with two provider aliases** instead — letting Terraform's own dependency graph enforce correct ordering, rather than trying to coordinate two independently-applied states. Route 53 is different again: it's a global service, so `dns/` needs only one provider.

## Status

✅ Complete. Every layer built, applied, and independently verified via AWS CLI — not just `terraform apply` exit codes. Ran a real failure-injection test: killed the primary application tier, watched Route 53 detect it in ~2 minutes across all 15 global checker locations, triggered the Aurora Global Database promotion, and verified both durability (pre-failure data survived) and writability (a fresh post-promotion instance's write succeeded). Full results in `FAILOVER_TEST.md`. Full writeup of the build — architecture decisions and every real bug hit along the way — in `POSTMORTEM.md`.

## Cost discipline

Every layer here is built to be applied, verified, and torn down in the same working session — Aurora Global Database and ALBs are never free-tier. See teardown verification approach: re-run `plan` after `apply`/`destroy` to confirm zero drift, cross-checked against AWS CLI, not just a green Terraform exit code.
