# DevOps, IaC, CI/CD, Observability, Reliability and Cost Control for Production AI Apps on Google Cloud (learning resources + production facts, as of 2026-11-06)

Notes for the report writer:
- Research date: 2026-11-06. All facts below come from pages fetched or searched on this date.
- Google moved its docs. `cloud.google.com/<product>/docs/...` now returns HTTP 301 to `docs.cloud.google.com/<product>/docs/...` (seen on the Terraform best-practices page and the Cloud Deploy canary page). Use `docs.cloud.google.com` links in the final report.
- **Big naming change in 2026:** Vertex AI is now called **Gemini Enterprise Agent Platform** ("Agent Platform"). Google's own docs now use the new name, for example the context-caching page says "Gemini Enterprise Agent Platform offers two types of caching" — [Agent Platform context cache overview](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview). Google's Next '26 blog calls Agent Platform "the evolution of Vertex AI" — [Google Cloud blog, 2026-04-22](https://cloud.google.com/blog/topics/cost-management/introducing-spend-caps-ai-cost-visibility-next26/). Courses and videos made before April 2026 still say "Vertex AI". URLs still contain `/vertex-ai/`.
- Learner profile used for the "fit" column: Vietnamese AI engineer. Strong in Docker, Kubernetes (RKE2, Rancher), Helm, ArgoCD GitOps, Prometheus + Grafana and Langfuse. Zero GCP. The reference project deploys several Cloud Run services from GitLab (pinned commits), has dev and uat environments, stores job step timings in Firestore and records AI fees per claim.

---

## Q1. CI/CD: Cloud Build, Artifact Registry, Cloud Deploy (Cloud Run targets, canary), GitLab CI to Cloud Run with Workload Identity Federation, Python container images, separate dev/uat/prod projects

### Takeaway
For a GitLab-based team, the keyless path is: GitLab OIDC token → Workload Identity Federation (WIF) → Artifact Registry push → deploy to Cloud Run. You can deploy with `gcloud run deploy` directly, or with a Cloud Deploy delivery pipeline (dev → uat → prod). Cloud Deploy adds promotion, approvals and canary. Its first active multi-target pipeline per billing account is free, and each extra one costs $5/month. Container Registry and Cloud Source Repositories are gone or end-of-sale, so skip any lesson built on them.

### Cited Findings

