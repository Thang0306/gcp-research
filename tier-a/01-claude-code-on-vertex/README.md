# Tier A #1: Claude Code on Google Cloud's Agent Platform (formerly Vertex AI)

Source: https://code.claude.com/docs/en/google-vertex-ai (read 2026-11-07)

> **Tóm tắt (VI):** gcloud đã được cài. Bạn cần tự làm 5 việc trên Google Cloud (tạo project, bật billing trả phí, bật API, bật model Claude trong Model Garden, đặt budget). Sau đó dùng `vertex-env.sh` để chạy Claude Code qua Vertex trong **một terminal riêng**, không ảnh hưởng tài khoản Claude hiện tại. Chạy `check.sh` để kiểm tra từng bước.

## The 5 prerequisites and where you are

| # | Prerequisite (from the doc) | Status | Who does it |
|---|---|---|---|
| 1 | GCP account with **billing enabled** | ⬜ | You (needs a card) |
| 2 | Project with **Agent Platform API** (`aiplatform.googleapis.com`) enabled | ⬜ | You, one command |
| 3 | **Access to Claude models** (e.g. Sonnet 4.6) | ⬜ | You, in the console |
| 4 | `gcloud` installed and configured | ✅ installed (592.0.0, `~/google-cloud-sdk`) / ⬜ login | You (browser login) |
| 5 | Quota in your region | ⬜ check | Usually OK by default |

---

## Step 0: Put gcloud on your PATH (once)

The installer did **not** edit your `~/.zshrc`. Add these two lines yourself:

```bash
echo 'source "$HOME/google-cloud-sdk/path.zsh.inc"' >> ~/.zshrc
echo 'source "$HOME/google-cloud-sdk/completion.zsh.inc"' >> ~/.zshrc
exec zsh
gcloud --version   # should print "Google Cloud SDK 592.0.0"
```

## Step 1: Log in (2 logins, they are different)

```bash
gcloud auth login                         # 1) for gcloud commands (you, in the terminal)
gcloud auth application-default login     # 2) "ADC": for programs (Claude Code, Python SDKs)
```

- `gcloud auth login` lets **gcloud** act as you.
- `application-default login` writes `~/.config/gcloud/application_default_credentials.json`. **Claude Code and the Google SDKs read this file**, not the first login.
- Interview point: on Cloud Run there is no ADC file. The code gets credentials from the **attached service account** through the metadata server. Same code, different credential source.

## Step 2: Create a dedicated project + billing

The doc says: *"Create a dedicated GCP project for Claude Code to simplify cost tracking and access control."*

```bash
# Project IDs are global and permanent. Pick something like:
export PROJECT_ID=nam-claude-sandbox-01
gcloud projects create $PROJECT_ID --name="Claude sandbox"
gcloud config set project $PROJECT_ID

gcloud billing accounts list               # copy the ACCOUNT_ID (format XXXXXX-XXXXXX-XXXXXX)
gcloud billing projects link $PROJECT_ID --billing-account=XXXXXX-XXXXXX-XXXXXX
```

**Free trial trap:** the $300 free-trial credit **cannot pay for Claude** (partner models). In the console go to *Billing → Overview → Activate full account* (upgrade to paid). You keep the remaining credit for Google services (Cloud Run, Firestore, etc.).

## Step 3: Set a budget alert FIRST (before any model call)

Console: *Billing → Budgets & alerts → Create budget* → scope: this project → amount e.g. **$20/month** → alerts at 50%, 90%, 100%.

Or by command:

```bash
gcloud services enable billingbudgets.googleapis.com
gcloud billing budgets create \
  --billing-account=XXXXXX-XXXXXX-XXXXXX \
  --display-name="claude-sandbox-20usd" \
  --budget-amount=20USD \
  --filter-projects=projects/$PROJECT_ID \
  --threshold-rule=percent=0.5 --threshold-rule=percent=0.9 --threshold-rule=percent=1.0
```

> A budget **only sends emails**. It does not stop spending. (Interview point: to hard-stop you need Pub/Sub budget notification → Cloud Function that disables billing. Week 2 practice idea.)

## Step 4: Enable the Agent Platform API

```bash
gcloud services enable aiplatform.googleapis.com
```

## Step 5: Enable Claude models in Model Garden ("Access to desired Claude models")

This is the step you asked about. It is **console-only** (there is no gcloud command to accept the Anthropic terms).

