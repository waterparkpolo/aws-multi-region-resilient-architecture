# Failover Test — Results

**Date:** 2026-07-30
**Architecture:** Warm Standby, `us-east-1` (primary) → `us-west-2` (secondary)

## What this test proves

1. Route 53 detects a real primary-region outage automatically, without manual intervention.
2. Aurora Global Database can be promoted from a warm secondary to a fully writable primary.
3. Data written before the failure survives the promotion (durability).
4. The promoted cluster genuinely accepts new writes afterward (writability) — not just reachable, actually functioning as the new primary.
5. The application requires zero configuration changes at failover time, because each region's app tier was always pointed at its own region's Aurora cluster endpoint — promotion changes what that endpoint can do, not its address.

## Method

- **Failure injected**: primary ASG (`project5-use1-primary-asg`) scaled to `min-size=0, desired-capacity=0` via AWS CLI — chosen over simulating a database failure because the app tier's static page doesn't re-check DB connectivity per request, so a DB-only failure would never trip the ALB health check. Chosen over simply terminating instances because the ASG would just relaunch replacements, producing no sustained outage.
- **Baseline** captured before injection: 2 existing rows in the `visits` table, health check healthy, `us-east-1` confirmed as global cluster writer.

## Timeline

| Time (UTC) | Event |
|---|---|
| 18:09:39 | Primary ASG scaled to 0 — failure injected |
| ~18:09:40 | ALB confirmed returning `503 Service Unavailable` (direct curl) |
| ~18:11:30 | Route 53 health check flips to `Failure` across all 15 global checker locations |
| 18:12:26 | Aurora Global Database failover triggered (`aws rds failover-global-cluster`) |
| 18:12:43 | Secondary ASG scaled 1→3 (`aws autoscaling update-auto-scaling-group`) |
| 18:13:07 | Old primary DB cluster gracefully shut down (managed switchover in progress) |
| ~18:17:00 | Global cluster promotion completes — `us-west-2` cluster now `IsWriter: true` |
| 18:16:38 | First verified post-promotion write from a freshly-booted secondary instance |

**Total time from failure injection to a verified, fully-functional promoted database: ~8 minutes.**

## Key verification evidence

**Route 53 health check, post-failure (all 15 global checker locations agree):**
```
Failure: HTTP Status Code 503, Service Temporarily Unavailable.
```

**Global cluster roles, before and after:**
```
Before:  acme-resilient-primary (us-east-1)   IsWriter: True
         acme-resilient-secondary (us-west-2)  IsWriter: False

After:   acme-resilient-primary (us-east-1)   IsWriter: False
         acme-resilient-secondary (us-west-2)  IsWriter: True
```

**Final page load from the secondary ALB, post-promotion** — the row from `i-07e5dee9baa32e706` was written *after* promotion completed; the three `us-east-1` rows were written *before* the failure:
```
Instance ID: i-07e5dee9baa32e706
Recent database writes:
  us-west-2 | i-07e5dee9baa32e706 | 2026-07-30 18:16:38
  us-east-1 | i-0fd48152de6f34504 | 2026-07-30 17:31:23
  us-east-1 | i-03b339117c3f22837 | 2026-07-30 17:26:08
  us-east-1 | i-084bdb3eb20513d71 | 2026-07-30 17:20:53
```

## A real bug found during this test

The app's boot script has no error-checking on its `mysql` write. Two secondary instances launched during the initial scale-up booted *before* the Aurora promotion finished, attempted their `INSERT` against a still-read-only replica, and failed silently — the script has no verification that its own write actually succeeded, so the page just showed replicated historical data with no indication anything had gone wrong. This was caught by terminating one instance to force a fresh, post-promotion boot, whose write did succeed. A production version of this script would need to check the `mysql` command's exit code and retry or surface the failure rather than silently continuing to the read.
