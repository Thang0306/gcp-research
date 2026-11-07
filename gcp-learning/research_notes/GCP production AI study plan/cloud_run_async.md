# Production backends and async pipelines on Google Cloud serverless (Cloud Run services and jobs, Cloud Tasks, Pub/Sub, Eventarc, Workflows): deep learning resources and production facts

Research date: 2026-11-06. Learner: Vietnamese AI engineer, strong in Python/FastAPI, Celery+Redis, Docker, Kubernetes (RKE2, Helm, ArgoCD), with zero GCP experience. Reference system: "ACE" claim engine. It runs several Cloud Run services by role (api, extract, classify, adjudicate) and chains them with Cloud Tasks HTTP tasks signed with OIDC tokens. Dispatch deadlines are 900-1800 s, and it falls back to running work in a background thread.

Two platform facts the report writer should know first:
- **Docs moved domain.** Every `cloud.google.com/run/docs/...`, `/tasks/docs/...` and so on URL now answers with a 301 redirect to `docs.cloud.google.com/...`. For example, `https://cloud.google.com/run/docs/tips/general` returns 301 to `https://docs.cloud.google.com/run/docs/tips/general` (seen while fetching on 2026-11-06). Old links still work, but the canonical URLs are on docs.cloud.google.com.
- **Skills Boost was renamed.** `https://www.cloudskillsboost.google/course_templates/371` returns 308 to `https://www.skills.google/course_templates/371`. "Google Cloud Skills Boost" is now "Google Skills" at skills.google (seen 2026-11-06).

---

## Q1. Cloud Run production essentials, and the best deep resource for each topic

### Takeaway
The best deep material on Cloud Run production behaviour is the official docs on docs.cloud.google.com. The key pages are "tips/general", "tips/python", billing settings, request timeout, health checks, execution environments, rollouts, service-to-service auth, jobs, GPU, quotas, and the release notes. The single most important concept for ACE is the billing mode. With request-based billing (the default, formerly "CPU only allocated during request processing"), CPU is disabled or severely limited after the response is sent. That makes "do work in a background thread after returning 200" unsafe. Instance-based billing (formerly "CPU always allocated") allows background work, but an idle instance can still be shut down at any time.

### Cited Findings

