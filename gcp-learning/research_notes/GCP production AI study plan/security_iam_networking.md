# Google Cloud Security, Identity, Networking and Compliance for Production AI Apps (Health/Insurance Data)

Research date: 2026-11-06. Learner: Vietnamese AI engineer, knows Azure and self-hosted Kubernetes (RBAC, secrets, ArgoCD), zero GCP. Works for a health insurance TPA (Pacific Cross Vietnam, with Hong Kong and Philippines markets). Reference production project: one Cloud Run service per role, Cloud Tasks with OIDC-signed tasks verified by the receiving service, JWT user auth, GitLab CI deploys, calls a partner HBS system with an API key.

**Two currency warnings come first because they affect every resource below:**
1. **Docs moved.** On 2026-11-06, every `cloud.google.com/<product>/docs/...` URL I fetched returned `301 Moved Permanently` to `docs.cloud.google.com/<product>/docs/...` (for example [docs.cloud.google.com/run/docs/authenticating/service-to-service](https://docs.cloud.google.com/run/docs/authenticating/service-to-service)). Old bookmarks still work through the redirect.
2. **Vertex AI was renamed.** At Google Cloud Next '26 (April 22, 2026), Vertex AI was rebranded as **Gemini Enterprise Agent Platform** ("Agent Platform"). Vertex AI Studio became Agent Studio, the Vertex AI API became the Agent Platform API, and Agent Engine became Agent Runtime ([search summary of Google release notes and press](https://docs.cloud.google.com/gemini-enterprise-agent-platform/release-notes); [HPCwire, 2026-04-23](https://www.hpcwire.com/aiwire/2026/04/23/google-unveils-gemini-enterprise-agent-platform/)). The API host is still `aiplatform.googleapis.com` (it appears in Nov 2, 2026 release notes), but the Python agent SDK moved to `google-cloud-agentplatform` 2.0.1 with breaking namespace changes on Sept 18, 2026 ([Agent Platform release notes](https://docs.cloud.google.com/gemini-enterprise-agent-platform/release-notes)). Any course, book or blog that says "Vertex AI" is from before this change, but the security ideas (VPC-SC, CMEK, IAM roles like `roles/aiplatform.user`) are still the same.

---

## Key Question 1: IAM fundamentals done right (principals, predefined vs custom roles, least privilege, one SA per Cloud Run service, no keys, impersonation, IAM Conditions, Recommender, deny policies)

### Takeaway
Google's own pages say the same thing many times: give each workload its own user-managed service account, grant the smallest predefined role at the smallest resource scope, never create service account keys (org policy blocks them by default for orgs created after May 3, 2024), use impersonation or Workload Identity Federation instead, and use deny policies as org-wide guardrails that are checked *before* allow policies. The two best deep resources are "Best practices for using service accounts" and "Use IAM securely".

### Cited Findings

**Service accounts (the "workload identity" of GCP, similar to an Azure Managed Identity or a K8s ServiceAccount)**
- Google recommends *single-purpose* service accounts: "Use a dedicated account per application to simplify lifecycle management and traceability." Other headings on the page: manage SAs as resources, follow a naming convention, disable unused SAs before deleting them (deleting and recreating with the same name loses IAM bindings) — [Best practices for using service accounts](https://docs.cloud.google.com/iam/docs/best-practices-service-accounts)
- Privilege-escalation rules on the same page: avoid letting users impersonate more privileged SAs; don't let users create or upload SA keys; **don't grant service account access at the project or folder level** (grant `serviceAccountUser`/`TokenCreator` on the single SA instead); don't run code from less protected sources on resources with privileged SAs — [Best practices for using service accounts](https://docs.cloud.google.com/iam/docs/best-practices-service-accounts)
- Non-repudiation: "Use service account keys only when there is no viable alternative" because keys make it impossible to tell who used them; enable **Data Access logs for IAM APIs and the Security Token Service API** to record impersonation; correlate CI/CD history with Cloud Audit Logs — [Best practices for using service accounts](https://docs.cloud.google.com/iam/docs/best-practices-service-accounts)
- Also listed: use the Service Account Credentials API for temporary privilege elevation; use **Credential Access Boundaries** to downscope tokens (Cloud Storage only); use **role recommendations** to find unused permissions; use **lateral movement insights** — [Best practices for using service accounts](https://docs.cloud.google.com/iam/docs/best-practices-service-accounts)
- Org policy `iam.automaticIamGrantsForDefaultServiceAccounts` stops default SAs from automatically getting the Editor role (it does not remove existing grants). "If your organization was created on or after May 3, 2024, this constraint is enforced by default." The key-creation constraint has the same May 3, 2024 default-enforcement note; key *upload* is a separate constraint — [Best practices for using service accounts](https://docs.cloud.google.com/iam/docs/best-practices-service-accounts)
- Default service accounts: you can delete them but cannot recreate them, so disable instead if unsure — [Best practices for using service accounts](https://docs.cloud.google.com/iam/docs/best-practices-service-accounts)

**Cloud Run service identity (one SA per service)**
- If you don't set a service account, Cloud Run uses the **Compute Engine default service account**, which (depending on org policy) may have the Editor role on the project. The page "strongly recommend[s]" enforcing `iam.automaticIamGrantsForDefaultServiceAccounts`, and labels user-managed SAs as "recommended" — [Cloud Run service identity](https://docs.cloud.google.com/run/docs/securing/service-identity)
- "Never set `GOOGLE_APPLICATION_CREDENTIALS` as an environment variable on a Cloud Run service, job, or worker pool that uses service identity" — [Cloud Run service identity](https://docs.cloud.google.com/run/docs/securing/service-identity)
- The service identity (runtime SA) is separate from the deployer account (the identity calling the Cloud Run Admin API) — [Cloud Run service identity](https://docs.cloud.google.com/run/docs/securing/service-identity)
- To deploy a service that runs as an SA, the deployer needs Cloud Run Admin (`roles/run.admin`) on the service **and** Service Account User (`roles/iam.serviceAccountUser`) on the runtime SA; Cloud Run checks this at deploy time — [Cloud Run: configure secrets](https://docs.cloud.google.com/run/docs/configuring/services/secrets)

**Roles, least privilege, Conditions, Recommender**
- Avoid basic roles (Owner/Editor/Viewer) in production; use the most limited predefined role, or a custom role if none fits; use the role recommender to replace basic roles; use **Policy Simulator** to check that a change won't break access; grant at the smallest scope (e.g. one Pub/Sub topic); one SA per app component; grant roles to groups, not individuals; use **IAM Conditions** for time-limited access; grant Service Account User with caution — [Use IAM securely](https://docs.cloud.google.com/iam/docs/using-iam-securely)
- Child resources inherit allow policies from parents (org → folder → project → resource) — [Use IAM securely](https://docs.cloud.google.com/iam/docs/using-iam-securely)

**Deny policies (guardrails)**
- "IAM always checks relevant deny policies before checking relevant allow policies." Deny policies attach to an org, folder or project and apply to everything below; a higher-level deny wins even if a lower-level allow is more permissive. Limit: 500 deny policies / 500 deny rules per resource — [Deny policies overview](https://docs.cloud.google.com/iam/docs/deny-overview)
- Rule fields: `deniedPrincipals`, `exceptionPrincipals`, `deniedPermissions`, `exceptionPermissions`, `denialConditions`. Denial conditions use the IAM Conditions syntax but **only recognize resource tag functions**; if a condition can't be evaluated, the denial applies. Only some permissions can be denied — [Deny policies overview](https://docs.cloud.google.com/iam/docs/deny-overview)
- Agent Platform release notes list "IAM Unified Access Policies are GA" on Aug 31, 2026 (no detail in the fetched text) — [Agent Platform release notes](https://docs.cloud.google.com/gemini-enterprise-agent-platform/release-notes)

**Long-form opinion content on IAM**
- Cloud Security Podcast by Google episode EP199 "Your Cloud IAM Top Pet Peeves and How to Fix Them" — [player.fm listing](https://ppacc.player.fm/series/cloud-security-podcast-by-google/ep199-your-cloud-iam-top-pet-peeves-and-how-to-fix-them); show on [Apple Podcasts](https://podcasts.apple.com/us/podcast/id1554145026)

### Inferences
- Azure/K8s mapping for the learner (my mapping, not from a source): GCP *service account attached to Cloud Run* ≈ Azure *user-assigned managed identity*; GCP *IAM allow policy binding* ≈ K8s *RoleBinding* (but scoped to a resource hierarchy, not a namespace); GCP *deny policy* ≈ Azure *deny assignment*; GCP *org policy* ≈ *Azure Policy*.
- For the reference project, a clean IAM layout is: `api-sa` (public API service), `worker-sa` (task worker), `tasks-invoker-sa` (identity inside Cloud Tasks OIDC tokens, only has `roles/run.invoker` on the worker), `deployer-sa` (impersonated by GitLab CI through WIF; has `roles/run.admin` + `roles/iam.serviceAccountUser` on *each* runtime SA only, not project-wide). This follows the "single-purpose" and "don't grant SA access at project level" rules above.
- In an interview, say "least privilege = smallest role × smallest scope × shortest time (IAM Conditions)". That one sentence covers three Google recommendations.

### Gaps
- I did not fetch dedicated pages for IAM Conditions syntax, IAM Recommender/Activity Analyzer, Principal Access Boundary (PAB) policies, or Privileged Access Manager. The "Use IAM securely" page does not mention PAB or deny policies. Read `docs.cloud.google.com/iam/docs/conditions-overview`, `.../principal-access-boundary-policies`, and `.../recommender-overview` before an interview.
- The exact constraint ID for key creation (`iam.disableServiceAccountKeyCreation`, plus newer "managed" constraint variants) was not shown on the fetched page.
- I found no detail on what "IAM Unified Access Policies" (GA Aug 31, 2026) means.

---

## Key Question 2: Service-to-service authentication (Cloud Run invoker, ID tokens/OIDC, Cloud Tasks and Pub/Sub OIDC tokens and receiver verification, IAP, API Gateway, Python JWT verification)

### Takeaway
On Cloud Run, a private service is protected by IAM: the caller's SA needs `roles/run.invoker` on the receiving service and must send a Google-signed **ID token** (OIDC JWT) whose `aud` is the receiver's `run.app` URL or a configured custom audience. Cloud Tasks and Pub/Sub can mint these tokens for you. If the receiver verifies the token itself, it must check signature, `aud`, `exp`, `iss`, **and** the `email`/`email_verified` claims. Never trust `X-CloudTasks-*` headers for identity.

### Cited Findings

**Cloud Run service-to-service basics**
- Grant the *calling* service's SA `roles/run.invoker` on the *receiving* service (`gcloud run services add-iam-policy-binding`). Private services must not grant `allUsers` — [Cloud Run: service-to-service auth](https://docs.cloud.google.com/run/docs/authenticating/service-to-service)
- The caller gets a Google-signed OIDC ID token with `aud` = receiving service URL **or** a configured custom audience. **Custom domains are not accepted as `aud` values.** With traffic tags, `aud` stays the service URL — [Cloud Run: service-to-service auth](https://docs.cloud.google.com/run/docs/authenticating/service-to-service)
- Send as `Authorization: Bearer ID_TOKEN` or `X-Serverless-Authorization: Bearer ID_TOKEN`. If both are present, only `X-Serverless-Authorization` is checked by Cloud Run (useful when your app needs the `Authorization` header for its own user JWT) — [Cloud Run: service-to-service auth](https://docs.cloud.google.com/run/docs/authenticating/service-to-service); the [cloud-run-proxy PR #25](https://github.com/GoogleCloudPlatform/cloud-run-proxy/pull/25) moved to this header for exactly that reason.
- Ways to get the token: the Google auth library (`google.oauth2.id_token.fetch_id_token(auth_req, audience)`), or the metadata server `http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity?audience=AUDIENCE` with header `Metadata-Flavor: Google`. External workloads using WIF call `generateIdToken`. Tokens expire after about one hour; check `exp` if you cache them. User account credentials are not accepted — [Cloud Run: service-to-service auth](https://docs.cloud.google.com/run/docs/authenticating/service-to-service)
- Receiver-side sample (Python): parse the `Authorization` header, check the scheme is Bearer, call `google.oauth2.id_token.verify_token(...)`, read the `email` claim; errors raise `GoogleAuthError`. The Java sample checks `aud` against a `SERVICE_URL` env var and checks `email_verified` — [Cloud Run: service-to-service auth](https://docs.cloud.google.com/run/docs/authenticating/service-to-service)
- **Custom audiences**: an IAM-protected Cloud Run service can accept extra `aud` values. Use them when clients reach the service through a custom domain, or when several regional services sit behind one load balancer. Set with `gcloud run services update SERVICE --add-custom-audiences=AUDIENCE` (or the `run.googleapis.com/custom-audiences` annotation, or Terraform `custom_audiences`). The `run.app` URL "always remains as an accepted audience value". Changing it creates a new revision — [Cloud Run custom audiences](https://docs.cloud.google.com/run/docs/configuring/custom-audiences)

#### Example: caller side (adapted from the official Python sample)
```python
import requests
import google.auth.transport.requests
import google.oauth2.id_token

WORKER_URL = "https://worker-abc123-as.a.run.app"   # receiving service URL = audience

def call_worker(path: str, payload: dict) -> requests.Response:
    auth_req = google.auth.transport.requests.Request()
    token = google.oauth2.id_token.fetch_id_token(auth_req, WORKER_URL)  # uses the attached SA on Cloud Run
    return requests.post(f"{WORKER_URL}{path}", json=payload,
                         headers={"Authorization": f"Bearer {token}"}, timeout=10)
```
Source pattern: [Cloud Run: service-to-service auth](https://docs.cloud.google.com/run/docs/authenticating/service-to-service)

**Cloud Tasks OIDC tokens (matches the reference project)**
- `oidc_token.service_account_email` is required; `audience` is optional — [Cloud Tasks: create HTTP target tasks](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks)
- **Default audience:** "Audience to be used when generating OIDC token. If not specified, the URI specified in target will be used." The SA "must be within the same project as the queue", and "the caller must have iam.serviceAccounts.actAs permission for the service account" — [Cloud Tasks REST: OidcToken](https://docs.cloud.google.com/tasks/docs/reference/rest/v2/OidcToken)
- Required IAM: the enqueuing identity needs Cloud Tasks Enqueuer; the token SA needs the handler's access role (e.g. Cloud Run Invoker); the **Cloud Tasks service agent** `service-PROJECT_NUMBER@gcp-sa-cloudtasks.iam.gserviceaccount.com` needs `roles/iam.serviceAccountUser` on the token SA so it can create tokens; `roles/cloudtasks.serviceAgent` is auto-granted (manual only for projects that enabled the API before March 19, 2019) — [Cloud Tasks: create HTTP target tasks](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks)
- A queue-level `oidcToken` override takes precedence over task-level auth — [Cloud Tasks: create HTTP target tasks](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks)
- "Cloud Tasks headers such as `X-CloudTasks-QueueName` provide task information only. They should not be used to establish identity, because external requests can spoof them" — [Cloud Tasks: create HTTP target tasks](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks)
- ID tokens are for handlers like Cloud Run; OAuth access tokens are for Google APIs on `*.googleapis.com` — [Cloud Tasks: create HTTP target tasks](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks)

#### Example: enqueue a task with an explicit audience (Python, field names from the official sample)
```python
import json
from google.cloud import tasks_v2

client = tasks_v2.CloudTasksClient()
parent = client.queue_path("my-project", "asia-southeast1", "claims-queue")
task = tasks_v2.Task(
    http_request=tasks_v2.HttpRequest(
        http_method=tasks_v2.HttpMethod.POST,
        url="https://worker-abc123-as.a.run.app/tasks/process-claim",
        headers={"Content-Type": "application/json"},
        body=json.dumps({"claim_id": "C-123"}).encode(),
        oidc_token=tasks_v2.OidcToken(
            service_account_email="tasks-invoker@my-project.iam.gserviceaccount.com",
            audience="https://worker-abc123-as.a.run.app",  # set explicitly; default would be the full target URL incl. path
        ),
    )
)
client.create_task(parent=parent, task=task)
```
IAM setup (one-time):
```bash
gcloud run services add-iam-policy-binding worker --region=asia-southeast1 \
  --member="serviceAccount:tasks-invoker@my-project.iam.gserviceaccount.com" --role="roles/run.invoker"
gcloud iam service-accounts add-iam-policy-binding tasks-invoker@my-project.iam.gserviceaccount.com \
  --member="serviceAccount:service-PROJECT_NUMBER@gcp-sa-cloudtasks.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
```
Sources: [Cloud Tasks: create HTTP target tasks](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks); [OidcToken](https://docs.cloud.google.com/tasks/docs/reference/rest/v2/OidcToken)

**Pub/Sub push OIDC tokens (same JWT shape, very good verification checklist)**
- Pub/Sub signs an OIDC JWT and sends it as a Bearer token on each push; tokens may be up to an hour old — [Pub/Sub: authenticate push subscriptions](https://docs.cloud.google.com/pubsub/docs/authenticate-push-subscriptions)
- Verify: Google signature; `aud` = configured audience; `email` = the push SA; `email_verified` = true; `iss` = `accounts.google.com` or `https://accounts.google.com` (Go sample) — [Pub/Sub: authenticate push subscriptions](https://docs.cloud.google.com/pubsub/docs/authenticate-push-subscriptions)
- Python: `id_token.verify_oauth2_token(token, requests.Request(), audience=...)` checks signature, `aud`, `exp`; **you must check `email` and `email_verified` yourself** — [Pub/Sub: authenticate push subscriptions](https://docs.cloud.google.com/pubsub/docs/authenticate-push-subscriptions)
- IAM: the Pub/Sub service agent `service-{PROJECT_NUMBER}@gcp-sa-pubsub.iam.gserviceaccount.com` needs **Service Account Token Creator** on the push SA (or `iam.serviceAccounts.getOpenIdToken`); whoever creates the subscription needs `actAs` (e.g. `roles/iam.serviceAccountUser`) — [Pub/Sub: authenticate push subscriptions](https://docs.cloud.google.com/pubsub/docs/authenticate-push-subscriptions)

#### Example: receiver-side verification for Cloud Tasks / Pub/Sub tokens (combines the official checklist)
```python
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

EXPECTED_AUD = "https://worker-abc123-as.a.run.app"
ALLOWED_CALLERS = {"tasks-invoker@my-project.iam.gserviceaccount.com"}
_req = google_requests.Request()

def verify_google_oidc(authorization_header: str) -> dict:
    scheme, _, token = (authorization_header or "").partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise PermissionError("missing bearer token")
    claims = id_token.verify_oauth2_token(token, _req, audience=EXPECTED_AUD)  # signature + aud + exp (+ iss)
    if claims.get("email") not in ALLOWED_CALLERS or claims.get("email_verified") is not True:
        raise PermissionError("caller not allowed")
    return claims
```
Source checklist: [Pub/Sub: authenticate push subscriptions](https://docs.cloud.google.com/pubsub/docs/authenticate-push-subscriptions)

**Identity-Aware Proxy (IAP) for human users**
- IAP can now be enabled **directly on Cloud Run without a load balancer**, securing "all ingress paths, including default `run.app` URLs and load balancers." You cannot configure IAP on both the LB and the Cloud Run service. Cloud Run enforces IAP *before* IAM checks, so services such as Pub/Sub that rely on their own auth may fail — [IAP for Cloud Run](https://docs.cloud.google.com/run/docs/securing/identity-aware-proxy-cloud-run)
- Classic LB route: enable IAP on the backend service with `gcloud compute backend-services update BACKEND --iap=enabled,oauth2-client-id=ID,oauth2-client-secret=SECRET --global`; IAP is not compatible with Cloud CDN — [Set up global external ALB with Cloud Run](https://docs.cloud.google.com/load-balancing/docs/https/setting-up-https-serverless)

**Workforce/Workload Identity Federation cannot be granted run.invoker directly**
- Google blog (Nov 21, 2024): "The specific permission to invoke a Cloud Run instance does not support Workload Identity Federation principal and principalSets." Also: "VPC Service Controls ingress and egress rules do not support Workload Identity Federation principal and principalSets." For these, keep using SA impersonation — [Google Cloud blog: Make IAM for GKE easier with WIF](https://cloud.google.com/blog/products/identity-security/make-iam-for-gke-easier-to-use-with-workload-identity-federation)
- The GitHub `auth` action says WIF through a service account "is required if you need to generate OAuth 2.0 access tokens or ID tokens" — [google-github-actions/auth](https://github.com/google-github-actions/auth)

### Inferences
- For the reference project, the strongest design is **two layers**: (1) Cloud Run IAM (`--no-allow-unauthenticated`, only `tasks-invoker-sa` has `run.invoker` on the worker) and (2) app-level check of `email` in the claims, so that even if someone later grants `run.invoker` to another SA, the worker still only accepts the expected caller.
- Because the default Cloud Tasks audience is the *full target URI* (including path), the reference project's choice "audience = service URL/path" works for app-level verification, but setting `audience` explicitly to the base service URL (or a custom audience) is safer if you rely on Cloud Run's built-in IAM check, because the docs only promise the service URL and custom audiences as accepted `aud` values.
- If the public API uses its own user JWT in `Authorization`, and it also needs to call private services, send the Google ID token in `X-Serverless-Authorization` so the two tokens don't collide.
- `google.auth.transport.requests.Request()` fetches Google's public certs; in a hot path, reuse one `Request` object with a cached HTTP session so you don't download certs on every request (performance inference, not from a source).

### Gaps
- **Unverified, test before relying on it:** I recall that when Cloud Run's IAM check passes, the `Authorization` header forwarded to the container may have its JWT signature removed (replaced with a placeholder like `SIGNATURE_REMOVED_BY_GOOGLE`). That would make app-level `verify_oauth2_token` fail on an IAM-protected service. My search found no official page confirming or denying this. Test it in a sandbox: deploy a private service, log the header, and decide whether to (a) trust Cloud Run's check and only *decode* claims, or (b) keep the service public at the IAM layer (but internal ingress) and verify in the app.
- Not confirmed: whether Cloud Run's built-in IAM check accepts an `aud` that is the service URL **plus a path**. The docs only say "service URL or custom audience".
- API Gateway (JWT auth with `x-google-*` OpenAPI extensions) was not researched; I found only the [API Gateway load balancing page](https://cloud.google.com/api-gateway/docs/gateway-load-balancing).
- The fetched IAP page did not describe the `x-goog-iap-jwt-assertion` header or its audience format; read the IAP "Securing your app with signed headers" page.
- The IAP-on-Cloud-Run launch stage (Preview/GA) was not stated in the fetched content.

---

## Key Question 3: Workload Identity Federation (WIF) for CI/CD from GitLab and GitHub Actions without keys

### Takeaway
Both GitLab and GitHub issue OIDC tokens that Google's Security Token Service exchanges for short-lived Google credentials. Google requires an **attribute condition** that limits the pool to your group/org, because GitLab.com and GitHub each use one shared issuer for everyone. GitLab now uses the `id_tokens` keyword (the old `CI_JOB_JWT_V2` was removed in GitLab 17.0). Use direct resource access where supported; otherwise impersonate a deployer SA (needed for Cloud Run deploys that set a runtime SA, and for minting ID tokens).

### Cited Findings

**Google's official guide (best single page)**
- GitLab SaaS: issuer `https://gitlab.com`, default audience; map `google.subject=assertion.sub` (the `sub` contains project path and git ref, so you can control by repo and branch); optionally map `attribute.project_id` and `attribute.namespace_id`. Claims listed: `sub`, `namespace_id`, `project_id`, `user_id`, `environment`, `ref_path` — [WIF with deployment pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)
- **Attribute condition is required**: e.g. `assertion.namespace_id=='GROUP_ID'`, because "GitLab uses one issuer URL for all organizations"; can narrow further: `assertion.namespace_id=='GROUP_ID' && assertion.environment=='production'` — [WIF with deployment pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)
- Google recommends **direct resource access** where the API supports it and SA impersonation otherwise; grant impersonation with `roles/iam.workloadIdentityUser` to a `principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/attribute.ATTR/VALUE` member. **Use the project number, not the project ID** — [WIF with deployment pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)
- Pipeline setup: define `id_tokens` with an audience pointing to your provider, write the token to a file, create a credential configuration that reads it; use the regional STS endpoint if available — [WIF with deployment pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)
- GitHub: name fields like `repository` and `repository_owner` allow **cybersquatting/typosquatting** if a repo/org is deleted; use the numeric `repository_id` and `repository_owner_id`; optionally narrow by `assertion.ref=='refs/heads/main'` — [WIF with deployment pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)

**GitLab docs (two pages, both useful)**
- *Manual OIDC tutorial* (works for self-managed GitLab too): issuer = your GitLab URL with trailing slash; audience = same URL without slash; one pool per GitLab installation per project; job uses `id_tokens: GITLAB_OIDC_TOKEN: aud: https://gitlab.example.com`; exchange at `https://sts.googleapis.com/v1/token`, then call `generateAccessToken` on IAM Credentials API; set `CLOUDSDK_AUTH_ACCESS_TOKEN` for gcloud. "`CI_JOB_JWT_V2` was removed in GitLab 17.0." Reference project: `gitlab.com/guided-explorations/gcp/configure-openid-connect-in-gcp` — [GitLab: OIDC with GCP WIF](https://docs.gitlab.com/ci/cloud_services/google_cloud/)
- Doc quality note: in that page's second `curl` example, `Authorization: Bearer FEDERATED_TOKEN` is missing the `$` variable prefix — [GitLab: OIDC with GCP WIF](https://docs.gitlab.com/ci/cloud_services/google_cloud/)
- *Google Cloud IAM integration* (GitLab.com only, all tiers; introduced 16.10, enabled on GitLab.com in 17.1): guided setup in **Settings > Integrations > Google Cloud IAM**; issuer like `https://auth.gcp.gitlab.com/oidc/my-root-group`; rich claims (`project_path`, `namespace_path`, `maintainer_access`, `user_access_level`...); jobs use `identity: google_cloud` — [GitLab: Google Cloud IAM integration](https://docs.gitlab.com/integration/google_cloud_iam/)
- A third-party tutorial (Jan 15, 2025) shows WIF letting GitLab deploy to Cloud Run with short-lived credentials — [GitLab Cloud Run WIF tutorial (mirror)](https://awskws.duckdns.org/blog/google-cloud-integrations-for-secure-cloud-run-deployments-at-gitlab/) (mirror of an unclear original; treat as secondary)

**GitHub Actions (`google-github-actions/auth@v3`, Node 24)**
- Ranking: (1) Direct WIF (preferred; principalSet gets IAM directly; "not all Google Cloud resources support `principalSet` identities"; token ≤10 minutes), (2) WIF through a service account (required for OAuth access tokens or ID tokens), (3) SA key JSON (least preferred) — [google-github-actions/auth](https://github.com/google-github-actions/auth)
- "Always add an Attribute Condition to restrict entry into the Workload Identity Pool"; workflow needs `permissions: id-token: write`; IAM and pool changes can take up to 5 minutes to propagate — [google-github-actions/auth](https://github.com/google-github-actions/auth)

#### Example: GitLab CI job (adapted from the official steps; check exact flags in the docs)
```yaml
deploy:
  image: google/cloud-sdk:slim
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/gitlab/providers/gitlab-com
  script:
    - echo "$GITLAB_OIDC_TOKEN" > .ci_job_jwt_file
    - gcloud iam workload-identity-pools create-cred-config
        projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/gitlab/providers/gitlab-com
        --service-account=deployer@my-project.iam.gserviceaccount.com
        --credential-source-file=.ci_job_jwt_file
        --output-file=.gcp_cred.json
    - gcloud auth login --cred-file=.gcp_cred.json
    - gcloud run deploy worker --image=$IMAGE --region=asia-southeast1
        --service-account=worker-sa@my-project.iam.gserviceaccount.com --no-allow-unauthenticated
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```
Provider condition example: `assertion.namespace_id=='GROUP_ID' && assertion.ref=='main' && assertion.ref_protected=='true'` (the `ref`/`ref_protected` claims are my assumption from GitLab's ID-token payload; Google's page only shows `namespace_id` and `environment`). Sources: [WIF with deployment pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines); [GitLab OIDC with GCP](https://docs.gitlab.com/ci/cloud_services/google_cloud/)

### Inferences
- Because Cloud Run's invoke permission doesn't accept principalSets ([Google blog](https://cloud.google.com/blog/products/identity-security/make-iam-for-gke-easier-to-use-with-workload-identity-federation)), and `gcloud run deploy --service-account=...` needs `actAs` on the runtime SA, the practical GitLab pattern is **WIF → impersonate one `deployer-sa`**. Direct WIF is fine for simpler things like pushing to Artifact Registry.
- Interview phrasing: "No JSON keys in GitLab variables. GitLab issues a short-lived OIDC JWT per job; Google STS validates issuer, audience and my attribute condition, then returns a short-lived token. Every deploy shows up in audit logs as the deployer SA, linked to the GitLab job." (Correlating CI history with audit logs is a Google recommendation — [SA best practices](https://docs.cloud.google.com/iam/docs/best-practices-service-accounts).)

### Gaps
- I did not verify a Google page listing the exact GitLab claim names `ref`, `ref_type`, `ref_protected`, `project_path` in the attribute-condition context; GitLab's own ID-token payload docs should be checked.
- Self-managed GitLab behind a firewall: STS must reach the issuer's JWKS endpoint (or you upload JWKS). Not researched.

---

## Key Question 4: Secret Manager with Cloud Run (env var vs volume mount, versions, rotation)

### Takeaway
Env-var secrets are read once at instance start (pin a specific version); volume-mounted secrets are fetched on read and follow `latest`, so they suit rotation. Secret Manager does **not** rotate secrets itself; it only sends `SECRET_ROTATE` Pub/Sub messages on a schedule, and you build the rotation worker.

### Cited Findings
- **Env vars:** "Environment variables are resolved at instance startup time." If retrieval fails, the instance doesn't start. Google recommends pinning env-var secrets to a specific version, not `latest`. A rotated value is not picked up until instances restart — [Cloud Run: configure secrets](https://docs.cloud.google.com/run/docs/configuring/services/secrets)
- **Volumes:** not resolved at startup; Cloud Run fetches from Secret Manager on read, default `latest`, "works well with secret rotation"; if the secret becomes inaccessible at runtime, reads of the file fail — [Cloud Run: configure secrets](https://docs.cloud.google.com/run/docs/configuring/services/secrets)
- **IAM:** the runtime SA needs `roles/secretmanager.secretAccessor` on the secret (grant on the single secret, not project-wide); deployers need `roles/run.admin` + `roles/iam.serviceAccountUser` on the runtime SA — [Cloud Run: configure secrets](https://docs.cloud.google.com/run/docs/configuring/services/secrets)
- **Cross-project:** reference `projects/PROJECT_NUMBER/secrets/SECRET_NAME` — [Cloud Run: configure secrets](https://docs.cloud.google.com/run/docs/configuring/services/secrets)
- **Rotation:** Secret Manager "only sends notifications", publishing `SECRET_ROTATE` to the secret's Pub/Sub topics at `next_rotation_time` / every `rotation_period` (≥1 hour; first time ≥5 minutes in the future). "You must configure a Pub/Sub subscriber to receive and act on the `SECRET_ROTATE` messages"; failed sends are retried up to 7 days; scheduled rotations are skipped if one is in flight — [Secret Manager: rotation](https://docs.cloud.google.com/secret-manager/docs/secret-rotation)
- **CMEK:** Secret Manager supports CMEK for secret payloads — [Cloud KMS: CMEK compatible services](https://docs.cloud.google.com/kms/docs/compatible-services)
- **Hands-on:** the Next '26 codelab "The ultimate Cloud Run guide from zero to production" includes a Secret Manager section with a dedicated SA and `secretAccessor` — [Codelab](https://codelabs.developers.google.com/next26/ultimate-cloud-run-guide)

#### Example: partner HBS API key
```bash
printf '%s' "$HBS_KEY" | gcloud secrets create hbs-api-key --data-file=- --replication-policy=user-managed --locations=asia-southeast1
gcloud secrets add-iam-policy-binding hbs-api-key \
  --member="serviceAccount:worker-sa@my-project.iam.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"
# Option A: env var pinned to version 3 (restart/redeploy to rotate)
gcloud run deploy worker ... --set-secrets=HBS_API_KEY=hbs-api-key:3
# Option B: file mount following latest (app re-reads the file; good for rotation)
gcloud run deploy worker ... --set-secrets=/secrets/hbs/key=hbs-api-key:latest
```
Behavior sources: [Cloud Run: configure secrets](https://docs.cloud.google.com/run/docs/configuring/services/secrets) (the `--replication-policy`/`--locations` flags are standard gcloud flags, not shown on the fetched page)

### Inferences
- For a partner API key that the partner rotates manually, Option A (env var pinned to a version + redeploy through GitLab) is simpler and gives an audit trail per deploy. Option B is better if you want rotation without redeploy, but the app must re-read the file (not cache forever).
- K8s mapping: env-var secret ≈ `envFrom: secretRef` (read at pod start); volume secret ≈ mounted Secret volume (but Cloud Run reads it from Secret Manager on access, there is no etcd copy).
- User-managed replication in `asia-southeast1` keeps the secret payload in Singapore, which helps data-residency stories (inference; check Secret Manager locations docs).

### Gaps
- The fetched page did not discuss version aliases, disabling/destroying old versions, or Secret Manager regional secrets vs global secrets; read `docs.cloud.google.com/secret-manager/docs/best-practices`.

---

## Key Question 5: Networking for serverless (Direct VPC egress vs connector, Private Google Access, Private Service Connect, internal ingress, Cloud NAT static egress IP, Cloud Armor + LB in front of Cloud Run)

### Takeaway
Use **Direct VPC egress** (recommended, GA, no VM cost) to put Cloud Run traffic into your VPC; add **Cloud NAT with a reserved static IP** and `--vpc-egress=all-traffic` when a partner (like HBS) whitelists IPs. Lock down inbound with **ingress settings** (`internal` for workers, `internal-and-cloud-load-balancing` for the public API behind an external Application Load Balancer + **Cloud Armor**). Ingress controls the network path; IAM controls identity; use both.

### Cited Findings

**Direct VPC egress vs Serverless VPC Access connector**
- Direct VPC egress is labeled "(recommended)". Comparison: cost (Direct = network egress only; connector = Compute Engine VM charges + egress), latency (Direct lower), throughput (Direct higher), IP usage (Direct uses more IPs), scaling (Direct scales slower, including from zero, because new network interfaces must be created), network tags (Direct per-service; connector shared), spend caps (Direct supported; connector not), maintenance (Direct none). Both GA; neither supports Cloud NGFW Enterprise L7 inspection — [Cloud Run: connect to a VPC](https://docs.cloud.google.com/run/docs/configuring/connecting-vpc)

**Static outbound IP for an IP-allowlisting partner**
- Steps: create a Cloud Router in the service's region; reserve a static external IP (`gcloud compute addresses create --region=REGION`); create a Cloud NAT gateway with `--nat-custom-subnet-ip-ranges` and `--nat-external-ip-pool` (Terraform: `MANUAL_ONLY`); deploy with Direct VPC egress (`--network --subnet --vpc-egress=all-traffic`) or a connector (`--vpc-connector --vpc-egress=all-traffic`); verify with an IP-echo service — [Cloud Run: static outbound IP](https://docs.cloud.google.com/run/docs/configuring/static-outbound-ip)
- Caveats: default egress IPs are dynamic and shared; one IP in manual mode can run out of ports under many instances/connections (add IPs, raise min ports per VM, or use dynamic port allocation); Cloud NAT is control-plane only (no extra hop); a reserved IP persists until you release it — [Cloud Run: static outbound IP](https://docs.cloud.google.com/run/docs/configuring/static-outbound-ip)

**Ingress settings and default URL**
- `all` (internet allowed), `internal` (internal ALBs, same-project VPCs, the Shared VPC the service sends traffic to, and listed Google products), `internal-and-cloud-load-balancing` (internal + external ALB; direct `run.app` internet requests blocked) — [Cloud Run ingress](https://docs.cloud.google.com/run/docs/securing/ingress)
- Internal also includes on-prem over Cloud VPN/Interconnect, and **Cloud Scheduler, Cloud Tasks, Eventarc, Pub/Sub, Workflows when in the same project or VPC-SC perimeter and using the default `run.app` URL** (not a custom domain) — [Cloud Run ingress](https://docs.cloud.google.com/run/docs/securing/ingress)
- You can disable the `run.app` URL (`--no-default-url`), but that breaks Cloud Scheduler, Cloud Tasks, Pub/Sub, Eventarc and Workflows integrations that call it — [Cloud Run ingress](https://docs.cloud.google.com/run/docs/securing/ingress)
- "IAM authentication still applies to requests from every ingress path"; Google recommends both layers — [Cloud Run ingress](https://docs.cloud.google.com/run/docs/securing/ingress)

**Private access patterns**
- Make a service private with `internal` ingress (enforce org-wide with `run.allowedIngress`). Reach it from a VPC via Private Google Access on the source subnet (requests show `remoteIp` 0.0.0.0), a Private Service Connect endpoint + private DNS zone for `run.app`, an internal ALB, or publish via PSC — [Cloud Run private networking](https://docs.cloud.google.com/run/docs/securing/private-networking)
- For Cloud Run to reach Google APIs privately: `all-traffic` egress + Private Google Access on the Direct VPC egress subnet; DNS for `run.app` → `private.googleapis.com` (199.36.153.8/30) or `restricted.googleapis.com` (199.36.153.4/30) — [Cloud Run private networking](https://docs.cloud.google.com/run/docs/securing/private-networking)
- VPC peering with a network outside your project does **not** make traffic internal — [Cloud Run private networking](https://docs.cloud.google.com/run/docs/securing/private-networking)

**External ALB + Cloud Armor + (optional) IAP in front of Cloud Run**
- Steps: reserve a global static IPv4 (Premium tier) → Google-managed SSL cert → serverless NEG (`--network-endpoint-type=serverless --cloud-run-service=...`, same region as service) → global backend service → URL map → HTTPS proxy → forwarding rule on 443 → DNS A record — [Global external ALB with Cloud Run](https://docs.cloud.google.com/load-balancing/docs/https/setting-up-https-serverless)
- Attach a Cloud Armor security policy to the backend service; the console offers a default rate-limit policy (1–10,000 requests per interval, keyed by all traffic, IP, or X-Forwarded-For IP) — [Global external ALB with Cloud Run](https://docs.cloud.google.com/load-balancing/docs/https/setting-up-https-serverless)
- Set Cloud Run ingress to "Internal and Cloud Load Balancing", otherwise users can hit the default URL and **bypass Cloud Armor**; you can also disable the default URL — [Global external ALB with Cloud Run](https://docs.cloud.google.com/load-balancing/docs/https/setting-up-https-serverless)
- Limits: no health checks for serverless NEGs; one serverless NEG per region per backend service; Google-managed cert provisions only after DNS points to the LB (migration can cause <1h downtime) — [Global external ALB with Cloud Run](https://docs.cloud.google.com/load-balancing/docs/https/setting-up-https-serverless)
- LB-to-serverless-NEG traffic uses special routes outside your VPC, so firewall rules don't apply — [Portuguese version of the regional ALB guide](https://docs.cloud.google.com/load-balancing/docs/https/setting-up-reg-ext-https-serverless?hl=pt)

**Hands-on**
- Next '26 codelab covers "Connect to a VPC": a private backend with internal ingress + required auth, a frontend with Direct VPC egress, and `run.invoker` granted to the frontend SA — [Codelab: ultimate Cloud Run guide](https://codelabs.developers.google.com/next26/ultimate-cloud-run-guide)
- Skills Boost skill badge "Build a Secure Google Cloud Network" — conflicting durations seen (6h45m vs 1h15m) — [Skills Boost course 654](https://www.cloudskillsboost.google/course_templates/654)

### Inferences
- Reference architecture for the TPA project (asia-southeast1):
  - `api` service: ingress `internal-and-cloud-load-balancing`, behind global external ALB + Cloud Armor (WAF + rate limit), app validates the user JWT.
  - `worker` service: ingress `internal`, `--no-allow-unauthenticated`, invoked only by Cloud Tasks (same project, `run.app` URL, so it counts as internal).
  - `hbs-gateway` (or the worker): Direct VPC egress `all-traffic` → Cloud NAT with 1–2 reserved IPs → partner HBS. Give HBS those IPs to whitelist, and still send the API key.
- Azure mapping: Direct VPC egress ≈ App Service/Container Apps VNet integration; Cloud NAT static IP ≈ Azure NAT Gateway; PSC endpoint ≈ Private Endpoint; Cloud Armor + global ALB ≈ Front Door + WAF.
- Older tutorials (pre-2024) show only Serverless VPC Access connectors; treat that as outdated unless you need a connector-specific feature.

### Gaps
- I did not fetch the Cloud Armor preconfigured WAF rules (OWASP CRS) page or Adaptive Protection docs.
- Not researched: Cloud Run + internal ALB for private APIs across projects, and Cloud NGFW for egress FQDN filtering.

---

## Key Question 6: Protecting sensitive data for AI: VPC Service Controls, CMEK, Sensitive Data Protection (de-identify before LLM calls), data residency in asia-southeast1, Agent Platform (Vertex AI) data governance, Claude on Google Cloud

### Takeaway
VPC Service Controls (VPC-SC) protects Agent Platform (`aiplatform.googleapis.com`), BigQuery and Sensitive Data Protection against data exfiltration. Cloud Run inside a perimeter needs internal ingress, `all-traffic` egress and restricted-VIP DNS. CMEK exists for Vertex/Agent Platform, BigQuery, GCS, Firestore, Secret Manager, Cloud Tasks and more, but **not** for Gemini durable caching. Google says it won't train on your data without permission. Gemini caches data for up to 24h by default, and you can turn that off per project. Abuse-monitoring logs depend on the model and contract (Claude Fable/Mythos: logged up to 30 days, so ZDR may not be possible). For Singapore residency, use a regional endpoint, never `global`, and check model-by-model support.

### Cited Findings

**VPC Service Controls**
- Supported (GA, protectable by perimeters): Gemini Enterprise Agent Platform (`aiplatform.googleapis.com`), BigQuery, Sensitive Data Protection (`dlp.googleapis.com`) — [VPC-SC supported products](https://docs.cloud.google.com/vpc-service-controls/docs/supported-products)
- SDP inside perimeters can return 403 for org-level resources (perimeters don't support folder/org resources) — [VPC-SC supported products](https://docs.cloud.google.com/vpc-service-controls/docs/supported-products)
- Cloud Run + VPC-SC: add the Cloud Run Admin API as a restricted service; add an ingress policy so developers/CI outside the perimeter can deploy; org policies `run.allowedIngress` (only `internal` or `internal-and-cloud-load-balancing`) and `run.allowedVPCEgress` (only `all-traffic`); use Direct VPC egress or connector with all traffic; "Setting ingress to 'all' disables VPC Service Controls enforcement" — [Cloud Run with VPC-SC](https://docs.cloud.google.com/run/docs/securing/using-vpc-service-controls)
- Network setup: Private Google Access on subnets; deny-all egress firewall rule; allow `199.36.153.4/30` TCP 443; Cloud DNS response policy mapping `*.googleapis.com` and `*.run.app` to `restricted.googleapis.com` — [Cloud Run with VPC-SC](https://docs.cloud.google.com/run/docs/securing/using-vpc-service-controls)
- Limits: continuous deployment isn't available in a perimeter; Artifact Registry must be in the same perimeter; **ingress rules using IAM principals aren't supported for Cloud Run (only `ANY_IDENTITY`)**; existing services keep serving until redeployed after org-policy changes — [Cloud Run with VPC-SC](https://docs.cloud.google.com/run/docs/securing/using-vpc-service-controls)
- VPC-SC ingress/egress rules do not support WIF principals/principalSets — [Google blog, Nov 2024](https://cloud.google.com/blog/products/identity-security/make-iam-for-gke-easier-to-use-with-workload-identity-federation)
- 2026 Agent Platform changes: Agent Gateway enforces VPC-SC for deployments created after Sept 8, 2026; Computer Use/Shell sandboxes support VPC-SC + PSC (Sept 9) — [Agent Platform release notes](https://docs.cloud.google.com/gemini-enterprise-agent-platform/release-notes)

**CMEK / Cloud KMS**
- CMEK integrations table includes: Vertex AI/Agent Platform ("data associated with resources"), BigQuery, Cloud Storage, Firestore, Cloud Run (**container image only**), Secret Manager (payloads), Cloud SQL (backups separate row), Artifact Registry, Pub/Sub, Cloud Tasks (task body/header at rest), Cloud Logging (Log Router and storage, separate rows). All listed support software and HSM keys and EKM — [Cloud KMS: CMEK compatible services](https://docs.cloud.google.com/kms/docs/compatible-services)
- "Customer-managed encryption keys (CMEK) aren't supported for durable caching" in Gemini — [Agent Platform data governance](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/data-governance)
- CMEK cannot be used if Memory Bank or Sessions use the global endpoint (June 17, 2026); CMEK now protects supervised fine-tuning jobs and tuned models (Oct 19, 2026) — [Agent Platform release notes](https://docs.cloud.google.com/gemini-enterprise-agent-platform/release-notes)
- Gen-AI security-controls table: online prediction and context caching mostly "Yes" for data residency, CMEK, VPC-SC, Access Transparency; batch inference often "No" for CMEK/AXT; Grounding with Google Search/Maps "No" for all four; "Security controls are not supported for preview models" — [Gen AI security controls](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/security-controls)

**Agent Platform (Vertex AI) data governance and zero data retention (ZDR)**
- "Google won't use your data to train or fine-tune any AI/ML models without your prior permission or instruction." Applies to all managed models including pre-GA — [Agent Platform data governance](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/data-governance)
- "By default, Google's published Gemini models cache Customer Data." In-memory cache: deleted ≤24h after write. Durable cache: ≤24h, often sooner. Turn off all caching with a PATCH to the project `cacheConfig` with `"disableCache": true` (needs `roles/aiplatform.admin`); turn off only durable caching with `retentionType: EPHEMERAL`; settings apply to all regions; org-wide durable-cache disable needs the account team — [Agent Platform data governance](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/data-governance); [ZDR page](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/vertex-ai-zero-data-retention)
- Other ZDR switches: request-response logging is off by default ("To achieve zero data retention, do not enable this feature"); Interactions API `store` defaults to `true` — set `store=false`; Live API session resumption off by default (stores up to 24h if enabled); Grounding with Google Search keeps logs up to 3 days and cannot be disabled (use Web Grounding for Enterprise for ZDR); Grounding with Google Maps keeps data 30 days; Deep Research / CodeMender sessions keep 7 days — [ZDR page](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/vertex-ai-zero-data-retention)
- **Abuse monitoring:** standard Google models log prompts only when safety classifiers flag activity, kept up to **90 days**; Frontier Models (e.g. "Gemini 4 Argon (Cyber Permissive)") up to 30 days inside the customer's environment; **Advanced AI models (Claude Mythos, Claude Fable, and Claude Opus ≥4.7 / Sonnet ≥5 when `advanced_ai_enabled=true` for Anthropic's Cyber Verification Program): all prompts and responses logged, up to 30 days**; for Claude Fable 5 and Mythos 5, customers must enable sharing this data with Anthropic. **Customers with a Google Cloud Master Agreement are exempt by default** from prompt logging for standard Google models. "Zero data retention may not be possible when using some Advanced AI features." — [Abuse monitoring](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/abuse-monitoring)
- Older guidance (still in search snippets) says customers "can request an exception by filling out a form"; the current page describes no form, only the Master Agreement default exemption and "contact your account team" — [Abuse monitoring](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/abuse-monitoring). **Flag: older blog posts about the opt-out form are outdated.**
- June 2, 2026 release note: abuse-monitoring/ZDR docs updated, including request-response logging for certain partner models — [Agent Platform release notes](https://docs.cloud.google.com/gemini-enterprise-agent-platform/release-notes)
- "Customer prompts and model responses are not shared with third-parties when using the Vertex AI API, including partner models" (search-snippet wording from Google's abuse-monitoring page; not re-confirmed in the fetched current version) — [Abuse monitoring](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/abuse-monitoring?authuser=7)

**Claude on Google Cloud**
- Two offerings now exist: "Claude Models on Google Cloud (Google managed)" (Agent Platform, `AnthropicVertex` client, `aiplatform.googleapis.com ...:rawPredict`) and "Anthropic managed" (`claude.googleapis.com`, `AnthropicGoogleCloud` client) — [Anthropic docs: Claude Models on Google Cloud (Google managed)](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/google-managed)
- For the Google-managed offering, "Google Cloud governs data handling"; IAM needs `aiplatform.endpoints.predict` (e.g. `roles/aiplatform.user`); turning on request-response logging "doesn't give Google or Anthropic any access to your content"; Anthropic recommends keeping ≥30 days of logs — [Anthropic docs](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/google-managed)
- Endpoints: **Global** (recommended for availability; requests go to any region), **Multi-region** `us`/`eu`, **Regional** (e.g. `us-east5`). Multi-region and regional cost **10% more**. "Regional endpoints serve Claude Sonnet 4.6 and earlier models only. For newer models, use a global or multi-region endpoint." Request payload limit 30 MB — [Anthropic docs](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/google-managed)
- Google's Claude page: optional 30-day request-response logging; metadata-only logging (token counts, latency, errors) without prompts; "operates within the Google Cloud FedRAMP High authorization boundary"; "Anthropic models are not a Google product" (Separate Offerings terms) — [Google: Claude on Agent Platform](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/partner-models/claude)
- Inference request metadata logging (metadata only) became GA Oct 30, 2026 — [Agent Platform release notes](https://docs.cloud.google.com/gemini-enterprise-agent-platform/release-notes)
- Vertex runs a CSAM classifier on requests to all hosted Anthropic models, separate from Anthropic's own filters — [search snippet of Google Claude safety page](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/partner-models/claude/safety?hl=zh-cn)

**Data residency (Singapore asia-southeast1)**
- Data at rest stays in the selected location regardless of endpoint. ML processing location follows the endpoint: `us`/`eu` multi-region endpoints keep processing in that jurisdiction; single-region endpoints keep it within the region's broader jurisdiction; **global endpoints give no residency guarantees**. No `asia` multi-region endpoint is described — [Gen AI data residency](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/data-residency)
- Singapore ML processing listed for: Gemini 4 Argon, Gemini 3.5 Flash, Gemini 2.5 Flash (128k and 1M). Not listed: Gemini 3.5 Flash-Lite, Gemini 2.5 Pro. Claude in Singapore listed for some versions (e.g. Opus 5.5, Sonnet 5.5, Sonnet 5, Opus 5, Opus 4.5, Opus 4.6) but **not** Sonnet 4.6 — [Gen AI data residency](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/data-residency); **contradicted by** Anthropic's statement that regional endpoints serve only Sonnet 4.6 and earlier — [Anthropic docs](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/google-managed). Confirm in Model Garden for your project before designing.
- Assured Workloads offers a **Singapore Data Boundary** and a **Hong Kong Data Boundary** (plus Australia, India, Indonesia, Japan, etc.) — [Assured Workloads supported products](https://docs.cloud.google.com/assured-workloads/docs/supported-products). The Singapore package lists Generative AI on Vertex AI, batch prediction and model monitoring (`aiplatform.googleapis.com`) and is in the free tier — [Singapore Data Boundary (JA)](https://docs.cloud.google.com/assured-workloads/docs/control-packages/singapore-data-boundary?hl=ja)

**Sensitive Data Protection (SDP, formerly Cloud DLP) and Model Armor**
- `content:deidentify` (`POST https://dlp.googleapis.com/v2/projects/PROJECT_ID/content:deidentify`) takes the text, an `InspectConfig` (infoTypes to find) and a `DeidentifyConfig` (transformations), and returns the same structure with sensitive parts transformed — [SDP: de-identify](https://docs.cloud.google.com/sensitive-data-protection/docs/deidentify-sensitive-data)
- Transformations: redaction (`redactConfig`), replacement (`replaceConfig`, e.g. `[EMAIL_ADDRESS]`), character masking, cryptographic hashing (pseudonymization with a 32/64-byte key), date shifting (keeps order and intervals, per person), tokenization/encryption with surrogates — [SDP: de-identify](https://docs.cloud.google.com/sensitive-data-protection/docs/deidentify-sensitive-data)
- infoTypes: `HONG_KONG_ID_NUMBER` exists; `MEDICAL_DATA` covers medical content but **excludes medical IDs**; no Vietnam-specific or Philippines-specific infoTypes were found; call `infoTypes.list` for the current list — [SDP infoTypes reference](https://docs.cloud.google.com/sensitive-data-protection/docs/infotypes-reference?hl=id); [high-sensitivity infoTypes](https://docs.cloud.google.com/sensitive-data-protection/docs/high-sensitivity-infotypes-reference)
- **Model Armor** screens prompts and responses; basic mode only inspects a fixed list of infoTypes; **advanced mode uses SDP inspect + de-identify templates** to redact/transform PII in prompts and responses — [Model Armor overview](https://docs.cloud.google.com/model-armor/overview?hl=en); hands-on lab (create `ma-inspect-template`, `ma-deidentify-template`, link via `advancedConfig`) — [Skills Boost lab 32261](https://www.skills.google/catalog_lab/32261)
- Model Armor for Agent Gateway GA June 24, 2026 — [Agent Platform release notes](https://docs.cloud.google.com/gemini-enterprise-agent-platform/release-notes)

### Inferences
- A safe LLM call path for claims/medical text: `worker` reads claim → SDP `content:deidentify` (replace names, ID numbers, phone, email with typed placeholders; date-shift dates; custom regex infoTypes for Vietnamese CCCD/CMND, PhilHealth and policy numbers) → call Gemini or Claude on a **regional** endpoint → re-identify only if needed with a reversible crypto transform. Model Armor (advanced) can add the same SDP step plus prompt-injection filtering at the gateway.
- For a strict "Singapore only" story: Agent Platform regional endpoint `asia-southeast1`; turn caching off with `disableCache`; keep request-response logging off; no Grounding with Google Search; check the Master Agreement status for abuse-monitoring exemption; avoid Claude Fable/Mythos if you need ZDR.
- Mapping from Azure: VPC-SC has no exact Azure twin (closest: Private Endpoints + "deny public network access" + Azure Policy), which is why interviewers like to ask about it.

### Gaps
- Not confirmed which Claude versions are actually callable in `asia-southeast1` today, because Google's residency table conflicts with Anthropic's endpoint note.
- Not confirmed whether Cloud Run, Cloud Tasks and Secret Manager are in the Singapore Data Boundary package (table truncated).
- I did not find Google SDP infoTypes for Vietnam or Philippines IDs; custom infoTypes would be needed (custom infoTypes are a standard SDP feature, but I did not fetch that page).
- The SDP de-identify page truncated before details of deterministic encryption, FPE, and KMS-wrapped keys. Read `.../pseudonymization` and `.../transformations-reference`.
- Whether the ~90-day abuse-monitoring log applies to partner models outside the Advanced AI list is not stated.

---

## Key Question 7: Organization policies and audit logs (guardrails and evidence)

### Takeaway
Org policies are the "Azure Policy" of GCP: enforce no SA keys, no default-SA Editor grants, internal-only Cloud Run ingress and all-traffic egress. Audit logs: Admin Activity and System Event are always on; **Data Access logs are off by default (except BigQuery)** and must be enabled for PHI access evidence.

### Cited Findings
- Constraints seen in official docs: `iam.automaticIamGrantsForDefaultServiceAccounts` (default-enforced for orgs created on/after May 3, 2024), SA key creation/upload constraints — [SA best practices](https://docs.cloud.google.com/iam/docs/best-practices-service-accounts); `run.allowedIngress`, `run.allowedVPCEgress` (enforced at deploy/traffic changes; old revisions keep serving until redeployed) — [Cloud Run with VPC-SC](https://docs.cloud.google.com/run/docs/securing/using-vpc-service-controls); resource location constraint enforced by Agent Registry (June 18, 2026) — [Agent Platform release notes](https://docs.cloud.google.com/gemini-enterprise-agent-platform/release-notes)
- Audit log types: **Admin Activity** (always written, can't disable), **System Event** (always, can't disable), **Data Access** ("Except for BigQuery, Data Access audit logs are disabled by default"), **Policy Denied** (on by default, can exclude from storage). `_Required` bucket holds Admin Activity + System Event (can't change); `_Default` holds Data Access + Policy Denied. Aggregated sinks route logs from child resources of orgs/folders. Enabling Data Access logs may add cost — [Cloud Audit Logs overview](https://docs.cloud.google.com/logging/docs/audit)
- Google recommends enabling Data Access logs for IAM APIs and STS to trace impersonation — [SA best practices](https://docs.cloud.google.com/iam/docs/best-practices-service-accounts)
- HIPAA guidance: don't put PHI or credentials in resource metadata, logs, monitoring labels or alert configs — [Google Cloud HIPAA](https://docs.cloud.google.com/docs/security/compliance/hipaa)
- The enterprise foundations blueprint centralizes security and audit logs with aggregated sinks to a central project — [Enterprise foundations blueprint](https://docs.cloud.google.com/architecture/security-foundations)

### Inferences
- Minimum org-policy set for this project (my synthesis): disable SA key creation + upload; disable automatic default-SA grants; `gcp.resourceLocations` limited to Singapore (and HK if needed); `run.allowedIngress` = internal / internal-and-cloud-load-balancing; `run.allowedVPCEgress` = all-traffic; `iam.allowedPolicyMemberDomains` = your Cloud Identity domain. (`gcp.resourceLocations` and `iam.allowedPolicyMemberDomains` are standard constraints I did not fetch this session.)
- Turn on Data Access logs for Agent Platform, Cloud Storage, Secret Manager, Firestore and IAM/STS, and route them with an aggregated sink to a locked logging project. Never log raw prompts that contain PHI.

### Gaps
- Retention periods (commonly `_Required` 400 days, `_Default` 30 days) were not stated on the fetched page; check "Quotas and limits: Logs retention periods".
- No full list of Cloud Run / Agent Platform org-policy constraints was fetched.

---

## Key Question 8: Healthcare and regional compliance (HIPAA guidance, Vietnam PDPL 91/2025, Hong Kong PDPO, Philippines Data Privacy Act) at the cloud-architecture level

### Takeaway
Google's HIPAA page is the best "healthcare on GCP" reference: shared responsibility, a BAA that covers named products (Cloud Run, BigQuery, Cloud Storage, Secret Manager, Gemini Enterprise Agent Platform), and practical rules like "disable unsupported services for PHI". Vietnam's PDPL (Law 91/2025/QH15, effective Jan 1, 2026, with Decree 356/2025) adds transfer-impact and DPIA filings, a 72-hour breach notice and fines up to 5% of revenue. Hong Kong's PCPD issued updated cloud guidance in Jan 2025. In the Philippines, health is "sensitive personal information" with 72-hour breach notice and outsourcing contract rules. None of these laws gives cloud-specific technical controls, so you map them to GCP controls yourself.

### Cited Findings

**HIPAA on Google Cloud**
- "Complying with HIPAA is a shared responsibility between you and Google." HHS has no HIPAA certification. You decide if you're a Covered Entity or Business Associate; you configure and secure your environment; disable unsupported services for PHI; avoid PHI in metadata/logs/labels/alerts — [Google Cloud HIPAA](https://docs.cloud.google.com/docs/security/compliance/hipaa)
- BAA covers the whole infrastructure (all regions) plus named products; listed: BigQuery, Cloud Storage, Secret Manager, Cloud Run, Cloud SQL, Gemini Enterprise Agent Platform, Generative AI on Agent Platform, Vertex AI Workbench. Product list updated 2025-09-17 (Cloud) and 2026-10-28 (Workspace) — [Google Cloud HIPAA](https://docs.cloud.google.com/docs/security/compliance/hipaa); BAA text at [cloud.google.com/terms/hipaa-baa](https://cloud.google.com/terms/hipaa-baa)

**Vietnam: Law on Personal Data Protection No. 91/2025/QH15**
- Effective Jan 1, 2026, with Decree No. 356/2025/ND-CP (dated Dec 31, 2025) replacing Decree 13/2023 — [Allen & Gledhill](https://www.allenandgledhill.com/vn/publication/articles/31075/upcoming-changes-to-vietnam-s-personal-data-protection-regime); [Tilleke & Gibbins, Aug 27, 2025 (updated)](https://tilleke.com/insights/vietnams-new-personal-data-protection-law-a-closer-look)
- Breach reporting "within 72 hours of detection" (the clock now starts at detection). Cross-border transfer violations: up to 5% of prior-year revenue, floor VND 3 billion. TIA and DPIA must be updated every six months if anything changes; TIAs filed with A05 before Jan 1, 2026 stay valid. Small businesses/startups get a 5-year optional period, but **not** if they directly process sensitive data or provide processing services — [Tilleke & Gibbins](https://tilleke.com/insights/vietnams-new-personal-data-protection-law-a-closer-look)
- Health and insurance are named as sectors with tailored safeguards; cloud computing and AI are listed as sectors with tailored safeguards, but no specific rules are given in the article — [Tilleke & Gibbins](https://tilleke.com/insights/vietnams-new-personal-data-protection-law-a-closer-look)
- The cross-border transfer impact assessment is described as "not an approval type of procedure" but may lead to restrictions; sources disagree on timing (within 60 days of first transfer vs. from date of transfer) and recipient (A05 vs MPS) — [search summary of law-firm briefs incl. FPF](https://fpf.org/blog/fpf-releases-issue-brief-on-vietnams-law-on-protection-of-personal-data-and-the-law-on-data/)
- A TIA exemption exists for storing **employees'** personal data on cloud computing services; it does not cover customer/patient data — [search summary (Baker McKenzie / others)](https://connectontech.bakermckenzie.com/?p=5530)

**Hong Kong: PDPO + PCPD Guidance on Cloud Computing (updated Jan 2025)**
- Recommends robust logging, user configuration, encryption in transit and at rest, MFA, contract clauses for data erasure/return; verify provider safeguards via declarations or audit reports; require providers and sub-contractors to report breaches promptly; outsourcing doesn't reduce the data user's legal obligation; inform data subjects when data goes outside Hong Kong (DPP 1). Triggered by the Urban Renewal Authority breach (DPP 4(1)) — [Mayer Brown, Apr 2025](https://www.mayerbrown.com/zh-hans/insights/publications/2025/04/urban-renewal-authority-data-breach-incident-prompts-update-of-guidance-on-cloud-computing-by-the-privacy-commissioner-for-personal-data-in-hong-kong); [Digital Policy Alert](https://digitalpolicyalert.org/event/25922-adopted-pcpd-updated-guidance-on-cloud-computing-explaining-the-relevant-requirements-of-the-personal-data-privacy-ordinance); PCPD PDF [IL_cloud_e.pdf](https://pcpd.org.hk/english/resources_centre/publications/files/IL_cloud_e.pdf)
- Assured Workloads has a Hong Kong Data Boundary control package — [Assured Workloads supported products](https://docs.cloud.google.com/assured-workloads/docs/supported-products)

**Philippines: Data Privacy Act of 2012 (RA 10173) and IRR**
- IRR has sections on subcontracting, outsourcing agreements, and duties of personal information processors; IRR specifies required clauses in outsourcing contracts — [IRR of RA 10173 (NPC PDF)](https://privacy.gov.ph/wp-content/uploads/2023/06/IRR_RA-10173-as-amended.pdf); [Hogan Lovells](https://www.hoganlovells.com/en/publications/philippines-finalizes-data-privacy-act-implementing-rules)
- Health is **sensitive personal information**; notify NPC and data subjects within 72 hours of unauthorized acquisition of sensitive PI; registration threshold includes processing sensitive PI of ≥1,000 individuals (current framework NPC Circular 2022-04, effective Jan 11, 2023); DPA applies to offshore processing with Philippine links — [Hogan Lovells](https://www.hoganlovells.com/en/publications/philippines-finalizes-data-privacy-act-implementing-rules); [Linklaters](https://www.linklaters.com/en/insights/data-protected/data-protected---philippines); [IAPP summary](https://iapp.org/news/a/summary-philippines-data-protection-act-and-implementing-regulations)

**Google architecture guidance tied to compliance**
- Well-Architected Framework security pillar has a principle "Meet regulatory, compliance, and privacy needs" plus "Use AI securely and responsibly" — [WAF security pillar](https://docs.cloud.google.com/architecture/framework/security)

### Inferences
- Interview framing for a TPA: "HIPAA is the US benchmark that Google documents best. For our markets, I map Vietnam PDPL (72h breach, TIA/DPIA for sensitive health data), HK PDPO (DPP 4 security, DPP 1 transfer notice) and PH DPA (sensitive PI, outsourcing contract, 72h breach) to the same GCP controls: Singapore region + resource-location org policy, CMEK, VPC-SC, SDP de-identification before LLMs, Data Access audit logs, and a signed Cloud Data Processing Addendum."
- Storing Vietnamese health data in Singapore is a cross-border transfer under PDPL, so a TIA filing is likely needed (legal team decides; this is not legal advice).

### Gaps
- I did not read the statute text of Law 91/2025 or Decree 356/2025; the exact list of "sensitive personal data" (health, insurance, financial) is in the decree and was not confirmed.
- No Philippines NPC circular specific to cloud was found; the 2020 DOH-NPC telemedicine circular was not examined. Insurance Commission (PH) and HKIA/IA (HK) outsourcing/cloud rules for insurers were not researched.
- No Google Cloud page specific to Vietnam, Philippines or Hong Kong privacy law was found in this session.

---

## Key Question 9: Curated long-form learning resources (title, URL, owner, format, length, cost, last-updated, topics, hands-on, fit)

### Takeaway
The best path is: Google's long official pages (service-account best practices, Cloud Run securing section, WIF for pipelines, VPC-SC for Cloud Run, Agent Platform data governance/ZDR/abuse monitoring) plus the Well-Architected security pillar and the enterprise foundations blueprint (with Terraform), then Skills Boost "Manage Security in Google Cloud" + "Security Best Practices in Google Cloud" for labs, then the Next '26 Cloud Run codelab and the Model Armor lab for hands-on AI security. The only GCP security book found (Packt 2023) is now partly outdated.

### Cited Findings

Notes: "Last updated" = what the fetched page showed; most docs pages did not show a date in the fetched text ("not shown"). Cost for Google docs is free (public pages). Skills Boost/Coursera pricing was not verified.

| # | Title | URL | Owner | Format | Approx. length | Cost | Last updated | Topics | Hands-on | Fit for learner |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Best practices for using service accounts | [link](https://docs.cloud.google.com/iam/docs/best-practices-service-accounts) | Google Cloud | Doc | Long (~25 practices) | Free | not shown | SA lifecycle, keys, impersonation, escalation, audit | Low (concepts + links) | ★★★ Must-read; core interview material |
| 2 | Use IAM securely | [link](https://docs.cloud.google.com/iam/docs/using-iam-securely) | Google Cloud | Doc | Medium | Free | not shown | Least privilege, basic roles, groups, Conditions, Recommender, Policy Simulator | Low | ★★★ |
| 3 | Deny policies overview | [link](https://docs.cloud.google.com/iam/docs/deny-overview) | Google Cloud | Doc | Medium | Free | not shown | Deny evaluation, exceptions, tag conditions | Low | ★★ |
| 4 | WIF with deployment pipelines | [link](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines) | Google Cloud | Doc + tutorial | Long | Free | not shown | GitLab, GitHub, Azure DevOps etc., attribute conditions, impersonation | High (gcloud + YAML) | ★★★ Directly matches GitLab CI |
| 5 | Configure OpenID Connect with GCP WIF | [link](https://docs.gitlab.com/ci/cloud_services/google_cloud/) | GitLab | Tutorial | Medium | Free | not shown (mentions GitLab 17.0) | `id_tokens`, STS exchange, impersonation | High | ★★★ (works on self-managed) |
| 6 | Google Cloud WIF and IAM policies (GitLab integration) | [link](https://docs.gitlab.com/integration/google_cloud_iam/) | GitLab | Doc | Medium | Free (all tiers, GitLab.com only) | history 16.10 / 17.1 | Guided WIF setup, claims, `identity: google_cloud` | Medium | ★★ if GitLab.com |
| 7 | google-github-actions/auth README | [link](https://github.com/google-github-actions/auth) | Google (GitHub org) | README | Long | Free | v3 (Node 24) | Direct WIF vs SA, conditions | High | ★★ (GitHub variant) |
| 8 | Cloud Run "Securing" section: service-to-service, service identity, ingress, private networking, custom audiences, IAP, VPC-SC | [s2s](https://docs.cloud.google.com/run/docs/authenticating/service-to-service), [identity](https://docs.cloud.google.com/run/docs/securing/service-identity), [ingress](https://docs.cloud.google.com/run/docs/securing/ingress), [private](https://docs.cloud.google.com/run/docs/securing/private-networking), [audiences](https://docs.cloud.google.com/run/docs/configuring/custom-audiences), [IAP](https://docs.cloud.google.com/run/docs/securing/identity-aware-proxy-cloud-run), [VPC-SC](https://docs.cloud.google.com/run/docs/securing/using-vpc-service-controls) | Google Cloud | Doc set | Long (7+ pages) | Free | not shown | Everything in KQ2/KQ5/KQ6 | Medium–High (gcloud/Terraform) | ★★★ Most relevant set for the reference project |
| 9 | Cloud Tasks: create HTTP target tasks + OidcToken reference | [guide](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks), [ref](https://docs.cloud.google.com/tasks/docs/reference/rest/v2/OidcToken) | Google Cloud | Doc | Medium | Free | not shown | OIDC tokens, service agent roles | High (code in 4 languages) | ★★★ Matches reference project |
| 10 | Pub/Sub: authenticate push subscriptions | [link](https://docs.cloud.google.com/pubsub/docs/authenticate-push-subscriptions) | Google Cloud | Doc | Medium | Free | not shown | JWT claims checklist, Python verify | High | ★★★ Best JWT verification checklist |
| 11 | Cloud Run secrets + Secret Manager rotation | [secrets](https://docs.cloud.google.com/run/docs/configuring/services/secrets), [rotation](https://docs.cloud.google.com/secret-manager/docs/secret-rotation) | Google Cloud | Doc | Medium | Free | not shown | Env vs volume, versions, rotation events | High | ★★★ |
| 12 | Connect to VPC (Direct VPC egress vs connector) + Static outbound IP | [vpc](https://docs.cloud.google.com/run/docs/configuring/connecting-vpc), [static IP](https://docs.cloud.google.com/run/docs/configuring/static-outbound-ip) | Google Cloud | Doc + tutorial | Medium | Free (NAT/IP billed) | not shown | Egress, Cloud NAT | High | ★★★ (HBS IP allowlist) |
| 13 | Set up global external ALB with Cloud Run (serverless NEG, Cloud Armor, IAP) | [link](https://docs.cloud.google.com/load-balancing/docs/https/setting-up-https-serverless) | Google Cloud | Tutorial | Long (10 steps) | Free (LB billed) | not shown | ALB, certs, Cloud Armor, IAP, ingress | High | ★★★ |
| 14 | VPC-SC supported products | [link](https://docs.cloud.google.com/vpc-service-controls/docs/supported-products) | Google Cloud | Reference | Very long (~300k chars) | Free | not shown | Per-service VPC-SC support and limits | Low | ★★ reference |
| 15 | CMEK compatible services | [link](https://docs.cloud.google.com/kms/docs/compatible-services) | Google Cloud | Reference | Long table | Free | not shown | CMEK coverage per service | Low | ★★ |
| 16 | Sensitive Data Protection: de-identify sensitive data | [link](https://docs.cloud.google.com/sensitive-data-protection/docs/deidentify-sensitive-data) | Google Cloud | Doc + code | Very long (~190k chars) | Free doc (API billed) | not shown | Redact, mask, hash, date-shift, tokenization | High | ★★★ PII before LLM |
| 17 | Model Armor overview + Skills Boost lab "Enable the Model Armor API" | [overview](https://docs.cloud.google.com/model-armor/overview?hl=en), [lab](https://www.skills.google/catalog_lab/32261) | Google Cloud | Doc + lab | Lab (length not shown) | Lab cost not verified | not shown | Prompt/response screening with SDP templates | High | ★★★ AI-specific |
| 18 | Agent Platform (Vertex AI) data governance, ZDR, abuse monitoring, data residency, security controls | [governance](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/data-governance), [ZDR](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/vertex-ai-zero-data-retention), [abuse](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/abuse-monitoring), [residency](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/data-residency), [controls](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/security-controls) | Google Cloud | Doc set | Long | Free | not shown (June 2, 2026 ZDR update in release notes) | Training, caching, logging, residency, CMEK/VPC-SC per feature | Low–Medium | ★★★ Must-read for health data + LLM |
| 19 | Claude Models on Google Cloud (Google managed) | [link](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/google-managed) | Anthropic | Doc | Long | Free | not shown (API version 2026-10-21 mentioned) | Endpoints, IAM, logging, features | High | ★★★ if using Claude |
| 20 | Google: Anthropic Claude models on Agent Platform | [link](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/partner-models/claude) | Google Cloud | Doc | Medium | Free | not shown | Logging, FedRAMP High, terms | Low | ★★ |
| 21 | Agent Platform release notes | [link](https://docs.cloud.google.com/gemini-enterprise-agent-platform/release-notes) | Google Cloud | Changelog | Very long | Free | Nov 2, 2026 entry seen | VPC-SC, CMEK, Model Armor, ZDR changes | — | ★★ keep current |
| 22 | Well-Architected Framework: Security pillar (+ printable version) | [link](https://docs.cloud.google.com/architecture/framework/security), [printable](https://docs.cloud.google.com/architecture/framework/security/printable) | Google Cloud | Guide | Long (7 principles, multi-page) | Free | not shown | Security by design, zero trust, shift-left, AI securely, compliance | Low | ★★★ Architecture language for interviews |
| 23 | Enterprise foundations blueprint (formerly security foundations blueprint) + Terraform | [guide](https://docs.cloud.google.com/architecture/security-foundations), [repo](https://github.com/terraform-google-modules/terraform-example-foundation) | Google Cloud | Guide + IaC | Very long | Free | not shown | Org/folders, groups, Shared VPC, SCC, logging, KMS, Cloud Build GitOps | High (Terraform) | ★★ (platform-team level; good for "how would you set up the org") |
| 24 | Google Cloud HIPAA compliance | [link](https://docs.cloud.google.com/docs/security/compliance/hipaa) | Google Cloud | Guide | Long | Free | products 2025-09-17 | BAA, shared responsibility, PHI rules | Low | ★★★ Health data |
| 25 | Cloud Audit Logs overview | [link](https://docs.cloud.google.com/logging/docs/audit) | Google Cloud | Doc | Medium | Free (logs billed) | not shown | Log types, buckets, sinks | Low | ★★ |
| 26 | Skills Boost: Manage Security in Google Cloud | [link](https://www.skills.google/course_templates/21) | Google Cloud Training | Video + labs | **4h45m** (older listing said 8h30m) | not verified | "5 hours ago" | Shared fate, Cloud Identity, Workforce Identity Federation, IAM roles/conditions/policies, VPC, firewalls, VPC-SC | Medium–High | ★★★ Start here (refreshed) |
| 27 | Skills Boost: Security Best Practices in Google Cloud | [link](https://www.skills.google/course_templates/87) | Google Cloud Training | Video + labs | 11h15m | not verified | "3 months ago" | Storage access, encryption, CSEK, API scopes, Shielded VMs, signed URLs, GKE | Medium–High | ★★ (some VM/GKE focus) |
| 28 | Skills Boost path: Professional Security Engineer Certification | [link](https://www.skills.google/paths/15) | Google Cloud | Learning path | 25 activities | not verified | "about 1 month ago" | Exam breadth, labs, skill badges | High | ★ only if aiming for the cert (breadth) |
| 29 | Skill badge: Build a Secure Google Cloud Network | [link](https://www.cloudskillsboost.google/course_templates/654) | Google Cloud | Labs + challenge | 6h45m or 1h15m (conflicting) | not verified | not shown | VPC, firewall, IAP TCP | High | ★★ |
| 30 | Coursera: Security in Google Cloud (Specialization) | [link](https://www.coursera.org/programs/google-specialization/specializations/security-google-cloud-platform) | Google Cloud Training | MOOC | 4 courses (announced 2019) | subscription (not verified) | not shown | Same content as Skills Boost series | Medium | ★ use Skills Boost instead; flag possible older version |
| 31 | Coursera: Security & Compliance on Google Cloud (Specialization) | [link](https://www.coursera.org/specializations/security-and-compliance-on-google-cloud) | Google Cloud | MOOC | 7 courses | not verified | not shown | Incl. Layered Security Operations | Medium | ★ (not checked in depth) |
| 32 | Codelab: The ultimate Cloud Run guide from zero to production (Next '26) | [link](https://codelabs.developers.google.com/next26/ultimate-cloud-run-guide) | Google | Codelab | 10 sections (time not shown) | Free (GCP usage billed) | 2026 (Next '26 series) | Dedicated SAs, Secret Manager, Direct VPC egress, internal ingress, run.invoker, ADK agent | High | ★★★ Best hands-on match |
| 33 | Official Google Cloud Certified Professional Cloud Security Engineer Exam Guide (Chowdhary & Kulkarni, foreword Phil Venables) | [Packt](https://www.packtpub.com/en-mx/product/official-google-cloud-certified-professional-cloud-security-engineer-exam-guide-9781835468869) | Packt | Book | 496 pages | price not verified | 1st ed. Aug 2023 | IAM, network, data security, SCC, BeyondCorp, containers | Medium | ★ **Partly outdated** (pre-Agent Platform, pre-Model Armor) |
| 34 | Cloud Security Podcast by Google (EP199 IAM pet peeves; EP275 Next 2026) | [Apple](https://podcasts.apple.com/us/podcast/id1554145026), [EP199](https://ppacc.player.fm/series/cloud-security-podcast-by-google/ep199-your-cloud-iam-top-pet-peeves-and-how-to-fix-them) | Google (Anton Chuvakin) | Podcast | ~30 min/episode (not verified), 275+ episodes | Free | weekly, 2026 episodes exist | Cloud security opinions | None | ★★ commute listening |
| 35 | Google Cloud blog: Make IAM for GKE easier with WIF (Nov 21, 2024) | [link](https://cloud.google.com/blog/products/identity-security/make-iam-for-gke-easier-to-use-with-workload-identity-federation) | Google Cloud | Blog | Short–medium | Free | 2024-11-21 | principalSet limits (Cloud Run invoke, VPC-SC) | Low | ★ for one key fact |
| 36 | HK PCPD Guidance on Cloud Computing | [PDF](https://pcpd.org.hk/english/resources_centre/publications/files/IL_cloud_e.pdf) | PCPD (HK regulator) | Guidance | not verified | Free | updated Jan 2025 | Cloud contracts, security, cross-border | None | ★★ HK market |
| 37 | Tilleke & Gibbins: Vietnam's New PDPL – A Closer Look | [link](https://tilleke.com/insights/vietnams-new-personal-data-protection-law-a-closer-look) | Law firm | Article | Long | Free | 2025-08-27 (updated for Decree 356) | PDPL obligations | None | ★★ VN market |

### Inferences
- **Suggested order (about 6 weeks, 6–8 h/week)**, built from the table:
  1. Week 1 – IAM: #1, #2, #3, Skills Boost #26 (labs). Map each concept to Azure/K8s.
  2. Week 2 – Cloud Run security: #8, #9, #10, #11; do codelab #32 end-to-end in a sandbox project; rebuild the Cloud Tasks → worker OIDC flow and test the "signature removed" question from KQ2 Gaps.
  3. Week 3 – CI/CD: #4, #5 (or #6); move a GitLab pipeline to WIF with a `deployer-sa`.
  4. Week 4 – Networking: #12, #13, #29; build ALB + Cloud Armor + static NAT IP.
  5. Week 5 – Data protection for AI: #18, #19/#20, #16, #17, #14, #15; build SDP de-identify before a Gemini/Claude call on a Singapore endpoint with caching disabled.
  6. Week 6 – Architecture + compliance: #22, #23 (skim Terraform), #24, #36, #37, #25; write a one-page "controls mapping" for VN/HK/PH.
- Skip or deprioritize: #30 (older Coursera packaging of the same Skills Boost content), #28 unless the learner wants the certification (breadth, not depth, which the brief says to skip), #33 except as a structured review.

### Gaps
- **YouTube playlists and Next '26 talk recordings:** I could not find an official, verifiable Google Cloud Tech YouTube playlist or Next '26 security session list in this session. EP275 show notes mention Next '26 sessions ("Redefining security for the AI era with Google Cloud and Wiz") but this wasn't confirmed — [podcast listing](https://castbox.fm/channel/3830644).
- **Long blog series:** No verified long blog series on Cloud Run security (e.g. Google Cloud Community on Medium) was found by search. One Medium post, "Authorization enforcement for Cloud Run", appeared in results but wasn't read — [Medium](https://medium.com/google-cloud/authorization-enforcement-for-cloud-run-1864f4f0a2d1).
- Not verified this session (candidates to check): Google's free online book *Building Secure and Reliable Systems* (sre.google); the official PCSE exam guide PDF; Skills Boost "Mitigate Threats and Vulnerabilities with Security Command Center" (one page says 5h30m) — [search result](https://cloud.google.com/blog/products/identity-security/new-educational-lab-for-security-command-center-can-help-address-security-talent-gap/).
- Skills Boost and Coursera pricing (credits/subscription) and module lists were not visible without sign-in.
- Most Google docs pages did not show "last updated" dates in the fetched text.

---

## Key Question 10: 25 production interview questions (security, IAM, networking) with short answers

### Takeaway
These questions cover what a senior interviewer for a health-insurance AI platform on GCP is likely to ask, and each answer is tied to a Google (or Anthropic/regulator) source. The answers use the reference project as the example.

### Cited Findings

1. **Q: Why one service account per Cloud Run service, and what happens if you don't set one?**
   A: Single-purpose SAs give least privilege and clear audit trails. Without one, Cloud Run uses the Compute Engine default SA, which may have project Editor. Enforce `iam.automaticIamGrantsForDefaultServiceAccounts`. — [Cloud Run service identity](https://docs.cloud.google.com/run/docs/securing/service-identity); [SA best practices](https://docs.cloud.google.com/iam/docs/best-practices-service-accounts)

2. **Q: How do you authenticate GitLab CI to GCP without a JSON key?**
   A: Workload Identity Federation. A GitLab `id_tokens` OIDC JWT is exchanged at STS. A provider attribute condition limits it to our group (`assertion.namespace_id=='GROUP_ID'`), and the pipeline impersonates a `deployer-sa` through `roles/iam.workloadIdentityUser`. — [WIF with deployment pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines); [GitLab OIDC GCP](https://docs.gitlab.com/ci/cloud_services/google_cloud/)

3. **Q: Why is an attribute condition mandatory for GitLab.com / GitHub WIF?**
   A: Both use one shared issuer for all customers, so without a condition any GitLab/GitHub project could get into your pool. On GitHub, use the numeric `repository_id`/`repository_owner_id` to avoid typosquatting. — [WIF with deployment pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)

4. **Q: Can a WIF principalSet be granted `run.invoker` directly?**
   A: No. "The specific permission to invoke a Cloud Run instance does not support Workload Identity Federation principal and principalSets." Impersonate an SA and mint an ID token. — [Google blog](https://cloud.google.com/blog/products/identity-security/make-iam-for-gke-easier-to-use-with-workload-identity-federation); [google-github-actions/auth](https://github.com/google-github-actions/auth)

5. **Q: Service A calls private Cloud Run service B. What is needed?**
   A: Grant A's SA `roles/run.invoker` on B. A fetches an ID token with `aud` = B's `run.app` URL (or a custom audience) from the metadata server or google-auth, and sends `Authorization: Bearer`. Custom domains can't be the `aud`. — [Cloud Run s2s](https://docs.cloud.google.com/run/docs/authenticating/service-to-service)

6. **Q: What's the difference between an ID token and an access token here?**
   A: ID tokens (OIDC JWT with `aud`) are for calling your own handlers like Cloud Run. OAuth access tokens are for Google APIs on `*.googleapis.com`. — [Cloud Tasks HTTP targets](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks)

7. **Q: In Cloud Tasks, what audience does the OIDC token get if you don't set one, and which IAM bindings are needed?**
   A: The task's target URI. Bindings: the token SA needs `run.invoker` on the worker, the Cloud Tasks service agent needs `roles/iam.serviceAccountUser` on the token SA, the enqueuer needs Cloud Tasks Enqueuer plus `actAs`, and the SA must be in the queue's project. — [OidcToken](https://docs.cloud.google.com/tasks/docs/reference/rest/v2/OidcToken); [Cloud Tasks HTTP targets](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks)

8. **Q: What must the receiver check when it verifies a Google-signed OIDC token itself?**
   A: Google signature, `aud`, `exp`, `iss` (`accounts.google.com`), `email` = the expected SA, and `email_verified` = true. In Python, `verify_oauth2_token` checks signature, aud and exp, but you check `email` yourself. — [Pub/Sub push auth](https://docs.cloud.google.com/pubsub/docs/authenticate-push-subscriptions)

9. **Q: Can you trust the `X-CloudTasks-QueueName` header to know the request came from Cloud Tasks?**
   A: No. Those headers can be spoofed. Identity must come from the OIDC token. — [Cloud Tasks HTTP targets](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks)

10. **Q: Your API uses its own user JWT in `Authorization`. How do you also pass a Google ID token to a private Cloud Run service?**
    A: Use `X-Serverless-Authorization: Bearer <id_token>`. If both headers are present, Cloud Run checks only `X-Serverless-Authorization`. — [Cloud Run s2s](https://docs.cloud.google.com/run/docs/authenticating/service-to-service)

11. **Q: Ingress settings vs IAM: what does each protect, and which setting for a Cloud Tasks-only worker?**
    A: Ingress = network path. IAM = identity, and it applies on every path. Use both. For the worker, use `internal` + `--no-allow-unauthenticated`. Cloud Tasks counts as internal when it's in the same project/perimeter and uses the `run.app` URL. — [Cloud Run ingress](https://docs.cloud.google.com/run/docs/securing/ingress)

12. **Q: How do you put a WAF in front of Cloud Run and stop people bypassing it?**
    A: Use a global external ALB with a serverless NEG and a Cloud Armor policy on the backend service. Set ingress to `internal-and-cloud-load-balancing` (or disable the default URL), otherwise the `run.app` URL bypasses Cloud Armor. — [ALB with Cloud Run](https://docs.cloud.google.com/load-balancing/docs/https/setting-up-https-serverless)

13. **Q: Partner HBS whitelists IPs. How does Cloud Run get a fixed egress IP?**
    A: Use Direct VPC egress (or a connector) with `--vpc-egress=all-traffic`, plus a Cloud Router and Cloud NAT using a reserved static IP in manual mode. Watch for NAT port exhaustion (add IPs or tune ports). — [Static outbound IP](https://docs.cloud.google.com/run/docs/configuring/static-outbound-ip)

14. **Q: Direct VPC egress or a Serverless VPC Access connector?**
    A: Direct VPC egress (recommended): no connector VMs to pay for, lower latency, higher throughput, per-service tags, spend caps. The costs are more subnet IPs and slower scale-from-zero. — [Connect to VPC](https://docs.cloud.google.com/run/docs/configuring/connecting-vpc)

15. **Q: Secret as env var or volume, and how do you rotate?**
    A: An env var is resolved at instance start, so pin a version and rotate by redeploying. A volume is read on access and follows `latest`, so it's rotation-friendly. Secret Manager only sends `SECRET_ROTATE` Pub/Sub events, and you write the rotation logic. The runtime SA needs `secretAccessor` on that one secret. — [Cloud Run secrets](https://docs.cloud.google.com/run/docs/configuring/services/secrets); [Secret rotation](https://docs.cloud.google.com/secret-manager/docs/secret-rotation)

16. **Q: What does VPC Service Controls add on top of IAM?**
    A: A perimeter that blocks data exfiltration even with valid credentials (for example, copying BigQuery/GCS data to an outside project). For Cloud Run inside the perimeter: internal ingress, `all-traffic` egress, Private Google Access, and DNS to `restricted.googleapis.com`. Ingress `all` disables enforcement. — [Cloud Run with VPC-SC](https://docs.cloud.google.com/run/docs/securing/using-vpc-service-controls); [VPC-SC supported products](https://docs.cloud.google.com/vpc-service-controls/docs/supported-products)

17. **Q: Which services in this stack support CMEK, and is there any catch?**
    A: Agent Platform/Vertex resources, BigQuery, GCS, Firestore, Secret Manager, Pub/Sub, Cloud Tasks, Artifact Registry and Logging do. Catches: Cloud Run CMEK covers only the container image, and Gemini durable caching does not support CMEK. — [CMEK services](https://docs.cloud.google.com/kms/docs/compatible-services); [Data governance](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/data-governance)

18. **Q: Does Google train on our prompts? What about caching?**
    A: There's no training or fine-tuning without permission. Gemini caches data by default for up to 24h; turn it off per project with `cacheConfig.disableCache=true` (needs `roles/aiplatform.admin`). — [Data governance](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/data-governance)

19. **Q: Is there any prompt logging by Google, and can we get zero data retention?**
    A: For standard Google models, prompts are logged only when classifiers flag abuse, kept up to 90 days. Master Agreement customers are exempt by default. For ZDR, also keep request-response logging off, set `store=false`, and avoid Grounding with Google Search/Maps. Claude Fable/Mythos (Advanced AI) log all prompts up to 30 days, so ZDR may not be possible with them. — [Abuse monitoring](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/abuse-monitoring); [ZDR](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/vertex-ai-zero-data-retention)

20. **Q: How do you keep LLM processing in Singapore?**
    A: Use a regional `asia-southeast1` endpoint, never `global`, because global gives no residency guarantee. Check per-model support (e.g. Gemini 3.5 Flash is listed for Singapore, 2.5 Pro is not). Claude endpoint support conflicts between sources, so verify in Model Garden. Add a resource-location org policy, or Assured Workloads Singapore Data Boundary. — [Data residency](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/data-residency); [Anthropic endpoints](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/google-managed); [Assured Workloads](https://docs.cloud.google.com/assured-workloads/docs/supported-products)

21. **Q: How do you remove PII/PHI from claim text before calling an LLM?**
    A: Use Sensitive Data Protection `content:deidentify` with an InspectConfig (infoTypes, plus custom ones for VN/PH IDs) and a DeidentifyConfig (replace with infoType, masking, crypto hash/tokenization, date shift). Or use Model Armor advanced mode with SDP templates at the gateway. Note that `MEDICAL_DATA` excludes medical IDs. — [SDP de-identify](https://docs.cloud.google.com/sensitive-data-protection/docs/deidentify-sensitive-data); [Model Armor](https://docs.cloud.google.com/model-armor/overview?hl=en); [infoTypes](https://docs.cloud.google.com/sensitive-data-protection/docs/infotypes-reference?hl=id)

22. **Q: Deny policy vs allow policy: which wins and where do you attach it?**
    A: Deny policies are evaluated first and win. They attach at org, folder or project, can exempt principals, and their conditions can only use resource tags. — [Deny policies](https://docs.cloud.google.com/iam/docs/deny-overview)

23. **Q: Which audit logs are on by default, and what must you enable for PHI access evidence?**
    A: Admin Activity and System Event are always on, and Policy Denied is on by default. Data Access logs are off except for BigQuery, so enable them for GCS, Agent Platform, Secret Manager and IAM/STS. Never log PHI into logs or labels. — [Audit logs](https://docs.cloud.google.com/logging/docs/audit); [HIPAA](https://docs.cloud.google.com/docs/security/compliance/hipaa); [SA best practices](https://docs.cloud.google.com/iam/docs/best-practices-service-accounts)

24. **Q: Is Google Cloud "HIPAA compliant"? What does the BAA cover?**
    A: There's no HIPAA certification; compliance is shared. The BAA covers the infrastructure plus named products (Cloud Run, BigQuery, GCS, Secret Manager, Agent Platform...). You must configure them securely and disable non-covered services for PHI. — [Google Cloud HIPAA](https://docs.cloud.google.com/docs/security/compliance/hipaa)

25. **Q: What changes with Vietnam's PDPL for a cloud AI system that handles health claims?**
    A: Law 91/2025/QH15 took effect Jan 1, 2026 (with Decree 356/2025). It requires DPIA and transfer-impact assessments (updated every 6 months on change), breach reports within 72 hours of detection, and fines up to 5% of prior-year revenue for cross-border violations. Hosting in Singapore counts as a cross-border transfer. — [Tilleke & Gibbins](https://tilleke.com/insights/vietnams-new-personal-data-protection-law-a-closer-look); [Allen & Gledhill](https://www.allenandgledhill.com/vn/publication/articles/31075/upcoming-changes-to-vietnam-s-personal-data-protection-regime)

### Inferences
- Good follow-up answers to prepare (not sourced as Q&A, built from the facts above): "Walk me through your Cloud Tasks → worker flow end to end" (combine Q5, Q7, Q8, Q9, Q11), and "Design the network for an AI claims service with a partner IP allowlist" (combine Q12, Q13, Q14, Q16).
- Interviewers may still say "Vertex AI". Answer with "Agent Platform (formerly Vertex AI)" to show you are current as of the April 2026 rename.

### Gaps
- Q8 depends on the unverified "signature removed" behavior (KQ2 Gaps). If Cloud Run strips the signature after its own IAM check, the right answer is "Cloud Run already verified it; the app decodes claims and checks `email`."
- Q20's Claude part is unresolved because the sources conflict.
