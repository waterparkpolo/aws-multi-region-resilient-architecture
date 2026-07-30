# Postmortem — Multi-Region Resilient Architecture

## Summary

Built and tested a Warm Standby disaster recovery architecture across `us-east-1` (primary) and `us-west-2` (secondary): VPC, ALB/ASG, Aurora Global Database, and Route 53 failover routing. Ran a real failure-injection test — killed the primary application tier, watched Route 53 detect it and Aurora promote the secondary, and verified the promoted database was both durable (old data survived) and writable (new writes succeeded). See `FAILOVER_TEST.md` for the full timeline and evidence.

This document covers the architecture decisions and everything that went wrong along the way, since the debugging is where most of the actual learning happened.

## Architecture decisions and why

**Independent root configs per region for VPC/ALB, single root with dual providers for the database.** VPC and ALB/ASG resources in one region have zero coupling with the other — independent state, independent blast radius. Aurora Global Database is different: it's one logical resource spanning two regions with a strict creation-order dependency (the secondary can't join until the global cluster and primary exist). Terraform can't express that ordering across two independently-applied states, so the database layer uses one root with two provider aliases instead, letting Terraform's own dependency graph enforce the order.

**`terraform_remote_state` for consuming outputs, never for coordinating creation order.** Used to read VPC/subnet/security-group outputs into the database layer, and to read the database's secret ARNs into each region's app tier. Rejected for the database's own internal primary/secondary relationship, because that coupling needs to be created together, not read independently by two separately-applied configs.

**A Secrets Manager secret per region, not one shared secret.** A single secret hardcoded to the primary's endpoint would have sent `us-west-2` instances back to `us-east-1` during normal operation. Each region's app tier reads its own region's secret, containing that region's own cluster endpoint — which is what makes the "no app config change at failover" property actually true: the endpoint address never changes, only its write capability does, after promotion.

**A private Route 53 hosted zone, not a public one.** Avoided touching an unrelated production domain (a client's live site) and avoided a registration cost. Tradeoff: DNS only resolves inside the associated VPCs, so verifying it required SSM Session Manager rather than a browser. The health check itself targets the ALB's real public DNS name directly, independent of the private zone — Route 53's health checkers run outside any VPC and can't resolve private records, but the ALB is genuinely internet-facing regardless of what zone sits in front of it.

**Failure injected by scaling the primary ASG to zero, not by killing the database.** The app's page is a static file generated once at boot — it never re-checks DB connectivity per request, so a database-only failure would never trip the ALB health check. Also rejected plain instance termination, since the ASG would just relaunch replacements with no sustained outage.

## What went wrong, in the order it happened

1. **Missing module arguments.** First `terraform validate` on the region root caught four missing required arguments — a real error, fixed by reading the module's `variables.tf`.
2. **IMDSv1 in the user data script.** An unauthenticated metadata curl that would've silently gone blank if the account ever enforced IMDSv2. Fixed once, regressed once under time pressure, fixed again.
3. **Missing root-level outputs.** Neither region root exposed anything from its own module calls, which blocked the database layer's remote-state reads until added.
4. **Three sequential Aurora Global Database API errors**, each only discoverable by actually trying to apply: `storage_encrypted` mismatch between the global cluster and its primary member (forced a replace), `manage_master_user_password` unsupported for global databases at all (fell back to `random_password` + a manual Secrets Manager secret), and an unsupported burstable instance class plus a missing explicit KMS key for the cross-region encrypted replica.
5. **A bidirectional bootstrap dependency.** The app tier needed the database's secret ARN; the database layer needed the app tier's network/security-group outputs. Neither could apply first. Fixed by making the secret ARN variable optional with a `null` default and conditionally creating the IAM policy, so the app tier could bootstrap without the database, then get wired in on a second pass once the database existed.
6. **A silent write failure during the first scale-up.** Two secondary instances booted before the Aurora promotion had actually finished, attempted their `INSERT` against a still-read-only replica, and failed — with no error-checking in the script, the page just showed replicated historical data with no indication anything had gone wrong. Caught by deliberately forcing a fresh, post-promotion instance boot and confirming its write succeeded.
7. **The teardown after the failover test hung for ~40 minutes with zero CPU usage and zero new AWS-side events.** Root cause: Terraform's destroy order is based on the *declared* `depends_on` in the code, which said "destroy the secondary's resources before the primary's." That was true when secondary really was the secondary. But the failover test had *actually promoted* the secondary to be the real master — a fact Terraform has no way of knowing, because it happened through an AWS API call outside Terraform's control. Terraform tried to delete the actual master's last instance first; AWS correctly refused (`InvalidDBClusterStateFault`). Recovered by killing the hung process and finishing the deletion manually in the correct real-world order (detach both clusters from the global database, delete whichever is currently the replica first, delete the master last, then delete the global cluster wrapper), then reconciling Terraform state with `terraform state rm`.
8. **Destroying the database layer before the regions broke the regions' own destroy plan.** The region configs still referenced the database layer's outputs via remote state; once the database's state was empty, that reference had nothing to resolve, and `terraform destroy` on the regions failed before it could even build a plan. Fixed by temporarily pointing the reference at `null` (since everything was being deleted anyway) and restoring the real code afterward.

## The core lesson

Points 6, 7, and 8 are all the same underlying idea wearing different clothes: **Terraform's model of the world is the declared configuration, not the live state of infrastructure that can change through means outside Terraform's control** — a real failover, a manually-triggered promotion, an out-of-band AWS API call. The moment live reality and declared configuration diverge, Terraform's automatic reasoning (dependency ordering, destroy sequencing) can actively work against you instead of for you. Recognizing that divergence — rather than assuming Terraform will always "just handle it" — is the actual skill this project was built to practice.

## What I'd do differently in production

- Add error-checking to the boot script's database write, with a retry or an explicit health signal, instead of silently continuing to the read on failure.
- Reconsider the `depends_on` between the primary and secondary Aurora clusters given it actively worked against a clean teardown after a real promotion — possibly detect current role at destroy time rather than assuming the declared roles still hold.
- Wire the ALB/ASG's own health check to actually verify DB connectivity per request (not just serve a static file), so a database-only failure would be detected too, not just an application-tier outage.