**GitLab → Google Cloud keyless auth (WIF)**
- GitLab's own "Google Cloud Workload Identity Federation and IAM policies" integration works on all tiers (Free, Premium, Ultimate) but only on **GitLab.com**. Self-managed is not listed. It was introduced in GitLab 16.10 behind a feature flag and enabled on GitLab.com in 17.1 — [GitLab Docs: Google Cloud IAM integration](https://docs.gitlab.com/integration/google_cloud_iam/)
- In that GitLab integration, the OIDC issuer URI must include the top-level group, e.g. `https://auth.gcp.gitlab.com/oidc/my-root-group`. Attribute mappings include `project_id`, `project_path`, `namespace_id`, `namespace_path`, `user_email`, the access-level flags (`developer_access`, `maintainer_access` ...) and `google.subject=assertion.sub`. The CI keyword is `identity: google_cloud` — [GitLab Docs: Google Cloud IAM integration](https://docs.gitlab.com/integration/google_cloud_iam/)
- GitLab's example grants roles to a principal set like `principalSet://iam.googleapis.com/projects/<PROJECT_NUMBER>/locations/global/workloadIdentityPools/<POOL_ID>/attribute.my_project_maintainer/true`. It uses the CEL condition `assertion.maintainer_access=="true" && assertion.project_path=="gitlab-org/my-project"` and grants `roles/artifactregistry.writer` — [GitLab Docs: Google Cloud IAM integration](https://docs.gitlab.com/integration/google_cloud_iam/)
- Google's generic guide (works without the GitLab integration and uses plain `id_tokens`) says:
  - For GitLab SaaS the issuer is `https://gitlab.com`.
  - Recommended mapping is `google.subject=assertion.sub`. The `sub` claim holds the project path and the git ref, so you can limit access by repo and branch.
  - Available claims include `namespace_id`, `project_id`, `user_id`, `environment` and `ref_path`.
  
  — [Google Cloud IAM: WIF with deployment pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)
- **Security warning (important interview point):** GitLab SaaS uses a single issuer URL across all organizations, so you **must** add an attribute condition such as `assertion.namespace_id=='GROUP_ID'`. You can narrow it further with `&& assertion.environment=='production'`. Without it, other GitLab.com users could spoof access. Google also says not to grant basic roles like Owner in production — [Google Cloud IAM: WIF with deployment pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)
- **Two access models.** Google recommends **direct resource access**, where you grant roles to the `principal://...` federated identity. Use **service account impersonation** only for APIs with federation limits. Impersonation needs `roles/iam.workloadIdentityUser` on the service account. Member identifiers use the project **number**, not the project ID — [Google Cloud IAM: WIF with deployment pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)
- `.gitlab-ci.yml` pattern from Google:
  - `id_tokens: WORKLOAD_IDENTITY_TOKEN: aud: https://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID`
  - The script writes the JWT to a file, then builds an `external_account` credential file and points `GOOGLE_APPLICATION_CREDENTIALS` at it.
  - Note that the `aud` uses `https://iam.googleapis.com/...` while the credential file `audience` uses `//iam.googleapis.com/...`.
  
  — [Google Cloud IAM: WIF with deployment pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)
- GitLab's Cloud Run component tutorial:
  - Grants `roles/run.admin` and `roles/iam.serviceAccountUser` to the workload identity pool principals.
  - Pipeline: build image → push to GitLab registry → copy to Google Artifact Registry → deploy to Cloud Run.
  - It warns not to re-run the setup script if a pool already exists.
  
  — [GitLab tutorial: Cloud Run component](https://docs.gitlab.com/tutorials/create_and_deploy_web_service_with_google_cloud_run_component/). Background: [GitLab blog, 2025-01-15](https://about.gitlab.com/blog/google-cloud-integrations-for-secure-cloud-run-deployments-at-gitlab)
- A separate GitLab **Cloud Deploy** component is marked Beta, needs a feature flag and needs `roles/clouddeploy.releaser` on the pool. This comes from a search snippet of the component repo, so the current status is unverified — [gitlab.com google-gitlab-components/cloud-deploy](https://gitlab.com/google-gitlab-components/cloud-deploy/-/tree/9e4fd587e8c8f79eb9deccb508afe9a68e352627)

**Cloud Build ↔ GitLab**
- Cloud Build connects to GitLab through **2nd gen repositories**. You first create a host connection, then link repositories (console "Link repository", or `gcloud builds repositories create --remote-uri ... --connection ... --region ...`). This needs the Cloud Build and Secret Manager APIs — [Cloud Build: connect GitLab repo](https://docs.cloud.google.com/build/docs/automating-builds/gitlab/connect-repo-gitlab)

**Cloud Deploy with Cloud Run targets**
- Files you need:
  - `skaffold.yaml` with profiles (e.g. `dev`, `prod`), each pointing to a Cloud Run service manifest, and `deploy: cloudrun: {}`.
  - `clouddeploy.yaml` with `serialPipeline.stages[].targetId` plus `profiles`.
  - Targets with `run: location: projects/PROJECT_ID/locations/REGION`.
  - Register everything with `gcloud deploy apply`.
  
  — [Cloud Deploy: deploy to Cloud Run](https://docs.cloud.google.com/deploy/docs/deploy-app-run)
- `gcloud deploy releases create --images my-app-image=<image>` swaps the placeholder. Google **recommends a SHA-qualified (digest) image**. The first rollout to the first target starts automatically unless you pass `--disable-initial-rollout`. Then you **Promote** to the next target. The page also notes that two targets can share one project through Skaffold profiles, and that separate projects may not need profiles — [Cloud Deploy: deploy to Cloud Run](https://docs.cloud.google.com/deploy/docs/deploy-app-run)
- **Canary on Cloud Run** (Cloud Deploy):
  - Supported for services and worker pools, **not jobs**. Cloud Run itself splits traffic by the percentages you set.
  - Three modes: automated (you list the percentages), custom-automated, and custom.
  - Phases are auto-named (25/50/75 → `canary-25`, `canary-50`, `canary-75`, then `stable`).
  - Each phase can run a verify job and **deploy analysis** (Google Cloud Observability metrics or a custom metrics provider). An `advanceRolloutRule` automation can promote automatically.
  - **A 100% canary is not allowed for Cloud Run.**
  
  — [Cloud Deploy: canary strategy](https://docs.cloud.google.com/deploy/docs/deployment-strategies/canary)
- **Cloud Deploy pricing:** "First active multiple-target delivery pipeline (per billing account): No charge. Each additional active multiple-target delivery pipeline $5.00". A pipeline is "active" if at least one release or rollout was created that billing month — [Cloud Deploy pricing](https://cloud.google.com/deploy/pricing) (read from the raw page HTML)

**Cloud Run native revisions and traffic (no Cloud Deploy)**
- Deploy without traffic: `gcloud run deploy --image IMAGE --no-traffic`.
- Shift traffic: `gcloud run services update-traffic SERVICE --to-revisions REVISION=PERCENTAGE` (or `LATEST=5`).
- Tagged test URL: `--tag green` gives `https://green---myservice-abcdef.a.run.app`.
- Rollback: `--to-revisions OLD=100`. Rollback "updates the routing configuration immediately" and does **not** re-run health checks.
- Traffic splits persist into later deploys until you send traffic `--to-latest`.
- Tags with revision-level min instances do allocate min instances, so remove tags you no longer need to avoid extra billing.

— [Cloud Run: rollouts, rollbacks, traffic migration](https://docs.cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration)

**Artifact Registry and outdated registries**
- Container Registry was deprecated on 2023-05-15. Writes were blocked from **2025-03-18** and reads from **2025-06-03**. `gcr.io` URLs that are hosted on Artifact Registry are not affected. There is an automatic migration tool — [GKE: transition from Container Registry](https://docs.cloud.google.com/kubernetes-engine/docs/deprecations/container-registry); [Artifact Registry: prepare for GCR shutdown](https://docs.cloud.google.com/artifact-registry/docs/transition/prepare-gcr-shutdown)
- Artifact Registry **cleanup policies**:
  - Delete and keep policies. Conditions: `tagState`, `tagPrefixes`, `versionNamePrefixes`, `packageNamePrefixes`, `olderThan`/`newerThan` (e.g. `30d`) and `mostRecentVersions`.
  - Keep wins over delete.
  - Dry run: `gcloud artifacts repositories set-cleanup-policies ... --dry-run`. Results show in Data Access audit logs.
  - Policies run in a background job, and "changes take effect within approximately one day".
  - Works only on standard repositories.
  
  — [Artifact Registry: cleanup policies](https://docs.cloud.google.com/artifact-registry/docs/repositories/cleanup-policy)
- **Cloud Source Repositories** reached end-of-sale on **2024-06-17**. Projects that enabled it earlier keep access. Google will announce the shutdown date at least one year ahead. Google suggests Secure Source Manager or a third-party Git host — [CSR migration guides](https://docs.cloud.google.com/source-repositories/docs/migration-guides); [Google Dev forum thread quoting the banner](https://discuss.google.dev/t/cloud-source-repositories-will-be-discontinued/154676)

**Python container images (uv, slim, multi-stage)**
- uv in Docker:
  - Pin the binary: `COPY --from=ghcr.io/astral-sh/uv:0.13.7 /uv /uvx /bin/`. Pin a SHA256 digest for reproducible builds, because tags can move.
  - Add `.venv` to `.dockerignore`.
  - Layer caching: `RUN --mount=type=cache,target=/root/.cache/uv --mount=type=bind,source=uv.lock,target=uv.lock uv sync --frozen --no-install-project`, then `COPY . /app` and `uv sync --locked`.
  - Env vars: `UV_COMPILE_BYTECODE=1`, `UV_LINK_MODE=copy`, `UV_NO_DEV=1`.
  - Multi-stage: the builder runs `uv sync --locked --no-editable`. The final image copies only `/app/.venv` and sets `PATH="/app/.venv/bin:$PATH"`.
  
  — [uv docs: Using uv in Docker](https://docs.astral.sh/uv/guides/integration/docker/)
- Google's Python-on-Cloud-Run tips:
  - Use a "slimline base image". `python:slim` may lack build tools for wheels. Alpine has wheel-compatibility issues. Distroless is an option.
  - Starting command: `gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app`. Tune workers to the number of cores.
  - Set custom startup probes, because Gunicorn listens before the app loads. Consider `--preload`.
  - Import heavy modules lazily.
  - Set `PYTHONUNBUFFERED`.
  - For Uvicorn the page only shows `uvicorn --port $PORT --host 0.0.0.0 main:app`.
  
  — [Cloud Run: Python tips](https://docs.cloud.google.com/run/docs/tips/python)

**Environment separation**
- Google's Terraform root-module guide recommends `environments/dev`, `environments/qa`, `environments/prod` directories, each with its own `backend.tf` and `main.tf`, and "use only the default workspace" — [Terraform best practices: root modules](https://docs.cloud.google.com/docs/terraform/best-practices/root-modules)
- The enterprise foundation example creates `development`, `nonproduction` and `production` environments (folders and projects), plus a `shared` environment — [terraform-example-foundation](https://github.com/terraform-google-modules/terraform-example-foundation)

### Inferences
- For the reference project (GitLab, several Cloud Run services, dev + uat), the cleanest pattern is:
  1. One GCP project per environment (`*-dev`, `*-uat`, later `*-prod`).
  2. One WIF pool per project (or a central one), with the attribute condition pinned to the GitLab group and, optionally, `environment`/`ref_path`.
  3. Build once and push to Artifact Registry tagged with the git commit SHA.
  4. Deploy by **digest**, so the "pinned commit" maps 1:1 to an immutable image.
  
  This follows from the WIF guide, the Cloud Deploy digest recommendation and the root-module env-directory advice.
- If the team wants ArgoCD-like promotion and audit history, use Cloud Deploy, with one delivery pipeline per service and targets dev → uat → prod. Cost is near zero for a small team: the first multi-target pipeline is free and the rest are $5/month each. If they only need "deploy this SHA to this env", plain `gcloud run deploy --image ...@sha256:...` from GitLab CI plus `--no-traffic`/`--tag` for smoke tests is simpler.
- The GitLab-native "Google Cloud IAM" integration is GitLab.com only. A **self-managed GitLab** must use the generic Google WIF guide, with the issuer set to the self-managed instance URL. That issuer value is not shown on the Google page; see Gaps.

### Gaps
- The Google WIF page covers only GitLab SaaS. I found no Google page with the exact issuer and attribute recommendations for **self-managed GitLab**.
- The current Beta/GA status of GitLab's Cloud Deploy component was not verified. The source is a search snippet.
- The Cloud Build GitLab page I fetched does not list token scopes, webhook setup or GitLab.com vs GitLab Enterprise differences. Those are on the linked "connect a GitLab host" page, which I did not fetch.
- Cloud Deploy approvals (`requireApproval`), rollback and deploy parameters were not on the fetched pages.

---

## Q2. Infrastructure as code: Terraform on Google Cloud (best-practices doc, GCS state, Cloud Foundation Fabric, terraform-google-modules, project factory, enterprise foundations blueprint, Infrastructure Manager). Best long course or book in 2026?

### Takeaway
The best long, free and current material is Google's multi-page "Best practices for using Terraform" doc set plus two real codebases: Cloud Foundation Fabric (modules + FAST + project factory) and terraform-example-foundation (the enterprise foundations blueprint code). The Skills Boost course "Getting Started with Terraform for Google Cloud" (6.5 h) is a good first hands-on step. I found **no** GCP-specific Terraform book newer than Packt's January 2023 "Terraform for Google Cloud Essential Guide". Deployment Manager reached end of support on 2026-03-31, so skip it.

### Cited Findings

**Google's Terraform best-practices series**
- General style and structure:
  - Every module starts with `main.tf`, has a `README.md` and an `examples/` folder, and groups resources into descriptive files (`network.tf`).
  - Naming: underscores in names, name a single resource `main`, use singular names.
  - Variables live in `variables.tf`, each with a type and description. Put units in names (`ram_size_gb`). Don't default environment-specific variables like `project_id`.
  - Outputs live in `outputs.tf` and should reference resource attributes.
  - Protect stateful resources with `lifecycle { prevent_destroy = true }`.
  - Use `for_each` for copies. Keep custom scripts to a minimum.
  - Run `terraform fmt`. Publish modules to a registry.
  
  — [Terraform best practices: general style and structure](https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure)
- Root modules:
  - "Don't include more than 100 resources (and ideally only a few dozen) in a single state."
  - Layout: `SERVICE-DIRECTORY/modules/<service>/` + `environments/{dev,qa,prod}/{backend.tf,main.tf}`. "Use only the default workspace."
  - Declare each provider and pin to a **minor** version in `versions.tf`.
  - Supply variables via `terraform.tfvars`, not `-var`/`-var-file`.
  - Commit `.terraform.lock.hcl` to source control.
  - Other configs can only reference root-module-level outputs.
  
  — [Terraform best practices: root modules](https://docs.cloud.google.com/docs/terraform/best-practices/root-modules)
- Other series pages linked: reusable modules — [Terraform best practices: reusable modules](https://docs.cloud.google.com/docs/terraform/best-practices/reusable-modules) (linked, not fetched)

**State in GCS**
- Backend is `terraform { backend "gcs" { bucket = "..." } }`. Move local state with `terraform init -migrate-state`.
- The example bucket enables **object versioning** (with lifecycle rules to delete old versions), `force_destroy = false`, `public_access_prevention = "enforced"`, `uniform_bucket_level_access = true` and a `random_id` suffix.
- Only a small set of admins (main plus backup) should have bucket admin. Other developers only read and write objects.

— [Store Terraform state in Cloud Storage](https://docs.cloud.google.com/docs/terraform/resource-management/store-state)

**Cloud Foundation Fabric**
- Described as "End-to-end modular samples and landing zones toolkit for Terraform on GCP".
- Folders:
  - `modules`: kept close to provider resources and easy to fork.
  - `fast`: an org-wide landing-zone toolkit "used to bootstrap real-world cloud foundations".
  - `blueprints`.
- Includes a **project factory** (`modules/project-factory/README.md`).
- About 2.1k stars and 7,239 commits when fetched. Ships both `default-versions.tf` and `default-versions.tofu` (OpenTofu).

— [GitHub: GoogleCloudPlatform/cloud-foundation-fabric](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric)

**Enterprise foundations blueprint code (terraform-example-foundation)**
- Shows "how the CFT modules can be composed to build a secure cloud foundation".
- Stages:
  - `0-bootstrap`: seed + CI/CD projects.
  - `1-org`: logging, SCC, KMS, secrets, shared VPC hosts.
  - `2-environments`.
  - `3-networks-svpc` / `3-networks-hub-and-spoke`.
  - `4-projects`.
  - `5-app-infra`.
- Environments: `development`, `nonproduction`, `production`.
- Uses Cloud Build by default. It follows the "Google Cloud Enterprise Foundations Blueprint (previously called the Security Foundations Guide)".

— [GitHub: terraform-google-modules/terraform-example-foundation](https://github.com/terraform-google-modules/terraform-example-foundation)

**Infrastructure Manager (Infra Manager)**
- A managed service that runs Terraform "blueprints".
- Each deployment starts a **Cloud Build** job that runs `terraform init`, `validate`, then `apply`/`destroy`. Logs stream to a bucket.
- It stores state, config and resource list per revision.
- Sources: GCS, Git or a local directory. Supports preview deployments.
- It does **not** manage application deployment; Google points to Cloud Build or Cloud Deploy for that.

— [Infrastructure Manager overview](https://docs.cloud.google.com/infrastructure-manager/docs/overview)

**Deployment Manager (outdated)**
- Cloud Deployment Manager reached **end of support on 2026-03-31**. Google says to move to Infrastructure Manager. DM Convert can turn DM configs into Terraform, but not all concepts convert. Existing resources keep running but can't be managed with DM — [Deployment Manager deprecations](https://docs.cloud.google.com/deployment-manager/docs/deprecations)

**Courses and books**
- Skills Boost course "Getting Started with Terraform for Google Cloud":
  - Length 6 h 30 min, cost 16 credits, introductory level.
  - Covers resources, variables, outputs, state stored in a Cloud Storage bucket, and modules.
  - Prerequisite: Google Cloud Fundamentals: Core Infrastructure.
  
  — [Skills Boost course_templates/443](https://www.cloudskillsboost.google/course_templates/443); details from [Class Central listing](https://classcentral.com/course/getting-started-with-terraform-for-google-cloud-199788)
- Global Knowledge sells the same course as a paid instructor-led class, GO8335. Its outline adds Terraform Registry and Cloud Foundation Toolkit modules — [Global Knowledge GO8335](https://www.globalknowledge.com/en-us/courses/google/cloud_computing/go8335)
- Book: "Terraform for Google Cloud Essential Guide" by Bernd Nordhausen (Packt), January 2023, 180 pages, beginner to intermediate. Covers auth, modules, multiple environments and Google Cloud tooling. Some retailers list a 2022 copyright — [O'Reilly listing](https://oreilly.com/library/view/terraform-for-google/9781804619629)
- "Terraform: Up & Running" (Brikman), 3rd ed. 2022, is general Terraform, not GCP-specific. No 2025–2026 GCP-specific Terraform book was found at Packt or O'Reilly — [O'Reilly search results summary](https://www.oreilly.com/library/view/-/9781804619629/)
- Real-world module to study: `langfuse/langfuse-terraform-gcp` builds GKE, a VPC, Cloud SQL Postgres 16 (Enterprise Plus, regional HA), Memorystore Redis (1 GB STANDARD_HA), a GCS bucket, in-cluster ClickHouse (3 replicas), GKE Ingress, a managed cert and Cloud DNS. Only `domain` is required. It needs Terraform ≥ 1.3, google ≥ 5.0, and a two-stage apply — [GitHub: langfuse-terraform-gcp](https://github.com/langfuse/langfuse-terraform-gcp)

### Inferences
- "Best long course for Terraform on GCP in 2026" has no single answer. The strongest path is to:
  1. Take the 6.5 h Skills Boost course for the basics and GCS state.
  2. Read the whole Google best-practices series.
  3. Study Fabric's `modules/` + `project-factory` and the foundation repo's stage layout.
  
  The Packt book is dated (2023) but still useful for structure. The learner's Helm-values-per-env habit maps directly to `environments/{dev,uat,prod}` root modules.
- For a small AI team with a few Cloud Run services, the full enterprise blueprint (6 stages, org-level folders) is likely more than they need. Fabric's project factory plus a simple per-env root module is closer to their size. This is an inference from the repo scopes.

### Gaps
- The GCS state page I fetched does not mention **state locking**. I could not confirm the locking behavior from a fetched Google source.
- I could not get the latest release versions or dates for Fabric or terraform-example-foundation; the Releases sections were empty in the fetch.
- The full page list of the best-practices series (dependency management, security, testing, operations, version control ...) was not visible in the fetched content.
- Infra Manager pricing and supported Terraform versions were not on the overview page.
- The terraform-google-modules project-factory module (`terraform-google-project-factory`) was not fetched.

---

## Q3. Observability: Cloud Logging, Cloud Monitoring (uptime, SLOs, alerting), Cloud Trace + OpenTelemetry for Python/FastAPI, Error Reporting, Cloud Profiler, LLM call observability (tokens, latency, cost), Agent Platform request-response logging, Langfuse on GCP

### Takeaway
On Cloud Run, write **one-line JSON to stdout**. Cloud Logging parses it into `jsonPayload`, uses `severity`/`message`, and links logs to traces through `logging.googleapis.com/trace`. Use OpenTelemetry (OTLP, ideally through a Collector) for traces, the Managed Service for Prometheus sidecar if you want to keep Prometheus `/metrics`, and Cloud Monitoring SLOs with burn-rate alerts. For LLM calls, combine three things:
- per-request token logging from `usageMetadata` into BigQuery or log-based metrics,
- the built-in `token_count` metric,
- optional sampled request-response logging to BigQuery.

Langfuse can still run self-hosted on GCP through its official Terraform module.

### Cited Findings

**Cloud Logging on Cloud Run**
- Cloud Run collects `stdout`/`stderr`, `/var/log` files, syslog, and client-library logs.
- One line of JSON becomes `jsonPayload`. `severity` maps to the LogEntry severity and `message` becomes the display text.
- Stdout logs **don't count** against the `entries.write` per-minute quota. Exceptions in logs appear in **Error Reporting**.
- Trace correlation: read the `X-Cloud-Trace-Context` header and write `logging.googleapis.com/trace = projects/PROJECT_ID/traces/TRACE_ID`. The Python example uses `print(json.dumps(entry))`.

— [Cloud Run: logging](https://docs.cloud.google.com/run/docs/logging)
- Retention and limits:
  - `_Required` bucket: 400 days, not configurable.
  - `_Default` bucket: 30 days, configurable 1–3650 days in projects.
  - Max `LogEntry` 256 KiB; 64 labels per entry; max `entries.write` request 10 MB.
  
  — [Cloud Logging quotas and limits](https://docs.cloud.google.com/logging/quotas)
- Routing (sinks):
  - Destinations: another project (one hop), log bucket (with "Observability Analytics" and a read-only linked BigQuery dataset), a BigQuery dataset (one table per log name), Cloud Storage (JSON files) and Pub/Sub (e.g. Splunk, Datadog).
  - Each sink has one inclusion filter and many exclusion filters. Exclusions do **not** reduce `entries.write` quota.
  - You can't modify or delete the `_Required` sink.
  
  — [Cloud Logging routing overview](https://docs.cloud.google.com/logging/docs/routing/overview)
- Log-based metrics:
  - Types: counter, distribution (histogram, e.g. latency) and boolean.
  - User-defined metrics count **both included and excluded** logs.
  - Data comes only from entries received **after** the metric is created (no backfill).
  - They are chargeable custom metrics and can drive alerting policies. Set missing-data handling for counters.
  
  — [Log-based metrics overview](https://docs.cloud.google.com/logging/docs/logs-based-metrics)

**Pricing (read from the raw Google Cloud Observability pricing page HTML)**
- Logging storage: **$0.50/GiB**, one-time, with the "first 50 GiB/project/month" free. Includes up to 30 days of storage, and querying is free.
- Retention: **$0.01 per GiB per month** beyond 30 days. No charge for logs in `_Required`. Log Router and Log Analytics have "no additional charge".
- Monitoring:
  - Data ingested by bytes: **$0.2580/MiB** for 150–100,000 MiB, $0.1510/MiB for 100k–250k, $0.0610/MiB above 250k. The first 150 MiB per billing account is free.
  - Managed Service for Prometheus: **$0.06/million samples** for the first 50 billion.
- Cloud Trace: **$0.20/million spans**, with the "first 2.5 million spans per billing account" free.

— [Google Cloud Observability pricing](https://cloud.google.com/stackdriver/pricing)

**Cloud Monitoring SLOs and alerting**
- SLI types:
  - Request-based: good requests / total requests.
  - Windows-based: needed for latency percentiles.
- SLI meanings: availability = successful / all responses; latency = calls under a threshold / all calls.
- Compliance periods: calendar, or rolling **1–30 days**.
- Auto-detected service types are only Cloud Service Mesh, Istio on GKE and App Engine. **Cloud Run is not listed**, so define a custom service.

— [SLO monitoring overview](https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring)
- Burn-rate alerting uses the `select_slo_burn_rate` selector and a lookback of at most 24 h. Google suggests:
  - fast-burn: start at **10x baseline** with a 1–2 h lookback,
  - slow-burn: start at **2x baseline** with a 24 h lookback,
  - and running both.
  
  — [Alerting on budget burn rate](https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate)

**OpenTelemetry for Python**
- Google recommends exporting through an **OpenTelemetry Collector** "when your environment supports" it. Otherwise use an in-process OTLP exporter.
- The sample uses `OTLPSpanExporter`/`OTLPLogExporter`/`OTLPMetricExporter`, `python-json-logger`, `opentelemetry-instrumentation-logging`, `-flask` and `-requests`.
- Log fields written: `logging.googleapis.com/trace`, `logging.googleapis.com/spanId`, `logging.googleapis.com/trace_sampled`.
- Sample repo: `GoogleCloudPlatform/opentelemetry-samples` → `python/instrumentation-quickstart`. It is **Flask-based**, not FastAPI.

— [Cloud Trace: Python OpenTelemetry instrumentation](https://docs.cloud.google.com/trace/docs/setup/python-ot); [GitHub: opentelemetry-samples](https://github.com/GoogleCloudPlatform/opentelemetry-samples)
- Google's Telemetry (OTLP) API lives at `telemetry.googleapis.com`. Google recommends a Collector or an in-process OTLP exporter (no Collector) — [Telemetry (OTLP) API overview](https://cloud.google.com/stackdriver/docs/reference/telemetry/overview)
- `opentelemetry-exporter-credential-provider-gcp` (pre-release 0.66b0) gives ADC credentials to OTel Python auto-instrumentation. It needs OTLP exporter ≥ 1.37. Its README says the endpoint "currently ... only supports OTLP traces"; this may be out of date — [PyPI: opentelemetry-exporter-credential-provider-gcp](https://pypi.org/project/opentelemetry-exporter-credential-provider-gcp/0.66b0/)
- Community FastAPI + Cloud Run + OTel samples (not official): [mfkessai/opentelemetry-python-sample-app](https://github.com/mfkessai/opentelemetry-python-sample-app); [Zenn: FastAPI OTel to Cloud Trace (JP)](https://zenn.dev/taxin/articles/opentelemetry-fast-api-instrumentation-basics)

**Prometheus on Cloud Run (mapping for the learner)**
- The Managed Service for Prometheus sidecar for Cloud Run:
  - Scrapes port 8080 `/metrics` every 30 s by default, with a start-up scrape after 10 s and a shutdown scrape.
  - Config is `RunMonitoring`, "a subset of the Kubernetes PodMonitoring resource", stored in Secret Manager.
  - Needs the annotation `run.googleapis.com/container-dependencies: {"collector":["app"]}`.
  - Query with PromQL in Metrics Explorer. Billing is per sample.
  - Google recommends instance-based billing / always-allocated CPU, because scrapes may fail when CPU is throttled.
  - If the service writes OTLP metrics, use the OpenTelemetry sidecar instead.
  
  — [Managed Service for Prometheus: Cloud Run sidecar](https://docs.cloud.google.com/stackdriver/docs/managed-prometheus/cloudrun-sidecar)

**LLM call observability**
- Agent Platform (Vertex) **request-response logging**:
  - Writes sampled Gemini requests and responses (`generateContent`/`streamGenerateContent`; also Anthropic Claude via `rawPredict`, REST only) to **BigQuery**.
  - The sampling rate is configurable (1.0 = all). The default table is `request_response_logging`.
  - Fine-tuned endpoints use `predictRequestResponseLoggingConfig`.
  - `enableOtelLogging` records extra information.
  
  — [Log requests and responses](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/multimodal/request-response-logging)
- The cached-token field in the response metadata is `cachedContentTokenCount` — [Agent Platform context cache overview](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview)
- Model-level token metric `aiplatform.googleapis.com/publisher/online_serving/token_count`, with a `type` label (input/output). Per a third-party article, Agent Runtime has no per-agent token metrics, so use Trace or Logging for that. Both sources are third-party; verify in Google's metrics list — [DZone: Monitoring AI agents](https://dzone.com/articles/monitoring-ai-agents-gemini-enterprise); [New Relic Vertex AI integration](https://docs.newrelic.com/docs/infrastructure/google-cloud-platform-integrations/gcp-integrations-list/google-vertexai-monitoring-integration/)
- A Google community answer suggests logging token counts per request and querying them in Logging or BigQuery, or creating custom metrics with alerts — [Google Dev forum](https://discuss.google.dev/t/monitor-the-usage-of-gemini-api-on-vertex-ai/171653)
- For 429 debugging, Google suggests enabling "inference request metadata logs" to see which seconds and models got 429s — [Agent Platform: error code 429](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/error-code-429)
- Traceloop OpenLLMetry `opentelemetry-instrumentation-google-generativeai` wraps Gemini calls and emits token-usage and latency metrics following the OTel GenAI conventions. This is from an aggregator listing, so the version and maintenance status are unverified — [openapps.pro listing](https://openapps.pro/packages/opentelemetry-instrumentation-google-generativeai)

**Langfuse on GCP**
- Official guide is "Self Hosting → GCP (Terraform)", using `langfuse/langfuse-terraform-gcp`. The Helm chart is the alternative — [Langfuse docs: GCP](https://langfuse.com/self-hosting/deployment/gcp)
- What the module provisions (GKE + Cloud SQL + Memorystore + GCS + ClickHouse ...): see Q2. Known issues: managed certs take about 20 min (`ERR_SSL_VERSION_OR_CIPHER_MISMATCH` until then), Postgres and ClickHouse must both use UTC, and it is not a migration path from v3 Bitnami installs — [GitHub: langfuse-terraform-gcp](https://github.com/langfuse/langfuse-terraform-gcp)

**Error Reporting and Profiler**
- Exceptions written to Cloud Run logs are reported in Error Reporting — [Cloud Run: logging](https://docs.cloud.google.com/run/docs/logging)
- The Cloud Profiler Python docs list Compute Engine, GKE, App Engine flexible and App Engine standard; Cloud Run was **not** in the snippet. Python 3.6+ per the docs, but a third-party mirror says 3.7–3.13. Package `google-cloud-profiler` (4.1.0 in a PyPI snapshot) is Linux-only with a native part — [Profiling Python applications](https://docs.cloud.google.com/profiler/docs/profiling-python); [PyPI google-cloud-profiler](https://pypi.org/project/google-cloud-profiler/)

### Inferences
- **Logging cost example** (inference from the prices above): a project ingesting 100 GiB/month pays (100 − 50) × $0.50 = **$25/month**. If it keeps those logs for 90 days instead of 30, add about $0.01 × 100 GiB × 2 extra months of retention. Chatty LLM prompt and response logging is the biggest risk, so log token counts and IDs, not full prompts, or use sampled request-response logging into BigQuery instead.
- **Per-claim AI fee pattern for the reference project:**
  1. After each Gemini call, log one JSON line with fields like `claim_id`, `job_id`, `step`, `model`, `prompt_tokens`, `output_tokens`, `cached_tokens`, `latency_ms` and `cost_usd_estimate`.
  2. Route the logs with a sink to BigQuery, or use Log Analytics.
  3. Build a distribution log-based metric for latency/tokens with alerts.
  4. Reconcile monthly against the billing export.
  
  This replaces or complements the Firestore per-step timings for analytics. Firestore stays the operational store.
- Mapping for the learner: Prometheus → GMP (same PromQL, `RunMonitoring` ≈ `PodMonitoring`); Alertmanager → Monitoring alerting policies; Loki/ELK → Cloud Logging + Log Analytics; Jaeger/Tempo → Cloud Trace via OTLP; Langfuse stays Langfuse (self-host on GKE via the module, or Langfuse Cloud). Grafana can query GMP, but the fetched page did not document Grafana setup; see Gaps.

### Gaps
- No official Google **FastAPI** OpenTelemetry sample was found. The official one is Flask.
- I could not confirm from Google docs whether `telemetry.googleapis.com` now also accepts OTLP logs and metrics. The PyPI README says traces only.
- The official Google metric reference page for `token_count` and other Agent Platform metrics was not fetched. Current sources are third-party.
- No official Google Grafana-on-GMP page was fetched.
- No source confirmed Cloud Profiler support on Cloud Run.
- Uptime check pricing and configuration details were not collected.
- Error Reporting pricing and grouping details were not collected.

---

## Q4. Reliability: Google SRE books (which chapters matter for an AI app), Architecture Framework reliability and operational excellence, retries with backoff and jitter, idempotency, quota management, multi-region

### Takeaway
Read about 20 targeted chapters across the three free SRE books, not everything: SLOs, monitoring, alerting on SLOs, overload and cascading failures, canarying, postmortems, and least privilege. Then read the 9 reliability-pillar principles and the AI/ML perspective of the Well-Architected Framework. For Gemini, the practical rules are:
- retry 429 and 5xx errors with truncated exponential backoff plus jitter,
- never stack retries,
- use the global endpoint for pay-as-you-go,
- ramp traffic gradually,
- buy Provisioned Throughput for steady capacity.

A rewritten SRE book **2nd edition (2026)** exists but is paid. The 2016 edition is still free online.

### Cited Findings

**Books (owner: Google, via sre.google)**
- sre.google lists the following, plus newer non-book resources "AI Engineering Reliable Operations" (marked New!), a Google SRE Video Gallery and "Product-Focused Reliability for SRE" — [sre.google/books](https://sre.google/books/):
  - "Site Reliability Engineering, 2nd Edition" (New!, buy only).
  - "Building Secure & Reliable Systems" (free online).
  - "The Site Reliability Workbook" (free online).
  - "Site Reliability Engineering" (original, free online).
- SRE book 2nd edition:
  - Google's blog calls it a "completely rewritten" edition for the 10th anniversary. It covers AI, microservices, multi-cloud, serverless and platform engineering.
  - O'Reilly authors: Beyer, Jones, Leng, Huska, Petoff, Murphy. ISBN 9798341607675.
  - Publication date conflicts between sources: Sep 2026 on O'Reilly vs 31 Oct or 1 Dec 2026 at retailers.
  
  — [Google Cloud blog: SRE book second edition](https://cloud.google.com/blog/products/devops-sre/sre-book-second-edition); [O'Reilly listing](https://www.oreilly.com/library/view/site-reliability-engineering/9798341607675/); [IT Brief UK](https://itbrief.co.uk/story/google-revises-site-reliability-engineering-book-for-ai-era)
- SRE book (2016, free) has 34 chapters. Chapters most useful for a Cloud Run + LLM app:
  - Ch 3 Embracing Risk
  - Ch 4 Service Level Objectives
  - Ch 5 Eliminating Toil
  - Ch 6 Monitoring Distributed Systems
  - Ch 8 Release Engineering
  - Ch 10 Practical Alerting
  - Ch 12 Effective Troubleshooting
  - Ch 14 Managing Incidents
  - Ch 15 Postmortem Culture
  - Ch 21 Handling Overload
  - Ch 22 Addressing Cascading Failures
  - Ch 25 Data Processing Pipelines
  - Ch 26 Data Integrity
  - Ch 27 Reliable Product Launches at Scale
  
  — [SRE book TOC](https://sre.google/sre-book/table-of-contents/) (e.g. [/sre-book/addressing-cascading-failures/](https://sre.google/sre-book/addressing-cascading-failures/))
- SRE Workbook (free) has 21 chapters plus appendices. Key chapters:
  - Ch 2 Implementing SLOs
  - Ch 3 SLO Engineering Case Studies
  - Ch 4 Monitoring
  - Ch 5 Alerting on SLOs
  - Ch 6 Eliminating Toil
  - Ch 8 On-Call
  - Ch 9 Incident Response
  - Ch 10 Postmortem Culture
  - Ch 11 Managing Load
  - Ch 13 Data Processing Pipelines
  - Ch 14–15 Configuration Design / Specifics
  - Ch 16 Canarying Releases
  - Ch 17 Identifying and Recovering from Overload
  - Appendix A Example SLO Document
  - Appendix B Example Error Budget Policy
  
  — [SRE Workbook TOC](https://sre.google/workbook/table-of-contents/)
- Building Secure & Reliable Systems (free) has 22 chapters. Key chapters:
  - Ch 5 Design for Least Privilege
  - Ch 6 Design for Understandability
  - Ch 8 Design for Resilience
  - Ch 9 Design for Recovery
  - Ch 10 Mitigating DoS
  - Ch 14 Deploying Code
  - Ch 15 Investigating Systems
  - Ch 16 Disaster Planning
  - Ch 17 Crisis Management
  - Ch 18 Recovery and Aftermath
  
  — [BSRS TOC](https://google.github.io/building-secure-and-reliable-systems/raw/toc.html)
- "AI in SRE: How Google is Engineering the Future of Reliable Operations" (Papapanagiotou, Malesevic, Heiser, Meshenberg) is a long web article, 3 pages. Main points:
  - Evaluate agents against Bronze/Silver/Gold datasets, with nightly LLM-as-judge plus deterministic scoring.
  - Log signals, hypotheses and confidence, and keep execution traces.
  - Give agents least-privilege identities and dry-run APIs.
  - Use agent-specific rate limits and circuit breakers.
  - Provide "Red Button" pause controls.
  - Escalate to humans with the investigation history attached.
  
  — [sre.google: AI in SRE](https://sre.google/resources/practices-and-processes/ai-engineering-reliable-operations/)

**Well-Architected Framework**
- The reliability pillar has 9 principles, each with a page — [Reliability pillar](https://docs.cloud.google.com/architecture/framework/reliability):
  1. Define reliability based on user-experience goals.
  2. Set realistic targets.
  3. Build HA through redundancy.
  4. Use horizontal scalability.
  5. Detect failures with observability.
  6. Design for graceful degradation.
  7. Test recovery from failures.
  8. Test recovery from data loss.
  9. Conduct postmortems.
  
  For multi-region it links to [Multi-regional deployment archetype](https://docs.cloud.google.com/architecture/deployment-archetypes/multiregional).
- The **AI and ML perspective** is a cross-pillar guide with its own operational excellence, reliability and cost pages. The changelog shows operational excellence expanded on 2025-04-28, cost optimization on 2025-07-28 and reliability on 2025-08-07 — [AI/ML perspective](https://docs.cloud.google.com/architecture/framework/perspectives/ai-ml); [Framework what's new](https://docs.cloud.google.com/architecture/framework/whats-new)

**Retries, backoff, jitter, idempotency**
- Google's retry-strategy page:
  - Retry **408, 429, 5xx**, socket timeouts and TCP disconnects. Fix permanent errors (auth, config) before retrying.
  - Use "exponential backoff with jitter" only for retryable **and idempotent** operations.
  - gcloud defaults: base 1 s, multiplier 2, max delay 32 s, max retries 32. The Python client: max backoff 60 s, deadline 120 s.
  - Non-idempotent operations (e.g. creating a Pub/Sub notification) must not be blindly retried. Use preconditions (`ifGenerationMatch`) to make writes idempotent.
  - Anti-patterns: no backoff, retrying permanent errors, infinite retries, and **stacking app retries over library retries** (3 × 3 = 9 attempts).
  
  — [Cloud Storage: retry strategy](https://docs.cloud.google.com/storage/docs/retry-strategy)
- Gemini 429 handling:
  - Pay-as-you-go message: "Resource exhausted, please try again later." Sharp increases trigger "acceleration limits", so ramp up gradually.
  - Retry with truncated exponential backoff. Use the **global endpoint** instead of a regional one where possible.
  - Request a quota increase. Consider Provisioned Throughput (overflow above it is billed as pay-as-you-go).
  - On-demand 429s are not counted against the SLA error rate.
  
  — [Agent Platform: error code 429](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/error-code-429)
- Cloud Run lifecycle: idle instances (even min instances) can be shut down at any time. Trap **SIGTERM** for about 10 s of grace. Idle instances scale down after at most 15 min. For async work with retries up to 30 min, Google suggests Cloud Tasks — [Cloud Run billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings)

### Inferences
- For an AI claim-processing pipeline, the most important reliability habits are:
  - Idempotent job steps, keyed by `claim_id` + `step` (Firestore already stores step timings, so it can also store step status, letting retries skip done steps).
  - One retry layer only (either the SDK's or yours).
  - Backoff with jitter on 429/5xx.
  - A per-request timeout and an overall deadline.
  - Graceful degradation, e.g. fall back from Pro to Flash, or queue for later.
  
  This follows from the retry anti-patterns and the reliability pillar's graceful-degradation principle.
- Multi-region for Gemini is mostly handled by the global endpoint. Multi-region for Cloud Run itself means deploying the service in two regions behind a global load balancer. That follows from the multi-regional archetype, but the archetype page was not read in detail.

### Gaps
- The operational-excellence pillar page and the AI/ML reliability page were not fetched in detail. Only the changelog dates were found.
- No official Google page on Gemini "dynamic shared quota" or Priority/Flex PayGo semantics was fetched. The 429 page does not mention them.
- The multi-regional deployment archetype page and Cloud Run multi-region (global external load balancer + serverless NEGs) were not fetched.
- The free-online status of the SRE book 2nd edition: sre.google shows only a buy link, so it is assumed not free.

---

## Q5. Cost control: billing export to BigQuery, budgets and alerts, FinOps for gen AI (token costs, caching, batch, Flash vs Pro routing), Cloud Run cost model, BigQuery cost guards, labels

### Takeaway
Do these on day one:
1. Turn on the billing export to BigQuery (no full backfill later).
2. Label everything (`env`, `service`, `team`, `model`, `use_case`).
3. Create budgets with Pub/Sub notifications. Budgets alone don't cap spend.
4. Use the new **spend caps** for AI APIs and Cloud Run (GA for limited services in October 2026).

For Gemini the big levers are:
- model routing: Flash-Lite at $0.30/$2.50 vs 3.1 Pro at $2/$12 per 1M tokens on the Gemini Developer API,
- context caching (90% discount on cached input),
- Batch/Flex (50% off),
- staying under the >200K-token tier, which doubles the price.

Watch for scheduled price increases on Gemini 4 Argon (2026-12-01) and Gemini 3.8 Flash (2027-01-01). On Cloud Run, concurrency is the main cost lever.

### Cited Findings

**Billing export, budgets, spend caps**
- Billing export to BigQuery:
  - Export types: standard usage cost (includes **labels**), detailed usage cost (resource-level), pricing, FOCUS and others. Data exports "automatically throughout the day".
  - Backfill is limited: multi-region (US/EU) datasets get the current and previous month (up to 5 days to finish), regional datasets get none, and pricing data gets none.
  - Google recommends enabling it "at the same time that you create a Cloud Billing account".
  - Query through **views**, because schemas change.
  
  — [Export Cloud Billing data to BigQuery](https://docs.cloud.google.com/billing/docs/how-to/export-data-bigquery)
- Budgets:
  - An alerts-only budget "doesn't automatically cap" spend. Default thresholds are 50%, 90% and 100% of actual spend. Forecasted rules exist, but not for custom date ranges.
  - Pub/Sub notifications are sent several times a day and can trigger automation (Slack, disabling billing).
  - Label scope works only on account-level budgets, one label per budget. Up to 50,000 budgets per billing account.
  
  — [Create, edit, or delete budgets](https://docs.cloud.google.com/billing/docs/how-to/budgets)
- **Spend caps:**
  - Announced as a private preview on 2026-04-22 for AI Studio, Agent Platform, **Cloud Run**, Cloud Run functions and Maps. They "alert and ultimately pause API traffic once your set budget is reached, but leave your resources intact."
  - The same post announced a **FinOps Explainability Agent** that can split AI spend by model, API key and input vs output tokens.
  
  — [Google Cloud blog, Next '26](https://cloud.google.com/blog/topics/cost-management/introducing-spend-caps-ai-cost-visibility-next26/)
- Cloud Billing release notes say spend-cap budgets reached **GA on 2026-10-13 for a limited set of services**. Details:
  - Enforcement is not instant, and overages during the delay are billed.
  - Caps apply to one project and one service.
  - Persistent resources (compute, storage) keep accruing.
  - A cap stays enforced for the month unless lifted.
  - A third-party blog gives Oct 30 instead (conflict).
  
  — [Manage spend cap budgets](https://docs.cloud.google.com/billing/docs/how-to/budgets-spend-caps); [Cloud Billing release notes](https://docs.cloud.google.com/billing/docs/release-notes); contradicting date: [remio.ai](https://www.remio.ai/post/google-cloud-spend-caps-reach-general-availability-trading-runaway-usage-for-ser)
- The Cloud Run docs say "Budget spend caps apply to all Cloud Run resource types and pause workloads when hit". VPC connector VMs are not covered — [Cloud Run billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings)

**Gemini token pricing (Gemini Developer API / AI Studio page, per 1M tokens, USD)**

The `ai.google.dev/gemini-api/docs/pricing` URL now redirects to `aistudio.google.com/docs/pricing`. Agent Platform (Vertex) prices could not be read; see Gaps.

- **Gemini 3.1 Pro Preview**:
  - Standard: input $2.00 (≤200K) / $4.00 (>200K); output $12.00 / $18.00; caching $0.20 / $0.40; cache storage $4.50 per 1M tokens per hour.
  - Batch and Flex: half price ($1.00 / $6.00).
  - Priority: $3.60 / $21.60.
  
  — [Gemini API pricing](https://aistudio.google.com/docs/pricing)
- **Gemini 3.8 Flash**:
  - Standard $0.75 in / $3.75 out; Batch/Flex $0.375 / $1.875; caching $0.075.
  - These prices hold through 2026-12-31. They **double from 2027-01-01** (→ $1.50 / $7.50).
  
  — [Gemini API pricing](https://aistudio.google.com/docs/pricing)
- **Gemini 3.5 Flash-Lite**: Standard $0.30 in / $2.50 out; Batch $0.15 / $1.25; caching $0.03 — [Gemini API pricing](https://aistudio.google.com/docs/pricing)
- **Gemini 4 Argon** (flagship reasoning): $2.00 / $10.00 through 2026-11-30, rising to **$4.00 / $20.00 on 2026-12-01** — [Gemini API pricing](https://aistudio.google.com/docs/pricing)

**Context caching on Agent Platform**
- Implicit caching is on by default with a **90% discount**. Explicit caching gets 90% on Gemini 2.5+ and 75% on 2.0.
- Minimum cacheable tokens: 2,048 (Gemini 2), 4,096 (Gemini 3/4), 6,144 for some Flash versions.
- Explicit TTL defaults to 60 min, with no maximum. Implicit entries live at most 24 h.
- Billing: cache creation is billed at the input price. Explicit caches also pay storage per hour; implicit caches have no storage fee.
- Usage shows in `cachedContentTokenCount`.

— [Agent Platform context cache overview](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview)

**Cloud Run cost model**
- Request-based (default) bills only during requests, startup and shutdown. It suits spiky traffic.
- Instance-based bills the whole instance life and suits steady traffic or background work. It needs ≥ 512 MiB, and is required if you use health-check probes.
- Recommender suggests switching if instance-based would be cheaper.
- Jobs and worker pools are always instance-based.

— [Cloud Run billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings)
- Raw pricing page facts:
  - Billing is "rounded up to the nearest 100 millisecond".
  - Free tier is aggregated per billing account: request-based 180,000 vCPU-s, 360,000 GiB-s and 2 million requests per month; instance-based 240,000 vCPU-s and 450,000 GiB-s.
  - Worked example: 10M requests/month, 400 ms, 1 vCPU, 512 MiB in europe-west1 costs **$13.69/month at concurrency 20** but **$81.72/month at concurrency 1**.
  
  — [Cloud Run pricing](https://cloud.google.com/run/pricing)

**BigQuery cost guards**
- Set **maximum bytes billed**: the query fails before it runs, with no charge, if the estimate is too high.
- Use a **dry run** (`--dry_run`) to estimate.
- Set **custom daily quotas** per project or user.
- Use **preview** (free) instead of `SELECT ... LIMIT`; LIMIT doesn't reduce bytes on non-clustered tables.
- Materialize intermediate results.
- On editions, set the reservation baseline to 0 with a max.

— [BigQuery: control costs](https://docs.cloud.google.com/bigquery/docs/best-practices-costs)

**FinOps guidance for AI**
- The AI/ML perspective (cost) says:
  - Track **unit costs** ("cost per inference, data point, or task").
  - Use billing reports, budgets and billing export to BigQuery.
  - Label resources by project, team, environment, **model name** and **use case**.
  - Alert on KPIs. Rightsize idle resources.
  - Prefer managed services and pre-trained models.
  
  — [Well-Architected AI/ML perspective: cost optimization](https://docs.cloud.google.com/architecture/framework/perspectives/ai-ml/cost-optimization)
- Third-party and secondary claims:
  - Signal65 research (via ITPro) says agentic workloads use 4–15x more tokens than chatbots — [ITPro](https://www.itpro.com/technology/artificial-intelligence/google-targets-ai-cost-efficiency-with-new-finops-features-for-gemini-enterprise)
  - A partner case study (CloudHealth) reports a 99.6% cost cut through model choice, rules-based short-circuiting and prompt compression. Partner-reported — [Google Dev forum](https://discuss.google.dev/t/how-cloudhealth-partnered-with-google-cloud-to-cut-finops-bot-costs-by-over-99-with-googles-gemini-model/289100)
  - An older official post (2023) suggests a gen-AI cost model plus a shared finance/tech/product "front door" — [Google Cloud blog 2023](https://cloud.google.com/blog/transform/maximize-your-generative-ai-investments-with-cloud-finops)
- Artifact Registry cleanup policies "can help you reduce artifact storage costs" — [Artifact Registry: cleanup policies](https://docs.cloud.google.com/artifact-registry/docs/repositories/cleanup-policy)

### Inferences
- **Token cost formula** (inference from the published prices):
  `cost = (input_tokens − cached_tokens) × in_price + cached_tokens × cache_price + output_tokens × out_price` (per 1M tokens). Note that thinking tokens count as output, as the page says "output incl. thinking".
  
  Example on Gemini 3.8 Flash Standard, one claim with 20,000 input tokens (15,000 cached) and 2,000 output tokens:
  - 5,000 × $0.75/1M = $0.00375
  - 15,000 × $0.075/1M = $0.001125
  - 2,000 × $3.75/1M = $0.0075
  - **Total ≈ $0.0124 per claim.**
  
  The same claim on 3.1 Pro (≤200K) is ≈ 5,000 × 2 + 15,000 × 0.2 + 2,000 × 12 = $0.037. That is about 3x more. After 2027-01-01 the Flash cost doubles.
- Routing rule of thumb: send extraction and classification to Flash-Lite or Flash. Send only hard reasoning steps to Pro or Argon. Use Batch/Flex (50% off) for anything that is not user-facing, such as nightly re-processing. Keep prompts under 200K tokens to avoid the 2x tier.
- For the reference project, "AI fee per claim" should be computed from `usageMetadata` at request time, using a price table kept in config. Reconcile it weekly against the billing export (filter by labels and SKU), because list prices change on fixed dates.

### Gaps
- **Agent Platform (Vertex) Gemini prices** could not be read. The page is JS-rendered and came back truncated. Vertex prices may differ from the Gemini Developer API prices quoted above.
- Exact Cloud Run per-vCPU-second and per-GiB-second prices for Tier 1 regions were in a JS-rendered table and not extracted.
- The BigQuery on-demand price per TiB was not on the fetched page.
- The exact list of services eligible for GA spend caps was not fully read.
- Whether billing export rows carry Gemini token-level SKUs (input vs output) was not confirmed. The FinOps blog implies the split exists.

---

## Q6. Long-form courses: Skills Boost "DevOps Engineer" path items and Coursera equivalents — which are current and worth the time

### Takeaway
The Coursera "Cloud DevOps Engineer Professional Certificate" prep series (5 courses, about 42 h, labs) and the Skills Boost paths #20 (Professional Cloud DevOps Engineer, 15 activities) and #106 (DevOps Engineer, SRE) are the official long-form tracks. Courses worth the learner's time:
- "Logging and Monitoring in Google Cloud" (about 14 h)
- "Observability in Google Cloud" (about 6 h; Trace, Profiler, Error Reporting)
- "Getting Started with Terraform for Google Cloud" (6.5 h)

"Developing a Google SRE Culture" (about 8 h) is aimed at leaders and is light on hands-on work. Skip the GKE-heavy and Cloud Source Repositories–based labs ("Implement DevOps Workflows in Google Cloud"), because they don't match a Cloud Run + GitLab stack.

### Cited Findings
- Coursera **"Preparing for Google Cloud Certification: Cloud DevOps Engr Professional Certificate"**:
  - 5 courses: Google Cloud Fundamentals: Core Infrastructure (8 h), **Developing a Google SRE Culture (8 h)**, Google Cloud Architecture: Design Principles (6 h), **Logging and Monitoring in Google Cloud (14 h)**, Getting Started with GKE (6 h).
  - Uses Qwiklabs labs. Beginner level. Rated 4.7 from 54,685 reviews.
  - Sample reviews are dated 2018–2021. No content update date is shown.
  
  — [Coursera specialization](https://www.coursera.org/specializations/sre-devops-engineer-google-cloud)
- "Developing a Google SRE Culture" is aimed at IT and business leaders, beginner level, about 8 h with a final quiz. A learner review calls it foundational, "not a deep dive" into tools — [Coursera course](https://www.coursera.org/programs/google-specialization/learn/developing-a-google-sre-culture); [OpenCourser review](https://opencourser.com/course/ctyiix/developing-a-google-sre-culture)
- "Observability in Google Cloud" is part 2 after "Logging and Monitoring in Google Cloud". It covers APM tools: Error Reporting, Cloud Trace and Cloud Profiler. A Polish-locale path listing gives about 6 h — [Skills Boost path 20](https://cloudskillsboost.google/paths/20); search-summary of skills.google profile pages (low confidence on duration)
- Skills Boost path **#20 "Professional Cloud DevOps Engineer Certification"** says it covers "CI/CD pipelines ... monitoring and optimizing production systems for performance and cost" and "balance service reliability with delivery speed". It contains **15 activities**, but the list was not visible without login — [skills.google/paths/20](https://www.skills.google/paths/20)
- Skills Boost path **#106 "DevOps Engineer, SRE"**: partner copies show 14 activities. A newer version replaced an older path, and progress carries over — [partner.skills.google/paths/106](https://partner.skills.google/paths/106?locale=ja); [skills.google/paths](https://www.skills.google/paths)
- The "Implement DevOps Workflows in Google Cloud" skill badge covers git repos with **Cloud Source Repositories** and GKE deployments. CSR is end-of-sale, so this badge is outdated for this learner — [Skills Boost path 20](https://cloudskillsboost.google/paths/20) (search snippet); [CSR migration guides](https://docs.cloud.google.com/source-repositories/docs/migration-guides)
- "Monitor and Log with Google Cloud Observability" is an introductory skill badge (Compute Engine VMs, multi-project monitoring) — search summary of [Skills Boost path 20](https://cloudskillsboost.google/paths/20)
- "Getting Started with Terraform for Google Cloud": 6 h 30 min, 16 credits; see Q2 — [Skills Boost course_templates/443](https://www.cloudskillsboost.google/course_templates/443)
- Skills Boost now lives under the **skills.google** domain. A search snippet mentions a $29/month subscription (unverified) — [skills.google/paths](https://www.skills.google/paths)
- YouTube (Google Cloud Tech):
  - "Engineering for Reliability" playlist, 24 videos: SLOs, burn-rate alerting, SLIs with custom metrics — [cotalks.dev mirror of playlist](https://cotalks.dev/playlists/engineering-for-reliability)
  - "Monitoring Cloud Run Applications: From Basic to Custom Metrics", 10 parts — [Class Central listing](https://classcentral.com/classroom/youtube-monitor-your-cloud-run-app-332314)

### Inferences
- Priority order for this learner (strong K8s and observability, zero GCP), estimated about 60–80 h total:
  1. "Logging and Monitoring in Google Cloud" + "Observability in Google Cloud" (about 20 h).
  2. "Getting Started with Terraform for Google Cloud" (6.5 h) + the Google Terraform best-practices docs.
  3. SRE Workbook chapters 2, 4, 5, 16, 17 (free) + the Engineering for Reliability playlist.
  4. Cloud Deploy and Cloud Run docs with a self-built GitLab WIF pipeline.
  5. Optionally, "Developing a Google SRE Culture" for interview vocabulary only.
  
  Skip "Getting Started with GKE" (the learner already knows K8s) and CSR-based labs.
- Courses recorded before April 2026 say "Vertex AI" instead of "Agent Platform". Courses from before 2025 may show Container Registry (`gcr.io`) or Cloud Source Repositories in labs. Treat those steps as outdated and replace them with Artifact Registry and GitLab.

### Gaps
- The exact activity lists of Skills Boost paths #20 and #106 could not be read; login or JS is required.
- Last-updated dates for the Skills Boost and Coursera courses were not shown.
- Coursera subscription price and audit availability were not found.
- I found no official long course on Cloud Deploy or on GitLab-to-Cloud-Run.
- The Google Cloud Tech YouTube playlists were found only through mirror or listing sites. Direct youtube.com playlist URLs were not captured.

---

## Q7. Curated resource catalog (title, URL, owner, format, length, cost, last updated, topics, hands-on level, fit)

### Takeaway
About 30 resources cover every topic. All Google docs are free. Most are undated in the fetched content, so "last updated" is often "not shown". The highest-value, current items are the Terraform best-practices docs, the Cloud Deploy and Cloud Run docs, the GitLab WIF guide, the free SRE books, Fabric, the GMP Cloud Run sidecar doc and the Agent Platform caching and logging docs.

### Cited Findings
Each row's facts come from the URL in that row. "n/s" means not shown in the fetched content. Length marked "~" is approximate as given by the source, or derived from a chapter count.

| # | Title | URL | Owner | Format | Length | Cost | Last updated | Topics | Hands-on | Fit for learner |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Best practices for using Terraform (general style, root modules, reusable modules ...) | https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure | Google Cloud | Multi-page docs | Multi-page series | Free | n/s | Module layout, naming, env dirs, version pinning | Medium (patterns) | High: maps Helm-per-env thinking to TF |
| 2 | Store Terraform state in Cloud Storage | https://docs.cloud.google.com/docs/terraform/resource-management/store-state | Google Cloud | Tutorial | Single page | Free | n/s | GCS backend, versioning, IAM | High | High |
| 3 | Cloud Foundation Fabric | https://github.com/GoogleCloudPlatform/cloud-foundation-fabric | Google Cloud (GitHub) | Code repo | Large (7,239 commits) | Free | Releases n/s | Modules, FAST landing zone, project factory | Very high | High for "real code"; FAST may be too big |
| 4 | terraform-example-foundation (Enterprise foundations blueprint code) | https://github.com/terraform-google-modules/terraform-example-foundation | Google (terraform-google-modules) | Code repo | 6 stages | Free | n/s | Org/folders/envs/networks/projects | Very high | Medium: enterprise-scale |
| 5 | Infrastructure Manager overview | https://docs.cloud.google.com/infrastructure-manager/docs/overview | Google Cloud | Docs | Docs set | n/s | n/s | Managed Terraform via Cloud Build | Medium | Medium |
| 6 | Getting Started with Terraform for Google Cloud | https://www.cloudskillsboost.google/course_templates/443 | Google Cloud Skills Boost | Course + labs | 6 h 30 min | 16 credits | n/s | TF basics, state in GCS, modules | High (labs) | High as first step |
| 7 | Terraform for Google Cloud Essential Guide (Nordhausen) | https://oreilly.com/library/view/terraform-for-google/9781804619629 | Packt | Book | 180 pages | Paid | Jan 2023 | Auth, modules, multi-env | Medium | Medium: dated but structured |
| 8 | Google Cloud WIF with deployment pipelines (GitLab section) | https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines | Google Cloud | How-to | Long page | Free | n/s | OIDC, attribute conditions, `.gitlab-ci.yml` | High | Critical (GitLab → Cloud Run) |
| 9 | GitLab: Google Cloud WIF and IAM policies | https://docs.gitlab.com/integration/google_cloud_iam/ | GitLab | Docs | Single page | Free tier OK (GitLab.com only) | n/s | Guided WIF setup, claims | High | High if on GitLab.com |
| 10 | GitLab tutorial: Cloud Run component | https://docs.gitlab.com/tutorials/create_and_deploy_web_service_with_google_cloud_run_component/ | GitLab | Tutorial | Single page | Free | n/s | Build → AR → Cloud Run | High | High |
| 11 | Cloud Deploy: deploy to Cloud Run | https://docs.cloud.google.com/deploy/docs/deploy-app-run | Google Cloud | Quickstart | Single page | First multi-target pipeline free, then $5 each | n/s | Skaffold, pipeline, targets, promote | High | High: ArgoCD-promotion analogue |
| 12 | Cloud Deploy: canary | https://docs.cloud.google.com/deploy/docs/deployment-strategies/canary | Google Cloud | Docs | Long page | as above | n/s | Phases, verify, analysis, automation | Medium | High: Argo Rollouts analogue |
| 13 | Cloud Run rollouts, rollbacks, traffic migration | https://docs.cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration | Google Cloud | Docs | Single page | Free | n/s | Revisions, tags, split, rollback | High | High |
| 14 | Using uv in Docker | https://docs.astral.sh/uv/guides/integration/docker/ | Astral | Guide | Long page | Free | n/s (uv 0.13.7 shown) | Multi-stage, cache mounts, lockfiles | High | High |
| 15 | Cloud Run Python tips | https://docs.cloud.google.com/run/docs/tips/python | Google Cloud | Docs | Single page | Free | n/s | Base image, gunicorn, startup | Medium | High |
| 16 | Artifact Registry cleanup policies | https://docs.cloud.google.com/artifact-registry/docs/repositories/cleanup-policy | Google Cloud | Docs | Single page | Free | n/s | Retention, dry run | High | Medium |
| 17 | Cloud Run logging | https://docs.cloud.google.com/run/docs/logging | Google Cloud | Docs | Single page | Free | n/s | JSON logs, trace correlation | High | Critical |
| 18 | Cloud Logging routing overview + quotas | https://docs.cloud.google.com/logging/docs/routing/overview | Google Cloud | Docs | Multi-page | Free | n/s | Sinks, buckets, retention | Medium | High |
| 19 | Instrument Python with OpenTelemetry (+ opentelemetry-samples repo) | https://docs.cloud.google.com/trace/docs/setup/python-ot | Google Cloud | Tutorial + repo | Long page | Free | n/s | OTLP, Collector, log-trace correlation (Flask) | High | High (adapt to FastAPI) |
| 20 | Managed Service for Prometheus: Cloud Run sidecar | https://docs.cloud.google.com/stackdriver/docs/managed-prometheus/cloudrun-sidecar | Google Cloud | How-to | Long page | Per-sample billing | n/s | `/metrics` scrape, RunMonitoring, PromQL | High | Very high (Prometheus user) |
| 21 | SLO monitoring + burn-rate alerting | https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring | Google Cloud | Docs | Multi-page | Free (Monitoring pricing applies) | n/s | SLIs, compliance, burn rate | Medium | High |
| 22 | Log requests and responses (Agent Platform) | https://docs.cloud.google.com/vertex-ai/generative-ai/docs/multimodal/request-response-logging | Google Cloud | How-to | Single page | BigQuery costs | n/s | Sampled LLM logging to BQ | High | High (AI fee per claim) |
| 23 | Context cache overview (Agent Platform) | https://docs.cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview | Google Cloud | Docs | Single page | Free | n/s (uses 2026 product name) | Implicit/explicit cache, discounts | Medium | High |
| 24 | Langfuse on GCP (Terraform) | https://langfuse.com/self-hosting/deployment/gcp | Langfuse | Docs + module | Docs + repo | Free OSS (infra costs) | v4 docs | GKE, Cloud SQL, Redis, ClickHouse | High | High (already uses Langfuse) |
| 25 | Site Reliability Engineering (2016) | https://sre.google/sre-book/table-of-contents/ | Google | Book (free online) | 34 chapters | Free | 2016 edition | SLOs, overload, incidents | Low–medium | High (selected chapters) |
| 26 | The Site Reliability Workbook | https://sre.google/workbook/table-of-contents/ | Google | Book (free online) | 21 ch + 3 appendices | Free | n/s | SLO implementation, canarying, overload | Medium (worked examples) | Very high |
| 27 | Building Secure & Reliable Systems | https://google.github.io/building-secure-and-reliable-systems/raw/toc.html | Google | Book (free online) | 22 chapters | Free | n/s | Least privilege, resilience, deploy | Low–medium | Medium |
| 28 | Site Reliability Engineering, 2nd Edition | https://www.oreilly.com/library/view/site-reliability-engineering/9798341607675/ | Google / O'Reilly | Book | n/s | Paid | Sep–Dec 2026 (sources conflict) | AI-era SRE, serverless, platform eng | n/s | High if budget allows |
| 29 | AI in SRE (sre.google) | https://sre.google/resources/practices-and-processes/ai-engineering-reliable-operations/ | Google SRE | Long article | 3 pages | Free | n/s | Agent eval, guardrails, red button | Low | High for AI-ops interviews |
| 30 | Well-Architected: reliability pillar + AI/ML perspective | https://docs.cloud.google.com/architecture/framework/perspectives/ai-ml | Google Cloud | Framework docs | Multi-page | Free | AI/ML pages updated Apr–Aug 2025 | Reliability, cost, opex for AI | Low | High |
| 31 | Export billing to BigQuery + budgets + spend caps | https://docs.cloud.google.com/billing/docs/how-to/export-data-bigquery | Google Cloud | Docs | Multi-page | Free (BQ costs) | Spend caps GA 2026-10-13 | Billing export, budgets, caps | High | Critical |
| 32 | Coursera Cloud DevOps Engineer Professional Certificate prep | https://www.coursera.org/specializations/sre-devops-engineer-google-cloud | Google Cloud / Coursera | 5-course series + labs | ~42 h | Coursera subscription (price n/s) | n/s (reviews 2018–21) | SRE culture, logging/monitoring, GKE | Medium | Medium: take 2 of 5 |
| 33 | Skills Boost path #20 Professional Cloud DevOps Engineer | https://www.skills.google/paths/20 | Google Cloud | Path (15 activities) | n/s | Credits/subscription | n/s | CI/CD, monitoring, cost | Medium–high | Medium |
| 34 | Google Cloud Tech "Engineering for Reliability" playlist | https://cotalks.dev/playlists/engineering-for-reliability | Google Cloud Tech (YouTube) | Video playlist | 24 videos | Free | n/s | SLOs, burn rate, SLIs | Low | Medium |

### Inferences
- Roughly 80% of the value for this learner is in rows 1–2, 8, 11–13, 17, 19–23, 26 and 31. These are free, official and match a Cloud Run + GitLab + Gemini stack.

### Gaps
- Last-updated dates for most Google docs pages were not visible in the fetched content.
- I did not verify length in reading hours for docs pages.
- No direct youtube.com URLs were captured.

---

## Q8. Mapping the learner's Kubernetes / ArgoCD / Prometheus / Grafana / Langfuse knowledge to GCP equivalents

### Takeaway
Most of the learner's concepts carry over with a new name. The places where sources show a direct link are GMP (`RunMonitoring` is a subset of `PodMonitoring`, PromQL works), Cloud Deploy (pipeline + targets + canary ≈ ArgoCD promotion + Argo Rollouts), Cloud Run revisions and traffic splits (≈ Deployments + weighted Services), and WIF (≈ K8s OIDC service-account tokens instead of static keys).

### Cited Findings
- `RunMonitoring` is "a subset of the Kubernetes `PodMonitoring` resource", and metrics can be queried with PromQL in Metrics Explorer — [GMP Cloud Run sidecar](https://docs.cloud.google.com/stackdriver/docs/managed-prometheus/cloudrun-sidecar)
- Cloud Deploy uses Skaffold profiles per target, a `serialPipeline` of targets, and promotion between them — [Cloud Deploy: deploy to Cloud Run](https://docs.cloud.google.com/deploy/docs/deploy-app-run)
- Cloud Deploy canary has phases, verify jobs, metric analysis and auto-advance — [Cloud Deploy canary](https://docs.cloud.google.com/deploy/docs/deployment-strategies/canary)
- Cloud Run revisions, `--no-traffic`, tags and percentage splits — [Cloud Run traffic migration](https://docs.cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration)
- WIF exchanges the CI OIDC token for Google access, with attribute conditions — [Google WIF pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)
- Langfuse's GCP module deploys on GKE with Cloud SQL, Memorystore, GCS and ClickHouse — [langfuse-terraform-gcp](https://github.com/langfuse/langfuse-terraform-gcp)

### Inferences
Mapping table (inference built on the cited docs):

| You know (K8s world) | GCP equivalent for Cloud Run apps | Note |
|---|---|---|
| Docker registry / Harbor | Artifact Registry (+ cleanup policies) | Never `gcr.io` Container Registry |
| GitLab CI + kube secrets/static keys | GitLab CI + WIF (OIDC, keyless) | Attribute condition is mandatory on GitLab SaaS |
| Helm chart + values-dev/uat/prod | Cloud Run service YAML + Skaffold profiles; Terraform `environments/{dev,uat,prod}` | One GCP project per env |
| ArgoCD app-of-apps, sync, promotion | Cloud Deploy delivery pipeline (targets dev → uat → prod), Promote, approvals | Not pull-based GitOps; it is push/promote |
| Argo Rollouts canary + AnalysisTemplate | Cloud Deploy canary phases + deploy analysis + `advanceRolloutRule` | 100% canary not allowed on Cloud Run |
| Deployment ReplicaSet history / rollback | Cloud Run revisions; `update-traffic --to-revisions OLD=100` | Rollback is immediate, no health re-check |
| HPA / replicas | Cloud Run autoscaling (concurrency, min/max instances) | Concurrency is the main cost lever |
| Prometheus + ServiceMonitor | GMP sidecar + `RunMonitoring`, PromQL | Billed per sample ($0.06/M) |
| Alertmanager | Cloud Monitoring alerting policies; SLO burn-rate alerts | Fast 10x/1–2 h + slow 2x/24 h |
| Grafana dashboards | Cloud Monitoring dashboards (Grafana on GMP possible, not verified here) | — |
| Loki / ELK | Cloud Logging + Log Analytics + sinks to BigQuery | $0.50/GiB after 50 GiB/project |
| Jaeger / Tempo | Cloud Trace via OTLP (Collector recommended) | $0.20/M spans after 2.5M |
| Langfuse self-host on RKE2 | Langfuse on GKE via the official module, or Langfuse Cloud | Keeps the same LLM tracing UX |
| kubecost | Billing export to BigQuery + labels + budgets + spend caps | Enable export on day one |

### Gaps
- No official Google "Kubernetes to Cloud Run" or "ArgoCD to Cloud Deploy" migration guide was fetched. The mapping above is my synthesis.

---

## Q9. Production interview questions the learner must answer (DevOps / observability / cost), with short answers and sources

### Takeaway
There are 24 questions below. Each answer is short and checked against a source. They focus on the reference stack: GitLab → Cloud Run, dev/uat, Gemini, cost per claim.

### Cited Findings
1. **Q: How do you deploy to Cloud Run from GitLab CI without a service-account key?**
   A: Use Workload Identity Federation.
   - Create a pool and an OIDC provider (issuer `https://gitlab.com` for SaaS) with `google.subject=assertion.sub`.
   - Add an attribute condition on `namespace_id`.
   - In the job, request an `id_tokens` JWT with `aud` = the provider URL and build an `external_account` credential file.
   - Grant `roles/run.admin` + `roles/iam.serviceAccountUser` (and `roles/artifactregistry.writer`), preferably by direct resource access.
   
   — [Google WIF pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines); [GitLab Cloud Run tutorial](https://docs.gitlab.com/tutorials/create_and_deploy_web_service_with_google_cloud_run_component/)
2. **Q: Why is an attribute condition mandatory for GitLab.com WIF?**
   A: All GitLab.com organizations share one issuer URL and some claims aren't unique. Without a condition like `assertion.namespace_id=='GROUP_ID'`, tokens from other GitLab users could be accepted — [Google WIF pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)
3. **Q: Direct resource access vs service-account impersonation in WIF?**
   A: Direct access grants roles to the federated `principal://` identity and is recommended. Impersonation (`roles/iam.workloadIdentityUser` on a service account) is for APIs with federation limits. Both use the project number — [Google WIF pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)
4. **Q: How would you do a canary release of a Cloud Run service?**
   A: Two options:
   - Cloud Deploy `strategy.canary` with percentages (e.g. 25/50/75 → stable), verify jobs, deploy analysis and `advanceRolloutRule`. It works for services and worker pools, not jobs, and a 100% canary is not allowed.
   - Natively: `gcloud run deploy --no-traffic --tag canary`, then `update-traffic --to-tags canary=10`.
   
   — [Cloud Deploy canary](https://docs.cloud.google.com/deploy/docs/deployment-strategies/canary); [Cloud Run traffic](https://docs.cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration)
5. **Q: A bad revision is live. Fastest rollback?**
   A: `gcloud run services update-traffic SERVICE --to-revisions GOOD_REV=100`. It changes routing immediately and does not re-run health checks, so check dependencies first. Remember that splits persist into later deploys — [Cloud Run traffic](https://docs.cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration)
6. **Q: Why deploy images by digest, not tag?**
   A: Tags can move. Cloud Deploy recommends SHA-qualified images in `--images`, and uv's docs recommend pinning by SHA256 digest for reproducibility. This maps one git commit to one immutable image — [Cloud Deploy Cloud Run](https://docs.cloud.google.com/deploy/docs/deploy-app-run); [uv Docker](https://docs.astral.sh/uv/guides/integration/docker/)
7. **Q: What happened to Container Registry and Cloud Source Repositories?**
   A: Container Registry: writes stopped 2025-03-18 and reads 2025-06-03; use Artifact Registry (gcr.io repos on AR still work). CSR: end-of-sale 2024-06-17; use Secure Source Manager or GitLab/GitHub — [GKE GCR transition](https://docs.cloud.google.com/kubernetes-engine/docs/deprecations/container-registry); [CSR migration](https://docs.cloud.google.com/source-repositories/docs/migration-guides)
8. **Q: How do you write a small, fast Python image for Cloud Run?**
   A: Multi-stage build.
   - Copy a pinned uv binary.
   - `uv sync --frozen --no-install-project` with a cache mount, then `uv sync --locked --no-editable`.
   - Copy only `.venv` into a slim or distroless final image.
   - Set `UV_COMPILE_BYTECODE=1` and `PYTHONUNBUFFERED`. Import heavy libraries lazily and add a startup probe.
   
   — [uv Docker](https://docs.astral.sh/uv/guides/integration/docker/); [Cloud Run Python tips](https://docs.cloud.google.com/run/docs/tips/python)
9. **Q: How do you structure Terraform for dev/uat/prod?**
   A: Shared `modules/<service>` plus `environments/{dev,uat,prod}`, each with its own `backend.tf` (GCS) and `main.tf`.
   - Default workspace only.
   - At most 100 resources per state.
   - Pin providers to a minor version in `versions.tf`.
   - Commit `.terraform.lock.hcl`.
   - Use `terraform.tfvars`.
   
   — [TF root modules](https://docs.cloud.google.com/docs/terraform/best-practices/root-modules)
10. **Q: Where and how do you store Terraform state?**
    A: A GCS backend bucket with object versioning plus lifecycle rules for old versions, `public_access_prevention = "enforced"`, uniform bucket-level access and `force_destroy = false`. Only 1–2 admins get bucket admin; other users only read and write objects — [Store state in GCS](https://docs.cloud.google.com/docs/terraform/resource-management/store-state)
11. **Q: Would you use Deployment Manager?**
    A: No. It reached end of support on 2026-03-31. Use Terraform, either in CI or through Infrastructure Manager (which runs Terraform in Cloud Build and stores state and revisions) — [DM deprecations](https://docs.cloud.google.com/deployment-manager/docs/deprecations); [Infra Manager](https://docs.cloud.google.com/infrastructure-manager/docs/overview)
12. **Q: How do you make FastAPI logs structured and linked to traces on Cloud Run?**
    A: Print one JSON object per line to stdout with `severity` and `message`. Add `logging.googleapis.com/trace` (`projects/P/traces/T`, taken from `X-Cloud-Trace-Context` or OTel), `logging.googleapis.com/spanId` and `trace_sampled`. The OTel `LoggingInstrumentor` can inject these fields — [Cloud Run logging](https://docs.cloud.google.com/run/docs/logging); [Python OTel](https://docs.cloud.google.com/trace/docs/setup/python-ot)
13. **Q: Default log retention and cost?**
    A: `_Required` keeps logs 400 days, free and fixed. `_Default` keeps 30 days and is configurable from 1 to 3650 days. Ingest costs $0.50/GiB after 50 GiB/project/month. Retention beyond 30 days costs $0.01/GiB/month. Log Analytics has no extra charge — [Logging quotas](https://docs.cloud.google.com/logging/quotas); [Observability pricing](https://cloud.google.com/stackdriver/pricing)
14. **Q: How do you get logs into BigQuery for analytics, and what are the caveats?**
    A: Either a log sink to a BigQuery dataset (one table per log name), or a log bucket with Log Analytics and a linked read-only dataset. Exclusion filters don't reduce `entries.write` quota, and you cannot change the `_Required` sink — [Logging routing](https://docs.cloud.google.com/logging/docs/routing/overview)
15. **Q: Log-based metric gotchas?**
    A: Data starts only from creation time, with no backfill. User-defined metrics count excluded logs too. They are billed as custom metrics. Use distribution metrics for latency and tokens, and set missing-data behavior in alerts — [Log-based metrics](https://docs.cloud.google.com/logging/docs/logs-based-metrics)
16. **Q: How do you alert on an SLO without paging on every spike?**
    A: Use burn-rate alerts with `select_slo_burn_rate`. Run a fast-burn alert (about 10x, 1–2 h lookback) and a slow-burn alert (about 2x, 24 h). Cloud Run is not auto-detected for SLOs, so define a custom service with a request-based availability or latency SLI. See also Workbook ch 5 — [Burn-rate alerting](https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate); [SLO overview](https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring); [Workbook: Alerting on SLOs](https://sre.google/workbook/alerting-on-slos/)
17. **Q: We already expose Prometheus `/metrics`. How do we keep that on Cloud Run?**
    A: Add the GMP sidecar. It scrapes `:8080/metrics` every 30 s, is configured with `RunMonitoring` (a subset of PodMonitoring), and needs a container-dependencies annotation. Query with PromQL. Use instance-based billing so scrapes aren't CPU-throttled. Cost is $0.06 per million samples — [GMP Cloud Run sidecar](https://docs.cloud.google.com/stackdriver/docs/managed-prometheus/cloudrun-sidecar); [Observability pricing](https://cloud.google.com/stackdriver/pricing)
18. **Q: How do you measure LLM token usage and cost per request (per claim)?**
    A: Read `usageMetadata` from each response (prompt, output and `cachedContentTokenCount`). Log it as structured JSON with `claim_id`/`model`, sink it to BigQuery, and multiply by the price table. You can add sampled request-response logging to BigQuery and the `token_count` metric (input/output label). Langfuse traces work alongside — [Context cache overview](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview); [Request-response logging](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/multimodal/request-response-logging); [Google Dev forum](https://discuss.google.dev/t/monitor-the-usage-of-gemini-api-on-vertex-ai/171653)
19. **Q: Gemini returns 429. What do you do?**
    A: Retry with truncated exponential backoff and jitter, in one retry layer only. Use the global endpoint for pay-as-you-go and ramp traffic gradually (acceleration limits). Request a quota increase or buy Provisioned Throughput. Enable request metadata logs to see which seconds and models hit 429 — [429 doc](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/error-code-429); [Retry strategy](https://docs.cloud.google.com/storage/docs/retry-strategy)
20. **Q: What is safe to retry?**
    A: Errors 408, 429, 5xx and network timeouts, and only for idempotent operations (GET/LIST, or writes protected by preconditions or idempotency keys). Never retry permanent errors, never retry forever, and never stack app retries on top of library retries — [Retry strategy](https://docs.cloud.google.com/storage/docs/retry-strategy)
21. **Q: Does a budget stop spending?**
    A: An alerts-only budget does not; it emails at 50/90/100% and can send Pub/Sub messages for automation. Spend caps (GA 2026-10-13 for limited services, including AI APIs and Cloud Run) pause API traffic but leave resources intact. Enforcement is delayed, and overages are still billed — [Budgets](https://docs.cloud.google.com/billing/docs/how-to/budgets); [Spend caps](https://docs.cloud.google.com/billing/docs/how-to/budgets-spend-caps); [Next '26 blog](https://cloud.google.com/blog/topics/cost-management/introducing-spend-caps-ai-cost-visibility-next26/)
22. **Q: Why enable billing export on day one?**
    A: It is not fully backfilled. Multi-region datasets get only the current and previous month, and regional datasets get nothing before enablement. The standard export includes labels. Query through views, because schemas change — [Billing export](https://docs.cloud.google.com/billing/docs/how-to/export-data-bigquery)
23. **Q: How do you cut Gemini cost without hurting quality?**
    A: Several levers:
    - Route easy steps to Flash-Lite or Flash ($0.30/$2.50 or $0.75/$3.75 per 1M tokens vs $2/$12 for 3.1 Pro).
    - Use context caching (90% discount on cached input; mind the 2K–6K minimum token count).
    - Use Batch/Flex for offline work (50% off).
    - Stay under 200K tokens per prompt (the >200K tier is 2x).
    - Track scheduled price changes (e.g. 3.8 Flash doubles on 2027-01-01).
    
    — [Gemini API pricing](https://aistudio.google.com/docs/pricing); [Context cache](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview)
24. **Q: Cloud Run request-based vs instance-based billing, and the main cost lever?**
    A: Request-based bills only during requests and suits spiky traffic. Instance-based bills the whole life of the instance, needs ≥ 512 MiB, and suits steady traffic, background work and GMP scraping. Concurrency is the main lever: Google's example is $13.69/month at concurrency 20 vs $81.72 at concurrency 1 for the same 10M requests. The free tier is per billing account — [Billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings); [Cloud Run pricing](https://cloud.google.com/run/pricing)

### Inferences
- Questions 1–3, 18 and 21–24 are the most likely for a role that "records AI fees per claim" and deploys from GitLab. The learner should practice the per-claim cost calculation from Q5 out loud.

### Gaps
- The answers on Agent Platform pricing use Gemini Developer API (AI Studio) prices. Vertex/Agent Platform list prices were not readable and may differ.
- I found no source for a Cloud Deploy rollback command or an approval (`requireApproval`) answer, so those interview topics are not covered here.