**Billing / CPU allocation (best resource: "Billing settings" page)**
- There are two billing settings. With request-based billing (the default), "Cloud Run service instances are only charged when they process requests, when they start, and when they shut down". With instance-based billing, you are charged for "the entire lifecycle of each instance", even with no traffic. — [Billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings)
- Old names: request-based billing was previously called "CPU only allocated during request processing", and instance-based billing was previously "CPU always allocated". — [Billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings)
- The console setting "CPU allocation" was renamed "Billing" on December 13, 2024. — [Cloud Run release notes](https://docs.cloud.google.com/run/docs/release-notes)
- Request-based billing is recommended when traffic is "sporadic, bursty or spiky". Instance-based billing is recommended when traffic is steady and changes slowly. Recommender looks at the past month of traffic and may suggest switching to instance-based billing when it is cheaper. — [Billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings)
- Instance-based billing requires at least 512 MiB of memory. — [Billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings)
- An instance is not kept idle for more than 15 minutes after a request unless minimum instances keep it active. Instance-based billing plus min instances keeps instances running with full CPU, which enables background processing, and autoscaling still applies. — [Billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings)
- For work that does not fit "short background task after response", the billing page points to three options. Cloud Tasks for async tasks (with retries, up to 30 minutes), Cloud Run instances for a single long-lived workload (up to 7 days), and Cloud Run worker pools for non-HTTP, pull-based workers. — [Billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings)
- Budget spend caps that pause workloads launched in Preview on July 27, 2026 and reached GA on October 12, 2026. — [Cloud Run release notes](https://docs.cloud.google.com/run/docs/release-notes)

**Background work after the response (best resource: "General development tips")**
- With request-based billing, after a response is sent "the instance's access to CPU will be disabled or severely limited". The page says to avoid background threads and to make sure async operations finish before you respond. — [Designing Cloud Run services with recommended practices (tips/general)](https://docs.cloud.google.com/run/docs/tips/general)
- Suspended background work comes back unexpectedly: "any subsequent request to the same container instance resumes any suspended background activity". Anything logged after a request's log entry is a sign of background activity. — [tips/general](https://docs.cloud.google.com/run/docs/tips/general)
- With instance-based billing, short background tasks may run after the response. But idle instances can be shut down at any time, and the page suggests trapping SIGTERM, which gives a 10-second grace period. — [Billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings)

**Concurrency (best resources: tips/general and quotas)**
- Default concurrency is 80 requests per instance. The tuning loop is: optimize the service, set code-level limits, set Cloud Run concurrency at or below them, load test, and repeat. "Each request your service handles requires some amount of additional memory." Lower concurrency usually means lower latency but more instances. Watch `container/billable_instance_time` to find the cheapest setting. Guard mutable global state with locks. — [tips/general](https://docs.cloud.google.com/run/docs/tips/general)
- Maximum concurrency is 1,000 requests per instance for services (80 for the new Cloud Run instances resource). — [Cloud Run quotas and limits](https://docs.cloud.google.com/run/quotas)

**Python / FastAPI (best resource: "tips/python" plus the FastAPI quickstart)**
- The default WSGI command shown is `CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app`. The page says to "try to use a number of workers equal to the cores available", warns that "Setting too many workers or threads can have a negative impact", and notes that reducing threads saves memory. — [Optimize Python apps for Cloud Run (tips/python)](https://docs.cloud.google.com/run/docs/tips/python)
- ASGI is supported: "You can use any WSGI or ASGI web server, as long as the container listens on HTTP port `$PORT`". The example is `uvicorn --port $PORT --host 0.0.0.0 main:app`. — [tips/python](https://docs.cloud.google.com/run/docs/tips/python)
- By default gunicorn listens before the app code is evaluated, and the default startup probe "immediately marks a container instance as healthy" once the port is open. So the page says "you should set up custom startup probes". `--preload` evaluates app code before listening, catches runtime bugs at deploy time, and saves memory. — [tips/python](https://docs.cloud.google.com/run/docs/tips/python)
- Other Python tips: set `PYTHONUNBUFFERED` so logs are not buffered; use `slim` base images (Alpine often lacks prebuilt wheels); import only the submodules you need from heavy dependencies; and use instance-based billing for background activity. — [tips/python](https://docs.cloud.google.com/run/docs/tips/python)
- The official FastAPI quickstart deploys with `gcloud run deploy --source .` and pins `fastapi[standard]==0.116.1`. Sibling quickstarts cover LangChain and smolagents FastAPI apps. — [Quickstart: Build and deploy a Python (FastAPI) web app to Cloud Run](https://cloud.google.com/run/docs/quickstarts/build-and-deploy/deploy-python-fastapi-service) (seen through search snippet only); [LangChain quickstart](https://docs.cloud.google.com/run/docs/quickstarts/build-and-deploy/deploy-python-langchain-service)

**Cold starts, startup CPU boost, min instances (best resource: tips/general)**
- Startup time covers pulling the image, running the entrypoint, and waiting for the port to listen. Startup CPU boost temporarily adds CPU during startup. Min instances keep instances warm. While a new instance starts, requests wait in a queue for up to "3.5 times average startup time" (at least 10 seconds). Avoid system exits in containers that use min instances, because they cause cold starts. — [tips/general](https://docs.cloud.google.com/run/docs/tips/general)
- Container image size does not affect startup time, because of image streaming. Smaller images still reduce the attack surface. Global (eager) initialization adds to cold start. Lazy initialization makes the first request on each instance slower and can cause overscaling during revision rollouts. — [tips/general](https://docs.cloud.google.com/run/docs/tips/general)
- The in-memory filesystem counts against instance memory, and files can survive between requests. Delete temp files to avoid out-of-memory errors. Catch exceptions, because a crash means a slow restart while traffic waits in the queue. — [tips/general](https://docs.cloud.google.com/run/docs/tips/general)

**Request timeouts (best resource: request-timeout page)**
- The default timeout is 5 minutes (300 s), and it "can be extended up to 60 minutes (3600 seconds)". "For a timeout longer than 15 minutes, Google recommends implementing retries." Handlers should be idempotent or resumable, because "the longer the timeout is, the more likely the connection can be lost" and a reconnect may land on a different instance. — [Configure request timeout](https://docs.cloud.google.com/run/docs/configuring/request-timeout)

**Memory / CPU / size limits (best resource: quotas page)**
- Limits per instance: 32 GiB memory and 8 vCPU. HTTP/1 requests and responses are limited to 32 MiB (there is no request limit for HTTP/2, and chunked or streamed responses are exempt). The default limit is 100 instances per project per region (adjustable). Up to 1,000 revisions are kept per service before non-addressable ones are deleted. — [Cloud Run quotas and limits](https://docs.cloud.google.com/run/quotas)

**Health checks (best resource: health checks page)**
- Startup probes gate liveness and readiness checks. Liveness failures restart the container. Readiness failures stop new traffic, but "Cloud Run doesn't terminate the instance". TCP probes are allowed only for startup. HTTP probes must use HTTP/1 and return 2xx or 3xx. gRPC probes need the gRPC Health Checking protocol. — [Configure container health checks](https://docs.cloud.google.com/run/docs/configuring/healthchecks)
- If you set no startup probe, Cloud Run adds a default TCP startup probe with timeout 240 s, period 240 s and failure threshold 1. Startup limits: failure threshold × period ≤ 600 s (1800 s for GPU). Liveness period/timeout can go up to 3600 s. Readiness period/timeout can go up to 300 s. "CPU is always allocated when probes run". Probes are billed for CPU and memory, but there is no per-request charge. — [Health checks](https://docs.cloud.google.com/run/docs/configuring/healthchecks)
- Readiness probes for services launched in Preview on November 21, 2025 and reached GA on June 29, 2026, together with multi-region service health and automated failover. — [Release notes](https://docs.cloud.google.com/run/docs/release-notes)
- **Conflict:** the billing-settings page summary stated that "Healthcheck probes require instance-based billing". The health checks page does not say this. It only says CPU is always allocated while probes run. — [Billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings) vs. [Health checks](https://docs.cloud.google.com/run/docs/configuring/healthchecks)

**Execution environments, gen1 vs gen2 (best resource: execution environments page)**
- Gen1 is gVisor-based, with fast cold starts and emulation of most syscalls. Gen2 is microVM-based, with "full Linux compatibility", faster CPU and network, NFS support, and a minimum of 512 MiB memory. Pricing is the same. For services, Cloud Run "selects the execution environment based on the features used" unless you set one. Jobs and worker pools always use gen2. — [Execution environments](https://docs.cloud.google.com/run/docs/about-execution-environments)

**Revisions and traffic splitting (best resource: rollouts page)**
- Use `gcloud run deploy --image IMAGE --no-traffic --tag green` to get a tagged preview URL (`https://green---myservice-abcdef.a.run.app`). Then `gcloud run services update-traffic SERVICE --to-revisions REVISION=PERCENTAGE` (or `LATEST=5`) for a canary. Roll back with `--to-revisions REVISION=100`. A rollback applies immediately and does not rerun health checks. Once you split traffic, later deploys keep that split. With revision-level min instances, tagged revisions also get min instances, which costs money. — [Rollouts, rollbacks, and traffic migration](https://docs.cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration)

**Jobs vs services (best resource: create-jobs page)**
- A job "only runs its tasks and exits when finished". It runs up to 10,000 independent tasks in parallel, and each task reads `CLOUD_RUN_TASK_INDEX` / `CLOUD_RUN_TASK_COUNT`. The default task timeout is 10 min. The maximum is 168 h (7 days), or 12 h with GPUs. Each task gets 3 retries by default (range 0-10). "There is no explicit timeout for a job execution." — [Create jobs](https://docs.cloud.google.com/run/docs/create-jobs); [Quotas](https://docs.cloud.google.com/run/quotas)
- The 168-hour task timeout reached GA on November 11, 2025 (Preview since November 25, 2024). Sidecars for jobs reached GA on April 2, 2025. — [Release notes](https://docs.cloud.google.com/run/docs/release-notes)

**Worker pools and Cloud Run instances (new resource types)**
- Worker pools launched in Preview on June 25, 2025 and reached GA on April 14, 2026. Cloud Run instances ("long-lived, individually addressable workloads") launched in Preview on August 25, 2026. — [Release notes](https://docs.cloud.google.com/run/docs/release-notes)
- Worker pools are "a distinct resource type well-suited for continuous, non-HTTP, pull-based background processing". They need no public HTTP endpoint. Google says it charges "up to 40% less for CPU and memory, compared to instance-billed Cloud Run services". Rollouts split instances between revisions instead of traffic. Scaling uses a manual scaling API that open-source autoscalers drive (for example, the Kafka Autoscaler, which scales on offset lag). — [Making it easier to scale Kafka workloads with Cloud Run worker pools (Google Cloud blog, Jun 26 2025)](https://cloud.google.com/blog/products/serverless/exploring-cloud-run-worker-pools-and-kafka-autoscaler)
- Cloud Run instances run a single copy with no autoscaling, for up to 7 days of continuous runtime, with a stable HTTPS URL. Google's example price is $5.70 for 1 vCPU / 1 GiB running for 30 days. — [Introducing Cloud Run instances (Google Cloud blog)](https://cloud.google.com/blog/products/serverless/introducing-cloud-run-instances) (seen through search summary; launch confirmed in [release notes](https://docs.cloud.google.com/run/docs/release-notes))

**GPU on Cloud Run (best resource: GPU config page)**
- Supported GPUs are NVIDIA L4 (24 GB VRAM; needs at least 4 CPU and 16 GiB, with 8 CPU and 32 GiB recommended) and NVIDIA RTX PRO 6000 Blackwell (96 GB; needs at least 20 CPU and 80 GiB). You get one GPU per instance. "You must use instance-based billing to use the GPU feature", but the service can still scale to zero. Instances start in "approximately 5 seconds". Zonal redundancy is on by default and costs more. New projects get a quota of 3 GPUs. — [Configure GPUs for services](https://docs.cloud.google.com/run/docs/configuring/services/gpu)
- Timeline: GPU for services GA on April 7, 2025; GPU for jobs GA on October 21, 2025; RTX PRO 6000 GA on April 13, 2026; GPU jobs up to 12 h (Preview) on October 30, 2026. — [Release notes](https://docs.cloud.google.com/run/docs/release-notes)

**Service-to-service auth with ID tokens (best resource: service-to-service page)**
- Grant the caller's per-service, user-managed service account `roles/run.invoker`. Set the token `aud` to the receiving service URL or a configured custom audience (custom domains are not supported as `aud`). Send the token as `Authorization: Bearer`, or in `X-Serverless-Authorization` if `Authorization` is already in use (if both headers are present, only the X-Serverless one is checked). In Python, use `google.oauth2.id_token.fetch_id_token(request, audience)`. The metadata-server fallback does not work outside Google Cloud. Tokens expire after about 1 hour, so check `exp` if you cache them. — [Authenticating service-to-service](https://docs.cloud.google.com/run/docs/authenticating/service-to-service)

**Other recent platform changes worth knowing**
- On February 7, 2025, "Cloud Run integrations" were discontinued in the console and gcloud. Since January 13, 2025 (breaking change), the deployer needs Artifact Registry Reader on the image. Deploying functions to Cloud Run (Cloud Run functions) went GA on February 19, 2025. — [Release notes](https://docs.cloud.google.com/run/docs/release-notes)
- Container security tips: non-root `USER`, pinned deterministic builds, Artifact Registry instead of Docker Hub (to avoid rate limits), and vulnerability scanning. — [tips/general](https://docs.cloud.google.com/run/docs/tips/general)

### Inferences
- **ACE background-thread fallback is the riskiest pattern in the design.** On request-based billing, the thread is starved of CPU once the response goes out. It then resumes, unpredictably, when a later request lands on the same instance. On instance-based billing it gets CPU, but SIGTERM can still kill it with only 10 s of grace, and nothing will retry it. Safer fallbacks: (a) retry the Cloud Tasks enqueue, then return 5xx so the caller retries; (b) process synchronously within the request timeout; (c) start a Cloud Run job execution; or (d) write a "pending" row and let a sweeper re-enqueue it. These are design inferences built on the cited behaviour above.
- **The Cloud Run request timeout must be at least the Cloud Tasks dispatch deadline.** The Cloud Run default is 300 s, so an 1800 s task deadline does nothing unless each worker service is set to `--timeout=1800` or more. And because Google recommends retries above 15 minutes, the 900-1800 s stages must be idempotent and resumable.
- **FastAPI is ASGI.** The gunicorn example on tips/python is a WSGI (Flask) command. For FastAPI, use either `uvicorn` directly (as tips/python shows) or gunicorn with `-k uvicorn.workers.UvicornWorker`. The UvicornWorker detail comes from general FastAPI knowledge, not from a fetched Google page. For CPU-bound LLM-post-processing services, set Cloud Run concurrency low (for example 1-10) to match what one async worker process can handle.
- **K8s-to-Cloud-Run mapping that the sources support:**

| Kubernetes concept | Cloud Run equivalent |
|---|---|
| Deployment + HPA | Service with min/max instances and concurrency-driven autoscaling |
| Indexed Job | Cloud Run job with `CLOUD_RUN_TASK_INDEX` |
| startup/liveness/readiness probes | Cloud Run health checks (readiness GA June 2026) |
| Argo Rollouts / canary | `--no-traffic --tag` + `update-traffic` |
| ServiceAccount + NetworkPolicy | IAM `run.invoker` + ID tokens + ingress settings |
| sidecar containers | multi-container (sidecars) |
| GPU node pool | Cloud Run GPU (L4 / RTX PRO 6000) |
| Celery/Kafka consumer Deployment | worker pool |

### Gaps
- I did not fetch the ingress settings page (`internal`, `internal-and-cloud-load-balancing`, `all`) or the sidecar (multi-container) page, so there are no cited specifics for those here.
- I did not fetch the startup CPU boost page. Only the tips page mention is cited.
- No official Google page I found covers FastAPI + gunicorn + `UvicornWorker` tuning on Cloud Run specifically.
- Page titles and "last updated" dates were not visible in the fetched docs content (the fetch tool strips them). Titles given are best-effort.

---

## Q2. Cloud Tasks for production: queues, rate limits, retries, dispatch deadline, dedup, OIDC, invoking Cloud Run, idempotency

### Takeaway
Cloud Tasks is the closest managed equivalent of "Celery `apply_async` to a named queue". It is explicit invocation, with per-queue rate and concurrency limits, retry and backoff, scheduled delivery, and dedup by task name. Its HTTP handlers default to a 10-minute timeout, with a maximum of 30 minutes. That fits ACE's 900-1800 s deadlines exactly at the upper end, so there is no headroom left.

### Cited Findings
- **Dispatch deadline:** "for all HTTP target task handlers the default timeout is 10 minutes, with a maximum of 30 minutes." The Python `CreateTask` sample sets `dispatch_deadline` as an optional field. — [Create HTTP target tasks](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks)
- **OIDC token:** set `oidcToken.serviceAccountEmail`. "The service account used for authentication must be part of the same project where your Cloud Tasks queue resides." An optional `audience` can be set. "ID tokens should generally be used for any handler running on Google Cloud". Access tokens are for `*.googleapis.com`. Grant the Cloud Run Invoker role to the service account. "If authentication is configured at the queue level, this configuration overrides any authentication configured at the task level." — [Create HTTP target tasks](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks)
- **Retry-awareness headers:** `X-CloudTasks-TaskRetryCount` ("includes attempts where the task failed due to 5XX error codes") and `X-CloudTasks-TaskExecutionCount` ("does not include failures due to 5XX error codes"). Scheduling is supported for `CreateTask` but not for `BufferTask`. — [Create HTTP target tasks](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks)
- **Rate limits:** `max-dispatches-per-second` sets the token-bucket refill rate. `max-concurrent-dispatches` is "the maximum number of tasks in the queue that can run at once". `max_burst_size` is computed by the system (it can only be set through queue.yaml `bucket_size`). Example describe output: maxBurstSize 100, maxConcurrentDispatches 1000, maxDispatchesPerSecond 500. The rate limit applies to first attempts and retries alike. — [Configure Cloud Tasks queues](https://docs.cloud.google.com/tasks/docs/configuring-queues)
- **Retry parameters (example defaults):** `--max-attempts` 100 (includes the first attempt; -1 means unlimited); `--max-retry-duration` (0s means unlimited; default not shown); `--min-backoff` 0.100s; `--max-backoff` 3600s; `--max-doublings` 16. Retries stop only once both the attempts limit and the duration limit are reached, or when the task succeeds. A task-level retry config can override the queue-level one. — [Configure queues](https://docs.cloud.google.com/tasks/docs/configuring-queues)
- **Queue-level routing:** `uriOverride` overrides the task-level URL for existing and future tasks. Changing it on an HTTP queue means: pause, wait 1 minute, then resume. It is not compatible with CMEK. Use either queue.yaml or the API to manage queues, never both. — [Configure queues](https://docs.cloud.google.com/tasks/docs/configuring-queues)
- **Dedup by task name:** "The IDs of deleted tasks are not immediately available for reuse. It can take up to 24 hours (or 9 days if the task's queue was created using a queue.yaml or queue.xml)". — [REST tasks.create](https://docs.cloud.google.com/tasks/docs/reference/rest/v2/projects.locations.queues.tasks/create). **Conflict:** the Python client reference says a same-name task can't be created "for 1hour after the original task was deleted or executed" (9 days for queue.yaml). — [Python CreateTaskRequest reference](https://cloud.google.com/python/docs/reference/cloudtasks/latest/google.cloud.tasks_v2.types.CreateTaskRequest). Treat the window as "about 1-24 h, not guaranteed", and do not rely on it as your only idempotency mechanism.
- **Product limits versus Pub/Sub:** 1 MB max task size; 500 QPS max per queue; 31-day retention; regional; 1,000 queues per project per region; "Deduplication on creation: Yes"; "Scheduled delivery: Yes"; "Ordered delivery: No, best-effort order only"; "Multiple handlers per message: No". — [Choose Pub/Sub or Cloud Tasks](https://docs.cloud.google.com/pubsub/docs/choosing-pubsub-or-cloud-tasks)
- **Current Python sample:** the docs sample creates an HTTP POST task with a `json_payload` dict, optional schedule and task ID, and a deadline, and returns `tasks_v2.Task`. The older `googleapis/python-tasks` copy of `create_http_task.py` / `create_http_task_with_token.py` is in a repo archived on February 1, 2024. — [Create HTTP tasks sample](https://docs.cloud.google.com/tasks/docs/samples/cloud-tasks-create-http-task); [archived python-tasks sample](https://www.github.com/googleapis/python-tasks/blob/7a5a0c6ca5372035521d5366373054a7ba95f2bd/samples/snippets/create_http_task_with_token.py)
- Cloud Tasks also manages auth for async calls into Cloud Run (along with Pub/Sub, Cloud Scheduler and Eventarc), so the caller service does not mint tokens itself. — [Service-to-service auth](https://docs.cloud.google.com/run/docs/authenticating/service-to-service)

### Inferences
- **Idempotency pattern for ACE:** use a deterministic task name such as `claim-{claim_id}-stage-{stage}-v{attempt_epoch}` to dedupe enqueue retries (best-effort, see the conflict above). Also keep a DB-level idempotency key, for example a `(claim_id, stage)` row with a status column and a unique constraint. The handler then exits early when it sees a completed row, and reads `X-CloudTasks-TaskRetryCount` for logging and for "give up" logic. Return 2xx only after the stage's output is durably written. Any non-2xx triggers a retry under the queue's backoff.
- **Use one queue per stage** (extract, classify, adjudicate). Then `max-concurrent-dispatches` works as a per-stage concurrency cap (useful for LLM/API quotas), and each queue's retry policy can fit its stage. This is the equivalent of Celery's `-Q extract` workers plus `rate_limit`.
- **No headroom at 1800 s.** Since 30 min is the hard cap for HTTP targets, any stage that may exceed it should move to a Cloud Run job (up to 168 h) started by Workflows, or be split into resumable chunks.

### Gaps
- I did not find an official Cloud Tasks page that measures the latency cost of named tasks, or that states a default `max-retry-duration`.
- The `python-docs-samples` path for current Cloud Tasks snippets returned 404 at `/cloud-tasks/snippets`. The current repo location is unverified, so use the docs sample page instead.
- I found no Google codelab that builds Cloud Tasks + Cloud Run + OIDC end-to-end in Python.

---

## Q3. Pub/Sub push vs pull to Cloud Run, dead-letter topics, exactly-once, ordering keys

### Takeaway
Push subscriptions to a private Cloud Run service (OIDC-authenticated) are the simplest pattern. But push gives at most 10 minutes of processing per message, no exactly-once delivery, and only one outstanding message per ordering key. For long stages, exactly-once, or high-throughput ordered streams, use pull subscribers. On Cloud Run that now means worker pools.

### Cited Findings
- **Push to Cloud Run:** a success code (200 or 204) acks, and an error code (400 or 500) means retry. Give an invoker service account `roles/run.invoker`. The Pub/Sub service agent needs token-creator rights (built in for projects created after April 8, 2021). Use `--push-auth-service-account` and keep the service `--no-allow-unauthenticated`. The example uses `--ack-deadline=600`. IAM propagation can cause temporary 403s. — [Trigger Cloud Run from Pub/Sub push](https://docs.cloud.google.com/run/docs/triggering/pubsub-push)
- **Push mechanics:** success codes are 102, 200, 201, 202 and 204. You cannot modify the ack deadline of individual pushed messages. Messages are wrapped by default (base64 `message.data`), and unwrapped delivery is optional. Pub/Sub signs a JWT in the Authorization header. Push backoff "can't be turned on or off": it runs from 100 ms to 60 s, and the effective delay is the larger of backoff and retry policy. The slow-start push window grows exponentially up to 3,000 outstanding messages per region, then grows linearly, and shrinks if latency goes above 1 s or fewer than 99% of messages are acked. — [Push subscriptions](https://docs.cloud.google.com/pubsub/docs/push)
- **Max push processing:** "10 min for push" (versus 30 min for Cloud Tasks HTTP). Pub/Sub message size is 10 MB, there is no upper delivery rate (subject to quotas), and it allows 10,000 subscriptions per project. — [Choose Pub/Sub or Cloud Tasks](https://docs.cloud.google.com/pubsub/docs/choosing-pubsub-or-cloud-tasks)
- **Exactly-once:** "Only the pull subscription type supports exactly-once delivery". Push and export are not supported. The guarantee holds only when subscribers connect in the same region. Latency is "significantly higher". You need streaming pull for high throughput, and the ack-with-response API to detect failed acks. The `minDurationPerAckExtension` maximum is 600 s. — [Exactly-once delivery](https://docs.cloud.google.com/pubsub/docs/exactly-once-delivery)
- **Ordering keys:** publish all messages for a key in the same region; throughput is limited to 1 MBps per key. "For a push subscription, Pub/Sub supports only one outstanding message for each ordering key at a time." "Redeliveries of a message trigger redelivery of all subsequent messages for that key, even acknowledged ones." Order "might not be preserved" when messages go to a dead-letter topic. The ordering property can't be changed after the subscription is created. — [Ordering messages](https://docs.cloud.google.com/pubsub/docs/ordering)
- **Dead-letter topics:** max delivery attempts is 5-100 (default 5) and is configured on the subscription. Grant the Pub/Sub service agent `roles/pubsub.publisher` on the DLT and `roles/pubsub.subscriber` on the source subscription. The count is "approximate" (best-effort). Push requests carry `deliveryAttempt`. Monitor `subscription/dead_letter_message_count`. Forwarded messages get the `CloudPubSubDeadLetterSourceDeliveryCount` attribute. — [Handling message failures](https://docs.cloud.google.com/pubsub/docs/handling-failures)
- **Pull on Cloud Run:** worker pools handle Pub/Sub pull subscriptions and can scale on the subscription's undelivered-message count. — [Cloud Run worker pools blog](https://cloud.google.com/blog/products/serverless/exploring-cloud-run-worker-pools-and-kafka-autoscaler); there is also a hands-on [codelab: Cloud Run worker pool for pull-based Pub/Sub subscriptions](https://codelabs.developers.google.com/codelabs/cloud-run/cloud-run-worker-pool-pull-based-subscriptions)

### Inferences
- For ACE's 15-30 minute stages, Pub/Sub push to Cloud Run is a poor fit because of the 10-minute push limit. Either keep Cloud Tasks, or switch to pull consumers in worker pools, which is the closest analogue to Celery workers consuming from Redis.
- Pub/Sub is the right tool when one event must fan out to several independent consumers, for example "claim adjudicated" going to notifications, analytics, and an audit log. Cloud Tasks has "Multiple handlers per message: No".

### Gaps
- The retry policy page section (immediate vs exponential backoff with min/max values) was not in the fetched part of the handling-failures page, which is about 109k characters. I have no cited min/max retry-policy values.
- I did not verify a max ack deadline for push subscriptions as a stated limit. Only the 600 s example and the 600 s `minDurationPerAckExtension` max are cited.

---

## Q4. Workflows (and Eventarc) for orchestrating long-running multi-step pipelines

### Takeaway
Workflows is a managed orchestrator. An execution can last up to 1 year. Callbacks can pause for human-in-the-loop steps (12 h default wait), parallel branches are supported, built-in retry policies exist, and connectors include one that runs Cloud Run jobs. Its main constraints are a 512 KB variable memory limit and a 2 MB HTTP response limit, so you pass GCS URIs, not documents. Eventarc is the event router (CloudEvents, at-least-once, no ordering) that starts things, for example a Cloud Storage upload starting a workflow.

### Cited Findings
- **Limits:** max execution duration "1 year"; 10,000 concurrent executions per region per project (adjustable, with backlog to `QUEUED` up to 100,000); 20 concurrent branches or iterations per execution; 10 branches per parallel step; 512 KB total for variables, args and events; 256 KB max string; "2 MB" max HTTP response; 128 KB workflow source; 100,000 steps per execution; callback HTTP requests 1,500/min per location. — [Workflows quotas and limits](https://docs.cloud.google.com/workflows/quotas)
- **Callbacks:** `events.create_callback_endpoint` returns a URL, and `events.await_callback` pauses the execution. The default timeout is "43200 (12 hours)", and a `TimeoutError` is raised when it expires. The caller needs `workflows.callbacks.send` (which is in Workflows Invoker). Callbacks are idempotent. Use cases include human review steps. — [Wait using callbacks](https://docs.cloud.google.com/workflows/docs/creating-callback-endpoints)
- **Parallel steps:** they run blocking calls (sleep, HTTP, callbacks) at the same time. Google recommends parallelizing steps that take about 1 s or more. The feature launched in Preview in July 2022, and branch order is not deterministic. — [Execute workflow steps in parallel](https://docs.cloud.google.com/workflows/docs/execute-parallel-steps); [Introducing parallel steps (Google Cloud blog)](https://cloud.google.com/blog/topics/developers-practitioners/introducing-parallel-steps-workflows-speed-up-workflow-executions-by-running-steps-concurrently/)
- **Retries:** `http.default_retry` is for idempotent targets. It retries 429, 502, 503 and 504 plus `ConnectionError`, `ConnectionFailedError` and `TimeoutError`, up to 5 times, using `retry.default_backoff`. A separate `http.default_retry_non_idempotent` policy exists. — [http.default_retry](https://docs.cloud.google.com/workflows/docs/reference/stdlib/http/default_retry)
- **Running Cloud Run jobs from Workflows:** the tutorial wires an Eventarc trigger (`google.cloud.storage.object.v1.finalized`) to a workflow. The workflow calls connector `googleapis.run.v1.namespaces.jobs.run` with env-var overrides (`INPUT_BUCKET`, `INPUT_FILE`) and runs a 10-task `parallel-job` from the `jobs-demos` repo. A new trigger can take up to 2 minutes to propagate. The tutorial is about 3-4k words with 10 hands-on steps. — [Execute a Cloud Run job using Workflows](https://docs.cloud.google.com/workflows/docs/tutorials/execute-cloud-run-jobs)
- **Document pipeline reference:** Workflows has a built-in Document AI connector, so you can chain Document AI calls without writing request-formatting code. — [Build a document processing pipeline with Workflows (Document AI docs)](https://cloud.google.com/document-ai/docs/workflows)
- **Eventarc Standard vs Advanced:** both deliver at-least-once with "no in-order, first-in-first-out delivery guarantee", 24 h retention and exponential backoff, in CloudEvents format. Standard supports a dead-letter topic through Pub/Sub, a 512 KB max event, and targets Cloud Run services and functions, GKE, internal VPC HTTP endpoints, and Workflows. Advanced adds a bus model, CEL transforms, Pub/Sub targets, a 1 MB max event and Cloud Run jobs as a destination, but has no DLQ. — [Eventarc overview](https://docs.cloud.google.com/eventarc/docs/overview)
- **Orchestration vs choreography framing (Googler talks):** Mete Atamel's decision question is "can you describe the business logic as a flow chart?" If yes, orchestrate. Choreography (Eventarc/Pub/Sub) keeps services loosely coupled, while orchestration captures the flow centrally but can become a single point of failure. — [Mete Atamel, "Choreography vs Orchestration in services" (Speaker Deck, May 2022)](https://speakerdeck.com/meteatamel/choreography-vs-orchestration-in-services); [Guillaume Laforge deck](https://speakerdeck.com/glaforge/choreography-vs-orchestration-in-microservices-and-best-practices)
- **Outdated:** the May 2021 post says a Cloud Run proxy is needed between Eventarc and Workflows. Eventarc Standard now lists Workflows as a direct destination. — [Integrating Eventarc and Workflows (May 2021)](https://cloud.google.com/blog/topics/developers-practitioners/integrating-eventarc-and-workflows) vs. [Eventarc overview](https://docs.cloud.google.com/eventarc/docs/overview). His older "loss of parallelism" lesson also predates the July 2022 parallel-steps feature.
- A third-party long-form walkthrough builds Cloud Storage → Eventarc → Workflows → Cloud Run with little code. — [Richard Seroter, "Building a long-running, serverless, event-driven system with as little code as possible" (Oct 2022)](https://seroter.com/2022/10/10/building-a-long-running-serverless-event-driven-system-with-as-little-code-as-possible/)

### Inferences
- **Workflows design for ACE:** pass `gs://` URIs and claim IDs between steps, never document bytes, because of the 512 KB variable limit and 2 MB response limit. Use `parallel` for independent per-document extraction (10 branches per step, 20 concurrent). Use a callback step for human adjudication, raising the timeout above the 12 h default. Use `http.default_retry` only on idempotent stage endpoints.
- If a stage's HTTP call from Workflows could pass the Cloud Run 60-minute limit, run it as a Cloud Run job through the connector instead.

### Gaps
- I did not verify the maximum HTTP request timeout for a single Workflows `http.*` call step (commonly quoted as 1800 s). It was not on the quotas page as fetched.
- I did not verify the maximum `await_callback` timeout. The callback page defers to the quotas page, which did not show it.
- I did not fetch the official Architecture Center page for "serverless event processing". I saw only a mirror of the Google Cloud Solutions page (Eventarc + Cloud Run + Terraform + Gemini document understanding); the official URL is presumably `googlecloudplatform.github.io/cloud-solutions/serverless-event-processing`.

---

## Q5. Choosing among Cloud Tasks, Pub/Sub, Workflows and Eventarc for extract → classify → adjudicate, and the Celery/K8s mental map

### Takeaway
Google's own framing is that Cloud Tasks is explicit invocation (the producer controls the target, timing and rate), Pub/Sub is implicit fan-out, Workflows is central orchestration, and Eventarc is event routing. For a document pipeline with 15-30 minute stages, the strongest designs are: (1) the current ACE approach of per-stage Cloud Tasks queues with idempotent handlers (choreography), or (2) Eventarc/API → Workflows orchestrating Cloud Run services or jobs, which gives central state, parallelism and human-approval callbacks. Pub/Sub push is the weakest fit because of its 10-minute limit.

### Cited Findings
- "Cloud Tasks is aimed at **explicit** invocation where the publisher retains full control of execution", while with Pub/Sub publishers have "no control over the delivery of the messages save for the guarantee of delivery". Choose Cloud Tasks when a producer "needs to defer or control the execution timing". Choose Pub/Sub for "general event data ingestion and distribution". — [Choose Pub/Sub or Cloud Tasks](https://docs.cloud.google.com/pubsub/docs/choosing-pubsub-or-cloud-tasks)
- Key limits side by side: Cloud Tasks HTTP 30 min / 1 MB / 500 QPS per queue / dedup / scheduling; Pub/Sub push 10 min / 10 MB / ordering keys / fan-out — [Choose Pub/Sub or Cloud Tasks](https://docs.cloud.google.com/pubsub/docs/choosing-pubsub-or-cloud-tasks); Workflows 1-year executions, 512 KB variables, parallel branches, callbacks — [Workflows quotas](https://docs.cloud.google.com/workflows/quotas); Eventarc at-least-once, no ordering, 512 KB / 1 MB events — [Eventarc overview](https://docs.cloud.google.com/eventarc/docs/overview)
- The billing page names Cloud Tasks as the recommended pattern for async work (retries, up to 30 min) instead of background work in a service, and worker pools for pull workers. — [Billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings)
- Mete Atamel describes a hybrid design: "the trigger is an event but the actual work is done as an orchestrated workflow". — [Integrating Eventarc and Workflows](https://cloud.google.com/blog/topics/developers-practitioners/integrating-eventarc-and-workflows)
- A third-party comparison describes Workflows as ordered execution of several APIs, and Cloud Tasks as async execution through a queue, better for delays and rate limiting (not from Google, so treat it as weak evidence). — [nicheelab Workflows vs Cloud Tasks guide](https://nicheelab.com/articles/gcp/workflows-cloud-tasks-guide/)

### Inferences
**Comparison for extract → classify → adjudicate (synthesis from the cited limits):**

| Need | Cloud Tasks chain (ACE today) | Workflows orchestrator | Pub/Sub push | Eventarc |
|---|---|---|---|---|
| Stage up to 30 min | Yes (hard cap) | Calls Cloud Run (≤60 min) or runs jobs (≤168 h) | No (10 min) | Delivers only, same limits as its target |
| Per-stage rate/concurrency cap | Yes, per queue | Only by concurrency limits / your own code | Only through pull flow control | No |
| Central pipeline state / visibility | No, you build it (DB status table) | Yes, execution history | No | No |
| Fan-out / parallel docs | Enqueue N tasks | `parallel` branches (10/step, 20 concurrent) | Multiple subscriptions | Multiple triggers |
| Human adjudication pause | You build it | Callbacks (12 h default, executions ≤1 yr) | No | No |
| Dedup / idempotency | Task name (best-effort window) + your keys | Your keys; idempotent callbacks | Exactly-once with pull only | At-least-once |
| Ordering | Best-effort only | Sequential steps | Ordering keys | None |
| Payload limit | 1 MB | 512 KB variables, 2 MB responses | 10 MB | 512 KB / 1 MB |

**Celery + Redis + K8s → GCP mapping (my synthesis; each GCP side is backed by the citations above):**
- `task.apply_async(queue="extract")` → `CloudTasksClient.create_task(parent=extract_queue, http_request={url, oidc_token})`. The broker becomes a managed queue, and the worker becomes an HTTP endpoint on a Cloud Run service (push model).
- Celery worker `--concurrency` → Cloud Run `--concurrency` × max instances, plus the queue's `max-concurrent-dispatches`.
- `rate_limit="10/s"` → `max-dispatches-per-second`.
- `autoretry_for`, `retry_backoff`, `max_retries` → queue `max-attempts`, `min/max-backoff`, `max-doublings`, `max-retry-duration`. The handler must return non-2xx to trigger a retry (there is no `self.retry()`).
- `countdown` / `eta` → task `schedule_time`.
- `task_id` for dedup → task `name` (best-effort window).
- `time_limit` / `soft_time_limit` → `dispatch_deadline` (≤30 min) together with the Cloud Run request timeout (≤60 min).
- `chain()` → each stage enqueues the next (choreography) or a Workflows sequence. `group()` / `chord()` → Workflows `parallel` with a join step.
- Celery workers that pull (long-lived consumer Deployment) → Cloud Run worker pools (GA April 2026).
- K8s CronJob / Celery beat → Cloud Scheduler (named as an async caller on the [service-to-service page](https://docs.cloud.google.com/run/docs/authenticating/service-to-service). I did not research its details).
- K8s Job → Cloud Run job. K8s Deployment → Cloud Run service. ArgoCD-style progressive delivery → revisions plus traffic tags.
- **Important behavioural difference:** in Celery, a worker owns CPU for the whole task. On Cloud Run, CPU is guaranteed only while an HTTP request is open (request-based billing). So every unit of async work must be its own HTTP request (a Cloud Tasks task), a job execution, or a worker-pool consumer, never "fire and forget" after the response.

### Gaps
- I found no official Google page that directly compares all four services (Cloud Tasks, Pub/Sub, Workflows, Eventarc) in one table. The table above is a synthesis.
- I found no Google source that explicitly maps Celery concepts to Cloud Tasks. The mapping is an inference.

---

## Q6. Long-form courses, books and video series: what exists and is it current in 2026?

### Takeaway
The main official course is still current. "Developing Applications with Cloud Run on Google Cloud: Fundamentals" on Google Skills (formerly Skills Boost) runs 8 hours, is introductory, was "Updated 8 months ago" (about March 2026), and sits in the Professional Cloud Developer path. It is fundamentals-level, though, not production-deep. The only book (Venema, O'Reilly, December 2020) is good for mental models but predates billing renaming, GPUs, worker pools, instances, jobs sidecars and readiness probes. Serverless Expeditions samples are explicitly "not maintained past the release of the associated video".

### Cited Findings
- **Google Skills course:** title "Developing Applications with Cloud Run on Google Cloud: Fundamentals"; 8 hours; Introductory; "Updated 8 months ago"; part of the Professional Cloud Developer Certification path (path 19). — [skills.google path 19 / course 559](https://www.skills.google/paths/19/course_templates/559)
- Its syllabus covers Cloud Run fundamentals (resource model, container lifecycle, autoscaling), local develop-and-test, deployments and revisions, service identity and IAM, integration with Google Cloud services, and Pub/Sub with Cloud Run. It has a completion badge and a challenge-lab shortcut, and is described as the second course in the "Developing Applications with Google Cloud" series. — [Class Central listing](https://classcentral.com/course/google-cloud-skills-boost-developing-applications-with-cloud-run-on-google-cloud-fundamentals-272723); [Skills Boost listing](https://cloudskillsboost.google/paths/19/course_templates/559)
- A separate, broader course, "Application Development with Cloud Run" (course_templates/371), covers load balancing, Cloud SQL and Pub/Sub. Its current status and length could not be read (the fetch landed on the Google Skills home page). — [skills.google course 371](https://www.skills.google/course_templates/371); [Class Central](https://classcentral.com/course/application-development-with-cloud-run-199741)
- On Coursera, the same Fundamentals course is offered. The Korean version was updated in March 2026 with about 4 hours of content and 3 assignments. Specialization listings disagree on course count (1 vs 3 courses). — [Coursera Fundamentals](https://www.coursera.org/learn/developing-applications-with-cloud-run-on-gcp-fundamentals); [Coursera Korean version](https://www.coursera.org/learn/developing-applications-with-cloud-run-on-google-cloud-fundamentals-ko); [Specialization](https://www.coursera.org/programs/pega/specializations/developing-apps-gcp)
- Google Skills credits: the GEAR program offers "35 monthly credits for hands-on learning in Google Skills, at no cost to you". — [Google Skills home](https://www.skills.google/course_templates/371)
- **Book:** Wietse Venema, *Building Serverless Applications with Google Cloud Run*, O'Reilly, December 2020, about 200 pages. It covers IAM on Cloud Run, Terraform, background task scheduling, Cloud SQL, HTTP sessions, and moving to Knative Serving. — [O'Reilly](https://www.oreilly.com/library/view/building-serverless-applications/9781492057086); [Schweitzer](https://www.schweitzer-online.de/en/buch/Venema/Building-Serverless-Applications-Google-Cloud-Run/9781492057093/A55673904/)
- **Serverless Expeditions:** playlist on Google Cloud Tech. The code repo (Apache-2.0, 123 commits) says "All samples are provided as is, and are not maintained past the release of the associated video". Its Cloud Run folders include `cloud-run-alwayson-cpu-weather-advisory`, `cloud-run-jobs`, `webhooks-with-cloud-run`, `cloud-run-direct-vpc`, `blue-green`, `cloud-run-redis`, `cloud-run-iap`, `scheduled-cloud-run`, `cloud-run-yaml-deployment` and `using-python-on-google-cloud-with-cloud-run`. — [Playlist](https://www.youtube.com/playlist?list=PLIivdWyY5sqJwq_pgOxcHzusWjXDVCEiX); [GitHub repo](https://github.com/GoogleCloudPlatform/serverless-expeditions). A repo tracker shows it updated around April 8, 2026 with about 219 stars. — [relatedrepos](https://relatedrepos.com/gh/GoogleCloudPlatform/serverless-expeditions)
- Episodes include "Can Cloud Run handle these 9 workloads?", "How to trigger Cloud Run on a schedule", Cloud Run Jobs (with Dustin Ingram), and Extended episodes on YAML deployments and three-tier apps, many from 2020. — [cotalks.dev episode list](https://cotalks.dev/events/serverless-expeditions)
- **Most current long-form video (2026):** the Cloud Next '26 "Ultimate Cloud Run guide" talk ([youtu.be/ZEuHBOhy_uY](https://youtu.be/ZEuHBOhy_uY)), recapped by Sara Ford in 15 sections. Topics: rollouts and preview links, structured logging, the "failed to start on port 8080" error, ephemeral disks, volume mounts, Direct VPC egress, the two pricing models, scale-to-zero GPUs (L4 and RTX PRO 6000), worker pools, and a 7-day jobs runtime. It links a companion codelab. — [The Ultimate Cloud Run Guide 2026 (dev.to/googleai)](https://dev.to/googleai/the-ultimate-cloud-run-guide-2026-54f8)

### Inferences
- **Outdated-material flags.** Anything that says "CPU always allocated" uses pre-December-2024 naming. Anything that says jobs max out at 24 h predates the 168 h GA (November 2025). Anything that needs a Cloud Run proxy between Eventarc and Workflows is from 2021. The 2020 book and the 2020-2022 Serverless Expeditions episodes all predate GPUs, worker pools, instances, readiness probes and budget caps. Any "Cloud Run integrations" tutorial uses a feature discontinued in February 2025. Use these older resources for concepts, and the docs and release notes for limits.
- **No production-depth course.** For a learner who already knows K8s, the 8-hour Fundamentals course is a fast on-ramp (worth it mainly for the labs). Production depth comes from the docs pages in Q1-Q4 plus building the hands-on tutorials.

### Gaps
- I could not read the exact module/lab list, credit cost, or any "Serverless Cloud Run Development" quest status on Google Skills. The quest name could not be confirmed as still existing.
- Coursera pricing was not verified.
- The individual Serverless Expeditions episodes for Cloud Tasks, Pub/Sub or Workflows could not be confirmed from the repo folder names.
- Martin Omander's dev.to series exists ([dev.to/martinomander/series/36979](https://dev.to/martinomander/series/36979)), but its contents were not fetched.

---

## Q7. Curated resource catalog with metadata, and GitHub samples

### Takeaway
The highest-value deep resources are free official docs pages and hands-on tutorials on docs.cloud.google.com, supported by a few codelabs, one 8-hour course, the 2026 Next talk and recap, and selected Googler talks and blogs. Google's GitHub samples are mostly Flask-based. I found no Google-maintained, production-grade FastAPI + Cloud Tasks sample.

### Cited Findings
Notes on the catalog fields: "Date" is what was visible. Docs pages showed no last-updated date in the fetched text. "Length" is approximate. All official docs, codelabs, blogs and GitHub repos are free. Hands-on scale: H = step-by-step build; M = code snippets/commands; L = conceptual.

**A. Official docs: Cloud Run (owner: Google Cloud; format: docs page; cost: free)**

| # | Title (best-effort) | URL | Topics | Hands-on | Why it fits ACE / learner |
|---|---|---|---|---|---|
| 1 | Designing Cloud Run services with recommended practices (General development tips) | https://docs.cloud.google.com/run/docs/tips/general | background work vs CPU throttling, temp files, startup, min instances, lazy init, concurrency tuning, container security | M (snippets in 4 languages) | Explains exactly why ACE's background-thread fallback is risky |
| 2 | Optimize Python applications for Cloud Run | https://docs.cloud.google.com/run/docs/tips/python | gunicorn workers/threads, `--preload`, uvicorn, startup probes, `PYTHONUNBUFFERED`, slim images | M | Python/FastAPI-specific |
| 3 | Billing settings (formerly CPU allocation) | https://docs.cloud.google.com/run/docs/configuring/billing-settings | request vs instance-based, 15-min idle, SIGTERM 10 s, worker pools, instances, Cloud Tasks alternative | L-M | Core decision for async work |
| 4 | Configure request timeout | https://docs.cloud.google.com/run/docs/configuring/request-timeout | 300 s default, 3600 s max, retries over 15 min | M | Must match the 900-1800 s task deadlines |
| 5 | Configure container health checks | https://docs.cloud.google.com/run/docs/configuring/healthchecks | startup/liveness/readiness, limits, defaults | M | Maps to K8s probes |
| 6 | Execution environments | https://docs.cloud.google.com/run/docs/about-execution-environments | gen1 vs gen2 | L | Choosing an environment for heavy Python/ML libs |
| 7 | Rollouts, rollbacks, and traffic migration | https://docs.cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration | `--no-traffic`, tags, canary, rollback | H | ArgoCD/Argo Rollouts analogue |
| 8 | Authenticating service-to-service | https://docs.cloud.google.com/run/docs/authenticating/service-to-service | ID tokens, audience, run.invoker, X-Serverless-Authorization | M (Python sample) | ACE api→extract calls |
| 9 | Create jobs | https://docs.cloud.google.com/run/docs/create-jobs | tasks, index, timeouts, retries, parallelism | H | Long or batch stages over 30 min |
| 10 | Configure GPUs for services | https://docs.cloud.google.com/run/docs/configuring/services/gpu | L4/RTX PRO 6000, min CPU/mem, billing, zonal redundancy, regions | M | Self-hosted model inference |
| 11 | Quotas and limits | https://docs.cloud.google.com/run/quotas | memory, vCPU, concurrency, sizes, jobs, GPU quota | L | Interview numbers |
| 12 | Cloud Run release notes | https://docs.cloud.google.com/run/docs/release-notes | dated changes 2024-2026 | L | Checking whether a resource is outdated |
| 13 | Trigger from Pub/Sub push (tutorial) | https://docs.cloud.google.com/run/docs/triggering/pubsub-push | push sub, OIDC, private service | H | Event-driven entry point |
| 14 | Quickstart: Python (FastAPI) to Cloud Run | https://cloud.google.com/run/docs/quickstarts/build-and-deploy/deploy-python-fastapi-service | source deploy, FastAPI 0.116.1 | H (short) | First deploy in under 30 min |

**B. Official docs: Cloud Tasks, Pub/Sub, Workflows, Eventarc (Google Cloud; free)**

| # | Title | URL | Topics | Hands-on | Why |
|---|---|---|---|---|---|
| 15 | Create HTTP target tasks | https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks | 10/30 min handler timeout, OIDC, queue-level auth, retry headers | M (Python) | ACE's core pattern |
| 16 | Configure Cloud Tasks queues | https://docs.cloud.google.com/tasks/docs/configuring-queues | rate limits, retries, routing override | M (gcloud) | Celery queue/rate/retry analogue |
| 17 | tasks.create REST reference | https://docs.cloud.google.com/tasks/docs/reference/rest/v2/projects.locations.queues.tasks/create | task-name dedup window | L | Idempotency |
| 18 | Create HTTP tasks (code sample) | https://docs.cloud.google.com/tasks/docs/samples/cloud-tasks-create-http-task | current Python sample with JSON payload and deadline | M | Copy-ready code |
| 19 | Choose Pub/Sub or Cloud Tasks | https://docs.cloud.google.com/pubsub/docs/choosing-pubsub-or-cloud-tasks | feature/limit table | L | Interview comparison |
| 20 | Push subscriptions | https://docs.cloud.google.com/pubsub/docs/push | ack codes, backoff, slow-start, wrapping, JWT | L-M | Push semantics |
| 21 | Handling message failures (DLQ, retry policy) | https://docs.cloud.google.com/pubsub/docs/handling-failures | DLQ 5-100 attempts, IAM, metrics | M (very long, ~109k chars) | Poison-message handling |
| 22 | Ordering messages | https://docs.cloud.google.com/pubsub/docs/ordering | ordering keys, push limits, redelivery | M | Per-claim ordering |
| 23 | Exactly-once delivery | https://docs.cloud.google.com/pubsub/docs/exactly-once-delivery | pull-only, regional, ack-with-response | M | Common interview trap |
| 24 | Wait using callbacks | https://docs.cloud.google.com/workflows/docs/creating-callback-endpoints | callback endpoint, 12 h default, auth | M | Human adjudication pause |
| 25 | Execute workflow steps in parallel | https://docs.cloud.google.com/workflows/docs/execute-parallel-steps | parallel branches/for | M | Per-document fan-out |
| 26 | Workflows quotas and limits | https://docs.cloud.google.com/workflows/quotas | 1 yr, 512 KB, 2 MB, branches | L | Design constraints |
| 27 | http.default_retry | https://docs.cloud.google.com/workflows/docs/reference/stdlib/http/default_retry | retried codes, max 5 | L | Retry semantics |
| 28 | Execute a Cloud Run job using Workflows (tutorial) | https://docs.cloud.google.com/workflows/docs/tutorials/execute-cloud-run-jobs | Eventarc GCS trigger → Workflows → 10-task job | H (~3-4k words, 10 steps) | Best end-to-end serverless pipeline lab |
| 29 | Eventarc overview | https://docs.cloud.google.com/eventarc/docs/overview | Standard vs Advanced, delivery, DLQ, sizes | L | Event routing |
| 30 | Build a document processing pipeline with Workflows (Document AI) | https://cloud.google.com/document-ai/docs/workflows | Document AI connector in Workflows | H | Closest official analogue to ACE's extract/classify |

**C. Codelabs (Google; free; hands-on H)**
- 31. *Introduction to serverless orchestration with Workflows*. Connects Cloud Functions (Python), a private Cloud Run service, and an external API. — https://codelabs.developers.google.com/codelabs/cloud-workflows-intro
- 32. *Create a Cloud Run worker pool for pull-based Pub/Sub subscriptions*. The modern "Celery-worker-like" pattern. — https://codelabs.developers.google.com/codelabs/cloud-run/cloud-run-worker-pool-pull-based-subscriptions
- 33. *Cloud Run jobs* codelab (found in French; English path presumably the same). — https://developers.google.com/codelabs/cloud-run-jobs

**D. Courses**
- 34. *Developing Applications with Cloud Run on Google Cloud: Fundamentals*. Google Cloud Training, on Google Skills. 8 h, Introductory, updated about March 2026, labs plus challenge lab plus badge. Cost: credits or subscription (exact cost not verified; GEAR gives 35 free credits per month). — https://www.skills.google/paths/19/course_templates/559
- 35. *Application Development with Cloud Run* (broader: load balancing, Cloud SQL, Pub/Sub). Status unverified. — https://www.skills.google/course_templates/371
- 36. Coursera version of #34 (about 4 h in the Korean edition, updated March 2026; Coursera subscription). — https://www.coursera.org/learn/developing-applications-with-cloud-run-on-gcp-fundamentals

**E. Video**
- 37. *Serverless Expeditions* playlist (Google Cloud Tech; hosts include Martin Omander). Many short-to-medium episodes plus "Extended" ones. Free. Many are from 2020-2022. — https://www.youtube.com/playlist?list=PLIivdWyY5sqJwq_pgOxcHzusWjXDVCEiX ; code at https://github.com/GoogleCloudPlatform/serverless-expeditions
- 38. *The Ultimate Cloud Run Guide* (Cloud Next '26 talk) plus the dev.to recap by Sara Ford (Google AI, June 1 [2026]; about 1-1.5k words, 15 sections). — https://youtu.be/ZEuHBOhy_uY ; https://dev.to/googleai/the-ultimate-cloud-run-guide-2026-54f8

**F. Blogs and talks (Googlers)**
- 39. *Making it easier to scale Kafka workloads with Cloud Run worker pools*. Aniruddh Chaturvedi and Adam Kane, June 26 2025, about 1k words. — https://cloud.google.com/blog/products/serverless/exploring-cloud-run-worker-pools-and-kafka-autoscaler
- 40. *Introducing Cloud Run instances* (August 2026). — https://cloud.google.com/blog/products/serverless/introducing-cloud-run-instances
- 41. *Introducing parallel steps for Workflows* (Megan Bruce, July 2022). — https://cloud.google.com/blog/topics/developers-practitioners/introducing-parallel-steps-workflows-speed-up-workflow-executions-by-running-steps-concurrently/
- 42. *Integrating Eventarc and Workflows* (Mete Atamel, May 2021; **outdated proxy advice**). — https://cloud.google.com/blog/topics/developers-practitioners/integrating-eventarc-and-workflows
- 43. *Choreography vs Orchestration* slide decks (Mete Atamel, May 2022; Guillaume Laforge). — https://speakerdeck.com/meteatamel/choreography-vs-orchestration-in-services ; https://speakerdeck.com/glaforge/choreography-vs-orchestration-in-microservices-and-best-practices
- 44. Richard Seroter, long-form Eventarc + Workflows + Cloud Run build (October 2022). — https://seroter.com/2022/10/10/building-a-long-running-serverless-event-driven-system-with-as-little-code-as-possible/

**G. Book**
- 45. Wietse Venema, *Building Serverless Applications with Google Cloud Run* (O'Reilly, December 2020, about 200 pp; paid or O'Reilly subscription; hands-on chapters). Good for mental models, outdated on limits and features. — https://www.oreilly.com/library/view/building-serverless-applications/9781492057086

**H. GitHub samples**
- 46. *GoogleCloudPlatform/cloud-run-microservice-template-python*. Flask, structured JSON logging for Cloud Logging, `invoke` task automation, Cloud Code-ready. Forks show a SIGTERM handler and unit/system tests. It is a production-shaped template but **not FastAPI**. — https://goo.gle/3Qzsqip ; [fork showing SIGTERM + tests](https://github.com/brittek/python)
- 47. *GoogleCloudPlatform/cloud-run-helloworld-python* (minimal template). — https://github.com/GoogleCloudPlatform/cloud-run-helloworld-python
- 48. *GoogleCloudPlatform/serverless-expeditions*. Includes `cloud-run-alwayson-cpu-weather-advisory` (background work with always-on CPU), `cloud-run-jobs`, `webhooks-with-cloud-run`, `cloud-run-redis`. Not maintained after each video. — https://github.com/GoogleCloudPlatform/serverless-expeditions
- 49. *jobs-demos* (`parallel-job`), used by the Workflows → Cloud Run job tutorial (#28). Linked from https://docs.cloud.google.com/workflows/docs/tutorials/execute-cloud-run-jobs
- 50. Archived *googleapis/python-tasks* samples (`create_http_task.py`, `create_http_task_with_token.py`; archived February 1 2024). Use the docs sample (#18) instead. — https://www.github.com/googleapis/python-tasks/blob/7a5a0c6ca5372035521d5366373054a7ba95f2bd/samples/snippets/create_http_task_with_token.py
- Third-party: *Lin-jun-xiang/cloudrun-fastapi-python* (not evaluated). — https://github.com/Lin-jun-xiang/cloudrun-fastapi-python

### Inferences
- **Suggested study order for this learner (about 25-35 h):**
  1. #14 FastAPI quickstart.
  2. #1, #2, #3, #4: the production behaviour core.
  3. #34 course labs, for GCP console/IAM fluency.
  4. #15, #16, #17, #18, then build an ACE-like 3-stage Cloud Tasks chain with OIDC.
  5. #19-#23 Pub/Sub semantics.
  6. #28, then #30, #24, #25: rebuild the same pipeline in Workflows with a callback-based "adjudicate" step.
  7. #32: a worker-pool pull consumer (the Celery analogue).
  8. #7, #5, #8, #10, #11, #12 for interview polish.
  9. #38 talk for 2026 currency.
- The book (#45) and Serverless Expeditions (#37) are optional background, not primary sources.

### Gaps
- I found no Google-maintained FastAPI + Cloud Tasks + OIDC production sample repo. GoogleCloudPlatform samples for Python Cloud Run are mostly Flask.
- I did not locate the official Architecture Center reference architecture pages (for example "serverless event processing" or a generative-AI document summarization architecture) at their canonical URLs.
- The URL of the Next '26 "Ultimate Guide" codelab was not captured.
- The current location of the Cloud Tasks Python snippets inside python-docs-samples is unverified (the `/cloud-tasks/snippets` path returned 404).

---

## Q8. Production interview-style questions with short correct answers

### Takeaway
These 25 questions cover the limits and behaviours that interviewers most often probe, and that ACE's design depends on. Each answer is backed by a fetched official page.

### Cited Findings
1. **Q: What are Cloud Run's two billing modes, and their old names?** A: Request-based (default; formerly "CPU only allocated during request processing") and instance-based (formerly "CPU always allocated"). — [Billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings)
2. **Q: Why is starting a background thread after returning a response risky?** A: With request-based billing, CPU is "disabled or severely limited" after the response, and suspended work resumes only when a later request hits the same instance. — [tips/general](https://docs.cloud.google.com/run/docs/tips/general)
3. **Q: Does instance-based billing make background work safe?** A: It gives CPU, but idle instances can be shut down at any time (SIGTERM with a 10 s grace), and idle instances are kept at most 15 min unless min instances apply. You need durable queues for reliability. — [Billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings)
4. **Q: What are the default and maximum request timeouts?** A: 300 s default, 3600 s max. Google recommends retries above 15 min, and handlers should be idempotent or resumable. — [Request timeout](https://docs.cloud.google.com/run/docs/configuring/request-timeout)
5. **Q: What are the default and maximum concurrency, and how do you tune it?** A: Default 80, max 1,000. Load test, size memory per request, and watch `billable_instance_time`. — [tips/general](https://docs.cloud.google.com/run/docs/tips/general); [Quotas](https://docs.cloud.google.com/run/quotas)
6. **Q: How do you reduce cold starts?** A: Min instances, startup CPU boost, small or lazy-loaded dependencies, and careful global init. Image size does not matter because of image streaming. — [tips/general](https://docs.cloud.google.com/run/docs/tips/general)
7. **Q: How do you run a Python ASGI app, and how many workers?** A: Any ASGI server listening on `$PORT` (for example `uvicorn --port $PORT --host 0.0.0.0 main:app`). Workers ≈ available cores. Add a custom startup probe, or `--preload`, because the default probe passes as soon as the port opens. — [tips/python](https://docs.cloud.google.com/run/docs/tips/python)
8. **Q: What is the difference between startup, liveness and readiness probes on Cloud Run?** A: Startup gates the others. Liveness restarts the container. Readiness stops new traffic without killing the instance. TCP is allowed only for startup. The default TCP startup probe is 240 s. Readiness probes went GA in June 2026. — [Health checks](https://docs.cloud.google.com/run/docs/configuring/healthchecks); [Release notes](https://docs.cloud.google.com/run/docs/release-notes)
9. **Q: Gen1 or gen2?** A: Gen1 (gVisor) has faster cold starts and allows memory under 512 MiB. Gen2 (microVM) gives full Linux, NFS, and faster CPU and network, and needs at least 512 MiB. Jobs and worker pools are always gen2. — [Execution environments](https://docs.cloud.google.com/run/docs/about-execution-environments)
10. **Q: How do you do a canary and roll back?** A: `deploy --no-traffic --tag canary`, then `update-traffic --to-revisions REV=5`, and so on. To roll back, `update-traffic --to-revisions OLD=100`, which applies immediately without health checks. — [Rollouts](https://docs.cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration)
11. **Q: When should you use a Cloud Run job instead of a service?** A: For run-to-completion work with no HTTP serving. Up to 10,000 parallel tasks with `CLOUD_RUN_TASK_INDEX`. Task timeout is 10 min by default and up to 168 h (12 h with GPU). Retries default to 3 (range 0-10). — [Create jobs](https://docs.cloud.google.com/run/docs/create-jobs)
12. **Q: What are worker pools for?** A: Continuous, non-HTTP, pull-based consumers (Pub/Sub pull, Kafka). They have no public endpoint, cost up to 40% less than instance-billed services, use instance-split rollouts, and went GA in April 2026. — [Worker pools blog](https://cloud.google.com/blog/products/serverless/exploring-cloud-run-worker-pools-and-kafka-autoscaler); [Release notes](https://docs.cloud.google.com/run/docs/release-notes)
13. **Q: How does one Cloud Run service securely call another?** A: Give the caller's service account `roles/run.invoker` on the target. Fetch an ID token with `aud` set to the target URL or a custom audience, and send it as a Bearer token (or in `X-Serverless-Authorization`). Tokens last about 1 h. — [Service-to-service](https://docs.cloud.google.com/run/docs/authenticating/service-to-service)
14. **Q: What are the requirements for GPUs on Cloud Run?** A: Instance-based billing is required, but scale-to-zero still works. L4 needs at least 4 CPU and 16 GiB. RTX PRO 6000 needs at least 20 CPU and 80 GiB. One GPU per instance, about 5 s startup, and zonal redundancy is on by default. — [GPU config](https://docs.cloud.google.com/run/docs/configuring/services/gpu)
15. **Q: What is the maximum handler time for a Cloud Tasks HTTP target?** A: 10 min default, 30 min max (`dispatch_deadline`). — [HTTP target tasks](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks)
16. **Q: You set `dispatch_deadline=1800s`, but tasks die at 5 min. Why?** A: The Cloud Run service request timeout is still at its 300 s default. It must be ≥ 1800 s. (This combines the two cited limits.) — [Request timeout](https://docs.cloud.google.com/run/docs/configuring/request-timeout); [HTTP target tasks](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks)
17. **Q: How do you authenticate Cloud Tasks to a private Cloud Run service?** A: Set `oidcToken.serviceAccountEmail` (the SA must be in the queue's project) and optionally `audience`, and grant that SA Cloud Run Invoker. Queue-level auth overrides task-level auth. — [HTTP target tasks](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks)
18. **Q: Which retry knobs does a queue have?** A: `max-attempts` (includes the first attempt), `max-retry-duration`, `min-backoff`, `max-backoff`, `max-doublings`. Retries stop only when both limits are reached. The rate is controlled by `max-dispatches-per-second` and `max-concurrent-dispatches`. — [Configure queues](https://docs.cloud.google.com/tasks/docs/configuring-queues)
19. **Q: How do you dedupe and make Cloud Tasks handlers idempotent?** A: Use a deterministic task name; the name stays reserved for up to 24 h (9 days for queue.yaml), though one reference says 1 h. Also use your own DB idempotency key, and read `X-CloudTasks-TaskRetryCount` / `ExecutionCount`. — [tasks.create](https://docs.cloud.google.com/tasks/docs/reference/rest/v2/projects.locations.queues.tasks/create); [HTTP target tasks](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks)
20. **Q: Cloud Tasks vs Pub/Sub, in one sentence?** A: Cloud Tasks is explicit invocation (the producer controls target, timing and rate; dedup and scheduling; 30 min; 1 MB; 500 QPS per queue). Pub/Sub is implicit fan-out (many subscribers; ordering keys; 10 min push; 10 MB). — [Choose Pub/Sub or Cloud Tasks](https://docs.cloud.google.com/pubsub/docs/choosing-pubsub-or-cloud-tasks)
21. **Q: Does exactly-once delivery work with push to Cloud Run?** A: No. It is pull-only, works only with same-region subscribers, has higher latency, and needs ack-with-response. — [Exactly-once](https://docs.cloud.google.com/pubsub/docs/exactly-once-delivery)
22. **Q: What happens with ordering keys on a push subscription and on redelivery?** A: Push allows only one outstanding message per key. A redelivery re-sends all later messages for that key, even acked ones. A DLQ may break order. The limit is 1 MBps per key. — [Ordering](https://docs.cloud.google.com/pubsub/docs/ordering)
23. **Q: How do you configure a dead-letter topic?** A: On the subscription, set max delivery attempts to 5-100 (default 5). Grant the Pub/Sub service agent publisher on the DLT and subscriber on the subscription. Forwarding is best-effort. Monitor `dead_letter_message_count`. — [Handling failures](https://docs.cloud.google.com/pubsub/docs/handling-failures)
24. **Q: What are the key Workflows limits for a long pipeline?** A: Executions last up to 1 year. Callback wait defaults to 12 h. 10 branches per parallel step and 20 concurrent. 512 KB of variables and a 2 MB HTTP response, so pass GCS URIs. `http.default_retry` retries 429/502/503/504 up to 5 times. — [Workflows quotas](https://docs.cloud.google.com/workflows/quotas); [Callbacks](https://docs.cloud.google.com/workflows/docs/creating-callback-endpoints); [default_retry](https://docs.cloud.google.com/workflows/docs/reference/stdlib/http/default_retry)
25. **Q: What delivery guarantees does Eventarc give, and when would you use it?** A: At-least-once, no ordering, 24 h retry with backoff, and CloudEvents format. A DLQ is available in Standard through Pub/Sub. Use it to route platform events (for example a GCS object finalized) to Cloud Run or Workflows. — [Eventarc overview](https://docs.cloud.google.com/eventarc/docs/overview)

### Inferences
- An interviewer at a company running an ACE-like system will most likely dig into Q2/Q3 (background work), Q16 (timeout mismatch), Q19 (idempotency), and Q20/Q24 (why Cloud Tasks rather than Workflows or Pub/Sub). The learner should be able to draw the ACE flow and point to where each retry, timeout and auth boundary sits.

### Gaps
- I did not research or cite ingress-setting questions ("internal" vs "all", and how they combine with IAM), Cloud Scheduler questions, or VPC egress questions in this session.
