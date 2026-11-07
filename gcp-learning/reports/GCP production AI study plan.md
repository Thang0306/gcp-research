# Learn Google Cloud by Shipping Production AI

*Research date: 2026-11-06. For: Vietnamese AI engineer (Python/FastAPI, LangGraph, RAG with Qdrant/FalkorDB/Neo4j, Celery + Redis, PostgreSQL, Docker, Kubernetes RKE2/Helm/ArgoCD, vLLM, Azure Document Intelligence, Prometheus/Grafana/Langfuse), zero GCP, now building an OCR + claim/search engine on GCP at Pacific Cross Vietnam.*

## Tóm tắt (VI)

Không có một khóa học dài nào dạy đủ "AI production trên Google Cloud" năm 2026. Cách học nhanh và sâu nhất cho bạn là kết hợp ba thứ. Thứ nhất, đọc tài liệu chính thức theo từng dịch vụ: Cloud Run, Cloud Tasks/Pub/Sub/Workflows, Firestore, BigQuery, Cloud Storage, Document AI và Agent Platform. Thứ hai, làm codelab. Thứ ba, tự xây 6 project nhỏ bằng Claude Code trong một project sandbox riêng, có budget và luật an toàn rõ ràng. Năm tài nguyên quan trọng nhất là: (1) trang "Claude Code on Google Cloud's Agent Platform"; (2) tài liệu Anthropic "Claude Models on Google Cloud"; (3) bộ tài liệu production của Cloud Run (billing, timeout, health check, rollout, service-to-service auth); (4) Cloud Run AI cookbook, có 77 bài đến tháng 8/2026; (5) khóa Anthropic Academy "Claude with Google Cloud's Vertex AI".

Năm 2026 có nhiều thay đổi. Vertex AI đổi tên thành **Gemini Enterprise Agent Platform**. Agent Engine đổi thành Agent Runtime. Skills Boost đổi thành **Google Skills** (skills.google). Tài liệu chuyển sang **docs.cloud.google.com**. Gemini 2.5 đã bị retire trên Vertex ngày **20/10/2026**. Tuy vậy, API vẫn là `aiplatform.googleapis.com` và role vẫn là `roles/aiplatform.user`. Nên bỏ qua các khóa luyện thi chứng chỉ dạng "rộng" (Udemy, Coursera PMLE/PCA, Generative AI Leader). Kế hoạch học là 12 tuần, 8–10 giờ mỗi tuần. Bẫy lớn nhất khi chuyển từ Celery/K8s sang: ở chế độ billing mặc định, Cloud Run gần như ngắt CPU sau khi trả response. Vì vậy không được chạy việc nền bằng thread; hãy dùng Cloud Tasks, Cloud Run job hoặc worker pool. Cuối báo cáo có 126 câu hỏi phỏng vấn production (121 câu ngắn theo 8 nhóm và 5 tình huống thiết kế hệ thống) kèm đáp án ngắn và nguồn. Ngoài ra còn có danh sách điều phải tự kiểm tra trong sandbox. Ví dụ: model Claude nào chạy được ở endpoint `asia-southeast1`, vì nguồn của Google và Anthropic đang mâu thuẫn.

## Bottom line

**No single long course teaches production AI on Google Cloud in 2026.** The best path for you is a set of free official docs, codelabs and sample repos. Study them service by service, then test what you learn by building six small systems with Claude Code in a sandbox project. The core reading set is small:

- Anthropic's Claude Code on Agent Platform page and "Claude Models on Google Cloud" docs.
- The Cloud Run production pages and the Cloud Run AI cookbook (**77 entries up to 2026-08-17**) ([Cloud Run AI cookbook](https://docs.cloud.google.com/run/docs/ai/cookbook)).
- The limit pages for Cloud Tasks, Pub/Sub and Workflows.
- The BigQuery DML page and the Firestore transaction pages.
- The Document AI limits page.

Most paid video courses and cert-prep tracks fail you in one of two ways. Some only teach breadth for an exam. Others were recorded before the April 2026 rename. The rename matters. Vertex AI is now Gemini Enterprise Agent Platform ([Wikipedia](https://en.wikipedia.org/wiki/Gemini_Enterprise_Agent_Platform)). **Gemini 2.5 Pro/Flash/Flash-Lite were retired on Vertex on October 20, 2026** ([Model versions and lifecycle](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versioning)). Agent Starter Pack is archived ([GitHub](https://github.com/GoogleCloudPlatform/agent-starter-pack)). So you must "translate" any tutorial made before mid-2026 to the new names.

Your Kubernetes, Celery and Azure skills transfer well, with one dangerous exception. Under default (request-based) billing, Cloud Run "disables or severely limits" CPU after the response is sent ([Cloud Run tips](https://docs.cloud.google.com/run/docs/tips/general)). So "fire and forget" work must become a queued HTTP task, a job or a worker pool.

Production interviewers probe exactly these boundaries: timeouts, retries, idempotency, quotas, data residency and IAM. This report gives 126 questions with short, sourced answers: 121 short questions in eight areas, plus five system-design scenarios. A few important facts conflict across sources. The biggest one is which Claude models run on the Singapore regional endpoint. The report ends with a list of things to verify yourself.

---

## Three 2026 renames turn most tutorials into translation work

**Vertex AI was renamed "Gemini Enterprise Agent Platform" at Google Cloud Next '26 on April 22, 2026.** Agentspace and Agent Builder were folded into it ([Wikipedia](https://en.wikipedia.org/wiki/Gemini_Enterprise_Agent_Platform); [HPCwire](https://www.hpcwire.com/aiwire/2026/04/23/google-unveils-gemini-enterprise-agent-platform/)). The good news: **the API surface did not change.** The host is still `aiplatform.googleapis.com`. The IAM role is still `roles/aiplatform.user`. Claude Code still uses the env var `CLAUDE_CODE_USE_VERTEX` ([Claude Code on Agent Platform](https://code.claude.com/docs/en/google-vertex-ai)). So old code keeps running, but console names, docs URLs and SDK packages changed.

Two more renames affect every link in this report:

- **Google Cloud Skills Boost is now "Google Skills" at skills.google** ([Google Developer Program FAQ](https://developers.google.com/profile/help/benefits)). Old `cloudskillsboost.google` URLs redirect.
- **Docs moved.** `cloud.google.com/<product>/docs/...` now redirects (HTTP 301) to `docs.cloud.google.com/...`. Example: [docs.cloud.google.com/run/docs/tips/general](https://docs.cloud.google.com/run/docs/tips/general).

Interviewers may still say "Vertex AI". Answer with "Agent Platform (formerly Vertex AI)". It shows you are current.

Use this table as a "translation pass" whenever you open a course, book, notebook or blog post.

| What an older resource shows | What is true in November 2026 | Source |
|---|---|---|
| Vertex AI, Vertex AI Studio, Vertex AI Search, Vertex AI Pipelines | Gemini Enterprise Agent Platform, Agent Studio, Agent Search, Agent Platform Pipelines | [Release notes](https://docs.cloud.google.com/gemini-enterprise-agent-platform/release-notes?hl=de) |
| Reasoning Engine / Agent Engine | **Agent Runtime** | [HPCwire](https://www.hpcwire.com/aiwire/2026/04/23/google-unveils-gemini-enterprise-agent-platform/) |
| `from vertexai.generative_models import GenerativeModel` | `from google import genai`. The old module was deprecated on 2025-06-24, with removal scheduled for 2026-06-24 | [Deprecations](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/deprecations) |
| `genai.Client(vertexai=True)` | Current docs use `genai.Client(enterprise=True, project=..., location=...)` and `GOOGLE_GENAI_USE_ENTERPRISE` (some samples still show `vertexai=True`) | [google-genai docs](https://googleapis.github.io/python-genai/) |
| `google-cloud-aiplatform` for everything | `google-cloud-agentplatform` was split out on 2026-09-18. Gen AI modules moved to the Gen AI SDK | [Release notes](https://docs.cloud.google.com/gemini-enterprise-agent-platform/release-notes) |
| `gemini-2.0-*`, `gemini-2.5-pro/flash/flash-lite` | Retired on Vertex (2.0 on 2026-06-01, 2.5 on **2026-10-20**). Use `gemini-3.5-flash`, `gemini-3.8-flash` or `gemini-4-argon`. `gemini-3.6-flash` retires 2026-11-19 | [Model lifecycle](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versioning) |
| `uvx agent-starter-pack create` | Agent Starter Pack is archived (maintenance mode). Successor: **agents-cli** (`uvx google-agents-cli setup`) | [ASP repo](https://github.com/GoogleCloudPlatform/agent-starter-pack); [agents-cli migration](https://google.github.io/agents-cli/reference/from-agent-starter-pack/) |
| `docs.anthropic.com/en/api/claude-on-vertex-ai` | `platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/...`. There are now **two** offerings: Google-managed and Anthropic-managed | [Anthropic overview](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/overview) |
| `claude-sonnet-4-5@20250929` as a default | Sonnet 4.5, Sonnet 4, Opus 4.1 and Opus 4 are deprecated on Vertex. Claude 4.6+ use plain IDs (`claude-sonnet-5`, `claude-opus-5-5`, `claude-haiku-5-5`) | [Anthropic: Google managed](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/google-managed) |
| Cloud Run "CPU always allocated" / "CPU only during requests" | **Instance-based** / **request-based billing** (renamed 2024-12-13) | [Billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings); [Cloud Run release notes](https://docs.cloud.google.com/run/docs/release-notes) |
| Cloud Run jobs max 24 h | Max task timeout is **168 h** (GA 2025-11-11); 12 h with GPU | [Create jobs](https://docs.cloud.google.com/run/docs/create-jobs) |
| Serverless VPC Access connector as the only option | **Direct VPC egress** is recommended | [Connect to a VPC](https://docs.cloud.google.com/run/docs/configuring/connecting-vpc) |
| Cloud Run → proxy → Workflows behind Eventarc (2021 posts) | Eventarc Standard targets Workflows directly | [Eventarc overview](https://docs.cloud.google.com/eventarc/docs/overview) |
| "Cloud Run integrations" | Discontinued 2025-02-07 | [Cloud Run release notes](https://docs.cloud.google.com/run/docs/release-notes) |
| `gcr.io` Container Registry | Writes blocked 2025-03-18, reads blocked 2025-06-03. Use Artifact Registry | [GCR transition](https://docs.cloud.google.com/kubernetes-engine/docs/deprecations/container-registry) |
| Cloud Source Repositories in labs | End-of-sale 2024-06-17 | [CSR migration](https://docs.cloud.google.com/source-repositories/docs/migration-guides) |
| Deployment Manager | End of support 2026-03-31. Use Terraform or Infrastructure Manager | [DM deprecations](https://docs.cloud.google.com/deployment-manager/docs/deprecations) |
| GitLab `CI_JOB_JWT_V2` | Removed in GitLab 17.0. Use `id_tokens` | [GitLab OIDC + GCP](https://docs.gitlab.com/ci/cloud_services/google_cloud/) |
| BigQuery `tabledata.insertAll` | Now documented as "Storage Write API (REST)" | [Write API REST](https://docs.cloud.google.com/bigquery/docs/write-api-rest) |
| "Fill in a form to opt out of abuse monitoring" | Current page: Master Agreement customers are exempt by default; otherwise contact your account team | [Abuse monitoring](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/abuse-monitoring) |

A fast way to spot a stale resource is to scan it for five signals. Gemini 1.x/2.x model IDs. `vertexai.generative_models` imports. The words "CPU always allocated". `gcr.io` images. Cloud Source Repositories. Any one of these means the resource is from before 2025–2026. You can still use it for concepts. But take limits, names and code from the current docs and release notes.

---

## Twenty-six ranked resources cover everything you need

The ranking uses four tests. **Depth:** does it explain production behaviour and limits, not just a "hello world"? **Hands-on:** can you run it in a real GCP project? **Freshness:** after the April 2026 rename is best, and anything before 2025 is flagged. **Fit to your CV:** Python/FastAPI, async workers, RAG, Kubernetes and OCR. Official Google and Anthropic docs win most slots, because they are free, long, current and exact. Short descriptions and cert-breadth material are left out on purpose.

### What practice costs

**Google docs, codelabs and repos are free. You pay only for your own GCP usage.** The Always Free tier covers small workloads every month: Cloud Run (2M requests, 180,000 vCPU-s, 360,000 GB-s), Firestore (1 GiB storage and 50k reads per day), BigQuery (1 TiB query and 10 GiB storage), Cloud Storage (5 GB-months in three US regions), Cloud Build (2,500 build-minutes) and Cloud Logging (50 GiB). **Document AI and Agent Platform have no free usage** ([Google Cloud free program](https://docs.cloud.google.com/free/docs/free-cloud-features)).

The $300 / 90-day trial has a trap for this plan. **Trial credit cannot pay for model-as-a-service partner models (so not for Claude), blocks GPUs, and blocks quota increases** ([free program docs](https://docs.cloud.google.com/free/docs/free-cloud-features)). So for Claude practice you need a paid billing account with a tight budget, or a company dev project with permission.

Google Skills gives **35 free learning credits per month** on the free Google Developer Program tier ([Developer Program FAQ](https://developers.google.com/profile/help/benefits)). Paid plan prices conflict across Google pages ($29/month, $45/user/month and $24.99/month all appear), so check the live page before you pay ([Skills subscriptions](https://cloudskillsboost.google/subscriptions); [Developer Program plans](https://developers.google.com/program/plans-and-pricing)).

### Tier A — core curriculum (do all, roughly in this order)

| # | Resource | Format · length · cost | Freshness | What it covers | Why it fits you |
|---|---|---|---|---|---|
| 1 | [Claude Code on Google Cloud's Agent Platform](https://code.claude.com/docs/en/google-vertex-ai) (Anthropic) | Docs, 1 long page · free | Current (2026) | `/setup-vertex` wizard, env vars, model pinning, `roles/aiplatform.user`, 404/429 troubleshooting | Your daily tool. You configure it on day 1 |
| 2 | [Claude Models on Google Cloud — Google managed](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/google-managed) + [overview](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/overview) (Anthropic) | Docs, 2 pages, code in 7 languages · free | Current (references API version 2026-10-21) | `AnthropicVertex`, global/multi-region/regional endpoints, model IDs, features **not** on Vertex, 30 MB payload limit, logging | Almost every "Claude on GCP" interview answer comes from here |
| 3 | [Anthropic Academy: Claude with Google Cloud's Vertex AI](https://anthropic.skilljar.com/claude-with-google-vertex) | Video course + final assessment · lesson count and cost not confirmed (needs registration) | Not dated | Setup, multi-turn, tool use, RAG (chunking, BM25, reranking, contextual retrieval), PDFs, citations, prompt caching, MCP, Claude Code, agent workflows | The only long course built for Claude on GCP. It assumes Python + basic GCP, which you will have after week 2 |
| 4 | Cloud Run production docs: [general tips](https://docs.cloud.google.com/run/docs/tips/general), [Python tips](https://docs.cloud.google.com/run/docs/tips/python), [billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings), [request timeout](https://docs.cloud.google.com/run/docs/configuring/request-timeout), [health checks](https://docs.cloud.google.com/run/docs/configuring/healthchecks), [rollouts](https://docs.cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration), [service-to-service auth](https://docs.cloud.google.com/run/docs/authenticating/service-to-service), [jobs](https://docs.cloud.google.com/run/docs/create-jobs), [quotas](https://docs.cloud.google.com/run/quotas), [release notes](https://docs.cloud.google.com/run/docs/release-notes) | ~10 doc pages · free | Current. Use the release notes to date each fact | CPU after response, concurrency tuning, cold starts, probes, canary/rollback, ID tokens, jobs, limits | Replaces your Deployment/HPA/probe knowledge with exact Cloud Run behaviour |
| 5 | Next '26 talk ["The ultimate Cloud Run guide"](https://youtu.be/ZEuHBOhy_uY) + [codelab "from zero to production"](https://codelabs.developers.google.com/next26/ultimate-cloud-run-guide) + [recap](https://dev.to/googleai/the-ultimate-cloud-run-guide-2026-54f8) | Talk + 10-section codelab · free (GCP usage billed) | 2026 | Rollouts, structured logging, Direct VPC egress, worker pools, GPUs, Secret Manager, internal ingress + `run.invoker`, ADK agent | The most current end-to-end Cloud Run lab |
| 6 | [Cloud Run AI cookbook](https://docs.cloud.google.com/run/docs/ai/cookbook) | 77 codelabs/blogs/videos · free | 2024-10 → 2026-08-17 | ADK + RAG, LangChain agent, vLLM on Cloud Run GPUs, AI cold starts, Model Armor, MCP auth, agent evaluation, Eventarc agents | Pick about 15 entries. It matches your vLLM and RAG background. **No entry covers Document AI, Cloud Tasks or Claude** |
| 7 | Gemini production set: [google-genai SDK](https://googleapis.github.io/python-genai/), [model lifecycle](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versioning), [Standard PayGo](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/standard-paygo), [data residency](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/data-residency?hl=en), [reduce-429s blog](https://cloud.google.com/blog/products/ai-machine-learning/reduce-429-errors-on-vertex-ai) | Very long SDK reference + 4 pages · free | Current (Nov 2026); blog dated 2026-03-12 | Structured output, function calling, context caching, batch, async; retirement dates; what 429 really means; residency per model | Gemini interview questions are about quotas, retirement and residency, not prompting |
| 8 | Async pipeline docs: [Cloud Tasks HTTP targets](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks), [configure queues](https://docs.cloud.google.com/tasks/docs/configuring-queues), [Pub/Sub vs Cloud Tasks](https://docs.cloud.google.com/pubsub/docs/choosing-pubsub-or-cloud-tasks), [push](https://docs.cloud.google.com/pubsub/docs/push), [exactly-once](https://docs.cloud.google.com/pubsub/docs/exactly-once-delivery), [ordering](https://docs.cloud.google.com/pubsub/docs/ordering), [dead-letter](https://docs.cloud.google.com/pubsub/docs/handling-failures), [Workflows limits](https://docs.cloud.google.com/workflows/quotas), [callbacks](https://docs.cloud.google.com/workflows/docs/creating-callback-endpoints), [Eventarc](https://docs.cloud.google.com/eventarc/docs/overview) + tutorial [Workflows runs a Cloud Run job](https://docs.cloud.google.com/workflows/docs/tutorials/execute-cloud-run-jobs) | ~11 pages + 1 tutorial (10 steps) · free | Current | Deadlines, rate limits, retries, dedup, OIDC, DLQ, ordering, orchestration | Replaces your Celery + Redis broker knowledge with managed equivalents |
| 9 | Data layer docs. BigQuery: [DML](https://docs.cloud.google.com/bigquery/docs/data-manipulation-language), [transactions](https://docs.cloud.google.com/bigquery/docs/transactions), [quotas](https://docs.cloud.google.com/bigquery/quotas), [Storage Write API](https://docs.cloud.google.com/bigquery/docs/write-api), [cost control](https://docs.cloud.google.com/bigquery/docs/best-practices-costs). Firestore: [best practices](https://docs.cloud.google.com/firestore/native/docs/best-practices), [transactions](https://docs.cloud.google.com/firestore/native/docs/manage-data/transactions), [contention](https://firebase.google.com/docs/firestore/transaction-data-contention), [counters](https://docs.cloud.google.com/firestore/native/docs/solutions/counters), [TTL](https://docs.cloud.google.com/firestore/native/docs/ttl). GCS: [signed URLs](https://docs.cloud.google.com/storage/docs/access-control/signed-urls), [resumable uploads](https://docs.cloud.google.com/storage/docs/performing-resumable-uploads), [Bucket Lock](https://docs.cloud.google.com/storage/docs/bucket-lock), [notifications](https://docs.cloud.google.com/storage/docs/pubsub-notifications) | ~15 pages · free | Current | DML concurrency, table locks, hot spots, leases, browser uploads, retention | Most data "gotcha" questions live here. BigQuery is not PostgreSQL |
| 10 | Document AI: [limits](https://docs.cloud.google.com/document-ai/limits), [regions](https://docs.cloud.google.com/document-ai/docs/regions), [Enterprise OCR](https://docs.cloud.google.com/document-ai/docs/enterprise-document-ocr), [layout parser](https://docs.cloud.google.com/document-ai/docs/layout-parse-chunk), [Toolbox](https://docs.cloud.google.com/document-ai/docs/toolbox), [document-ai-samples](https://github.com/GoogleCloudPlatform/document-ai-samples) + badges [Automate Data Capture at Scale (674)](https://www.skills.google/course_templates/674) and [Build Custom Processors (686)](https://www.cloudskillsboost.google/course_templates/686) | Docs + 2 skill badges (686 is ~6 h 15 min, 30 credits) · docs free | Docs current. The 686 challenge lab is dated 2024-04-18 | Online/batch limits, checkbox add-on, custom extractors, version pinning, Toolbox → BigQuery | The GCP version of your Azure Document Intelligence work |
| 11 | [Architecture Center: Automate utilization-review of insurance claims](https://docs.cloud.google.com/architecture/use-generative-ai-utilization-management) | Long article + Terraform · free | Not dated | GCS → Cloud Run ingestion → Document AI → Firestore status → human-review app → Gemini; HIPAA/BAA, CMEK | The closest public reference to an insurance OCR + claims system |
| 12 | Security docs: [service account best practices](https://docs.cloud.google.com/iam/docs/best-practices-service-accounts), [use IAM securely](https://docs.cloud.google.com/iam/docs/using-iam-securely), [WIF for pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines), [Cloud Run ingress](https://docs.cloud.google.com/run/docs/securing/ingress), [Pub/Sub push auth](https://docs.cloud.google.com/pubsub/docs/authenticate-push-subscriptions), [Cloud Run secrets](https://docs.cloud.google.com/run/docs/configuring/services/secrets), [static egress IP](https://docs.cloud.google.com/run/docs/configuring/static-outbound-ip), [ALB + Cloud Armor](https://docs.cloud.google.com/load-balancing/docs/https/setting-up-https-serverless), [VPC-SC for Cloud Run](https://docs.cloud.google.com/run/docs/securing/using-vpc-service-controls), Agent Platform [data governance](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/data-governance) / [ZDR](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/vertex-ai-zero-data-retention), [Sensitive Data Protection de-identify](https://docs.cloud.google.com/sensitive-data-protection/docs/deidentify-sensitive-data), [Model Armor lab](https://www.skills.google/catalog_lab/32261) | ~20 pages + 1 lab · free | Current | IAM, keyless CI, OIDC verification, egress IP, perimeters, PII removal before LLM calls | Health-claim data needs every one of these controls |
| 13 | Ops and cost docs: [Cloud Run logging](https://docs.cloud.google.com/run/docs/logging), [OpenTelemetry for Python](https://docs.cloud.google.com/trace/docs/setup/python-ot), [Managed Prometheus sidecar](https://docs.cloud.google.com/stackdriver/docs/managed-prometheus/cloudrun-sidecar), [SLO burn-rate alerts](https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate), [LLM request-response logging](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/multimodal/request-response-logging), [context cache](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview), [billing export](https://docs.cloud.google.com/billing/docs/how-to/export-data-bigquery), [budgets](https://docs.cloud.google.com/billing/docs/how-to/budgets), [spend caps](https://docs.cloud.google.com/billing/docs/how-to/budgets-spend-caps), [Cloud Run pricing](https://cloud.google.com/run/pricing) | ~12 pages · free | Current (spend caps GA October 2026) | JSON logs + trace links, PromQL on Cloud Run, SLOs, token cost, hard spend caps | Maps straight from your Prometheus/Grafana/Langfuse stack |
| 14 | Terraform: [best-practices series](https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure), [root modules](https://docs.cloud.google.com/docs/terraform/best-practices/root-modules), [state in GCS](https://docs.cloud.google.com/docs/terraform/resource-management/store-state), course [Getting Started with Terraform for Google Cloud](https://www.cloudskillsboost.google/course_templates/443), [Cloud Foundation Fabric](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric) | Docs + 6 h 30 min course (16 credits) + large repo | Docs current | Module layout, `environments/{dev,uat,prod}`, GCS state, project factory | The same idea as your Helm values per environment |
| 15 | [SRE Workbook](https://sre.google/workbook/table-of-contents/) ch. 2, 4, 5, 16, 17 + [SRE book](https://sre.google/sre-book/table-of-contents/) ch. 21, 22 + [AI in SRE](https://sre.google/resources/practices-and-processes/ai-engineering-reliable-operations/) | Free online books + long article | Books 2016–2018; AI article is new | SLOs, alerting on SLOs, canarying, overload, cascading failures, agent guardrails | Production vocabulary for any interview |

### Tier B — agents, RAG and evaluation depth

| # | Resource | Format · length · cost | Freshness | What it covers | Why it fits you |
|---|---|---|---|---|---|
| 16 | [ADK docs (ADK 2.0)](https://adk.dev/) | Large docs site · free, open source | 2026 | Agents, multi-agent, tools (function, MCP, OpenAPI), sessions/memory, A2A, live agents, eval, deploy to Agent Runtime / Cloud Run / GKE. It has a Claude model page and LiteLLM support | Google's default agent framework. Learn it well enough to compare it with LangGraph |
| 17 | [agents-cli](https://google.github.io/agents-cli/reference/from-agent-starter-pack/) + [Agent Starter Pack (archived)](https://github.com/GoogleCloudPlatform/agent-starter-pack) | CLI + templates (`adk`, `adk_a2a`, `agentic_rag`, `langgraph`, `adk_live`) · free | ASP archived in 2026; agents-cli is current | Terraform, Cloud Build/GitHub Actions CI/CD, observability and eval for agents | Read the ASP `langgraph` and `agentic_rag` code as a "production layout" reference. Start new work with agents-cli |
| 18 | [GoogleCloudPlatform/generative-ai](https://github.com/GoogleCloudPlatform/generative-ai) | Hundreds of notebooks, 17.8k stars · free + GCP usage | Active (README promotes Gemini 4 Argon) | Gemini, RAG/grounding, agents, embeddings, partner models, eval tools; `RESOURCES.md` lists blogs and playlists | Copyable code. Check imports and model IDs first |
| 19 | [Gen AI evaluation service](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/evaluation-overview) + [define metrics](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/determine-eval) | Multi-page docs · free | 2026 (GenAI Client eval is Preview) | Adaptive rubrics (per-prompt pass/fail tests), `GENERAL_QUALITY`, tool-call and grounding metrics | You need a golden set for claim extraction |
| 20 | [Kaggle × Google 5-Day AI Agents Intensive](https://blog.google/innovation-and-ai/technology/developers-tools/ai-agents-intensive-recap/) | Whitepapers + podcasts + Kaggle notebooks + capstone · free | Nov 2025 + Jun 2026 "Vibe Coding" edition; now self-paced | Agent concepts, tools, memory, eval, prototype → production | Deep concepts in one structured week. Runs in Kaggle, not your GCP project |
| 21 | Book: [GenAI on Google Cloud](https://www.oreilly.com/library/view/genai-on-google/9798341623842/ch07.html) (Adedeji, Nigam, Joshi, Gervasi) | O'Reilly, ~317 pages · paid or O'Reilly subscription | Jan/Mar 2026 (still says "Vertex") | Multimodal ADK agent (ch. 3), evaluation (ch. 5), MLOps/AgentOps "nine pillars" (ch. 7), maturity framework (ch. 8) | The best current book. Read ch. 5 and 7 closely |
| 22 | Architecture Center: [agentic components](https://docs.cloud.google.com/architecture/choose-agentic-ai-architecture-components), [agent design patterns](https://docs.cloud.google.com/architecture/choose-design-pattern-agentic-ai-system?hl=ru), RAG on [AlloyDB](https://docs.cloud.google.com/architecture/rag-capable-gen-ai-app-using-vertex-ai) and on [GKE + Cloud SQL](https://docs.cloud.google.com/architecture/rag-capable-gen-ai-app-using-gke) | Long reference pages · free | AlloyDB guide revised 2026-04-06 | Framework/tool/memory choices, single vs multi-agent, RAG infrastructure | Design-interview language |
| 23 | RAG on Postgres: [AlloyDB ScaNN RAG codelab](https://codelabs.developers.google.com/patent-search-rag-recall), [Cloud SQL vectors](https://docs.cloud.google.com/sql/docs/postgres/work-with-vectors), [AlloyDB vectors](https://docs.cloud.google.com/alloydb/docs/ai/store-index-query-vectors), [BigQuery vector search](https://docs.cloud.google.com/bigquery/docs/vector-search-intro) | Codelab + docs · free + usage | Current | pgvector HNSW, ScaNN index, `embedding()` from SQL, `VECTOR_SEARCH` | Benchmark these against your Qdrant habits |
| 24 | MCP for Claude Code: [remote MCP setup](https://docs.cloud.google.com/mcp/configure-mcp-ai-application), [gcloud MCP server](https://docs.cloud.google.com/sdk/use-gcloud-mcp), [BigQuery MCP](https://docs.cloud.google.com/bigquery/docs/reference/mcp), [MCP Toolbox for Databases](https://googleapis.github.io/genai-toolbox/documentation/introduction), [cloud-run-mcp](https://github.com/GoogleCloudPlatform/cloud-run-mcp) | Docs + repos · free | 2026 (gcloud MCP is Preview) | Tool lists, `roles/mcp.toolUser`, blocked commands, OAuth, read-only tools | Lets Claude Code read your GCP resources with limited power |
| 25 | [Reduce 429s blog (Mar 2026)](https://cloud.google.com/blog/products/ai-machine-learning/reduce-429-errors-on-vertex-ai) + [older 429 post](https://cloud.google.com/blog/products/ai-machine-learning/learn-how-to-handle-429-resource-exhaustion-errors-in-your-llms) + [Apigee llm-circuit-breaking](https://github.com/GoogleCloudPlatform/apigee-samples/tree/main/llm-circuit-breaking) | 2 blogs + 1 sample · free | 2026 + older | Backoff with jitter, Standard/Priority/Provisioned/Flex/Batch, fallbacks in code, circuit breaking | Production LLM reliability, beyond "just retry" |
| 26 | [The Agent Factory](https://dev.to/googleai/the-agent-factory-podcast-5-episodes-to-kickstart-your-journey-to-production-ai-35ml) (Google Cloud Tech YouTube, playlist `PLIivdWyY5sqLXR1eSkiM5bE6pFlXC-OSs`) + [Anthropic webinar: Agents with Claude on Vertex](https://www.anthropic.com/webinars/agents-with-claude-on-vertex) | Video podcast (Jul–Dec 2025+) + webinar (2025-06-25) · free | 2025 | Frameworks, multi-agent, eval; Claude Code + Vertex; Claude + ADK | Listening material for the commute |

### Tier C — optional guided labs, books and background

Use these only when you want structure, or for one gap.

| Resource | Format · length · cost | Freshness / warning | Use it for |
|---|---|---|---|
| Google Skills "Google Cloud Fundamentals: Core Infrastructure" | Course + labs · length not verified, free credits | Not verified | The only breadth course worth doing (week 1: projects, IAM, networking basics) |
| [Developing Applications with Cloud Run: Fundamentals](https://www.skills.google/paths/19/course_templates/559) | 8 h, introductory, labs + badge | Updated ~March 2026 | Guided Cloud Run labs if docs alone feel hard |
| [Develop GenAI Apps with Gemini and Streamlit (978)](https://www.cloudskillsboost.google/course_templates/978) | Labs + challenge lab, 20 credits; 5 h 45 min (one locale page shows 1 h 45 min) | Labs may still use retired Gemini 2.x | First sandbox hands-on: function calling, SDK, deploy to Cloud Run |
| [Advanced: Generative AI for Developers (path 183)](https://www.skills.google/paths/183) | 12 activities, credits | Updated ~late 2025; pre-rename | Semantic search and RAG labs, picked one by one |
| Logging and Monitoring in Google Cloud (~14 h) + Observability in Google Cloud (~6 h) ([path 20](https://www.skills.google/paths/20)) | Courses + labs | Dates not shown | Guided labs on Trace, Error Reporting, Profiler |
| [Manage Security in Google Cloud](https://www.skills.google/course_templates/21) | 4 h 45 min, labs | Refreshed recently | IAM and VPC-SC labs |
| [Professional Agentic Architect path 4525](https://www.skills.google/paths/4525) + [cert](https://support.google.com/cloud-certification/answer/18080541?hl=en) | 12 activities; exam $200 at GA (mid-November 2026), plus hands-on labs with a 2-month window | Updated ~October 2026 | The one cert worth taking, **after** this plan. It recommends 1+ year of agentic work on GCP |
| [PCA case studies](https://services.google.com/fh/files/misc/v6.1_pca_professional_cloud_architect_exam_guide_english.pdf) (EHR Healthcare, Cymbal Retail) | Free PDFs | Exam guide v6.1 (Oct 2025) | System-design practice. EHR Healthcare is closest to insurance claims |
| Book: [Generative AI on Google Cloud with LangChain](https://packtpub.com/en-sg/product/generative-ai-on-google-cloud-with-langchain-9781835889336) (Kuligin et al.) | Packt, 306 pages, paid | Dec 2024; dated APIs | A bridge for a LangChain/LangGraph engineer, including a BigQuery vector store chapter |
| Book: [Generative AI on Google Cloud](https://oreilly.com/library/view/generative-ai-on/9781098159016) (Mona, Thallam, Nardini) | O'Reilly, paid | Listed Nov 2025, but the description still mentions PaLM 2 / Codey | Check the table of contents before you buy |
| Book: [Google BigQuery: The Definitive Guide](https://www.oreilly.com/library/view/bigquery-the-definitive/9781492044451/) | 519 pages, paid | 2019; no 2nd edition | BigQuery internals chapters only |
| Book: [Building Serverless Applications with Google Cloud Run](https://www.oreilly.com/library/view/building-serverless-applications/9781492057086) (Venema) | ~200 pages, paid | Dec 2020; no GPUs, worker pools, readiness probes | Mental models only |
| Book: [Visualizing Google Cloud](https://www.oreilly.com/library/view/-/9781119816324/) (Vergadia) | 256 illustrated pages | 2022; outdated for GenAI | A visual service map that is easy to read in English |
| [SRE 2nd edition](https://www.oreilly.com/library/view/site-reliability-engineering/9798341607675/) | Paid; "completely rewritten" for AI and serverless ([Google blog](https://cloud.google.com/blog/products/devops-sre/sre-book-second-edition)) | 2026 (dates conflict: Sep–Dec) | Only if you have a budget; the free 2016 book is enough |
| [Serverless Expeditions](https://www.youtube.com/playlist?list=PLIivdWyY5sqJwq_pgOxcHzusWjXDVCEiX) | YouTube playlist | Mostly 2020–2022; the [repo](https://github.com/GoogleCloudPlatform/serverless-expeditions) says samples are "not maintained past the release" | Short concept refreshers |
| [Cloud Security Podcast EP199 "IAM pet peeves"](https://ppacc.player.fm/series/cloud-security-podcast-by-google/ep199-your-cloud-iam-top-pet-peeves-and-how-to-fix-them) | Podcast | 2024–2026 series | Commute listening |
| Vietnamese: [#QuanQuanGCP Study Jam S7](https://cloud.google.com/events/google-cloud-study-jam-season-7/quanquangpc?hl=de), [VnReview: Google Skills là gì](https://vnreview.vn/threads/google-skills-la-gi-ai-nen-su-dung-su-dung-the-nao.81607/latest) | Events / article | The Study Jam ran Sep–Oct 2025 and is closed | The research found **no current long-form Vietnamese GCP AI course** |

### Skip list — redundant breadth or outdated

| Resource | Why skip it |
|---|---|
| Generative AI Leader path and cert ([path 1951](https://www.skills.google/paths/1951)) | Business-level and non-technical ([profile listing](https://www.skills.google/public_profiles/e89c2556-4f20-4edf-a11c-dc90653c4ded)) |
| "Beginner: Introduction to Generative AI" ([path 118](https://www.skills.google/paths/118)) | Conceptual. Too shallow for a working AI engineer |
| "Google Cloud Applied AI Summit" ([path 280](https://www.skills.google/paths/280)) | Teaches "Vertex AI and Duet AI". Outdated |
| Coursera PMLE / PCA / DevOps certificate packaging ([DevOps example](https://www.coursera.org/specializations/sre-devops-engineer-google-cloud)) | The same content as Google Skills, but slower. The DevOps series' visible reviews date from 2018–2021. PMLE is heavy on classic ML training |
| Coursera "AI Agents with Vertex AI Reasoning Engine and Agent Builder" ([link](https://www.coursera.org/specializations/ai-agents-with-vertex-ai-reasoning-engine-and-agent-builder)) | Uses names from two renames ago |
| Udemy cert-prep bundles, Pluralsight, freeCodeCamp GCP videos | Exam breadth. The research found no current freeCodeCamp GCP course with Agent Platform content |
| "Implement DevOps Workflows in Google Cloud" badge | Built on Cloud Source Repositories (end-of-sale) and GKE ([CSR](https://docs.cloud.google.com/source-repositories/docs/migration-guides)) |
| "Getting Started with GKE" | You already run RKE2 in production |
| Professional Security Engineer path, *Data Science on GCP 2e* (2022), Packt PCSE exam guide (2023) | Breadth for a cert, or written before GenAI and the 2026 platform |

---

## Your Kubernetes and Celery instincts transfer, except for one CPU trap

Most of what you know has a direct GCP equivalent. Cloud Run is "Deployment + HPA + Service" as one managed resource. Cloud Tasks is "a Celery queue whose workers are HTTP endpoints". Workload Identity Federation is "OIDC service-account tokens instead of static keys in CI". The table below maps your current stack to GCP. The "Watch out" column lists the places where the mapping breaks. Interviewers like to probe exactly those places.

| Area | You know | GCP equivalent | Watch out |
|---|---|---|---|
| Compute | K8s Deployment + HPA | Cloud Run service with min/max instances and concurrency-based autoscaling | Default concurrency is 80 and the max is 1,000 per instance ([quotas](https://docs.cloud.google.com/run/quotas)). Concurrency is the main cost lever: Google's example costs **$13.69/month at concurrency 20 vs $81.72 at concurrency 1** ([pricing](https://cloud.google.com/run/pricing)) |
| Compute | Pod startup/liveness/readiness probes | Cloud Run health checks | Startup gates the other probes. Readiness stops traffic without killing the instance (GA 2026-06-29). TCP probes work only for startup ([health checks](https://docs.cloud.google.com/run/docs/configuring/healthchecks)) |
| Compute | K8s Job / Indexed Job | Cloud Run job, `CLOUD_RUN_TASK_INDEX` / `CLOUD_RUN_TASK_COUNT` | Up to 10,000 parallel tasks, 168 h per task, 3 retries by default ([jobs](https://docs.cloud.google.com/run/docs/create-jobs)) |
| Compute | Long-lived consumer Deployment (Celery/Kafka worker) | Cloud Run **worker pool** (GA 2026-04-14) | No public endpoint. Up to 40% cheaper than instance-billed services ([worker pools blog](https://cloud.google.com/blog/products/serverless/exploring-cloud-run-worker-pools-and-kafka-autoscaler)) |
| Compute | GPU node pool + vLLM | Cloud Run GPU (NVIDIA L4 24 GB, RTX PRO 6000 96 GB), one GPU per instance | Needs instance-based billing, but still scales to zero. New projects get a quota of 3 GPUs ([GPU](https://docs.cloud.google.com/run/docs/configuring/services/gpu)) |
| Compute | Argo Rollouts canary | `gcloud run deploy --no-traffic --tag`, then `update-traffic`, or a Cloud Deploy canary | Rollback is immediate and does **not** rerun health checks. A traffic split persists into later deploys ([rollouts](https://docs.cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration)) |
| Delivery | ArgoCD app-of-apps + promotion | Cloud Deploy delivery pipeline (dev → uat → prod) | Push/promote, not pull GitOps. The first multi-target pipeline is free, then $5/month each ([Cloud Deploy pricing](https://cloud.google.com/deploy/pricing)) |
| Delivery | Helm values per environment | Terraform `environments/{dev,uat,prod}` + one GCP project per environment | Use the default workspace only and ≤100 resources per state ([root modules](https://docs.cloud.google.com/docs/terraform/best-practices/root-modules)) |
| Delivery | Harbor / Docker registry | Artifact Registry + cleanup policies | Never `gcr.io` Container Registry ([GCR shutdown](https://docs.cloud.google.com/kubernetes-engine/docs/deprecations/container-registry)) |
| Delivery | Static keys in CI variables | Workload Identity Federation (GitLab `id_tokens` → STS) | On GitLab.com an attribute condition is **mandatory**, because all orgs share one issuer ([WIF pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)) |
| Async | `task.apply_async(queue="extract")` | `CloudTasksClient.create_task()` to the `extract` queue; the worker is an HTTP handler | The handler must return non-2xx to trigger a retry. There is no `self.retry()` |
| Async | Celery `rate_limit`, `--concurrency` | Queue `max-dispatches-per-second`, `max-concurrent-dispatches` × Cloud Run concurrency × max instances | Rate limits apply to retries too ([queues](https://docs.cloud.google.com/tasks/docs/configuring-queues)) |
| Async | `autoretry_for`, `retry_backoff`, `max_retries` | `max-attempts`, `min-backoff`, `max-backoff`, `max-doublings`, `max-retry-duration` | Retries stop only when **both** the attempts and duration limits are reached ([queues](https://docs.cloud.google.com/tasks/docs/configuring-queues)) |
| Async | `countdown` / `eta`, `task_id`, `time_limit` | `schedule_time`, task `name`, `dispatch_deadline` | Deadline max is **30 min**. The dedup window is best-effort (sources say 1 h or up to 24 h) ([HTTP targets](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks); [tasks.create](https://docs.cloud.google.com/tasks/docs/reference/rest/v2/projects.locations.queues.tasks/create)) |
| Async | `chain()`, `group()`, `chord()` | Each stage enqueues the next (choreography), or Workflows steps + `parallel` | Workflows: 512 KB variables, 2 MB HTTP response, 10 branches per parallel step ([Workflows limits](https://docs.cloud.google.com/workflows/quotas)) |
| Async | Celery beat / K8s CronJob | Cloud Scheduler (an async caller that mints OIDC tokens) | Named as a caller on the [service-to-service page](https://docs.cloud.google.com/run/docs/authenticating/service-to-service). Details not researched here |
| Async | Redis pub/sub fan-out | Pub/Sub topics + subscriptions | Push gives 10 min per message. Exactly-once works only with **pull** ([Pub/Sub vs Tasks](https://docs.cloud.google.com/pubsub/docs/choosing-pubsub-or-cloud-tasks); [exactly-once](https://docs.cloud.google.com/pubsub/docs/exactly-once-delivery)) |
| Data | MinIO presigned PUT / multipart | GCS V4 signed URL or resumable session URI | The session URI is a bearer token valid for **one week** ([resumable](https://docs.cloud.google.com/storage/docs/performing-resumable-uploads)) |
| Data | Redis `SET NX PX` lock | Firestore lease document written in a transaction | TTL deletes "typically within 24 hours", so TTL must not expire locks ([TTL](https://docs.cloud.google.com/firestore/native/docs/ttl)) |
| Data | PostgreSQL + PgBouncer | Cloud SQL or AlloyDB via connectors / Unix socket / private IP | **100 connections per Cloud Run instance** to Cloud SQL. Cap pools and max instances ([connect from Cloud Run](https://docs.cloud.google.com/sql/docs/postgres/connect-run)) |
| Data | Qdrant | AlloyDB ScaNN, Cloud SQL pgvector HNSW, BigQuery `VECTOR_SEARCH`, or keep Qdrant on Cloud Run/GKE | BigQuery vector indexes are not supported in Standard edition ([vector search](https://docs.cloud.google.com/bigquery/docs/vector-search-intro)) |
| Data | Neo4j / FalkorDB | Not covered by this research | Keep them self-hosted on GKE until you evaluate options |
| Data | Postgres as analytics DB | BigQuery | Only 2 concurrent mutating DML statements per table. Keys are not enforced ([DML](https://docs.cloud.google.com/bigquery/docs/data-manipulation-language)) |
| OCR | Azure DI Read / Layout / custom neural / selection marks | Document AI Enterprise OCR / Form Parser + Layout Parser / Custom Extractor / `enableSelectionMarkDetection` | Online max is 15 pages (30 in imageless mode) ([limits](https://docs.cloud.google.com/document-ai/limits)) |
| Identity | Azure managed identity / K8s ServiceAccount | A user-managed service account attached to each Cloud Run service | If you don't set one, Cloud Run uses the Compute Engine default SA, which may have project Editor ([service identity](https://docs.cloud.google.com/run/docs/securing/service-identity)) |
| Identity | Azure Key Vault / K8s Secret | Secret Manager (env var pinned to a version, or a volume that follows `latest`) | Env vars resolve once at instance start ([secrets](https://docs.cloud.google.com/run/docs/configuring/services/secrets)) |
| Identity | Azure Policy / deny assignment | Organization Policy / IAM deny policy | Deny policies are checked **before** allow policies ([deny](https://docs.cloud.google.com/iam/docs/deny-overview)) |
| Network | VNet integration / NAT Gateway / Private Endpoint / Front Door + WAF | Direct VPC egress / Cloud NAT + static IP / Private Service Connect / global ALB + Cloud Armor | With an ALB, set ingress to `internal-and-cloud-load-balancing`, or the `run.app` URL **bypasses Cloud Armor** ([ALB](https://docs.cloud.google.com/load-balancing/docs/https/setting-up-https-serverless)) |
| Network | NetworkPolicy | Cloud Run ingress settings + `roles/run.invoker` + ID tokens | IAM applies on every ingress path. Google recommends using both layers ([ingress](https://docs.cloud.google.com/run/docs/securing/ingress)) |
| LLM | Azure OpenAI / your vLLM gateway | Agent Platform (Gemini, Claude), or vLLM on Cloud Run GPU | Claude on Vertex has **no server-side `fallbacks` and no Message Batches API** ([Anthropic](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/google-managed)) |
| Observability | Prometheus + ServiceMonitor | Managed Service for Prometheus sidecar + `RunMonitoring` (a subset of PodMonitoring), PromQL | Use instance-based billing so scrapes are not CPU-throttled ([GMP sidecar](https://docs.cloud.google.com/stackdriver/docs/managed-prometheus/cloudrun-sidecar)) |
| Observability | Loki / ELK, Jaeger / Tempo, Alertmanager | Cloud Logging + Log Analytics, Cloud Trace via OTLP, Monitoring alert policies + SLO burn-rate alerts | Cloud Run is not auto-detected for SLOs, so define a custom service ([SLO](https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring)) |
| Observability | Langfuse on RKE2 | Langfuse on GKE via the official Terraform module, or Langfuse Cloud; plus Agent Platform request-response logging to BigQuery | Managed certs take ~20 min; Postgres and ClickHouse must both use UTC ([langfuse-terraform-gcp](https://github.com/langfuse/langfuse-terraform-gcp)) |
| Cost | kubecost | Billing export to BigQuery + labels + budgets + spend caps | Billing export is **not fully backfilled**, so enable it on day one ([billing export](https://docs.cloud.google.com/billing/docs/how-to/export-data-bigquery)) |

### The one trap: CPU disappears after the response

In Celery, a worker owns its CPU for the whole task. Cloud Run is different. With request-based billing (the default), "after a response is sent, the instance's access to CPU will be disabled or severely limited". The general tips page tells you to **avoid background threads** ([Cloud Run tips](https://docs.cloud.google.com/run/docs/tips/general)). The suspended thread does not die cleanly. It "resumes" when a later request happens to land on the same instance, so bugs look random. Instance-based billing gives CPU after the response. But idle instances can still be shut down at any time, with a **SIGTERM and only 10 seconds of grace**. They also stay idle for at most 15 minutes unless min instances keep them alive ([billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings)). Google's own recommendation for async work is Cloud Tasks (retries, up to 30 minutes). For non-HTTP pull consumers it recommends worker pools.

```python
# BAD on Cloud Run (request-based billing): CPU is cut after the response
@app.post("/claims/{claim_id}/submit")
def submit(claim_id: str):
    threading.Thread(target=run_pipeline, args=(claim_id,)).start()
    return {"status": "accepted"}

# GOOD: make the work its own HTTP request, with retries owned by Cloud Tasks
@app.post("/claims/{claim_id}/submit", status_code=202)
def submit(claim_id: str):
    enqueue_extract(claim_id)   # if this raises, FastAPI returns 5xx and the client retries
    return {"status": "queued"}
```

Here is the Celery → Cloud Tasks translation in code. The field names follow the official Cloud Tasks sample and the OIDC reference ([HTTP target tasks](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks); [OidcToken](https://docs.cloud.google.com/tasks/docs/reference/rest/v2/OidcToken)).

```python
# Celery (what you know):
#   process_claim.apply_async(args=["C-123"], queue="extract", countdown=30, task_id="claim-C-123-extract")
import datetime, json
from google.cloud import tasks_v2
from google.protobuf import duration_pb2, timestamp_pb2

client = tasks_v2.CloudTasksClient()
PROJECT, REGION, QUEUE = "pcv-lab-ocr-01", "asia-southeast1", "extract"
WORKER = "https://extract-abc123-as.a.run.app"          # receiving service URL

def enqueue_extract(claim_id: str, version: int = 1, delay_s: int = 0) -> tasks_v2.Task:
    eta = timestamp_pb2.Timestamp()
    eta.FromDatetime(datetime.datetime.now(datetime.UTC) + datetime.timedelta(seconds=delay_s))
    task = tasks_v2.Task(
        name=client.task_path(PROJECT, REGION, QUEUE, f"claim-{claim_id}-extract-v{version}"),  # best-effort dedup
        schedule_time=eta,                                    # = countdown / eta
        dispatch_deadline=duration_pb2.Duration(seconds=1800),  # = time_limit, hard max 30 min
        http_request=tasks_v2.HttpRequest(
            http_method=tasks_v2.HttpMethod.POST,
            url=f"{WORKER}/tasks/extract",
            headers={"Content-Type": "application/json"},
            body=json.dumps({"claim_id": claim_id}).encode(),
            oidc_token=tasks_v2.OidcToken(
                service_account_email=f"tasks-invoker@{PROJECT}.iam.gserviceaccount.com",
                audience=WORKER,   # set it explicitly; the default is the full target URI including the path
            ),
        ),
    )
    return client.create_task(parent=client.queue_path(PROJECT, REGION, QUEUE), task=task)
```

The worker side does the work **inside** the request. It returns 2xx only after a durable write. The retry header is useful for logs, but never use it for identity, because "external requests can spoof" `X-CloudTasks-*` headers ([HTTP target tasks](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks)).

```python
@app.post("/tasks/extract")
async def extract(req: Request):
    claim_id = (await req.json())["claim_id"]
    retry = int(req.headers.get("X-CloudTasks-TaskRetryCount", "0"))  # logging / give-up logic only
    if await stage_done(claim_id, "extract"):        # idempotency key = (claim_id, stage)
        return Response(status_code=200)
    await run_extraction(claim_id)                    # real work, within the request timeout
    await mark_stage_done(claim_id, "extract")        # durable write FIRST
    enqueue_classify(claim_id)                        # then hand off to the next stage
    return Response(status_code=200)                  # any non-2xx => Cloud Tasks retries with backoff
```

The queue and the service must agree on time limits. **Cloud Run's default request timeout is 300 s.** So a 1,800 s task deadline does nothing unless you raise the service timeout (max 3,600 s) ([request timeout](https://docs.cloud.google.com/run/docs/configuring/request-timeout)).

```bash
gcloud tasks queues create extract --location=asia-southeast1 \
  --max-dispatches-per-second=5 --max-concurrent-dispatches=10 \
  --max-attempts=8 --min-backoff=10s --max-backoff=600s --max-doublings=5

gcloud run deploy extract \
  --image=asia-southeast1-docker.pkg.dev/pcv-lab-ocr-01/apps/extract@sha256:<digest> \
  --region=asia-southeast1 \
  --service-account=extract-sa@pcv-lab-ocr-01.iam.gserviceaccount.com \
  --no-allow-unauthenticated --ingress=internal \
  --timeout=1800 --concurrency=4 --max-instances=10
```

---

## The ACE claim engine teaches ten defendable trade-offs

The reference project is the "ACE" claim engine. It has Cloud Run services by role (api, extract, classify, adjudicate). Cloud Tasks HTTP tasks with OIDC chain the services. Firestore holds job state, counters and locks, BigQuery holds claim and audit tables, GCS takes browser-direct signed uploads, Document AI does the OCR, Gemini and Claude run on Vertex, and GitLab CI deploys everything. It is a good case study because it is a normal, sensible serverless design. Each choice has a clear reason and a clear failure edge. The same trade-offs appear in any document pipeline. So learn the pattern, not ACE itself.

| ACE choice | Why it is reasonable | Where it breaks | Stronger option to propose |
|---|---|---|---|
| One Cloud Run service per role, each with its own service account | Least privilege, separate scaling, separate timeouts ([SA best practices](https://docs.cloud.google.com/iam/docs/best-practices-service-accounts)) | More IAM wiring to maintain | Keep it. Tune concurrency and timeout per role (CPU-heavy stages get low concurrency) |
| Cloud Tasks HTTP tasks + OIDC between stages | Explicit invocation, per-queue rate caps that protect OCR/LLM quotas, retries, dedup ([Pub/Sub vs Tasks](https://docs.cloud.google.com/pubsub/docs/choosing-pubsub-or-cloud-tasks)) | 900–1,800 s deadlines sit at the **hard 30-minute cap** with zero headroom. Cloud Run's default 300 s timeout silently kills long tasks | One queue per stage. Service `--timeout` ≥ deadline. Move anything that may exceed 30 min to a Cloud Run job started by Workflows (≤168 h) ([Workflows → job](https://docs.cloud.google.com/workflows/docs/tutorials/execute-cloud-run-jobs)) |
| Fallback: run the work in a background thread when enqueue fails | Keeps the API fast during a Cloud Tasks hiccup | CPU is throttled after the response. Shutdown gives 10 s of grace. Nothing retries the work ([billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings)) | Retry the enqueue, then return 5xx so the caller retries. Or write a "pending" row that a sweeper re-enqueues. Or start a job |
| Firestore transaction for a sequential `claim_id` counter | Serializable and simple ([contention](https://firebase.google.com/docs/firestore/transaction-data-contention)) | "You can't update a single document at an unlimited rate". Shards give a count, not a unique sequence ([counters](https://docs.cloud.google.com/firestore/native/docs/solutions/counters)) | Fine at TPA volume (well under one claim per second). If volume grows, pre-allocate ID blocks or use a SQL sequence |
| Firestore lock against double push to the payer | Transactions are serializable | TTL is not a lock expiry (deletion can lag 24 h). Slow work inside a transaction hits the 20 s lock deadline or the 270 s limit ([transactions](https://docs.cloud.google.com/firestore/native/docs/manage-data/transactions)) | Lease doc `{owner, expires_at, fence}` checked in a short transaction. Use TTL only for cleanup. Make the push idempotent |
| BigQuery as an app store: `INSERT … WHERE NOT EXISTS`, `MERGE`, bulk `UPDATE … CASE`, `DELETE + INSERT` in a transaction | One place for audit, decisions and analytics | Keys are **not enforced** and INSERTs never conflict, so concurrent inserts can duplicate rows. A transaction takes a **table-level lock**, and a conflicting transaction **fails immediately** instead of queuing. Only 2 mutating DML per table run at once ([DML](https://docs.cloud.google.com/bigquery/docs/data-manipulation-language); [transactions](https://docs.cloud.google.com/bigquery/docs/transactions); [keys](https://docs.cloud.google.com/bigquery/docs/primary-foreign-keys)) | Keep the bulk `UPDATE … CASE` (one statement, not N). Enforce a single writer per claim (the lease). Use one `MERGE` without a transaction wrapper. Dedupe on read with `QUALIFY ROW_NUMBER()`. Keep hot status in Firestore/Cloud SQL |
| Browser-direct GCS uploads with signed resumable sessions | File bytes never pass through Cloud Run (HTTP/1 requests are capped at 32 MiB) ([quotas](https://docs.cloud.google.com/run/quotas)) | The session URI is a one-week bearer token. Upload notifications are at-least-once and can duplicate ([notifications](https://docs.cloud.google.com/storage/docs/pubsub-notifications)) | Short expiry, HTTPS only, bind the content type, send the CORS `Origin` header, dedupe on `bucket/object#generation` |
| Document AI Enterprise OCR, checkbox detection **only on LOA pages**, 60 s timeout | Add-ons cost about $6 vs $1.50 per 1,000 pages, so checkboxes on every page would cost ~5x ([pricing](https://cloud.google.com/document-ai/pricing)) | Online calls take max 15 pages (30 imageless). Selection marks cannot run together with Math OCR. A fixed 60 s ignores page count ([limits](https://docs.cloud.google.com/document-ai/limits); [Enterprise OCR](https://docs.cloud.google.com/document-ai/docs/enterprise-document-ocr)) | Keep the page routing. Set the timeout by page count. Send big bundles to batch (≤500 pages, results in GCS) |
| Gemini 2.5 Flash/Pro + Claude on Vertex | Two vendors, two cost tiers | **Gemini 2.5 was retired on Vertex on 2026-10-20** ([lifecycle](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versioning)). Claude on Vertex has no server-side `fallbacks` | Migrate to `gemini-3.5-flash` / `gemini-4-argon` (check residency per model) and rerun evals. Write the fallback in your own code |
| Hong Kong and Philippines markets on GCP | Mature regions nearby | GCS has Hong Kong (`asia-east2`), but the `ASIA` multi-region excludes Hong Kong, no Philippines region is listed, and **Document AI has no Hong Kong location** ([GCS locations](https://docs.cloud.google.com/storage/docs/locations); [Document AI regions](https://docs.cloud.google.com/document-ai/docs/regions)) | Say clearly in the design that OCR is cross-border processing. Pick Singapore or `us`/`eu` on purpose and get a legal sign-off |

ACE's biggest design question is the orchestration style. Cloud Tasks chaining is **choreography**: each stage knows the next one. Workflows is **orchestration**: one central flow. Mete Atamel's test is useful in interviews: "can you describe the business logic as a flow chart?" If yes, orchestrate ([Atamel, choreography vs orchestration](https://speakerdeck.com/meteatamel/choreography-vs-orchestration-in-services)). The table below summarizes the cited limits. Workflows wins when you need central visibility, parallel per-document fan-out, or a human-review pause. Cloud Tasks wins when you need per-stage rate caps.

| Need | Cloud Tasks chain (ACE) | Workflows orchestrator | Pub/Sub push | Eventarc |
|---|---|---|---|---|
| Stage up to 30 min | Yes (hard cap) | Calls Cloud Run (≤60 min) or runs jobs (≤168 h) | No (10 min) | Only routes events |
| Per-stage rate/concurrency cap | Yes, per queue | Your own code | Pull flow control only | No |
| Central state and history | You build it (status table) | Built in (execution history, up to 1 year) | No | No |
| Human adjudication pause | You build it | Callbacks (12 h default wait) | No | No |
| Payload limit | 1 MB | 512 KB variables, 2 MB responses | 10 MB | 512 KB / 1 MB |
| Delivery | Best-effort order, dedup on create | Sequential steps | Ordering keys; exactly-once only with pull | At-least-once, no ordering |

Sources: [Pub/Sub vs Cloud Tasks](https://docs.cloud.google.com/pubsub/docs/choosing-pubsub-or-cloud-tasks); [Workflows limits](https://docs.cloud.google.com/workflows/quotas); [callbacks](https://docs.cloud.google.com/workflows/docs/creating-callback-endpoints); [Eventarc](https://docs.cloud.google.com/eventarc/docs/overview).

The fair interview position is to defend ACE first, then name the edges. At TPA claim volume, a single counter document, a Firestore lease and BigQuery decision tables are all reasonable. They keep the system small. The risks show up under concurrency and burst load. A strong answer says which metric would tell you to change each choice. For example: "ABORTED: Too much contention" errors on the counter, or "Transaction is aborted due to concurrent update" errors on BigQuery.

---

## A twelve-week plan pairs every topic with one build

Budget 8–10 hours a week. Spend about 5 hours on study, 4 on building with Claude Code, and 1 on interview drills. Every week ends with a "done when" check. The check is something you can run or explain out loud. All builds happen in a personal sandbox project, never in the company production project. Weeks 11–12 are optional and polish the portfolio.

| Week | Study (resources from the ranked list) | Build with Claude Code (sandbox) | Done when |
|---|---|---|---|
| 1. Foundations | Core Infrastructure labs (free credits); [SA best practices](https://docs.cloud.google.com/iam/docs/best-practices-service-accounts); [Use IAM securely](https://docs.cloud.google.com/iam/docs/using-iam-securely); [free program limits](https://docs.cloud.google.com/free/docs/free-cloud-features) | Create a sandbox project, budget alerts at 50/90/100%, billing export to BigQuery. Set up Claude Code on Agent Platform with pinned models. Write a `CLAUDE.md` with GCP safety rules. Request Claude access in Model Garden | `/status` shows `API provider: Google Vertex AI`. One `AnthropicVertex` call and one `google-genai` call succeed |
| 2. Cloud Run | Resource #4 (all ten pages); Next '26 talk + codelab (#5); [uv in Docker](https://docs.astral.sh/uv/guides/integration/docker/) | A FastAPI service with a multi-stage uv image, Artifact Registry, a dedicated runtime SA and Secret Manager. Do a canary with `--no-traffic --tag`, then a rollback. Then demo the background-thread bug on purpose | You can explain request- vs instance-based billing and show a rollback |
| 3. Async pipelines | Resource #8; Celery mapping table above | **Project 1A:** browser upload (resumable session) → GCS → notification → `api` → Cloud Tasks (OIDC) → `extract` worker → Firestore status | A duplicate notification or a retried task does not create duplicate work |
| 4. Document AI | Resource #10; skill badges 674 and 686; [insurance utilization-review architecture](https://docs.cloud.google.com/architecture/use-generative-ai-utilization-management) | **Project 1B:** OCR worker with Enterprise OCR, checkbox add-on only on selected pages, batch fallback for >15 pages, cost per page logged | You can quote online/batch limits and the add-on cost from memory |
| 5. Data layer | Resource #9 (BigQuery, Firestore, GCS pages) | Firestore lease lock + status model. An audit log through the Storage Write API. Reproduce "Too many DML statements outstanding" and "Transaction is aborted due to concurrent update" **on purpose** | You can explain why `INSERT … WHERE NOT EXISTS` is unsafe under concurrency |
| 6. Claude + Gemini | Resources #2, #3 (Anthropic Academy), #7; Claude [quotas](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/partner-models/claude/quotas), [batch](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/partner-models/claude/batch), [prompt caching](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/partner-models/claude/prompt-caching) | **Project 2:** extraction service. Gemini structured output as primary, Claude as client-side fallback, one retry layer, token + cost logging per claim, 50-claim golden set | A cost-per-claim number and an eval score on a dashboard |
| 7. Search / RAG | Resources #22, #23; [RAG Engine + Vector Search](https://docs.cloud.google.com/gemini-enterprise-agent-platform/build/rag-engine/use-vertexai-vector-search?hl=de); cookbook RAG entries | **Project 3:** claim/policy search. Compare Qdrant on Cloud Run with AlloyDB ScaNN or BigQuery `VECTOR_SEARCH` on Vietnamese + English documents | A one-page latency / recall / cost comparison |
| 8. Agents + MCP | Resources #16–#20, #24; Agent Factory episodes | **Project 4:** adjuster-assistant agent (LangGraph or ADK) on Cloud Run with read-only tools via MCP Toolbox → Firestore/BigQuery | The agent answers 20 test questions; tool calls are traced |
| 9. Security | Resource #12; [VPC-SC for Cloud Run](https://docs.cloud.google.com/run/docs/securing/using-vpc-service-controls); [CMEK services](https://docs.cloud.google.com/kms/docs/compatible-services); [Model Armor lab](https://www.skills.google/catalog_lab/32261) | Harden Projects 1–4: internal ingress, receiver-side OIDC checks, SDP de-identification before LLM calls, static egress IP via Cloud NAT, Gemini caching off, Data Access audit logs on | You can draw every auth boundary in your pipeline |
| 10. DevOps, observability, cost | Resources #13, #14, #15; [WIF for pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines); [Cloud Deploy canary](https://docs.cloud.google.com/deploy/docs/deployment-strategies/canary) | **Project 5:** Terraform + GitLab/GitHub CI with WIF (no keys), deploy by digest, canary, SLO burn-rate alert, cost dashboard. Run a failure drill and write a postmortem | A pipeline run with no JSON key, plus a written postmortem |
| 11. Architecture + interviews (optional) | PCA case studies (EHR Healthcare, Cymbal Retail); [June 12, 2025 outage report](https://status.cloud.google.com/incidents/ow5i3PPK96RduMcb1SsW); question bank below | **Project 6:** batch backfill with Cloud Run jobs + Gemini/Claude batch predictions. Then mock interviews with Claude Code as the interviewer | You answer 30 random bank questions in <2 minutes each |
| 12. Cert or portfolio (optional) | [Agentic Architect path 4525](https://www.skills.google/paths/4525) or Professional Cloud Developer prep | Polish the repo, diagrams and README. Delete all lab projects | Portfolio public; billing shows $0 running cost |

The Professional Agentic Architect cert is the best fit for AI-product work. It has two parts: a proctored exam and hands-on labs in a live environment. It costs **$200 at GA (mid-November 2026)**. Google recommends 3+ years of cloud experience, including 1+ year building agentic solutions on Google Cloud ([certification FAQ](https://support.google.com/cloud-certification/answer/18080541?hl=en)). So take it after this plan, or after 3–6 months at work. If you want one classic cert instead, Professional Cloud Developer is closest to daily Cloud Run work. Its exam pages were updated on 2026-10-06 for the rename ([DirectCertify](https://www.directcertify.com/blog/google-cloud-certification-changes-2026-pearson-vue-and-ai-exam-overhaul/)).

---

## Six Claude Code projects turn reading into production instinct

Reading limits pages gives you facts. Building gives you instinct. The plan uses Claude Code as a pair-programmer **and** a tutor. You let it write code and Terraform. You ask it to explain every flag and every IAM role in simple English. You keep the dangerous actions (apply, deploy to anything real, IAM changes) in your own hands. The research found **no long official "Claude Code + Google Cloud" series**, only single posts such as a Google Cloud Community article on giving Claude Code access through Google's MCP servers ([Medium](https://medium.com/google-cloud/how-google-cloud-mcps-give-claude-code-inside-access-8504abf8122a)). So the setup below is assembled from the official Anthropic and Google pages.

### Set up Claude Code on Agent Platform in a dedicated sandbox

Anthropic recommends "a dedicated GCP project for Claude Code to simplify cost tracking and access control". The only IAM role you need for model calls is **`roles/aiplatform.user`**, which contains `aiplatform.endpoints.predict` ([Claude Code docs](https://code.claude.com/docs/en/google-vertex-ai)). Claude model access is requested per model in Model Garden, and approval "may take 24–48 hours". So request it on day 1.

```bash
# 1) One project per lab, labelled, linked to a PAID billing account
#    (the $300 trial credit cannot pay for partner models like Claude)
gcloud projects create pcv-claude-sandbox-01 --labels=owner=thang,purpose=lab
gcloud billing projects link pcv-claude-sandbox-01 --billing-account=XXXXXX-XXXXXX-XXXXXX

# 2) Budget alerts at 50/90/100% (an alert-only budget does NOT stop spending)
gcloud billing budgets create --billing-account=XXXXXX-XXXXXX-XXXXXX \
  --display-name="claude-sandbox" --budget-amount=50USD \
  --filter-projects=projects/pcv-claude-sandbox-01 \
  --threshold-rule=percent=0.5 --threshold-rule=percent=0.9 --threshold-rule=percent=1.0

# 3) Enable the Agent Platform API and create local credentials (ADC)
gcloud services enable aiplatform.googleapis.com --project=pcv-claude-sandbox-01
gcloud auth application-default login

# 4) Console: Model Garden -> search "Claude" -> request access for each model you need
# 5) Run `claude`, choose "3rd-party platform" -> "Google Vertex AI" (or run /setup-vertex later)
```

The wizard writes an `env` block into `~/.claude/settings.json`. You can also write it yourself. **Pin every model tier.** If you don't pin, `opus` resolves to Opus 5.5 and `sonnet` resolves to Sonnet 4.5 (deprecated), and Anthropic warns you are billed at the Opus rate. If `CLOUD_ML_REGION` is unset or invalid, it falls back to `us-east5` ([Claude Code docs](https://code.claude.com/docs/en/google-vertex-ai)).

```json
{
  "env": {
    "CLAUDE_CODE_USE_VERTEX": "1",
    "CLOUD_ML_REGION": "global",
    "ANTHROPIC_VERTEX_PROJECT_ID": "pcv-claude-sandbox-01",
    "ANTHROPIC_MODEL": "claude-sonnet-5",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-5",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "claude-haiku-5-5",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-5-5"
  }
}
```

`global` gives the best availability. But Google's residency page says global requests "may be processed in any Google Cloud location around the world" with no residency guarantee ([data residency](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/data-residency?hl=en)). That is fine for sandbox code with synthetic data. It is not fine for real claim data. Check with `/status`. It must show `API provider: Google Vertex AI`, plus your project, region and model. Three errors cover most first-day problems:

| Error | Meaning | Fix |
|---|---|---|
| "Could not load the default credentials" | No ADC on this machine | `gcloud auth application-default login`, or set `GOOGLE_APPLICATION_CREDENTIALS` |
| 404 "model not found" | Model not enabled in Model Garden, not offered in this region, or a pre-4.6 ID written without `@` (use `claude-sonnet-4-5@20250929`) | Enable it, use `global`/`us`/`eu`, or fix the ID |
| 429 | Regional quota or capacity | Check that both the primary and the small/fast model exist in that region, or switch to `CLOUD_ML_REGION=global` |

Sources: [Claude Code docs](https://code.claude.com/docs/en/google-vertex-ai); [Anthropic overview](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/overview).

### First calls from Python: Claude and Gemini side by side

The Claude client is `AnthropicVertex` from `pip install -U "anthropic[vertex]"`. After that, `messages.create` works like the normal Messages API ([Anthropic: Google managed](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/google-managed)). Prompt caching uses explicit `cache_control` breakpoints, with a 5-minute default TTL or `"ttl": "1h"`. On newer models, **cache-read tokens do not count toward input-TPM quota** ([Claude prompt caching](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/partner-models/claude/prompt-caching); [Claude quotas](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/partner-models/claude/quotas)).

```python
from anthropic import AnthropicVertex

claude = AnthropicVertex(project_id="pcv-claude-sandbox-01", region="global")
msg = claude.messages.create(
    model="claude-sonnet-5",
    max_tokens=1024,
    system=[{"type": "text", "text": EXTRACTION_RULES_AND_SCHEMA,      # long, stable prefix
             "cache_control": {"type": "ephemeral"}}],               # cache it (5 min default)
    messages=[{"role": "user", "content": f"Extract claim fields:\n{ocr_text}"}],
)
print(msg.content[0].text, msg.usage)   # usage shows cache read/write tokens
```

For Gemini, use the Google Gen AI SDK. Pass a Pydantic model as `response_schema`. The docs advise **not repeating the schema in the prompt**, because "output quality may suffer" ([google-genai docs](https://googleapis.github.io/python-genai/)).

```python
from google import genai
from google.genai import types
from pydantic import BaseModel

class ClaimFields(BaseModel):
    patient_name: str
    admission_date: str
    diagnosis_code: str
    total_amount: float

gem = genai.Client(enterprise=True, project="pcv-claude-sandbox-01", location="asia-southeast1")
resp = gem.models.generate_content(
    model="gemini-3.5-flash",            # listed with Singapore ML processing; gemini-2.5-* is retired
    contents=f"Extract the claim fields:\n{ocr_text}",
    config=types.GenerateContentConfig(
        response_mime_type="application/json",
        response_schema=ClaimFields,
    ),
)
fields: ClaimFields = resp.parsed
print(resp.usage_metadata)               # prompt / output / cached token counts -> cost per claim
```

There is **no server-side model fallback for Claude on Vertex**. The `fallbacks` parameter is unsupported, and Anthropic says to use a client-side pattern ([Anthropic: Google managed](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/google-managed)). Keep **one** retry layer. Google calls "stacking app retries over library retries" an anti-pattern, because 3 × 3 = 9 attempts ([retry strategy](https://docs.cloud.google.com/storage/docs/retry-strategy)).

```python
from google.genai import errors

def extract_fields(ocr_text: str) -> dict:
    try:
        return call_gemini(ocr_text)       # the SDK's own retry (HttpRetryOptions) is the ONLY retry layer
    except errors.APIError as e:
        if e.code not in (429, 500, 503):
            raise                          # permanent errors: fix them, don't retry
        log.warning("gemini_exhausted_fallback_to_claude", extra={"code": e.code})
        return call_claude(ocr_text)       # client-side fallback, logged for cost and eval tracking
```

### Guardrails that keep an AI pair-programmer safe on GCP

Google's own guidance for agents that touch Google Cloud is short. Use least privilege. Use a separate agent identity instead of your own user. Set the `project` parameter carefully. Consider Model Armor floor settings. Remember that logs may expose sensitive data ([gcloud remote MCP](https://docs.cloud.google.com/sdk/use-gcloud-mcp); [configure MCP](https://docs.cloud.google.com/mcp/configure-mcp-ai-application)). The rules below turn that guidance into habits.

| Rule | How to enforce it | Why |
|---|---|---|
| Sandbox only. Never point Claude Code at the company production project | A separate project per lab, named `*-lab-*`, and a deny rule in `CLAUDE.md` | Anthropic recommends a dedicated project ([Claude Code docs](https://code.claude.com/docs/en/google-vertex-ai)) |
| Cap the money | Budget alerts, billing export, and a spend cap on Agent Platform and Cloud Run | Budgets only alert. Spend caps (GA 2026-10-13 for limited services) pause API traffic, but enforcement is delayed and overages are billed ([budgets](https://docs.cloud.google.com/billing/docs/how-to/budgets); [spend caps](https://docs.cloud.google.com/billing/docs/how-to/budgets-spend-caps)) |
| Two identities | Model calls use your ADC with only `roles/aiplatform.user`. Infrastructure changes run as an impersonated SA (`--impersonate-service-account`) with narrow roles (for example `roles/run.developer` on one service) | Avoid basic roles. Grant at the smallest scope ([Use IAM securely](https://docs.cloud.google.com/iam/docs/using-iam-securely)) |
| No service account keys, ever | Use ADC + impersonation. Use the org policy that blocks key creation | Keys break non-repudiation ([SA best practices](https://docs.cloud.google.com/iam/docs/best-practices-service-accounts)) |
| Read-only by default | Claude Code permission rules: allow `describe/list/plan/--dry_run`, ask for `deploy/apply`, deny `projects delete`, `iam`, `auth` | The gcloud remote MCP server already blocks `gcloud auth`, `config`, `iam service-accounts`, `init` and all alpha/beta commands ([gcloud MCP](https://docs.cloud.google.com/sdk/use-gcloud-mcp)) |
| IaC first | Claude writes Terraform and runs `terraform plan`. **You** read the plan and run `apply` | The plan output is a review artefact you can learn from |
| Narrow MCP tools | Use toolset endpoints and read-only tools (`execute_sql_readonly`). Grant `roles/mcp.toolUser` only to the agent identity | IAM governs only Google Cloud MCP servers ([configure MCP](https://docs.cloud.google.com/mcp/configure-mcp-ai-application); [BigQuery MCP](https://docs.cloud.google.com/bigquery/docs/reference/mcp)) |
| Synthetic data only | Generate fake claim PDFs. Never paste real patient data into prompts or logs | Google's HIPAA guidance says to keep PHI out of metadata, logs, labels and alerts ([HIPAA](https://docs.cloud.google.com/docs/security/compliance/hipaa)) |
| Label and delete | Labels `owner=…, lab=…` on every resource. `gcloud projects delete` at the end | Deleting the project removes everything at once |

A starting permission block for the project's `.claude/settings.json` looks like this. Check the exact rule syntax against the current Claude Code permissions docs before you rely on it.

```json
{
  "permissions": {
    "allow": [
      "Bash(gcloud config list)",
      "Bash(gcloud run services describe:*)",
      "Bash(gcloud run services list:*)",
      "Bash(gcloud logging read:*)",
      "Bash(terraform plan:*)",
      "Bash(bq query --dry_run:*)"
    ],
    "ask": [
      "Bash(gcloud run deploy:*)",
      "Bash(gcloud tasks queues create:*)",
      "Bash(terraform apply:*)"
    ],
    "deny": [
      "Bash(gcloud projects delete:*)",
      "Bash(gcloud iam:*)",
      "Bash(gcloud auth:*)",
      "Bash(gcloud config set:*)",
      "Bash(terraform destroy:*)"
    ]
  }
}
```

And a `CLAUDE.md` block that sets the rules for every session:

```markdown
# GCP safety rules (this repo)
- Use project pcv-claude-sandbox-01 only. Refuse any project id containing "prod".
- Never create service account keys. Never grant roles/owner or roles/editor.
- Infrastructure = Terraform. Run `terraform plan`, show me the diff, stop. I run `apply`.
- Label every resource: owner=thang, lab=<project-name>.
- Synthetic claim documents only. Never print or log real personal data.
- For every gcloud flag and IAM role you use, explain it in one simple English sentence.
```

To let Claude Code see your Cloud Run services, add the open-source Cloud Run MCP server. It runs locally with your credentials: `claude mcp add cloud-run -- npx -y @google-cloud/cloud-run-mcp`. Its tools include `deploy`, `list-services` and `get-service` ([cloud-run-mcp](https://github.com/GoogleCloudPlatform/cloud-run-mcp)). For databases, MCP Toolbox for Databases supports Firestore, BigQuery, Cloud SQL, AlloyDB and Spanner from a `tools.yaml` config (`npx @toolbox-sdk/server --config tools.yaml`) ([MCP Toolbox](https://googleapis.github.io/genai-toolbox/documentation/introduction)). Google's remote MCP servers (for example `https://bigquery.googleapis.com/mcp`, `https://run.googleapis.com/mcp`, `https://cloudcli.googleapis.com/mcp`) use OAuth or ADC tokens. They need `roles/mcp.toolUser`. Follow the setup page for the exact client config ([configure MCP](https://docs.cloud.google.com/mcp/configure-mcp-ai-application)).

### The six projects

Each project copies one part of a production AI document system. The **break-it drill** is the most valuable part. It turns a doc sentence into a memory you can describe in an interview.

| # | Project | GCP services | What you practise | Break-it drill | Done when |
|---|---|---|---|---|---|
| 1 | **Claim intake + OCR pipeline** (weeks 3–4) | GCS resumable upload → notification → Cloud Run `api` → Cloud Tasks (OIDC) → `extract` worker → Document AI → Firestore status → BigQuery event log | One SA per service, OIDC verification, idempotency key `(claim_id, stage)`, retries, per-page cost | Deliver the same upload notification twice. Kill the worker mid-task. Set a 1,800 s task deadline on a service left at the 300 s default and watch it fail | 100 synthetic PDFs processed exactly once; cost per page logged |
| 2 | **LLM extraction + validation** (week 6) | `google-genai` (Gemini 3.5 Flash), `AnthropicVertex` (Claude), BigQuery for golden-set results, Cloud Logging | Structured output, prompt/context caching, 429 handling, client-side fallback, eval with adaptive rubrics ([eval service](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/evaluation-overview)) | Fire a burst to trigger 429s. Disable the primary model to exercise the fallback. Send a 30 MB+ payload to hit the Vertex limit | Eval score + cost per claim on a dashboard |
| 3 | **Claim/policy search (RAG)** (week 7) | Embeddings (`gemini-embedding-001`), AlloyDB ScaNN or BigQuery `VECTOR_SEARCH`, Qdrant on Cloud Run as a baseline | Hybrid keyword + vector search on Vietnamese + English documents; recall vs latency vs cost | Mix two embedding models in one index (BigQuery's docs warn that embeddings from different models are incompatible) ([vector search](https://docs.cloud.google.com/bigquery/docs/vector-search-intro)) | One-page comparison report |
| 4 | **Adjuster-assistant agent** (week 8) | LangGraph or ADK on Cloud Run (or Agent Runtime), MCP Toolbox read-only tools, Model Armor, dedicated agent SA, Langfuse / Cloud Trace | Tool design, least-privilege agent identity, tracing, agent eval (tool-call correctness) | Plant a prompt injection inside a claim document and check what Model Armor and your tool limits stop | 20 test questions answered with traced tool calls |
| 5 | **Hardening + CI/CD** (weeks 9–10) | Terraform, WIF from GitLab/GitHub, Artifact Registry (deploy by digest), revisions + traffic split or Cloud Deploy, Secret Manager, Cloud NAT static IP, SLO burn-rate alerts | Keyless CI, canary/rollback, ingress + IAM layers, SDP de-identify before LLM calls, postmortem writing | Deploy a bad revision, then roll back. Disable the Document AI API and check that alerts fire and tasks back off | A green pipeline with no JSON key, and a written postmortem |
| 6 | **Batch backfill + FinOps** (week 11) | Cloud Run jobs (`CLOUD_RUN_TASK_INDEX`), Gemini/Claude batch predictions, BigQuery `maximum_bytes_billed`, labels, billing export | Batch vs online cost, Claude batch limits (no global endpoint, 4 concurrent jobs, results within 24 h) ([Claude batch](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/partner-models/claude/batch)) | Run a full-table query with `maximum_bytes_billed` set. It fails with no charge ([BigQuery cost](https://docs.cloud.google.com/bigquery/docs/best-practices-costs)) | 10k-document backfill cost report; lab project deleted |

### Use Claude Code as tutor, reviewer and interviewer

Use Claude Code to explain things, not only to type code. You will learn GCP faster when it explains each piece before it runs anything. Three prompts are worth saving:

```text
Explain every flag in this gcloud command in simple English, then once more in Vietnamese.
Do not run it.

Review this Terraform for least privilege. List each IAM binding, the exact permission it
grants, and a smaller alternative if one exists. Cite the Google doc page for each claim.

Act as a senior GCP interviewer for a health-insurance AI team. Ask me one question at a time
about "async pipelines". After each answer, grade it 1-5, give the correct short answer, and
name the docs.cloud.google.com page that proves it.
```

---

## 126 interview questions with short, sourced answers

These questions come from the production limits and behaviours that real GCP AI systems depend on. Each answer is short enough to say in under a minute. Each one links to the page that proves it. Drill them with Claude Code as the interviewer. Then go one level deeper: explain *why* the limit exists and what you would monitor. Scenario questions at the end combine many facts, the way a system-design round does.

### A. Cloud Run and compute

| # | Question | Short answer | Source |
|---|---|---|---|
| A1 | What are Cloud Run's two billing modes, and their old names? | Request-based (default; formerly "CPU only allocated during request processing") and instance-based (formerly "CPU always allocated"). Request-based suits spiky traffic. Instance-based suits steady traffic and background work, and needs ≥512 MiB | [Billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings) |
| A2 | Why is a background thread after returning 200 risky? | Under request-based billing, CPU is "disabled or severely limited" after the response. Suspended work resumes only when a later request hits the same instance | [General tips](https://docs.cloud.google.com/run/docs/tips/general) |
| A3 | Does instance-based billing make background work safe? | It gives CPU, but idle instances can be shut down at any time (SIGTERM, 10 s grace). They are kept at most 15 min idle unless min instances apply. Nothing retries lost work, so use a durable queue | [Billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings) |
| A4 | Default and max request timeout? | 300 s default, 3,600 s max. Above 15 min Google recommends retries, and handlers must be idempotent or resumable | [Request timeout](https://docs.cloud.google.com/run/docs/configuring/request-timeout) |
| A5 | Default and max concurrency, and how do you tune it? | 80 default, 1,000 max. Load test, size memory per request, and watch `container/billable_instance_time`. Lower concurrency gives lower latency but more instances | [General tips](https://docs.cloud.google.com/run/docs/tips/general); [Quotas](https://docs.cloud.google.com/run/quotas) |
| A6 | How do you reduce cold starts? | Min instances, startup CPU boost, lazy imports, careful global init. Image size does not matter, thanks to image streaming. New requests wait up to 3.5× the average startup time (at least 10 s) | [General tips](https://docs.cloud.google.com/run/docs/tips/general) |
| A7 | How do you run FastAPI on Cloud Run? | Any ASGI server on `$PORT` (`uvicorn --host 0.0.0.0 --port $PORT main:app`). Workers ≈ cores. Set `PYTHONUNBUFFERED`. Add a custom startup probe, because the default TCP probe passes as soon as the port opens | [Python tips](https://docs.cloud.google.com/run/docs/tips/python) |
| A8 | Startup vs liveness vs readiness probes? | Startup gates the others. A liveness failure restarts the container. A readiness failure stops new traffic without killing it (GA June 2026). TCP is allowed only for startup. The default TCP startup probe is 240 s | [Health checks](https://docs.cloud.google.com/run/docs/configuring/healthchecks); [Release notes](https://docs.cloud.google.com/run/docs/release-notes) |
| A9 | How do you canary and roll back? | `gcloud run deploy --no-traffic --tag canary`, then `update-traffic --to-revisions REV=5`. Roll back with `--to-revisions OLD=100`. It is immediate, with no health re-check, and splits persist into later deploys | [Rollouts](https://docs.cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration) |
| A10 | Service vs job vs worker pool vs instance? | Service = HTTP, autoscaled. Job = run to completion, up to 10,000 tasks, 168 h each. Worker pool = continuous pull consumer with no endpoint (GA Apr 2026). Cloud Run instances = one long-lived addressable copy for up to 7 days (Preview Aug 2026) | [Jobs](https://docs.cloud.google.com/run/docs/create-jobs); [Billing settings](https://docs.cloud.google.com/run/docs/configuring/billing-settings); [Release notes](https://docs.cloud.google.com/run/docs/release-notes) |
| A11 | What do GPUs on Cloud Run require? | L4 needs ≥4 CPU / 16 GiB. RTX PRO 6000 needs ≥20 CPU / 80 GiB. One GPU per instance. Instance-based billing is required, but scale-to-zero still works. ~5 s start. Default quota is 3 GPUs | [GPU](https://docs.cloud.google.com/run/docs/configuring/services/gpu) |
| A12 | Key per-instance limits? | 32 GiB memory, 8 vCPU. HTTP/1 request/response 32 MiB (HTTP/2 and streamed responses are exempt). 100 instances per project per region by default | [Quotas](https://docs.cloud.google.com/run/quotas) |
| A13 | Gen1 or gen2 execution environment? | Gen1 (gVisor): faster cold starts, allows <512 MiB. Gen2 (microVM): full Linux, NFS, faster CPU and network, ≥512 MiB. Jobs and worker pools are always gen2 | [Execution environments](https://docs.cloud.google.com/run/docs/about-execution-environments) |

### B. Async pipelines: Cloud Tasks, Pub/Sub, Workflows, Eventarc

| # | Question | Short answer | Source |
|---|---|---|---|
| B1 | Cloud Tasks vs Pub/Sub in one sentence? | Cloud Tasks is explicit invocation: the producer controls target, timing and rate, with dedup, scheduling, 30 min, 1 MB and 500 QPS per queue. Pub/Sub is implicit fan-out: many subscribers, ordering keys, 10 min push, 10 MB | [Choose Pub/Sub or Cloud Tasks](https://docs.cloud.google.com/pubsub/docs/choosing-pubsub-or-cloud-tasks) |
| B2 | Max handler time for a Cloud Tasks HTTP target? | 10 min default, 30 min max (`dispatch_deadline`) | [HTTP targets](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks) |
| B3 | `dispatch_deadline=1800s`, but tasks die at 5 min. Why? | The Cloud Run request timeout is still at its 300 s default. Set `--timeout` ≥ 1800 | [Request timeout](https://docs.cloud.google.com/run/docs/configuring/request-timeout); [HTTP targets](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks) |
| B4 | Which IAM bindings does Cloud Tasks → private Cloud Run need? | The token SA has `run.invoker` on the worker. The Cloud Tasks service agent has `iam.serviceAccountUser` on the token SA. The enqueuer has Cloud Tasks Enqueuer + `actAs`. The SA must be in the queue's project. Queue-level auth overrides task-level auth | [HTTP targets](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks); [OidcToken](https://docs.cloud.google.com/tasks/docs/reference/rest/v2/OidcToken) |
| B5 | What audience does a Cloud Tasks OIDC token get by default? | The task's target URI (the full URL including the path). Set `audience` to the service URL explicitly | [OidcToken](https://docs.cloud.google.com/tasks/docs/reference/rest/v2/OidcToken) |
| B6 | Which retry knobs exist, and when do retries stop? | `max-attempts` (counts the first attempt), `max-retry-duration`, `min/max-backoff`, `max-doublings`. Retries stop only when both limits are hit, or on success. Rate limits apply to retries too | [Configure queues](https://docs.cloud.google.com/tasks/docs/configuring-queues) |
| B7 | How do you dedupe and make handlers idempotent? | A deterministic task name (the window is best-effort: 1 h per the Python reference, up to 24 h per the REST reference, 9 days for queue.yaml) **plus** your own DB idempotency key. Return 2xx only after a durable write | [tasks.create](https://docs.cloud.google.com/tasks/docs/reference/rest/v2/projects.locations.queues.tasks/create); [Python reference](https://cloud.google.com/python/docs/reference/cloudtasks/latest/google.cloud.tasks_v2.types.CreateTaskRequest) |
| B8 | Does exactly-once delivery work with push to Cloud Run? | No. It needs pull, same-region subscribers and ack-with-response, and it has higher latency | [Exactly-once](https://docs.cloud.google.com/pubsub/docs/exactly-once-delivery) |
| B9 | Ordering keys on a push subscription? | Only one outstanding message per key. A redelivery resends all later messages for that key, even acked ones. A DLQ may break order. The limit is 1 MBps per key | [Ordering](https://docs.cloud.google.com/pubsub/docs/ordering) |
| B10 | How do you configure a dead-letter topic? | On the subscription: max delivery attempts 5–100 (default 5). The Pub/Sub service agent needs publisher on the DLT and subscriber on the source subscription. The count is best-effort. Monitor `dead_letter_message_count` | [Handling failures](https://docs.cloud.google.com/pubsub/docs/handling-failures) |
| B11 | Key Workflows limits for a long pipeline? | Executions up to 1 year. 512 KB of variables and a 2 MB HTTP response (so pass `gs://` URIs). 10 branches per parallel step, 20 concurrent. Callbacks wait 12 h by default. `http.default_retry` retries 429/502/503/504 up to 5 times | [Workflows limits](https://docs.cloud.google.com/workflows/quotas); [Callbacks](https://docs.cloud.google.com/workflows/docs/creating-callback-endpoints); [default_retry](https://docs.cloud.google.com/workflows/docs/reference/stdlib/http/default_retry) |
| B12 | What does Eventarc guarantee? | At-least-once, no ordering, CloudEvents format, 24 h retry with backoff. Standard has a DLQ via Pub/Sub and 512 KB events. Advanced adds a bus, CEL transforms and 1 MB events, but no DLQ | [Eventarc](https://docs.cloud.google.com/eventarc/docs/overview) |
| B13 | Pitfalls of triggering OCR from GCS `OBJECT_FINALIZE`? | At-least-once delivery with possible duplicates for one event. Unordered. A new config takes up to 30 s to start. Undelivered messages may be dropped after 7 days. Dedupe on object + generation | [GCS notifications](https://docs.cloud.google.com/storage/docs/pubsub-notifications) |

### C. Data layer: Cloud Storage, Firestore, BigQuery, Cloud SQL / AlloyDB

| # | Question | Short answer | Source |
|---|---|---|---|
| C1 | Browser uploads a 200 MB PDF to GCS from a Cloud Run backend with no key file. How? | The server signs a V4 URL through IAM `signBlob` (the runtime SA needs Token Creator on itself + object create). Or the server starts a resumable session and returns only the session URI over HTTPS. Max V4 expiry is 7 days; keep it short | [Signing helpers](https://docs.cloud.google.com/storage/docs/access-control/signing-urls-with-helpers); [Signed URLs](https://docs.cloud.google.com/storage/docs/access-control/signed-urls) |
| C2 | Signed URL vs session URI risks? | Anyone holding either one can use it until it expires. The session URI lasts one week. Send `Origin` when CORS is used. Chunks must be multiples of 256 KiB (≥8 MiB recommended) | [Signed URLs](https://docs.cloud.google.com/storage/docs/access-control/signed-urls); [Resumable uploads](https://docs.cloud.google.com/storage/docs/performing-resumable-uploads) |
| C3 | How do you make claim documents tamper-proof? | A retention policy + Bucket Lock (irreversible, up to 100 years) and/or Object Retention Lock and event-based holds. Soft delete is on by default for 7 days (configurable 7–90) | [Bucket Lock](https://docs.cloud.google.com/storage/docs/bucket-lock); [Soft delete](https://docs.cloud.google.com/storage/docs/soft-delete) |
| C4 | Storage class for 7-year, rarely read files? | Coldline or Archive (90/365-day minimums, retrieval fees, still millisecond access), or Autoclass | [Storage classes](https://docs.cloud.google.com/storage/docs/storage-classes) |
| C5 | Why does a single Firestore counter doc bottleneck, and how do you fix it? | A single doc can't be updated at an unlimited rate, so you get contention and ABORTED errors. Sharded counters scale writes linearly, but reads cost more. For unique sequential IDs, pre-allocate ranges or use a SQL sequence | [Counters](https://docs.cloud.google.com/firestore/native/docs/solutions/counters); [Contention](https://firebase.google.com/docs/firestore/transaction-data-contention) |
| C6 | What is the 500/50/5 rule? | Start a new collection at ≤500 ops/s, then add 50% every 5 min. Avoid monotonically increasing IDs or indexed timestamps, which can cap a collection at ~500 writes/s | [Best practices](https://docs.cloud.google.com/firestore/native/docs/best-practices) |
| C7 | Firestore transaction limits and concurrency model? | Reads before writes. 270 s max, 60 s idle, 20 s lock deadline, 10 MiB. Serializable. Standard edition is pessimistic for server SDKs; Enterprise is optimistic | [Transactions](https://docs.cloud.google.com/firestore/native/docs/manage-data/transactions); [Contention](https://firebase.google.com/docs/firestore/transaction-data-contention) |
| C8 | Can Firestore TTL expire your locks? | No. TTL deletes "typically within 24 hours", and expired docs still show in queries. Check `expires_at` inside the transaction. Use TTL only for cleanup | [TTL](https://docs.cloud.google.com/firestore/native/docs/ttl) |
| C9 | Firestore Standard vs Enterprise? | Enterprise: MongoDB-compatible or Native API, advanced query engine, 16 MiB docs (Mongo API), bills by bytes. Standard: queries need indexes, 1 MiB docs, bills per document. The mode can't change after creation | [Editions](https://docs.cloud.google.com/firestore/docs/editions-overview) |
| C10 | BigQuery DML concurrency limits? | 2 concurrent UPDATE/DELETE/MERGE per table + 20 queued. INSERT: the first 1,500 per 24 h run immediately, then 10 concurrent + 100 queued. 25 DML statements per 10 s | [DML](https://docs.cloud.google.com/bigquery/docs/data-manipulation-language); [Quotas](https://docs.cloud.google.com/bigquery/quotas) |
| C11 | Two workers run `BEGIN; DELETE …; INSERT …; COMMIT;` on the same table. What happens? | A table-level lock (even on partitioned tables). The second fails **immediately** with "Transaction is aborted due to concurrent update against table". It is not queued. Retry after ≥60 s, or use one MERGE without a wrapper | [Transactions](https://docs.cloud.google.com/bigquery/docs/transactions) |
| C12 | Is `INSERT … WHERE NOT EXISTS` a safe dedupe in BigQuery? | Not under concurrency. INSERTs never conflict and primary keys are not enforced. Enforce a single writer upstream, or dedupe on read | [DML](https://docs.cloud.google.com/bigquery/docs/data-manipulation-language); [Keys](https://docs.cloud.google.com/bigquery/docs/primary-foreign-keys) |
| C13 | Storage Write API vs INSERT DML vs legacy streaming? | Use the Storage Write API (gRPC) for frequent ingest. The default stream is at-least-once; committed with offsets is exactly-once; pending is an atomic batch. gRPC rows can be modified by DML at once; "REST" (old insertAll) rows are locked for 30 min | [Write API](https://docs.cloud.google.com/bigquery/docs/write-api); [DML](https://docs.cloud.google.com/bigquery/docs/data-manipulation-language) |
| C14 | How do you stop a runaway BigQuery bill? | `maximum_bytes_billed` (the query fails with no charge), dry runs, custom daily quotas, partitioning + clustering. `LIMIT` doesn't reduce bytes read on non-clustered tables | [Cost control](https://docs.cloud.google.com/bigquery/docs/best-practices-costs) |
| C15 | When should BigQuery NOT be the app database? | For row-level, high-concurrency, low-latency mutations or uniqueness guarantees. Google points OLTP needs to Cloud SQL (federated queries) | [DML](https://docs.cloud.google.com/bigquery/docs/data-manipulation-language) |
| C16 | Cloud SQL or AlloyDB for pgvector RAG? | Cloud SQL: pgvector HNSW + `embedding()`, the cheaper default. AlloyDB: ScaNN index (auto-tuned, SQ8 quantization with <1–2% recall loss). Google claims up to 10x faster build, 3x less memory and 4x faster queries than HNSW. Independent results are mixed | [AlloyDB vectors](https://docs.cloud.google.com/alloydb/docs/ai/store-index-query-vectors); [AlloyDB overview](https://docs.cloud.google.com/alloydb/docs/ai/vector-search-landing); [DoiT](https://www.doit.com/blog/when-to-use-alloydb-instead-of-cloud-sql-for-postgresql) |
| C17 | How does Cloud Run connect to Cloud SQL, and what limit bites? | Unix socket `/cloudsql/…`, language connectors (Cloud SQL Client role), or private IP via Direct VPC egress. **100 connections per Cloud Run instance**. Pool, reconnect, and cap max instances | [Connect from Cloud Run](https://docs.cloud.google.com/sql/docs/postgres/connect-run) |

### D. Document AI and OCR

| # | Question | Short answer | Source |
|---|---|---|---|
| D1 | Online vs batch limits? | Online: 15 pages (30 in `imageless_mode` from page 1), 40 MB. Batch: 500 pages for OCR/Layout Parser, 100 for Form Parser, 200 for Custom Extractor; 1 GB per file; 5,000 files per request; results go to GCS | [Limits](https://docs.cloud.google.com/document-ai/limits) |
| D2 | How do you detect checkboxes, and why only on some pages? | Enterprise OCR v2.x `ocrConfig.premiumFeatures.enableSelectionMarkDetection` returns `filled_checkbox`/`unfilled_checkbox`. It can't run with Math OCR. Add-ons cost ~$6 vs $1.50 per 1,000 pages, so route only the pages that need it (the page selector is online-only) | [Enterprise OCR](https://docs.cloud.google.com/document-ai/docs/enterprise-document-ocr); [Pricing](https://cloud.google.com/document-ai/pricing) |
| D3 | Document AI or Gemini for claim extraction? | Document AI gives OCR-grounded text, layout, bounding boxes, checkbox states and confidence for human review, with versions pinned up to 18 months. Gemini 3+ reads up to 3,000 pages per PDF for semantic extraction. A common hybrid is OCR → Gemini on text + page images | [Enterprise OCR](https://docs.cloud.google.com/document-ai/docs/enterprise-document-ocr); [Gemini document understanding](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/multimodal/document-understanding); [Utilization review](https://docs.cloud.google.com/architecture/use-generative-ai-utilization-management) |
| D4 | Where can Document AI process data? | Full support in the `us` and `eu` multi-regions. Limited single regions include `asia-southeast1` and `asia-south1`. No Hong Kong. You must choose a location | [Regions](https://docs.cloud.google.com/document-ai/docs/regions) |
| D5 | A 40-page bundle fails on a 60 s online call. What do you change? | Online is capped at 15 pages anyway. Split it, use imageless mode (30 pages), or send it to batch (async, results in GCS). Size the timeout by page count | [Limits](https://docs.cloud.google.com/document-ai/limits) |
| D6 | How do you keep OCR output stable across model updates? | Pin a processor version (for example `pretrained-ocr-v2.1-2024-08-07`). Frozen versions keep behaviour for up to 18 months. Promote versions through Git + Terraform (the `processor-version-promotion` sample) | [Enterprise OCR](https://docs.cloud.google.com/document-ai/docs/enterprise-document-ocr); [document-ai-samples](https://github.com/GoogleCloudPlatform/document-ai-samples) |

### E. Claude and Gemini on Agent Platform

| # | Question | Short answer | Source |
|---|---|---|---|
| E1 | How is a Claude request on Vertex different from api.anthropic.com? | The model is in the URL (`…/publishers/anthropic/models/{model}:rawPredict`). `anthropic_version` (`vertex-2023-10-16` or `2026-10-21`) is in the body. Streaming uses `:streamRawPredict`. Auth is a Google token / ADC, not an API key. The client is `AnthropicVertex(project_id, region)` | [Anthropic: Google managed](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/google-managed) |
| E2 | Google-managed vs Anthropic-managed Claude on Google Cloud? | Google-managed: Agent Platform, `aiplatform.googleapis.com`, `AnthropicVertex`, Agent Platform IAM, Google quotas and billing. Anthropic-managed: `claude.googleapis.com`, `AnthropicGoogleCloud`, `roles/claude.user`, Anthropic rate limits, Marketplace billing, always `global` | [Anthropic overview](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/overview) |
| E3 | Which IAM role calls Claude or Gemini? | `roles/aiplatform.user`. It contains `aiplatform.endpoints.predict`, which token counting also needs | [Claude Code docs](https://code.claude.com/docs/en/google-vertex-ai) |
| E4 | Global vs multi-region vs regional endpoint? | Global: best availability, no residency guarantee. Multi-region (`us`/`eu`): broad-geo residency. Regional: single region. Multi-region and regional cost **+10%** (Sonnet 4.5+). Provisioned Throughput needs a regional endpoint | [Anthropic: Google managed](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/google-managed); [Data residency](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/data-residency?hl=en) |
| E5 | Processing must stay in Singapore. Can we use the newest Claude? | Anthropic says regional endpoints serve only Sonnet 4.6 and earlier. Google's residency table lists newer models for Singapore. The sources conflict, so verify in Model Garden. Never use `global` for PHI | [Anthropic: Google managed](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/google-managed); [Data residency](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/data-residency?hl=en) |
| E6 | Why does `claude-sonnet-4-5-20250929` return 404 on Vertex? | Pre-4.6 IDs use `@`: `claude-sonnet-4-5@20250929`. A 404 can also mean the model isn't enabled or isn't offered in that region | [Anthropic overview](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/overview); [Claude Code docs](https://code.claude.com/docs/en/google-vertex-ai) |
| E7 | How are Claude quotas measured? | QPM + input TPM + output TPM, per model per region. Models launched after 2026-05-26 share lineage buckets on global/multi-region. Cache reads are not counted. Sonnet 4.6 in `asia-southeast1`: 1,500 QPM / 1.5M input TPM / 150k output TPM | [Claude quotas](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/partner-models/claude/quotas) |
| E8 | Can you use the Message Batches API on Vertex? | No. Use Vertex batch predictions: BigQuery or GCS JSONL input with `custom_id`, in the same region as the BQ table. No global endpoint. 4 concurrent jobs by default. Results within 24 h | [Claude batch](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/partner-models/claude/batch) |
| E9 | Claude prompt caching on Vertex: how and what does it cost? | `cache_control` after a stable prefix. TTL is 5 min by default or `"ttl": "1h"`. Writes cost +25% (5 min) or +100% (1 h) over base input. Reads are cheap and excluded from TPM quota | [Claude prompt caching](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/partner-models/claude/prompt-caching); [Claude quotas](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/partner-models/claude/quotas) |
| E10 | Which Claude API features are missing on Vertex? | Files API, URL sources, server code execution, web fetch, MCP connector, Agent Skills, programmatic tool calling, Message Batches, Models/Admin/Usage APIs, Managed Agents, the `fallbacks` parameter | [Anthropic: Google managed](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/google-managed) |
| E11 | A scanned 40-page PDF fails on Vertex, but the token count is fine. Why? | The Agent Platform request payload limit is 30 MB. Split, compress, or send page images in chunks | [Anthropic: Google managed](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/google-managed) |
| E12 | Gemini returns 429 while the dashboard shows we're under quota. Why? | Under Standard PayGo / Dynamic Shared Quota, 429 means temporary contention on shared capacity, not a fixed quota. Second-level bursts get throttled. Single-region endpoints see the most 429s. Fix: backoff + jitter, smoothing, the global endpoint if residency allows, Priority PayGo or Provisioned Throughput | [Standard PayGo](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/standard-paygo); [Reduce-429s blog](https://cloud.google.com/blog/products/ai-machine-learning/reduce-429-errors-on-vertex-ai) |
| E13 | What are Standard PayGo usage tiers? | Org-level tiers by 30-day spend, measured per model on the global endpoint. Tier 1 ($10–250): 500k TPM for Pro/Argon, 2M for Flash. Tier 4 (>$50k): 10M / 50M | [Standard PayGo](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/standard-paygo) |
| E14 | Describe a correct retry policy for LLM calls. | Never retry immediately on 429/503. Use exponential backoff + jitter with max delay and max attempts (SDK `HttpRetryOptions`, Tenacity, or ADK Reflect-and-Retry). Add per-request timeouts and a circuit breaker or client-side fallback. Keep one retry layer | [Reduce-429s blog](https://cloud.google.com/blog/products/ai-machine-learning/reduce-429-errors-on-vertex-ai); [Retry strategy](https://docs.cloud.google.com/storage/docs/retry-strategy) |
| E15 | Which SDK should new Gemini code use? | `google-genai` (`from google import genai`). `vertexai.generative_models` was deprecated on 2025-06-24, with removal scheduled for 2026-06-24 | [Deprecations](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/deprecations) |
| E16 | How do you force JSON that matches a Pydantic model? | `response_mime_type="application/json"` + `response_schema=Model` (or `response_json_schema`). Don't repeat the schema in the prompt | [google-genai docs](https://googleapis.github.io/python-genai/) |
| E17 | Our code uses `gemini-2.5-flash`. OK in November 2026? | No. It was retired on Vertex on 2026-10-20. Move to `gemini-3.5-flash`, `gemini-3.8-flash` or `gemini-4-argon`, check residency (3.8 Flash is not listed for Singapore), and rerun evals | [Model lifecycle](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versioning); [Data residency](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/data-residency?hl=en) |
| E18 | What is Google's model retirement policy? | Stable models last at least 12 months, and retirement dates are never moved earlier. Shorter-lived models get ≥45 days' notice. Vertex and Gemini API dates can differ | [Model lifecycle](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versioning); [Forum](https://discuss.google.dev/t/gemini-2-5-flash-lite-retirement-date-different-for-gemini-api-vs-vertex-ai/389197) |
| E19 | How does Gemini context caching save money? | Implicit caching is on by default with a 90% discount. Explicit caching gives 90% on Gemini 2.5+. The minimum is 4,096 tokens on Gemini 3/4. Explicit TTL defaults to 60 min, and explicit caches pay storage per hour | [Context cache](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview) |
| E20 | How do you point Claude Code at Vertex, and why pin models? | `CLAUDE_CODE_USE_VERTEX=1`, `CLOUD_ML_REGION`, `ANTHROPIC_VERTEX_PROJECT_ID`, ADC. Pin `ANTHROPIC_DEFAULT_*_MODEL`. Without pins you are billed at the Opus rate, and aliases can fall back per session | [Claude Code docs](https://code.claude.com/docs/en/google-vertex-ai) |
| E21 | How do you audit-log prompts and responses? | Request-response logging writes sampled requests to BigQuery (Claude through `rawPredict`, REST only). Anthropic recommends keeping ≥30 days. Metadata-only inference logging (tokens, latency, errors) went GA on 2026-10-30. For zero data retention, keep content logging off | [Request-response logging](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/multimodal/request-response-logging); [Anthropic](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/google-managed); [Release notes](https://docs.cloud.google.com/gemini-enterprise-agent-platform/release-notes) |

### F. Agents, RAG, evaluation and MCP

| # | Question | Short answer | Source |
|---|---|---|---|
| F1 | How would you evaluate a claim-extraction pipeline on GCP? | The Gen AI evaluation service. Start with adaptive rubrics (per-prompt pass/fail tests) and `GENERAL_QUALITY`, then add custom metrics. For agents, use tool-call correctness and grounding. The GenAI Client eval is Preview, and the GA module lacks adaptive rubrics | [Eval overview](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/evaluation-overview); [Define metrics](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/determine-eval) |
| F2 | How do you fall back between Claude and Gemini? | There is no server-side Vertex feature. Write client-side code, use a router, or use Apigee circuit breaking (`llm-circuit-breaking` sample) | [Anthropic](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/google-managed); [Apigee sample](https://github.com/GoogleCloudPlatform/apigee-samples/tree/main/llm-circuit-breaking) |
| F3 | Where do you deploy an agent? | ADK agents deploy to Agent Runtime, Cloud Run or GKE. For a container-native LangGraph team, Cloud Run reuses FastAPI skills. The ASP/agents-cli `langgraph` template adds Terraform + CI/CD | [ADK](https://adk.dev/); [Agent Starter Pack](https://github.com/GoogleCloudPlatform/agent-starter-pack) |
| F4 | Single agent or multi-agent? | Google's pattern guide says start with a single agent. Move to multi-agent patterns (sequential, parallel) only when you need them | [Design patterns](https://docs.cloud.google.com/architecture/choose-design-pattern-agentic-ai-system?hl=ru) |
| F5 | Gotcha when backing RAG Engine with Vector Search? | It needs an **empty** Vector Search index. The corpus is linked automatically | [RAG Engine + Vector Search](https://docs.cloud.google.com/gemini-enterprise-agent-platform/build/rag-engine/use-vertexai-vector-search?hl=de) |
| F6 | BigQuery vector search limits? | `VECTOR_SEARCH` / `AI.SEARCH`, with an optional IVF/ScaNN index (brute force without one). No index in Standard edition. Pre-filters prune only partitioned/stored columns. `text-embedding-005` and friends retire 2027-04-01 | [Vector search](https://docs.cloud.google.com/bigquery/docs/vector-search-intro) |
| F7 | How do you give an agent database access safely? | MCP Toolbox or Google remote MCP with read-only tools (`execute_sql_readonly`), toolset endpoints, `roles/mcp.toolUser` on a separate agent identity, and Model Armor on user text | [Configure MCP](https://docs.cloud.google.com/mcp/configure-mcp-ai-application); [BigQuery MCP](https://docs.cloud.google.com/bigquery/docs/reference/mcp); [MCP Toolbox](https://googleapis.github.io/genai-toolbox/documentation/introduction) |
| F8 | What does the gcloud remote MCP server block? | `gcloud auth`, `config`, `iam service-accounts`, `init`, `survey`, all alpha/beta commands, and `bq init/pyshell/shell`. OAuth only, no API keys. It needs `roles/mcp.toolUser` | [gcloud MCP](https://docs.cloud.google.com/sdk/use-gcloud-mcp) |

### G. Security, IAM, networking and compliance

| # | Question | Short answer | Source |
|---|---|---|---|
| G1 | Why one service account per Cloud Run service? What if you set none? | Single-purpose SAs give least privilege and clear audit trails. With none set, Cloud Run uses the Compute Engine default SA, which may have project Editor. Enforce `iam.automaticIamGrantsForDefaultServiceAccounts` | [Service identity](https://docs.cloud.google.com/run/docs/securing/service-identity); [SA best practices](https://docs.cloud.google.com/iam/docs/best-practices-service-accounts) |
| G2 | Should you set `GOOGLE_APPLICATION_CREDENTIALS` on a Cloud Run service? | Never, when the service uses service identity. Credentials come from the attached SA | [Service identity](https://docs.cloud.google.com/run/docs/securing/service-identity) |
| G3 | What does a deployer need to deploy a service that runs as an SA? | `roles/run.admin` on the service **and** `roles/iam.serviceAccountUser` on the runtime SA. Cloud Run checks this at deploy time | [Cloud Run secrets](https://docs.cloud.google.com/run/docs/configuring/services/secrets) |
| G4 | How does GitLab CI authenticate without a JSON key? | WIF: a pool + OIDC provider (issuer `https://gitlab.com`), `google.subject=assertion.sub`, an attribute condition on `namespace_id`, a job `id_tokens` JWT with `aud` = the provider, an `external_account` credential file, and impersonation of a deployer SA via `roles/iam.workloadIdentityUser` | [WIF pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines); [GitLab OIDC](https://docs.gitlab.com/ci/cloud_services/google_cloud/) |
| G5 | Why is an attribute condition mandatory for GitLab.com / GitHub WIF? | Both use one shared issuer for all customers. Without a condition, any project could enter your pool. On GitHub, use numeric `repository_id` / `repository_owner_id` to avoid typosquatting | [WIF pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines) |
| G6 | Can a WIF principalSet get `run.invoker` directly? | No. Cloud Run's invoke permission doesn't support WIF principals, and neither do VPC-SC rules. Impersonate an SA and mint an ID token | [Google blog](https://cloud.google.com/blog/products/identity-security/make-iam-for-gke-easier-to-use-with-workload-identity-federation) |
| G7 | Service A calls private Cloud Run service B. What is needed? | A's SA gets `run.invoker` on B. A fetches an ID token with `aud` = B's `run.app` URL or a custom audience (custom domains are not accepted) and sends it as a Bearer token. Tokens last ~1 h | [Service-to-service](https://docs.cloud.google.com/run/docs/authenticating/service-to-service) |
| G8 | ID token vs access token? | ID tokens (OIDC JWT with `aud`) call your own handlers, like Cloud Run. OAuth access tokens call Google APIs on `*.googleapis.com` | [HTTP targets](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks) |
| G9 | What must a receiver check when it verifies a Google OIDC token itself? | Signature, `aud`, `exp`, `iss` (`accounts.google.com`), `email` = the expected SA, `email_verified` = true. Python's `verify_oauth2_token` checks signature/aud/exp; you check `email` yourself | [Pub/Sub push auth](https://docs.cloud.google.com/pubsub/docs/authenticate-push-subscriptions) |
| G10 | Can you trust `X-CloudTasks-QueueName` to prove a request came from Cloud Tasks? | No. Those headers can be spoofed. Identity must come from the OIDC token | [HTTP targets](https://docs.cloud.google.com/tasks/docs/creating-http-target-tasks) |
| G11 | The API uses its own user JWT in `Authorization`. How do you also send a Google ID token? | Use `X-Serverless-Authorization: Bearer …`. If both headers are present, Cloud Run checks only that one | [Service-to-service](https://docs.cloud.google.com/run/docs/authenticating/service-to-service) |
| G12 | Ingress vs IAM, and the right setting for a Cloud Tasks-only worker? | Ingress = network path. IAM = identity, on every path. Use both. Worker: `internal` + `--no-allow-unauthenticated`. Cloud Tasks counts as internal in the same project/perimeter when it calls the `run.app` URL | [Ingress](https://docs.cloud.google.com/run/docs/securing/ingress) |
| G13 | How do you put a WAF in front of Cloud Run and stop bypass? | Global external ALB + serverless NEG + Cloud Armor on the backend service. Set ingress to `internal-and-cloud-load-balancing` or disable the default URL. Serverless NEGs have no health checks | [ALB + Cloud Run](https://docs.cloud.google.com/load-balancing/docs/https/setting-up-https-serverless) |
| G14 | A partner whitelists IPs. How do you get a fixed egress IP? | Direct VPC egress (or a connector) with `--vpc-egress=all-traffic`, plus Cloud Router + Cloud NAT with a reserved static IP in manual mode. Watch for NAT port exhaustion | [Static outbound IP](https://docs.cloud.google.com/run/docs/configuring/static-outbound-ip) |
| G15 | Direct VPC egress or Serverless VPC Access connector? | Direct (recommended): no connector VMs, lower latency, higher throughput, per-service tags, spend-cap support. It costs more subnet IPs and scales from zero more slowly | [Connect to VPC](https://docs.cloud.google.com/run/docs/configuring/connecting-vpc) |
| G16 | Secret as env var or volume, and how do you rotate? | An env var resolves at instance start: pin a version and redeploy to rotate. A volume is read on access and follows `latest`. Secret Manager only sends `SECRET_ROTATE` Pub/Sub events, so you write the rotation logic. Grant `secretAccessor` on that one secret | [Cloud Run secrets](https://docs.cloud.google.com/run/docs/configuring/services/secrets); [Rotation](https://docs.cloud.google.com/secret-manager/docs/secret-rotation) |
| G17 | What does VPC Service Controls add on top of IAM? | A perimeter that blocks exfiltration even with valid credentials. Cloud Run inside it needs internal ingress, `all-traffic` egress, Private Google Access and DNS to `restricted.googleapis.com`. Ingress `all` disables enforcement. Ingress rules with IAM principals aren't supported for Cloud Run | [Cloud Run + VPC-SC](https://docs.cloud.google.com/run/docs/securing/using-vpc-service-controls) |
| G18 | Which services support CMEK, and what are the catches? | Agent Platform resources, BigQuery, GCS, Firestore, Secret Manager, Pub/Sub, Cloud Tasks, Artifact Registry and Logging. Catches: Cloud Run CMEK covers only the container image, and Gemini durable caching has no CMEK | [CMEK services](https://docs.cloud.google.com/kms/docs/compatible-services); [Data governance](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/data-governance) |
| G19 | Does Google train on our prompts? What about caching? | No training or fine-tuning without permission. Gemini caches data by default for up to 24 h. Turn it off per project with `cacheConfig.disableCache=true` (needs `roles/aiplatform.admin`) | [Data governance](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/data-governance) |
| G20 | Is there prompt logging by Google, and can we get zero data retention? | Standard Google models log prompts only when classifiers flag abuse, kept up to 90 days. Master Agreement customers are exempt by default. For ZDR: content logging off, `store=false`, no Grounding with Google Search/Maps. Advanced AI Claude models (Fable/Mythos) log all prompts up to 30 days | [Abuse monitoring](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/abuse-monitoring); [ZDR](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/vertex-ai-zero-data-retention) |
| G21 | How do you keep LLM processing in Singapore? | Regional `asia-southeast1` endpoint, never `global`. Check each model (Gemini 4 Argon and 3.5 Flash are listed; 2.5 Pro is not). Claude support conflicts across sources. Add a resource-location org policy or the Assured Workloads Singapore Data Boundary | [Data residency](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/data-residency); [Assured Workloads](https://docs.cloud.google.com/assured-workloads/docs/supported-products) |
| G22 | How do you remove PII/PHI before an LLM call? | SDP `content:deidentify` with an InspectConfig (plus custom infoTypes for CCCD or PhilHealth numbers) and a DeidentifyConfig (replace, mask, crypto-hash, date shift). Or Model Armor advanced mode with SDP templates. `MEDICAL_DATA` excludes medical IDs | [SDP de-identify](https://docs.cloud.google.com/sensitive-data-protection/docs/deidentify-sensitive-data); [Model Armor](https://docs.cloud.google.com/model-armor/overview?hl=en); [infoTypes](https://docs.cloud.google.com/sensitive-data-protection/docs/infotypes-reference?hl=id) |
| G23 | Deny vs allow policy: which wins? | Deny policies are checked first and win. They attach at org/folder/project, support principal exceptions, and their conditions use only resource tags | [Deny policies](https://docs.cloud.google.com/iam/docs/deny-overview) |
| G24 | Which audit logs are on by default? | Admin Activity and System Event (always), Policy Denied (on by default). Data Access logs are off except for BigQuery, so enable them for GCS, Agent Platform, Secret Manager and IAM/STS | [Audit logs](https://docs.cloud.google.com/logging/docs/audit) |
| G25 | Is Google Cloud "HIPAA compliant"? | There is no HIPAA certification; compliance is shared. The BAA covers the infrastructure plus named products (Cloud Run, BigQuery, GCS, Secret Manager, Agent Platform…). Disable non-covered services for PHI | [HIPAA](https://docs.cloud.google.com/docs/security/compliance/hipaa) |
| G26 | What does Vietnam's PDPL change for a cloud AI claims system? | Law 91/2025/QH15 (effective 2026-01-01) with Decree 356/2025: DPIA and transfer-impact assessments (update every 6 months on change), breach reports within 72 h of detection, fines up to 5% of prior-year revenue for cross-border violations. Legal decides whether hosting abroad needs a TIA | [Tilleke & Gibbins](https://tilleke.com/insights/vietnams-new-personal-data-protection-law-a-closer-look); [Allen & Gledhill](https://www.allenandgledhill.com/vn/publication/articles/31075/upcoming-changes-to-vietnam-s-personal-data-protection-regime) |
| G27 | What about Hong Kong and Philippines rules? | HK PCPD cloud guidance (updated Jan 2025): logging, encryption, MFA, contract clauses, tell data subjects about transfers outside HK. PH Data Privacy Act: health is sensitive personal information, 72 h breach notice, required outsourcing clauses | [PCPD guidance](https://pcpd.org.hk/english/resources_centre/publications/files/IL_cloud_e.pdf); [Hogan Lovells](https://www.hoganlovells.com/en/publications/philippines-finalizes-data-privacy-act-implementing-rules) |

### H. DevOps, observability, cost and reliability

| # | Question | Short answer | Source |
|---|---|---|---|
| H1 | Two ways to canary a Cloud Run service? | Cloud Deploy canary (25/50/75 → stable, verify jobs, deploy analysis, `advanceRolloutRule`; services and worker pools, not jobs; no 100% canary), or native tags + `update-traffic` | [Cloud Deploy canary](https://docs.cloud.google.com/deploy/docs/deployment-strategies/canary); [Rollouts](https://docs.cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration) |
| H2 | Why deploy by digest, not tag? | Tags can move. Cloud Deploy recommends SHA-qualified images, so one commit maps to one immutable image | [Cloud Deploy to Cloud Run](https://docs.cloud.google.com/deploy/docs/deploy-app-run) |
| H3 | How do you structure Terraform for dev/uat/prod? | `modules/` + `environments/{dev,uat,prod}`, each with its own `backend.tf` and `main.tf`. Default workspace only. ≤100 resources per state. Pin providers to a minor version. Commit `.terraform.lock.hcl`. Use `terraform.tfvars` | [Root modules](https://docs.cloud.google.com/docs/terraform/best-practices/root-modules) |
| H4 | Where do you keep Terraform state? | A GCS bucket with object versioning + lifecycle rules, public access prevention enforced, uniform bucket-level access, `force_destroy = false`. Only 1–2 admins | [State in GCS](https://docs.cloud.google.com/docs/terraform/resource-management/store-state) |
| H5 | Would you use Deployment Manager? | No. It reached end of support on 2026-03-31. Use Terraform, or Infrastructure Manager (which runs Terraform in Cloud Build) | [DM deprecations](https://docs.cloud.google.com/deployment-manager/docs/deprecations); [Infra Manager](https://docs.cloud.google.com/infrastructure-manager/docs/overview) |
| H6 | How do you make FastAPI logs structured and linked to traces? | One JSON object per line to stdout, with `severity` and `message`. Add `logging.googleapis.com/trace` = `projects/P/traces/T` (from `X-Cloud-Trace-Context` or OTel), plus `spanId` and `trace_sampled`. Stdout logs don't count toward the `entries.write` quota | [Cloud Run logging](https://docs.cloud.google.com/run/docs/logging); [OTel Python](https://docs.cloud.google.com/trace/docs/setup/python-ot) |
| H7 | Log retention and cost? | `_Required`: 400 days, fixed, free. `_Default`: 30 days (1–3,650). Ingest costs $0.50/GiB after 50 GiB/project/month. Retention beyond 30 days costs $0.01/GiB/month | [Logging quotas](https://docs.cloud.google.com/logging/quotas); [Observability pricing](https://cloud.google.com/stackdriver/pricing) |
| H8 | Log-based metric gotchas? | No backfill. User-defined metrics count excluded logs too. They are billed as custom metrics. Use distribution metrics for latency and tokens | [Log-based metrics](https://docs.cloud.google.com/logging/docs/logs-based-metrics) |
| H9 | How do you alert on an SLO without paging on every spike? | Burn-rate alerts with `select_slo_burn_rate`: fast burn ~10x over 1–2 h, slow burn ~2x over 24 h, both running. Cloud Run is not auto-detected, so define a custom service | [Burn-rate alerting](https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate); [SRE Workbook ch. 5](https://sre.google/workbook/alerting-on-slos/) |
| H10 | We expose Prometheus `/metrics`. How do we keep it on Cloud Run? | The Managed Service for Prometheus sidecar scrapes `:8080/metrics` every 30 s using `RunMonitoring` and a container-dependencies annotation. Query with PromQL. Use instance-based billing. $0.06 per million samples | [GMP sidecar](https://docs.cloud.google.com/stackdriver/docs/managed-prometheus/cloudrun-sidecar); [Pricing](https://cloud.google.com/stackdriver/pricing) |
| H11 | How do you compute LLM cost per claim? | Read `usageMetadata` (prompt, output, `cachedContentTokenCount`), log it as JSON with `claim_id` and `model`, sink to BigQuery, multiply by a price table, and reconcile with the billing export. Example at AI Studio list price on Gemini 3.8 Flash: 20k input (15k cached) + 2k output ≈ **$0.012 per claim** | [Context cache](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview); [Gemini API pricing](https://aistudio.google.com/docs/pricing) |
| H12 | What is safe to retry? | 408, 429, 5xx and network timeouts, and only for idempotent operations (or writes protected by preconditions like `ifGenerationMatch`). Never retry permanent errors or forever, and never stack retries | [Retry strategy](https://docs.cloud.google.com/storage/docs/retry-strategy) |
| H13 | Does a budget stop spending? | No. It alerts at 50/90/100% and can trigger Pub/Sub automation. Spend caps (GA 2026-10-13 for limited services, incl. AI APIs and Cloud Run) pause API traffic but leave resources running. Enforcement is delayed and overages are billed | [Budgets](https://docs.cloud.google.com/billing/docs/how-to/budgets); [Spend caps](https://docs.cloud.google.com/billing/docs/how-to/budgets-spend-caps) |
| H14 | Why enable billing export on day one? | It is not fully backfilled (multi-region datasets get the current + previous month; regional get none). It includes labels. Query through views, because schemas change | [Billing export](https://docs.cloud.google.com/billing/docs/how-to/export-data-bigquery) |
| H15 | How do you cut Gemini cost without hurting quality? | Route easy steps to Flash-Lite/Flash. Use context caching (90% off cached input). Use Batch/Flex for offline work (50% off). Stay under 200K tokens (the >200K tier costs more). Track scheduled price changes (AI Studio: Gemini 4 Argon doubles on 2026-12-01, 3.8 Flash on 2027-01-01). Vertex prices can differ | [Gemini API pricing](https://aistudio.google.com/docs/pricing); [Context cache](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview) |
| H16 | What did Google's June 12, 2025 outage teach? | Malformed policy data written to Spanner hit an unguarded null-pointer path in Service Control. Lessons: feature-flag every change, fail open, keep the status page independent, and use randomized exponential backoff (the recovery overloaded Spanner in us-central1) | [Incident report](https://status.cloud.google.com/incidents/ow5i3PPK96RduMcb1SsW) |

### I. System-design scenarios (combine the facts above)

**I1. "10,000 claim PDFs arrive in a burst. Design upload → OCR → extraction → index."**
Start with browser-direct resumable uploads, so no file bytes pass through Cloud Run ([resumable uploads](https://docs.cloud.google.com/storage/docs/performing-resumable-uploads)). Treat each `OBJECT_FINALIZE` notification as at-least-once and dedupe on `bucket/object#generation` ([notifications](https://docs.cloud.google.com/storage/docs/pubsub-notifications)). Put a Cloud Tasks queue in front of Document AI. Its `max-concurrent-dispatches` and `max-dispatches-per-second` turn the burst into a steady flow your OCR quota can take ([queues](https://docs.cloud.google.com/tasks/docs/configuring-queues)). Send ≤15-page documents to online OCR and bigger ones to batch ([limits](https://docs.cloud.google.com/document-ai/limits)). Track `(claim_id, stage)` status in Firestore. Stream events to BigQuery through the Storage Write API rather than single-row DML ([Write API](https://docs.cloud.google.com/bigquery/docs/write-api)). Send non-urgent LLM extraction to batch predictions at 50% of the price ([Gemini pricing](https://aistudio.google.com/docs/pricing)). Close with what you would monitor: queue depth, task retry count, DLQ size and cost per page.

**I2. "At 2 a.m., Gemini returns 429 and Claude returns 404. Walk me through it."**
For the 429, first say it is **not** a fixed quota under Standard PayGo. It is contention on shared capacity. Check the inference request metadata logs to see which seconds and models were throttled ([429 doc](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/error-code-429)). Confirm that only one retry layer with jitter is active. Then decide whether the global endpoint is allowed under your residency rules ([Standard PayGo](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/standard-paygo)). For the Claude 404, check three things: the model is enabled in Model Garden, the model is offered in that region, and the ID format is right (`@` for pre-4.6) ([Claude Code docs](https://code.claude.com/docs/en/google-vertex-ai)). Last, check the lifecycle table for a retirement you missed ([model lifecycle](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versioning)).

**I3. "Where do claim status, audit history and analytics live?"**
Hot, mutable status with locks goes in Firestore or Cloud SQL. Firestore gives serializable transactions but limits single-document write rate ([counters](https://docs.cloud.google.com/firestore/native/docs/solutions/counters)). Cloud SQL gives real unique constraints and sequences ([DML page pointing OLTP to Cloud SQL](https://docs.cloud.google.com/bigquery/docs/data-manipulation-language)). Append-only audit logs and analytics go in BigQuery, partitioned by date and clustered by `claim_id`, with `maximum_bytes_billed` on app queries ([cost control](https://docs.cloud.google.com/bigquery/docs/best-practices-costs)). Never use BigQuery DML on the user request path, and never rely on it for uniqueness ([keys](https://docs.cloud.google.com/bigquery/docs/primary-foreign-keys)).

**I4. "Walk me through PHI protection end to end."**
One service account per service and no keys ([SA best practices](https://docs.cloud.google.com/iam/docs/best-practices-service-accounts)). Internal ingress plus IAM on workers. ALB + Cloud Armor in front of the public API ([ingress](https://docs.cloud.google.com/run/docs/securing/ingress)). Run SDP de-identification before any LLM call ([SDP](https://docs.cloud.google.com/sensitive-data-protection/docs/deidentify-sensitive-data)). Use a regional endpoint with Gemini caching disabled ([data governance](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/data-governance)). Add CMEK where supported, a VPC-SC perimeter around Agent Platform, BigQuery and GCS ([VPC-SC](https://docs.cloud.google.com/run/docs/securing/using-vpc-service-controls)), Data Access audit logs, and no PHI in logs or labels ([HIPAA](https://docs.cloud.google.com/docs/security/compliance/hipaa)). Finish by mapping these controls to PDPL, PDPO and the PH DPA, and by naming what legal must still decide.

**I5. "A bad config reached every region. Run the postmortem."**
Use Google's own June 2025 incident as the model ([incident report](https://status.cloud.google.com/incidents/ow5i3PPK96RduMcb1SsW)). Cover the timeline, the unguarded code path, why the change was not behind a feature flag, and why recovery traffic needed randomized backoff. Then apply it to your system: staged rollouts with `--no-traffic` tags or Cloud Deploy canaries ([Cloud Deploy canary](https://docs.cloud.google.com/deploy/docs/deployment-strategies/canary)), an error-budget policy ([SRE Workbook](https://sre.google/workbook/table-of-contents/)), and a blameless write-up.

---

## Eighteen facts you must verify yourself before relying on them

The research found real conflicts between official sources, and some gaps no public page answers. Each item below is a small sandbox experiment or a question for your team. If you turn these into evidence ("I tested it, here is what happened"), they become your strongest interview stories.

| # | Open question | Why it matters | How to check |
|---|---|---|---|
| 1 | **Which Claude models are served on the `asia-southeast1` regional endpoint?** Anthropic says regional endpoints serve "Sonnet 4.6 and earlier" only. Google's residency table lists newer models (Opus 5.5, Sonnet 5.5, Sonnet 5…) for Singapore. Google's quotas page lists only Opus/Sonnet 4.6 and 4.5, Claude 3.5 Sonnet and Claude 3 Haiku there ([Anthropic](https://platform.claude.com/docs/en/build-with-claude/claude-models-on-google-cloud/google-managed); [residency](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/data-residency?hl=en); [quotas](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/partner-models/claude/quotas)) | It decides which Claude models you may use for regulated data | Model Garden → each model → "Supported regions". Then make one `AnthropicVertex(region="asia-southeast1")` call per model and record 200 or 404 |
| 2 | Which Gemini models have Singapore ML-processing commitments? `gemini-3.8-flash` was not listed in the research fetch ([residency](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/data-residency?hl=en)) | A call that succeeds does **not** prove residency | Read the live residency table and your contract. Don't rely on a test call |
| 3 | Does Cloud Run strip the JWT signature (a placeholder like `SIGNATURE_REMOVED_BY_GOOGLE`) after its own IAM check? Unconfirmed in the research | If yes, app-level `verify_oauth2_token` fails on IAM-protected services. You would decode claims instead | Deploy a private service that logs the `Authorization` header; call it with a valid ID token |
| 4 | Does Cloud Run's IAM check accept `aud` = service URL **plus a path** (the Cloud Tasks default)? The docs only promise "service URL or custom audience" ([service-to-service](https://docs.cloud.google.com/run/docs/authenticating/service-to-service)) | A silent 401/403 for every task | Enqueue a task without `audience` to a private service and watch the response code |
| 5 | Cloud Tasks task-name reuse window: 1 hour or up to 24 hours? ([REST](https://docs.cloud.google.com/tasks/docs/reference/rest/v2/projects.locations.queues.tasks/create) vs [Python reference](https://cloud.google.com/python/docs/reference/cloudtasks/latest/google.cloud.tasks_v2.types.CreateTaskRequest)) | Decides whether task names alone can dedupe | Create a named task, let it run, then retry the same name at +1 h and +2 h and record `ALREADY_EXISTS` |
| 6 | Do Cloud Run health-check probes require instance-based billing? The billing page summary says yes; the health-checks page doesn't ([billing](https://docs.cloud.google.com/run/docs/configuring/billing-settings) vs [health checks](https://docs.cloud.google.com/run/docs/configuring/healthchecks)) | Changes your cost model | Deploy a request-billed service with a liveness probe and see whether it is accepted |
| 7 | Is a new project's Claude quota stuck at 0? (A community report says yes for some projects) ([forum](https://discuss.google.dev/t/claude-sonnet-4-5-quota-stuck-at-0-on-all-regions-cannot-increase/355205)) | It can block week 6 | Quotas page → filter `base_model` (e.g. `anthropic-claude-sonnet`) in week 1. Request an increase or open a support case early |
| 8 | Does `genai.Client(vertexai=True)` still work, and did the `vertexai.generative_models` removal actually ship? ([deprecations](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/deprecations)) | Old notebooks and company code may break on upgrade | `pip install -U google-genai google-cloud-aiplatform` in a clean venv and try both imports |
| 9 | Document AI quality and limits for your documents: language hints for Vietnamese, Traditional Chinese and Tagalog; real online latency per page count; requests-per-minute quota. None was confirmed in the research | It sets your timeout, your batch threshold and your accuracy story | Run 20 representative synthetic documents through online and batch OCR. Measure latency and field accuracy |
| 10 | How many claim-ID transactions per second does one Firestore counter document take in your database mode? The docs give no fixed number ([best practices](https://docs.cloud.google.com/firestore/native/docs/best-practices)) | Tells you when ACE-style counters need to change | Load test at 1, 5 and 10 transactions/s and count `ABORTED` errors |
| 11 | Claude prompt caching on Vertex: explicit only, or automatic too? Do cache reads really drop out of TPM usage? ([Google caching page](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/partner-models/claude/prompt-caching); [quotas](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/partner-models/claude/quotas)) | Affects cost and quota planning | Send two identical cached calls. Compare `usage` and the `token_count` metric in Metrics Explorer |
| 12 | Does `telemetry.googleapis.com` accept OTLP logs and metrics, or only traces? Does Cloud Profiler work on Cloud Run? ([OTLP API](https://cloud.google.com/stackdriver/docs/reference/telemetry/overview); [Profiler](https://docs.cloud.google.com/profiler/docs/profiling-python)) | Decides your OTel Collector design | Send OTLP metrics from a test service; try the profiler agent |
| 13 | If the company uses **self-managed** GitLab: what issuer URL does WIF need, and can Google STS reach its JWKS? Google's page covers only GitLab SaaS ([WIF pipelines](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines); [GitLab manual OIDC](https://docs.gitlab.com/ci/cloud_services/google_cloud/)) | Keyless CI may need a different setup | Ask the platform team, then follow GitLab's manual OIDC tutorial |
| 14 | Which services can use spend caps at GA, and how long is the enforcement delay? ([spend caps](https://docs.cloud.google.com/billing/docs/how-to/budgets-spend-caps)) | Your sandbox safety net | Set a $1 cap on a sandbox project and watch when traffic pauses |
| 15 | Agent Platform Gemini prices vs the AI Studio prices quoted in this report. The Vertex pricing page could not be read ([Gemini API pricing](https://aistudio.google.com/docs/pricing)) | Your cost-per-claim numbers | Check the live Agent Platform pricing page and the billing-export SKUs after one day of use |
| 16 | Under Vietnam's PDPL, do you need a transfer-impact assessment to process claims in Singapore? Which data counts as "sensitive"? ([Tilleke & Gibbins](https://tilleke.com/insights/vietnams-new-personal-data-protection-law-a-closer-look)) | A legal blocker, not a technical one | Ask the legal/compliance team. This is not legal advice |
| 17 | Workflows: the max timeout of one `http.*` call step and the max `await_callback` timeout. Not shown on the limits page ([Workflows limits](https://docs.cloud.google.com/workflows/quotas)) | Human-review pauses longer than 12 h | Read the callbacks reference, then test a long callback in the sandbox |
| 18 | Current Google Skills price, per-lab credit costs, and the Anthropic Academy course length and cost (both behind login) | Your learning budget | Log in and check before you pay |

---

## Conclusion

Production fluency on Google Cloud is mostly **limit literacy at the joints between services**. Each managed service exposes a handful of hard numbers: 300 s default and 3,600 s max on Cloud Run, 30 min on Cloud Tasks, 10 min on Pub/Sub push, 15 pages on online OCR, 2 concurrent DML per BigQuery table, 20 s for a Firestore lock, 30 MB for a Vertex request. The real bugs, and the best interview questions, live where two of these numbers meet. A 1,800 s task deadline on a 300 s service. A Firestore lock held while a 60 s OCR call runs. A BigQuery transaction table lock hit by two parallel workers. So the most efficient study habit is to build a personal "intersection matrix" while you read: for every pair of services in your pipeline, write which limit wins. Your Celery and Kubernetes background is an advantage here, not a handicap. You already know what a worker, a broker and a probe should do, so you can see exactly where the serverless versions behave differently.

The 2026 churn also changes what "senior" means on GCP. Names, SDKs and model IDs changed several times in one year, and Google and Anthropic disagree about something as basic as which Claude models run in Singapore. So no memorized fact is safe for long. The durable skill is a verification habit: read release notes monthly, check the model lifecycle table before every migration, confirm regions in Model Garden, and test conflicting claims in a sandbox. Claude Code fits this habit best as an explainer, a reviewer and an interviewer working under strict guardrails, not as an autopilot. If you finish the twelve weeks with six small systems, a written postmortem and evidence for the eighteen open questions, you will be able to answer the hardest kind of production question there is: "how do you know?"