1. Open https://console.cloud.google.com/vertex-ai/model-garden (check the project picker at the top shows your sandbox project).
2. Search **"Claude"**.
3. Open the card, e.g. **Claude Sonnet 4.6** → click **Enable**.
4. A form asks for business info and use case. For a personal account write e.g. *"Individual developer. Learning and prototyping AI apps (RAG, document OCR pipelines) with Claude Code."* Accept the Anthropic terms (it is a Google Cloud Marketplace agreement, billed through your GCP bill).
5. Wait. The doc says **approval may take 24–48 hours**; often it is minutes.
6. Repeat for the models you want. Suggested set for study:

| Model | Why | Cost |
|---|---|---|
| **Claude Sonnet 4.6** | Main daily model, cheap enough for practice | $ |
| **Claude Haiku 4.5** | Background tasks + cheap app calls | ¢ |
| Claude Opus (newest) | Only if you want to compare. Claude Code's **default** on Vertex is `claude-opus-5-5`, so if you don't pin, you pay Opus prices | $$$ |

7. On each model card, look at **"Supported features" / regions**: write down whether it supports the **`global`** endpoint and which regions (e.g. `us-east5`, `europe-west1`, `asia-southeast1`). Copy the **exact model ID** shown on the card (e.g. `claude-sonnet-4-6`, `claude-haiku-4-5@20251001`).

> This also answers Open Fact #1 from the study plan: *"Which Claude models really run in asia-southeast1?"* Record it below.

| Model ID (copied from card) | global? | Regions listed | asia-southeast1? |
|---|---|---|---|
| | | | |
| | | | |

## Step 6: IAM

You are **Owner** of your own project, so you already have everything. For a real team you give only:

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="user:someone@example.com" --role="roles/aiplatform.user"
```

`roles/aiplatform.user` contains `aiplatform.endpoints.predict` (needed for calls and token counting).

## Step 7: Check quota (Step 5 of the prerequisites)

Console: *IAM & Admin → Quotas & system limits* → filter **"anthropic"** or the model name. New projects usually get a small default quota per minute. If you get **429**, see Troubleshooting.

## Step 8: Test one raw call (before Claude Code)

`check.sh` does this for you. It proves billing + API + model access + ADC all work, with a ~10-token request.

```bash
./check.sh nam-claude-sandbox-01 claude-sonnet-4-6 global
```

## Step 9: Run Claude Code through Vertex, in a separate terminal

**Why not the `/login` wizard?** The wizard writes to `~/.claude/settings.json`, which changes **every** Claude Code session on this Mac (including this one, which uses your Claude subscription). For learning, keep Vertex in its own terminal:

```bash
# edit PROJECT_ID inside first
source ./vertex-env.sh
claude          # then run /status
```

`/status` must show `API provider: Google Vertex AI`, your project, region and model. Later, when you are comfortable, try the wizard (`/login` → 3rd-party platform → Google Vertex AI, or `/setup-vertex`) to see what it writes.

## Troubleshooting (from the doc)

| Error | Cause | Fix |
|---|---|---|
| `Could not load the default credentials` | No ADC file | `gcloud auth application-default login` |
| **404** model not found | Model not enabled, or not offered in this location | Enable in Model Garden; check the card's regions; for `global` use a model that supports global, or set its `VERTEX_REGION_CLAUDE_*` variable |
| **429** | Quota, or primary/small model not in the region | Use `CLOUD_ML_REGION=global`; request quota increase |
| `/status` has no Vertex line | Env vars not in the shell that started `claude` | `source vertex-env.sh` in the **same** terminal |

## Things to remember for interviews

1. **Location forms:** `global` (best availability, Google routes), multi-region `us` / `eu` (data stays in the area; hosts `aiplatform.us.rep.googleapis.com`), single region e.g. `us-east5` (data residency, but fewer models and lower quota). For PDPL/Vietnam health data, `global` is the hard question: you cannot say where processing happens.
2. **Pin model versions** in production. Aliases like `sonnet` move when Claude Code updates. Same lesson for apps: pin `claude-sonnet-4-6`, never "latest".
3. **`ANTHROPIC_VERTEX_PROJECT_ID` wins** over `GOOGLE_CLOUD_PROJECT` and the project inside a credentials file.
4. **Prompt caching is on by default** in Claude Code (5-min TTL; `ENABLE_PROMPT_CACHING_1H=1` for 1 hour, costs more to write).
5. Billing goes through **your GCP invoice** (Marketplace), not Anthropic. Usage shows in Billing reports under the Anthropic SKU.
