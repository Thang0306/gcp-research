# Long-form GCP learning programs, Claude Code practice setup, and production question banks (for an AI engineer new to GCP, Nov 2026)

Scope note for the report writer: research done 2026-11-06. Two big 2026 changes affect almost every resource below:
1. **Vertex AI was renamed "Gemini Enterprise Agent Platform"** (announced at Google Cloud Next '26, April 22, 2026). Old APIs keep working, so older courses that say "Vertex AI" are still usable, but console names and docs changed.
2. **Google Cloud Skills Boost is now "Google Skills"** (skills.google). Old cloudskillsboost.google URLs still resolve.

Where a fact comes from my prior knowledge and was NOT verified in this session, it is placed in Inferences or Gaps and marked "unverified".

---

## 1. Which structured, long-form programs are current and deep in 2026 (and which are shallow or outdated)?

### Takeaway
The deepest *current* hands-on material for AI products on GCP is not one course. It is a mix of: (a) Google Skills paths and Document AI skill badges (real sandbox labs), (b) the Cloud Run AI cookbook (77 dated codelabs/blogs/videos, 2024-08 to 2026-08, ADK/MCP/RAG/GPU/vLLM), (c) the free Kaggle x Google "5-Day AI Agents Intensive" (now self-paced), (d) the Agent Starter Pack repo, and (e) the O'Reilly book *GenAI on Google Cloud* (Jan/Mar 2026). Coursera certificates, Udemy and older books (2022) are cert-breadth or pre-GenAI and are mostly redundant for this learner.

### Cited Findings

**Platform-level facts (affect every course)**
- Gemini Enterprise Agent Platform was announced April 22, 2026 at Next '26 as the successor ("evolution") of Vertex AI; Agentspace and Agent Builder were folded in — [Wikipedia](https://en.wikipedia.org/wiki/Gemini_Enterprise_Agent_Platform); [ITPro](https://www.itpro.com/technology/artificial-intelligence/google-expands-gemini-enterprise-consolidates-vertex-ai-services-to-simplify-agent-deployment); [The Journal](https://thejournal.com/articles/2026/05/04/google-announces-new-gemini-enterprise-agent-platform.aspx?p=1)
- Google's release notes list renames, e.g. Vertex AI Studio → Agent Studio, Vertex AI Search → Agent Search, Vertex AI Pipelines → Agent Platform Pipelines — [Agent Platform release notes](https://docs.cloud.google.com/gemini-enterprise-agent-platform/release-notes?hl=de) (via search summary)
- Existing Vertex AI integrations keep working; changes are mainly name, console and docs. Sources conflict on whether "Vertex AI is gone" vs. kept as building blocks — [Revolgy](https://www.revolgy.com/insights/blog/definitive-guide-to-gemini-enterprise-agent-platform-geap); [Medium GDE post "Vertex AI is gone"](https://medium.com/google-developer-experts/vertex-ai-is-gone-here-is-what-google-built-instead-92556d1c64eb). Note: the Claude Code docs still use `aiplatform.googleapis.com` and the env var `CLAUDE_CODE_USE_VERTEX`, which confirms the old API surface is still live — [Claude Code on Agent Platform docs](https://code.claude.com/docs/en/google-vertex-ai.md)
- Google Developer Program FAQ now calls the training platform "Google Skills" at skills.google and does not mention "Cloud Skills Boost" — [Google Developer Program Benefits FAQ](https://developers.google.com/profile/help/benefits)
- Lab content may still use older product names (e.g. "AI Applications was previously named Agent Builder") — [gend.co Google Skills explainer](https://www.gend.co/blog/google-skills)

**Google Skills (formerly Cloud Skills Boost) learning paths — real sandbox labs**
- "Advanced: Generative AI for Developers" — https://www.cloudskillsboost.google/paths/183 — for app developers, ML engineers, data scientists; 12 activities; topics include semantic search, RAG, MLOps for GenAI; recommends the "Introduction to Generative AI" path first; page says last updated "about 1 year" ago (so roughly late 2025; listing dated 2025-09-30 by one source) — [Google Skills path 183](https://www.skills.google/paths/183); [search summary](https://www.cloudskillsboost.google/paths/183)
- "Build and Modernize Applications With Generative AI" — https://www.skills.google/paths/1282 — for application developers; course on building apps with prompt design and RAG; lab with Gemini + Streamlit; **one course in the path is marked deprecated** — [Google Skills path 1282](https://www.skills.google/paths/1282)
- "Integrate Generative AI Into Your Data Workflow" — https://www.skills.google/paths/1281 — [Google Skills path 1281](https://www.skills.google/paths/1281)
- "Beginner: Introduction to Generative AI" — https://www.skills.google/paths/118 — conceptual overview (LLMs, responsible AI) — [Google Skills path 118](https://www.skills.google/paths/118)
- "Generative AI Leader Certification" path — https://www.skills.google/paths/1951 — [Google Skills path 1951](https://www.skills.google/paths/1951)
- "Professional Agentic Architect Certification" path — https://www.skills.google/paths/4525 — 12 activities; updated "11 days" ago (≈ late Oct 2026); activity list not visible without login — [Google Skills path 4525](https://www.skills.google/paths/4525)
- Document AI skill badges (directly relevant to OCR/claims work): "Automate Data Capture at Scale with Document AI" (introductory badge: extract, process, capture data) and "Build Custom Processors with Document AI" (custom extractors and classifiers) — [Google Skills public profile listing](https://www.skills.google/public_profiles/1d70d939-cbba-4227-a6e7-9e3a69cfc0af) (badge descriptions via search; catalog page not verified)
- Community view: Google Skills labs "pop you into a 'real' but sandboxed environment" (Reddit snapshot, March 2026) — [r/googlecloud snapshot](https://reddit.sentinel-team.org/posts/1s17geo/snapshots/2026-03-23T16%3A58%3A51.57144Z); another reviewer: labs run in real GCP projects, but it is "a lab platform, not a course" (lacks a structured curriculum) — [course-careers review](https://course-careers-edge.pages.dev/best-courses/best-google-cloud-courses-online-2026) (SEO-style site, low confidence)
- "Google Cloud Fundamentals: Core Infrastructure" on Skills is the commonly suggested free starting course — [course-careers beginners guide](https://course-careers-edge.pages.dev/beginners/google-cloud-for-beginners-where-to-start-in-2026) (low confidence source)
- Platform notice on path pages (Nov 2026): intermittent issues with Gemini Enterprise labs and ~20 min downtime on Nov 8, 2026 — [Google Skills path 183](https://www.skills.google/paths/183)

**Google Skills cost / credits**
- Google Developer Program standard (free) tier: 35 Google Skills learning credits per month — [Developer Program FAQ](https://developers.google.com/profile/help/benefits); also stated on [skills.google/subscriptions](https://skills.google/subscriptions)
- Legacy Premium ($299/year): unlimited Google Skills, 1 certification voucher/year, consultations, $50 GenAI credit, $500 Cloud credit bonus after passing a cert with the Premium voucher. Personal (@gmail) standalone Premium is being folded into Google AI Pro/Ultra: auto-renew ends March 30, 2026 (annual) and June 30, 2026 (monthly). AI Pro/Ultra give monthly Cloud credits ($10 Pro; $40/$100 for Ultra tiers) but **not** unlimited Google Skills, vouchers or consultations — [Developer Program FAQ](https://developers.google.com/profile/help/benefits); [YourStory, Jan 2026](https://yourstory.com/ai-story/google-developer-program-premium-ai-pro-ultra-27-jan-2026)
- Price conflict: old Skills Boost subscription page shows $29/month and $299/year; a Google Developer Program page shows a $45/user/month Premium with 100 monthly credits; the plans page also shows $24.99/month in another snapshot — [cloudskillsboost.google/subscriptions](https://cloudskillsboost.google/subscriptions); [Developer Program Plans & Pricing](https://developers.google.com/program/plans-and-pricing). **Unresolved conflict** — check live page.
- A Digital Trends item says "Skills now require a Google AI Pro or Ultra subscription" — [Digital Trends](https://www.digitaltrends.com/?p=6011155). This most likely refers to a Gemini app feature called "Skills", not the skills.google training site (my inference; not verified).

**Google Skills Arcade (gamified free labs)**
- 1 Arcade Point per completed Arcade game; 1 point per two skill badges; points expire each season; must subscribe on the Arcade page to claim swag; forum users report swag delivery delays (2025 swags still pending in 2026) — [discuss.google.dev Arcade 2026 prize counter](https://discuss.google.dev/t/google-skills-arcade-2026-prize-counter-update/347189?page=4); [Coming Soon: Arcade 2026 Tiers](https://discuss.google.dev/t/coming-soon-google-skills-arcade-2026-tiers/367503)

**Cloud Run AI cookbook (official, long, hands-on, current)**
- URL: https://docs.cloud.google.com/run/docs/ai/cookbook — 77 entries dated 2024-10 to 2026-08-17 (codelabs, blogs, videos). Includes: "Deploy a RAG agent in Streamlit with Google ADK" (2026-08-12), "Build and deploy AI agents with Gemma 4 and BigQuery MCP server" (2026-08-17), "Safely run AI-generated code in Cloud Run sandboxes" (2026-07-09), "From vibe checks to data-driven agent evaluation" (2026-07-09), "A guide to AI cold starts on Cloud Run" (2026-05-28), "Governing agentic workloads with Agent Gateway" (2026-05-28), "Secure agent with Model Armor and Identity" (2026-04-16), "Event-driven AI agents with Eventarc and ADK" (2026-04-22), "Gemma 4 inference on RTX Pro 6000 GPU with vLLM" (2026-04-13), "Deploy LangChain agent on Cloud Run" (2026-03-27), "LLM inference on Cloud Run GPUs with vLLM" (2025-11-13), "Deploy, manage, and observe an ADK agent" (2025-11-12), "Prototype to production: ADK agent with GPU" (2025-10-03), "RAG infrastructure with Vertex AI and Vector Search" (2025-03-07), "FastAPI chatbot with Gemini" (2025-04-02). **No entry covers document processing, Cloud Tasks, or Claude** — [Cloud Run AI cookbook](https://docs.cloud.google.com/run/docs/ai/cookbook)
- Cloud Next '26 talk write-up "The ultimate Cloud Run guide 2026" for experienced devs new to the platform (dedicated service account per service, avoid hard-coded API keys) — [dev.to/googleai](https://dev.to/googleai/the-ultimate-cloud-run-guide-2026-54f8)
- "Getting started with Gemini 3: deploy your first Gemini 3 app to Cloud Run" (Jan 2026, Google Cloud blog) — [Google Cloud blog](https://cloud.google.com/blog/topics/developers-practitioners/getting-started-with-gemini-3-deploy-your-first-gemini-3-app-to-google-cloud-run)

**Kaggle x Google intensives (free, long-form, whitepapers + codelabs)**
- "5-Day AI Agents Intensive": each day = whitepapers + podcast + Kaggle notebook codelabs + livestream. First run Nov 2025 (1.5M+ learners). Second run "Vibe Coding" edition June 15-19, 2026 with production deployment content and a capstone; now available free as a self-paced Kaggle "Learn Guide" — [Google blog recap](https://blog.google/innovation-and-ai/technology/developers-tools/ai-agents-intensive-recap/?linkId=37787671); [EdTech Innovation Hub](https://edtechinnovationhub.com/news/google-brings-back-its-free-ai-agents-course-after-reaching-15-million-learners-this-time-with-vibe-coding); [KDnuggets](https://www.kdnuggets.com/kaggle-googles-free-5-day-agentic-ai-course); [letsdatascience: self-paced](https://letsdatascience.com/news/kaggle-offers-vibe-coding-learning-resources-f4ae7c6e). Competition URL per community listing: kaggle.com/competitions/5-day-ai-agents-intensive-vibecoding-course-with-google — [globalai.community](https://globalai.community/e/asdzvyj2)
- Earlier "5-Day Gen AI Intensive" (whitepapers on foundation models, prompting, embeddings/vector stores, agents, MLOps) — [KDnuggets](https://www.kdnuggets.com/kaggle-googles-free-5-day-gen-ai-course)

**Workshop repos**
- Agent Starter Pack (GoogleCloudPlatform/agent-starter-pack): production-ready GenAI agent templates with infra, CI/CD, observability and security; ADK templates (ReAct base, A2A, agentic RAG, Live multimodal); `uvx agent-starter-pack create`; PyPI v0.40.0 seen; points to GoogleCloudPlatform/generative-ai for notebooks and to ADK samples — [GitHub](https://github.com/GoogleCloudPlatform/agent-starter-pack); [PyPI](https://pypi.org/project/agent-starter-pack/); [Why starter pack](https://googlecloudplatform.github.io/agent-starter-pack/guide/why_starter_pack.html)

**Coursera (Google Cloud as provider)**
- "Preparing for Google Cloud Certification: Machine Learning Engineer Professional Certificate" — ~66,783 enrolled (63,647 on another locale); included with Coursera Plus ($239/year, or $199 promo on one listing) — [Coursera](https://www.coursera.org/professional-certificates/preparing-for-google-cloud-machine-learning-engineer-professional-certificate)
- "Professional Cloud Architect Part 2: AI, Security, & Ops Specialization" (9-course series) — [Coursera](https://www.coursera.org/specializations/professional-cloud-architect-part-2-ai-security-ops)
- "Preparing for Google Cloud Certification: Cloud Engineer" specialization — [Coursera](https://www.coursera.org/specializations/preparing-google-cloud-certification-cloud-engineer)
- No current 2026 Coursera "Cloud Developer" certificate found; only an undated older blog naming "Developing Applications with Google Cloud Platform Specialization" — [Coursera blog](https://blog.coursera.org/ready-skills-cloud-first-world-google)

**Books**
- *GenAI on Google Cloud: Enterprise Generative AI Systems and Agents* — Ayo Adedeji, Lavi Nigam, Sarita Joshi, Stephanie Gervasi (O'Reilly). O'Reilly dates it Jan 2026; Amazon lists 1st ed. March 3, 2026, 317 pages (other listings 250-320). Chapters found: 1 "The Challenge of Generative AI Application Development", 3 "Building a Multimodal Agent with the Agent Development Kit (ADK)", 5 "Evaluation and Optimization Strategies", 7 "MLOps for Production-Ready AI and Agentic Systems" (nine pillars of AgentOps), 8 "The AI and Agentic Maturity Framework"; ch. 2/4/6 cover data prep, agent orchestration, model/infra optimization. Goal: prototype → production — [O'Reilly ch.7](https://www.oreilly.com/library/view/genai-on-google/9798341623842/ch07.html); [Amazon](https://www.amazon.com/GenAI-Google-Cloud-Enterprise-Generative/dp/B0FQB581SF); [Google Research pub page](https://research.google/pubs/genai-on-google-cloud-enterprise-generative-ai-systems-and-ai-agents/)
- *Generative AI on Google Cloud with LangChain* — Leonid Kuligin, Jorge Zaldívar, Maximilian Tschochohei, released Dec 2024 (Packt-style title on O'Reilly) — [O'Reilly preface](https://www.oreilly.com/library/view/generative-ai-on/9781835889329/B22439_Preface_Ebook.xhtml)
- *Generative AI on Google Cloud* (O'Reilly, ISBN 9781098159016; ch.2 "Generative AI Offerings with Vertex AI") — authors/final date not confirmed — [O'Reilly ch.2](https://www.oreilly.com/library/view/generative-ai-on/9781098159016/ch02.html)
- *Visualizing Google Cloud: 101 Illustrated References for Cloud Engineers and Architects* — Priyanka Vergadia, Wiley, April 2022, 256 pp — [O'Reilly](https://www.oreilly.com/library/view/-/9781119816324/); [i-programmer](https://i-programmer.info/book-watch-archive/15410-visualizing-google-cloud-wiley.html)
- *Data Science on the Google Cloud Platform, 2nd ed.* — Valliappa (Lak) Lakshmanan, O'Reilly, April 2022, ~446-462 pp — [O'Reilly](https://www.oreilly.com/library/view/data-science-on/9781098118945/preface01.html); [Schweitzer](https://www.schweitzer-online.de/en/buch/Lakshmanan/Data-Science-Google-Cloud-Platform/9781098118952/A63457513/)

**Udemy / Pluralsight / freeCodeCamp**
- Udemy GCP courses are mostly cert-prep (e.g. "Google Cloud ACE + GCP Networks 2-in-1 bundle 2026", 4.5★, 93 ratings, ~2,657 students); Pluralsight best for employer-paid licenses; "GCP is notoriously difficult to learn from video alone" — [course-careers](https://course-careers-edge.pages.dev/best-courses/best-google-cloud-courses-online-2026) (low-confidence SEO site)
- Many Udemy "Agentic Architect" practice-exam courses appeared in 2026 — [Udemy example](https://www.udemy.com/course/google-cloud-professional-agentic-architect-practice-exams-a/)
- Search found **no current freeCodeCamp GCP full course** with Gemini/Agent Platform content — (negative result; see Gaps)

**Vietnamese-language**
- #QuanQuanGCP Season 7 "Google Cloud AI Study Jam" for developers in Vietnam, Sep 18 - Oct 19, 2025, self-paced labs, skill badges, Slack community; registration closed — [Google Cloud events page](https://cloud.google.com/events/google-cloud-study-jam-season-7/quanquangpc?hl=de)
- GDG Cloud Hanoi / Da Nang / HCM ran Vietnamese Cloud Study Jams (2019, 2021) — [GDG event](https://gdg.community.dev/events/details/google-gdg-cloud-hanoi-presents-online-cloud-study-jams-vietnam-2019-8/)
- Vietnamese explainer "Google Skills là gì, ai nên sử dụng, sử dụng thế nào" on VnReview — [VnReview](https://vnreview.vn/threads/google-skills-la-gi-ai-nen-su-dung-su-dung-the-nao.81607/latest)

### Inferences

**Ranked list for this learner (strong Python/K8s/RAG, zero GCP, building OCR + claims search on Cloud Run/Tasks/Firestore/BigQuery/GCS/Document AI/Gemini/Claude)**

| Rank | Program | URL | Provider | Format | Length | Cost | Last updated | Labs | Cert tie-in | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Cloud Run AI cookbook (pick ~15 entries) | https://docs.cloud.google.com/run/docs/ai/cookbook | Google | Codelabs/blogs/videos | 77 entries (each codelab ~30-90 min, unverified) | Free (you pay own GCP usage) | Newest 2026-08-17 | Your own project | None directly (Agentic Architect overlap) | Best fit: current, Cloud Run-centric, ADK/MCP/RAG/vLLM/GPU, production topics (cold starts, Model Armor, eval) |
| 2 | Document AI skill badges (2) | skills.google catalog | Google Skills | Courses + graded challenge labs | not verified (typically a few hours each) | Credits (free 35/month may cover part) | not verified | Yes, sandbox | Skill badge | Must-do: closest to Pacific Cross OCR work |
| 3 | Kaggle 5-Day AI Agents Intensive (self-paced) | kaggle.com (Learn Guide) | Google + Kaggle | Whitepapers + notebooks + livestreams + capstone | 5 days, est. 15-25 h (unverified) | Free | June 2026 edition | Kaggle notebooks, not GCP sandbox | None | Strong for agent concepts, eval, deployment; ADK/Gemini-centric |
| 4 | GenAI on Google Cloud (book) | https://www.oreilly.com/library/view/genai-on-google/9798341623842/ | O'Reilly; Google authors | Book | ~317 pp | Book price (~$50-70, unverified) or O'Reilly sub | Jan/Mar 2026 | No | Helps Agentic Architect | Best book: ADK, eval, AgentOps; written just before the April rename so names say "Vertex" |
| 5 | Agent Starter Pack repo | https://github.com/GoogleCloudPlatform/agent-starter-pack | Google | Templates + CLI | n/a | Free | active (v0.40.0) | Your own project | Agentic Architect | Use as "reference production layout" (Terraform, CI/CD, observability) |
| 6 | Advanced: Generative AI for Developers | https://www.skills.google/paths/183 | Google Skills | Path, 12 activities | not verified (likely 20-40 h) | Credits or subscription | ~late 2025 | Yes | None/Agentic | Good for RAG/semantic search labs; partly pre-rename; check deprecated items |
| 7 | Professional Agentic Architect path | https://www.skills.google/paths/4525 | Google Skills | Path, 12 activities | not verified | Credits/sub | ~Oct 2026 | Yes | Agentic Architect | Most current official path for agents; take after weeks 1-6 |
| 8 | Google Cloud Fundamentals: Core Infrastructure | skills.google | Google Skills | Course + labs | not verified (~8-10 h historically, unverified) | Free per reviews | not verified | Yes | ACE/PCD foundation | Only "breadth" course worth doing; IAM, projects, networking basics |
| 9 | Generative AI on Google Cloud with LangChain | O'Reilly/Packt | Kuligin et al. | Book | not verified | Book price | Dec 2024 | No | None | Good bridge for a LangChain/LangGraph engineer; pre-2026 APIs/names |
| 10 | Coursera PMLE / PCA Part 2 | coursera.org | Google Cloud | Video + Qwiklabs-style labs (historically) | multi-course | Coursera Plus $199-239/yr | not verified | Partly (historically) | PMLE / PCA | Redundant: same content as Google Skills, slower, classic-ML heavy |
| 11 | Visualizing Google Cloud | Wiley | Priyanka Vergadia | Illustrated book | 256 pp | Book price | Apr 2022 | No | PCA | Nice visual map of services for weak-English learners; outdated for GenAI |
| 12 | Data Science on GCP 2e | O'Reilly | Lak Lakshmanan | Book | ~459 pp | Book price | Apr 2022 | No | PDE/PMLE | Outdated for GenAI; only BigQuery/data chapters still useful |
| — | Udemy cert-prep, Pluralsight/A Cloud Guru, freeCodeCamp GCP videos | various | various | Video | long | $ | mostly pre-2026 | Few/no real labs | ACE/PCA | Skip for this learner: breadth for exam, not AI product depth |

- Google Skills paths are "lab platforms" more than curricula; the learner should cherry-pick labs/skill badges matching the Pacific Cross stack instead of finishing whole paths.
- Anything published before April 2026 will use "Vertex AI" names; the APIs (`aiplatform.googleapis.com`) still work, so the learner should learn both names.
- The Generative AI Leader path and "Beginner: Introduction to GenAI" are shallow (conceptual) for a 3-year AI engineer.

### Gaps
- Exact hours, credit costs and per-lab lists for Google Skills paths 183, 1282, 4525 and the Document AI badges could not be read (login wall).
- Current Google Skills subscription price is unresolved ($29 vs $45 vs $24.99/month in different Google pages).
- No community ratings found for Google Skills paths, the Cloud Run cookbook, or *GenAI on Google Cloud*.
- A Cloud Guru/Pluralsight GCP AI paths, specific Udemy best-sellers (e.g. in28minutes/Ranga Karanam, Dan Sullivan courses — unverified, from memory), and freeCodeCamp GCP videos were not verified; freeCodeCamp's known GCP videos (e.g. ACE prep) are from ~2021-2022 per my prior knowledge (unverified) and pre-date GenAI.
- No high-quality *current* Vietnamese-language long-form GCP AI course was found; only Study Jam events (latest Sep-Oct 2025) and a VnReview explainer.
- Could not confirm whether Google "Innovators"/"Innovators Plus" still exists as a separate brand; it appears replaced by the Google Developer Program tiers (inference).

---

## 2. Which certification tracks are worth it for production AI work vs redundant?

### Takeaway
For this learner, the new **Professional Agentic Architect** (GA mid-November 2026, includes real hands-on labs) is the most aligned with AI-product work, followed by **Professional Cloud Developer** (Cloud Run/serverless app focus). Professional ML Engineer is partly redundant (classic ML/MLOps heavy), Professional Cloud Architect is useful mainly for interview-style case-study thinking, Associate Cloud Engineer is optional foundations, and Generative AI Leader is non-technical.

### Cited Findings
- **Professional Agentic Architect**: professional-level; for developers, cloud architects, engineers. Two parts, both must pass: (1) proctored multiple-choice exam (Pearson), (2) hands-on labs on Google Skills in a live cloud environment. Beta: register Sep 3-30, 2026, $120 (40% off); GA mid-November 2026 at $200; GA exam 2 hours; GA labs have a 2-month completion window. Assesses: building agents with low-code tools, using coding agents for app development, developing custom agents, evaluating and deploying agentic workflows, securing and governing them. Recommended: 3+ years cloud experience incl. 1+ year building agentic solutions on Google Cloud. Prep: path skills.google/paths/4525, exam page cloud.google.com/learn/certification/agentic-architect — [Google Cloud Certification Help FAQ](https://support.google.com/cloud-certification/answer/18080541?hl=en)
- Third-party guides list ADK, Agent Runtime, Agents CLI, Antigravity, Gemini Enterprise, Skill Registry and agent evaluation tools; ~33% weight on custom agent development (unverified) — [Whizlabs](https://www.whizlabs.com/blog/gcp-agentic-architect-exam-guide/); [CertCrush](https://www.certcrush.app/blog/google-cloud-agentic-architect-exam-guide-beta-2026)
- **Professional Cloud Developer**: not retired; exam guide updated (one tracker: version dated Sep 14, 2026; official pages updated Oct 6, 2026 for branding changes); 2 hours, 50-60 multiple-choice/multiple-select — [DirectCertify](https://www.directcertify.com/blog/google-cloud-certification-changes-2026-pearson-vue-and-ai-exam-overhaul/); [CertifyCloudx tracker](https://www.certifycloudx.com/exam-updates)
- **PMLE, PCA, PCD** exam pages all updated Oct 6, 2026 for branding (Agent Platform rename) — [DirectCertify](https://www.directcertify.com/blog/google-cloud-certification-changes-2026-pearson-vue-and-ai-exam-overhaul/); [dailydebian](https://dailydebian.com/blogs/it-certification-news/google-professional-exams-gemini-enterprise-agent-platform-update)
- All exams moved from Kryterion to Pearson VUE (dates conflict: Feb 22 vs Mar 2, 2026); content unchanged — [DirectCertify](https://www.directcertify.com/blog/google-cloud-certification-changes-2026-pearson-vue-and-ai-exam-overhaul/)
- July 2026: PCA, PDE, ACE and Cloud Digital Leader holders can renew by completing courses or skill badges; other certs (incl. PCD, PMLE) still need a renewal exam — [DirectCertify](https://www.directcertify.com/blog/google-cloud-certification-changes-2026-pearson-vue-and-ai-exam-overhaul/)
- **Professional Cloud Architect**: new exam released Oct 30, 2025; uses four case studies — Altostrat Media, Cymbal Retail (GenAI digital commerce), EHR Healthcare (carried over), KnightMotives Automotive; exam guide v6.1 — [gcpstudyhub](https://gcpstudyhub.com/blog/guide-to-the-new-professional-cloud-architect-exam-released-october-30th-2025); [PCA exam guide v6.1 PDF](https://services.google.com/fh/files/misc/v6.1_pca_professional_cloud_architect_exam_guide_english.pdf)
- **Generative AI Leader**: conceptual, aimed at non-engineers (one source says launched 2026; my prior knowledge says 2025 — conflict) — [careery.pro](https://careery.pro/blog/ai-careers/google-ai-certification-guide); [howtoai](https://howtoai.com/agentic-ai-certification/)
- **PMLE** Coursera prep certificate exists (~66k learners) — [Coursera](https://www.coursera.org/professional-certificates/preparing-for-google-cloud-machine-learning-engineer-professional-certificate)

### Inferences
- **Professional Agentic Architect — WORTH IT (best fit, but later).** Matches agent/RAG product work, has hands-on labs (proves real skill), and is brand-new (fewer holders = signal). Recommended 1 year of GCP agentic experience, so take it at the end of the 10-12 week plan or after ~3-6 months at Pacific Cross.
- **Professional Cloud Developer — WORTH IT if one classic cert is wanted.** Closest to daily work: Cloud Run, Pub/Sub/Tasks, Firestore, IAM for apps, CI/CD, observability. Multiple choice only.
- **Professional ML Engineer — PARTLY REDUNDANT.** Heavy on training pipelines, feature stores, classic MLOps; useful only if the learner will fine-tune/train models on GCP. Renewal needs an exam.
- **Professional Cloud Architect — STUDY THE CASE STUDIES, cert optional.** Case studies are excellent interview practice ("design for EHR Healthcare / Cymbal Retail"). Breadth (networking, hybrid, migration) is beyond AI-product needs.
- **Associate Cloud Engineer — OPTIONAL.** Good forcing function for gcloud/IAM/projects in weeks 1-3, but an experienced K8s engineer can learn this from labs without the exam.
- **Generative AI Leader — SKIP.** Non-technical.

### Gaps
- Official Agentic Architect exam guide PDF domain weights not read.
- Exact current PCD exam guide topics (post-rename) not read.

---

## 3. Free tier, $300 trial, sandboxes, and cost-safe practice setup

### Takeaway
Use Google Skills labs for "throw-away" sandboxes (no billing risk) and one personal project for building. The $300/90-day trial **cannot** pay for partner models (so Claude on Vertex/Agent Platform needs a paid billing account) and blocks GPUs and quota increases. The Always Free tier covers small Cloud Run/Firestore/BigQuery/GCS/Cloud Build use, but not Document AI or Gemini/Agent Platform.

### Cited Findings
- $300 trial: 90 days, cannot be paused/extended; only for users never paying for Google Cloud/Maps/Firebase; payment method required ($0-1 temporary hold). During trial: **no GPUs on VMs, no Marketplace, no quota increases**, no Windows Server VMs; **credit cannot pay for Gemini API in AI Studio or model-as-a-service generative AI partner models**. Upgrade to paid ends the trial but remaining credit still usable in the 90 days. If trial ends without upgrade: billing disabled, resources stopped, 30-day grace, then deleted — [Google Cloud free program docs](https://docs.cloud.google.com/free/docs/free-cloud-features)
- Always Free (per billing account, monthly): Cloud Run 2M requests, 360,000 GB-s memory, 180,000 vCPU-s, 1 GB egress (NA); Cloud Run functions 2M invocations; Firestore 1 GiB storage, 50k reads/20k writes/20k deletes per day; BigQuery 1 TiB query + 10 GiB storage; Cloud Storage 5 GB-months (us-east1/us-west1/us-central1 only); Cloud Build 2,500 build-min (e2-standard-2); Pub/Sub 10 GiB; Secret Manager 6 active versions/10k accesses; Artifact Registry 0.5 GB; Cloud Logging 50 GiB/project. **No free usage listed for Document AI or Vertex/Agent Platform** — [Google Cloud free program docs](https://docs.cloud.google.com/free/docs/free-cloud-features)
- AI Pro/Ultra subscribers get monthly Google Cloud credits ($10 / $40 / $100 tiers) — [Developer Program FAQ](https://developers.google.com/profile/help/benefits)
- Anthropic recommends "a dedicated GCP project for Claude Code to simplify cost tracking and access control" — [Claude Code on Agent Platform](https://code.claude.com/docs/en/google-vertex-ai.md)
- Claude Code warns: if no primary model is pinned you are billed at the Opus rate; pin `ANTHROPIC_MODEL` to a Sonnet ID to save money — [Claude Code on Agent Platform](https://code.claude.com/docs/en/google-vertex-ai.md)
- Google Skills labs run in sandboxed real GCP projects (no personal billing) — [r/googlecloud snapshot](https://reddit.sentinel-team.org/posts/1s17geo/snapshots/2026-03-23T16%3A58%3A51.57144Z)

### Inferences
- Cost-safe recipe (standard practice; individual steps not each verified in this session):
  1. One billing account → **one project per lab/project** (e.g. `pcv-lab-ocr-01`), labels `owner=me,lab=ocr01`; delete the whole project when done (`gcloud projects delete`), which removes everything at once.
  2. Budget with alerts at 50/90/100% (Cloud Billing budgets). Optionally a Pub/Sub budget notification → Cloud Run function that detaches billing (Google documents this "cap" pattern; unverified here).
  3. Use `us-central1` for Free Tier GCS; set `--max-instances` and `--min-instances=0` on Cloud Run; set BigQuery per-user/project query quotas or `maximum_bytes_billed`.
  4. Use Gemini Flash-class models and Claude Sonnet/Haiku for practice; pin models; use small test documents for Document AI (it is per-page billed).
  5. Because trial credit can't pay for Claude (partner model), the learner should practice Claude calls on the Pacific Cross dev project (with permission) or upgrade the personal account to paid and keep a tight budget.

### Gaps
- Exact Document AI and Agent Platform per-unit prices were not fetched (pricing pages not read in this session).
- Did not verify the official "disable billing with budget notifications" doc URL.

---

## 4. Using Claude Code with GCP for practice (Vertex/Agent Platform, MCP servers, safety)

### Takeaway
Claude Code runs natively on Google Cloud's Agent Platform (formerly Vertex AI) via a login wizard or env vars, needs only `roles/aiplatform.user`, and can be connected to Google's **official remote MCP servers** (gcloud CLI, BigQuery, Cloud Run, Agent Platform models; all need `roles/mcp.toolUser`), the open-source **MCP Toolbox for Databases** (Firestore, BigQuery, Cloud SQL, AlloyDB, Spanner), and the **Cloud Run MCP** repo. Google's own security guidance: least privilege, a separate agent identity, Model Armor. No long official "Claude Code + Google Cloud" series exists; only scattered Medium/dev.to posts.

### Cited Findings

**Claude Code on Agent Platform (official Anthropic docs, current)**
- Page title now "Claude Code on Google Cloud's Agent Platform" (formerly Vertex AI). Prereqs: billing-enabled project, Agent Platform API (`gcloud services enable aiplatform.googleapis.com`), Claude model access requested in Model Garden (may take 24-48 h), gcloud, regional quota — [Claude Code docs](https://code.claude.com/docs/en/google-vertex-ai.md)
- Wizard: run `claude` → "3rd-party platform" → "Google Vertex AI"; choose ADC / service account key / env credentials; wizard verifies models and writes to `~/.claude/settings.json` `env`; `/setup-vertex` reopens it — [Claude Code docs](https://code.claude.com/docs/en/google-vertex-ai.md)
- Manual env vars: `CLAUDE_CODE_USE_VERTEX=1`, `CLOUD_ML_REGION=global` (or `us`/`eu`/`us-east5`), `ANTHROPIC_VERTEX_PROJECT_ID`, optional `ANTHROPIC_VERTEX_BASE_URL`, per-model `VERTEX_REGION_CLAUDE_*`; pin with `ANTHROPIC_DEFAULT_OPUS_MODEL`, `ANTHROPIC_DEFAULT_SONNET_MODEL`, `ANTHROPIC_DEFAULT_HAIKU_MODEL`, or `ANTHROPIC_MODEL`; `gcpAuthRefresh` setting can run `gcloud auth application-default login` when creds expire; prompt caching on by default (`DISABLE_PROMPT_CACHING=1`, `ENABLE_PROMPT_CACHING_1H=1`); verify with `/status` — [Claude Code docs](https://code.claude.com/docs/en/google-vertex-ai.md)
- IAM: `roles/aiplatform.user` (needs `aiplatform.endpoints.predict`); dedicated project recommended; troubleshooting for "Could not load the default credentials", 404 model not found (region/global support), 429 (switch to global) — [Claude Code docs](https://code.claude.com/docs/en/google-vertex-ai.md)
- `ANTHROPIC_VERTEX_PROJECT_ID` overrides `GOOGLE_CLOUD_PROJECT`/credential-file project — [Claude Code docs](https://code.claude.com/docs/en/google-vertex-ai.md)

**Google official remote MCP servers**
- General: Streamable HTTP; auth via ADC, OAuth client, or bearer token; use toolset endpoints to reduce tools; enable the service first. Roles: `roles/mcp.toolUser` (permission `mcp.tools.call`), `roles/serviceusage.serviceUsageAdmin` to enable APIs, plus resource roles. Claude setup: create an OAuth "Web application" client with redirect URI `https://claude.ai/api/mcp/auth_callback`, then add a custom connector with client ID/secret. Endpoints shown: BigQuery `https://bigquery.googleapis.com/mcp`, Cloud Run `https://run.googleapis.com/mcp`, Agent Platform models toolset `https://aiplatform.googleapis.com/mcp/models` — [Configure MCP in an AI application](https://docs.cloud.google.com/mcp/configure-mcp-ai-application)
- Security guidance: use a separate identity (not your own user) for production; IAM only governs Google Cloud MCP servers; protect client secrets; ADC tokens expire about hourly; Model Armor regional endpoints for residency — [Configure MCP in an AI application](https://docs.cloud.google.com/mcp/configure-mcp-ai-application)
- **gcloud CLI remote MCP server** (Preview): endpoint `https://cloudcli.googleapis.com/mcp`; enabled via Cloud CLI Execution API; tools `run_gcloud_command`, `run_bq_command`; blocks `gcloud auth`, `config`, `iam service-accounts`, `init`, `survey`, all alpha/beta, and `bq init/pyshell/shell`; needs `roles/mcp.toolUser`; OAuth `cloud-platform` scope, no API keys; advice: least privilege, separate agent identity, set `project` parameter correctly, consider Model Armor floor settings, logs may expose sensitive data — [Use the gcloud remote MCP server](https://docs.cloud.google.com/sdk/use-gcloud-mcp); [Google Cloud blog announcement](https://cloud.google.com/blog/products/ai-machine-learning/google-cloud-cli-remote-mcp-server-in-preview)
- **BigQuery remote MCP**: tools incl. `list_dataset_ids`, `get_dataset_info`, `execute_sql_readonly`, `execute_sql`; preview as of Jan 2026 (status conflicts across sources) — [BigQuery MCP reference](https://docs.cloud.google.com/bigquery/docs/reference/mcp); [Google Cloud blog](https://cloud.google.com/blog/products/data-analytics/using-the-fully-managed-remote-bigquery-mcp-server-to-build-data-ai-agents)
- **Cloud Run remote MCP**: enabled with Cloud Run Admin API; OAuth + IAM; no API keys — [Use the Cloud Run remote MCP server](https://docs.cloud.google.com/run/docs/use-cloud-run-mcp)

**Open-source MCP servers**
- **MCP Toolbox for Databases** (repo renamed genai-toolbox → mcp-toolbox): AlloyDB, BigQuery, Cloud SQL (PG/MySQL/SQL Server), Spanner, Firestore, Dataplex; works with Claude Code, Gemini CLI, Antigravity, Codex; prebuilt tools like `list_tables`, `execute_sql`; install `npx @toolbox-sdk/server --config tools.yaml`, `brew install mcp-toolbox`, Docker; versions seen v0.31.0 and v1.0.0 (unconfirmed) — [MCP Toolbox docs](https://googleapis.github.io/genai-toolbox/documentation/introduction); [pkg.go.dev](https://pkg.go.dev/github.com/googleapis/mcp-toolbox)
- **Cloud Run MCP** (GoogleCloudPlatform/cloud-run-mcp): tools `deploy`, `deploy-file-contents`, plus `list-services`, `get-service`; config `npx -y @google-cloud/cloud-run-mcp`; if run remotely on Cloud Run it can only deploy to its own project — [GitHub](https://github.com/GoogleCloudPlatform/cloud-run-mcp); [playbooks.com](https://playbooks.com/mcp/google-cloud-run)

**Tutorials (no long series found)**
- "How Google Cloud MCPs Give Claude Code Inside Access" (Google Cloud Community Medium, ~Aug 2026): ADC + `claude mcp add-json` with a dynamic token helper (page blocked 403; details from search snippet) — [Medium](https://medium.com/google-cloud/how-google-cloud-mcps-give-claude-code-inside-access-8504abf8122a)
- "MCP Configuration for Google Workspace with Claude Code" — [Medium](https://medium.com/google-cloud/mcp-configuration-for-google-workspace-with-claude-code-87b91d6e6d2e)
- "Run Claude Code on Google Cloud: use your GCP credits" (dev.to, ~early 2026) — [dev.to](https://dev.to/timtech4u/run-claude-code-on-google-cloud-use-your-gcp-credits-for-ai-coding-desktop-control-and-more-2151)
- "Building with the Google Cloud Run MCP server for multi-agent A2A deployment" (GDE) — [dev.to/gde](https://dev.to/gde/building-with-the-google-cloud-run-mcp-server-for-multi-agent-a2a-deployment-fop)
- Cloud Run cookbook security items: "Safely run AI-generated code in Cloud Run sandboxes" (2026-07-09), "Securing AI agents with MCP Authorization" (2026-05-26), "Chain of Trust: securing MCP Toolbox architecture" (2025-09-03) — [Cloud Run AI cookbook](https://docs.cloud.google.com/run/docs/ai/cookbook)

### Inferences
- **Safe "AI pair-programmer on GCP" setup** (synthesis of the cited guidance):
  1. Separate sandbox project (e.g. `<name>-claude-sandbox`) with its own budget; never point Claude Code at the Pacific Cross prod project.
  2. Two identities: (a) Claude Code's *model* calls use your ADC with only `roles/aiplatform.user` on a "model" project; (b) *infrastructure* actions run as a dedicated service account (impersonated with `--impersonate-service-account`) holding only needed roles (e.g. `roles/run.developer`, `roles/storage.objectAdmin` on one bucket, `roles/datastore.user`) — no Owner/Editor.
  3. Claude Code permissions: allow read-only commands (`gcloud ... describe/list`, `terraform plan`, `bq query --dry_run`), require approval for `deploy`, `apply`, `delete`; deny `gcloud projects delete`, `gcloud iam`, `gcloud auth`. (The gcloud remote MCP already blocks auth/config/iam service-accounts.)
  4. IaC first: let Claude write Terraform + run `terraform plan`; a human runs `apply`. Use `--dry-run`/`plan` outputs as review artefacts.
  5. Prefer read-only MCP tools (`execute_sql_readonly`) and toolset endpoints to limit tool surface; enable Model Armor if MCP traffic carries user text.
  6. Pin Sonnet as default model for cost; turn on audit logs and label resources created by the agent.
- Practical approach for the learner: use Claude Code as "explainer + reviewer" (ask it to explain each gcloud flag, IAM role, and error in simple English) rather than letting it run everything — this builds GCP understanding faster.

### Gaps
- No long, multi-part "Claude Code + Google Cloud" blog/video series found; only single posts.
- Could not read the Medium "Inside Access" article body (403).
- No official Anthropic or Google doc on Claude Code + Terraform guardrails specifically for GCP was found.
- Official full list of Google remote MCP "Supported products" and GA/preview status not fetched.

---

## 5. Real-world production question banks, decision guides, case studies, postmortems

### Takeaway
The most realistic, deep material is: Google's Architecture Center "choose" guides (now including agentic AI components and design patterns), the four PCA case studies (Altostrat, Cymbal Retail, EHR Healthcare, KnightMotives), and real Google postmortems (June 12, 2025 Service Control outage). GitHub/Teal/Minova question lists are mostly trivia or generic DevOps; use them only for quick drills.

### Cited Findings
- Architecture Center "Choose agentic AI architecture components" (frontend, agent framework, tools, memory; ADK default, Genkit option; choices affect performance, scalability, cost, security) — [docs.cloud.google.com](https://docs.cloud.google.com/architecture/choose-agentic-ai-architecture-components)
- "Choose a design pattern for your agentic AI system" (single vs multi-agent; sequential, parallel patterns; start single-agent) — [docs.cloud.google.com](https://docs.cloud.google.com/architecture/choose-design-pattern-agentic-ai-system?hl=ru)
- Decision tree for data analytics workloads (ingest → store → process → analyze; July 2023 blog) — [Google Cloud blog](https://cloud.google.com/blog/products/data-analytics/decision-tree-for-data-analytics-workloads-on-google-cloud)
- PCA case studies (official PDFs linked from exam guide v6.1): Altostrat Media, Cymbal Retail (GenAI commerce), EHR Healthcare, KnightMotives Automotive; questions refer to these fictitious businesses — [PCA exam guide v6.1](https://services.google.com/fh/files/misc/v6.1_pca_professional_cloud_architect_exam_guide_english.pdf); [open-exam-prep case study guide](https://open-exam-prep.com/study-guides/gcp-cloud-architect/well-architected-case-studies/case-studies-ehr-cymbal)
- Google Cloud outage June 12, 2025 (10:51-18:18 PT): a policy change with malformed data written to Spanner tables used by Service Control hit an unguarded code path (null pointer) and crashed Service Control; lessons: feature-flag every change, fail open, keep status page independent, use randomized exponential backoff (us-central1 recovery overloaded Spanner) — [Google Cloud Service Health incident](https://status.cloud.google.com/incidents/ow5i3PPK96RduMcb1SsW); [ByteByteGo](https://blog.bytebytego.com/p/how-the-google-cloud-outage-crashed); [ThousandEyes](https://www.thousandeyes.com/blog/google-cloud-outage-analysis-june-12-2025); [Simon Willison](https://feeds.simonwillison.net/2025/Jun/14/google-cloud-outage-incident-report)
- Cloud Run production pitfalls content: "A guide to AI cold starts on Cloud Run" (2026-05-28), "Decoupling model files from containers (Cloud Storage FUSE)" — [Cloud Run AI cookbook](https://docs.cloud.google.com/run/docs/ai/cookbook)
- Question banks: eknatha/interview-prep GCP guide (40 questions: IAM, GKE, VPC, Cloud SQL, SCC, FinOps; flashcards) — [GitHub](https://github.com/eknatha/interview-prep); techikrish/devops-cloud-interview-scenarios (scenario "what would you do?" format; GCP folder unconfirmed) — [GitHub](https://github.com/techikrish/devops-cloud-interview-scenarios); NotHarshhaa/DevOps-Interview-Questions (cloud folder incl. GCP, mock scenarios) — [GitHub](https://github.com/NotHarshhaa/DevOps-Interview-Questions); Minova "Senior Cloud Engineer GCP interview questions" (Nov 2025; e.g. "When would you use Cloud Functions vs Cloud Run?") — [Minova](https://www.minova.ai/blog/interview/senior-cloud-engineer-gcp-interview-questions-complete-guide); Teal GCP engineer questions — [Teal](https://www.tealhq.com/interview-questions/gcp-engineer)

### Inferences
- Realistic interview questions for the Pacific Cross role (built from the above sources + the stack; to practice with Claude Code as interviewer):
  - "Claims PDFs arrive in bursts of 10k. Design upload → OCR → extraction → index with Cloud Run, Cloud Tasks, Document AI. How do you handle Document AI quotas, retries, idempotency, poison messages?" (Cloud Tasks vs Pub/Sub; dedupe keys in Firestore.)
  - "Cloud Run vs GKE vs Cloud Run jobs for OCR post-processing and for a vLLM model?" (cold starts, GPUs, concurrency.)
  - "Gemini returns 429 / Claude regional model not found — what do you check?" (quotas, global vs regional endpoints, fallback chain.)
  - "Firestore vs BigQuery vs Cloud SQL for claim status, audit, analytics?" (hotspots on sequential IDs, transaction limits, cost of BigQuery scans.)
  - "How do you keep PHI/PII safe?" (CMEK, VPC-SC, DLP/Sensitive Data Protection, IAM per service account, Model Armor, audit logs.)
  - "Postmortem drill: a bad config rolled to all regions" (map to June 2025 lessons: flags, staged rollout, backoff with jitter.)
- The PCA case studies are best used as "system design interviews": pick EHR Healthcare (regulated health data — closest to insurance claims) and Cymbal Retail (GenAI) and design each end-to-end.
- Google SRE books (sre.google — free online) are the classic deep source for production questions (from prior knowledge, not verified in this session).

### Gaps
- No high-quality, GCP-specific, AI-product-focused interview question bank was found; most repos are generic DevOps/trivia.
- Architecture Center "Choose a compute option"/"Choose a database" pages and the RAG/document-AI reference architectures were not fetched in this session.
- No Glassdoor-style real interview reports for Pacific Cross or similar insurtech GCP roles were researched.

---

## 6. Notable creators/series for GCP serverless + AI depth (2025-2026)

### Takeaway
In this session I could verify recent *official* channels (Cloud Run AI cookbook, Google Cloud blog developer posts, Google Cloud Community on Medium, GDE posts on dev.to, Kaggle intensives), but I could NOT verify 2026 activity for the named individuals (Martin Omander/Serverless Expeditions, Mete Atamel, Guillaume Laforge, Romin Irani, Lak Lakshmanan, Priyanka Vergadia).

### Cited Findings
- Mete Atamel: Developer Advocate in Google DevRel, London, 18+ years experience (undated profile) — [AsyncAPI ambassadors](https://asyncapi.com/community/ambassadors/meteatamel)
- Guillaume Laforge links his own 2026 blog posts on his feed (no Cloud Run/ADK tutorial confirmed) — [nitter mirror](https://nitter.kareem.one/glaforge)
- Google Cloud Community on Medium has 2026 Claude Code + Google Cloud MCP posts — [Medium Google Cloud](https://medium.com/google-cloud/how-google-cloud-mcps-give-claude-code-inside-access-8504abf8122a); and "Agent development with Gemini CLI" — [Medium](https://medium.com/google-cloud/agent-development-with-gemini-cli-800d2c6f18ed)
- GDE posts: "Deploy a multi-agent ADK application to Google Cloud Run" — [dev.to/gde](https://dev.to/gde/deploy-a-multi-agent-adk-application-to-google-cloud-run-59on)
- Google AI DevRel on dev.to: "The ultimate Cloud Run guide 2026" — [dev.to/googleai](https://dev.to/googleai/the-ultimate-cloud-run-guide-2026-54f8)
- Priyanka Vergadia's *Visualizing Google Cloud* (2022) remains her main long-form work found — [O'Reilly](https://www.oreilly.com/library/view/-/9781119816324/)
- Lak Lakshmanan's *Data Science on GCP 2e* (2022) — [O'Reilly](https://www.oreilly.com/library/view/data-science-on/9781098118945/preface01.html)

### Inferences (unverified, from prior knowledge)
- Martin Omander's "Serverless Expeditions" (Google Cloud Tech YouTube) was the classic Cloud Run series; last confirmed activity unknown for 2026.
- Mete Atamel (atamel.dev) and Guillaume Laforge (glaforge.dev) write deep Gemini/Cloud Run/LangChain4j/ADK posts; Romin Irani publishes long Gemini CLI/ADK tutorial series on the Google Cloud Medium publication; Lak Lakshmanan left Google and writes on Medium about AI engineering; Priyanka Vergadia left Google (moved to another company). All unverified in this session — the report writer should present these as "check before relying".

### Gaps
- Could not verify 2026 posting activity, playlists, or series lengths for Omander, Atamel, Laforge, Irani, Lakshmanan, Vergadia.
- Google Cloud Tech YouTube "GenAI for developers" playlists not verified.

---

## 7. Proposed order (10 weeks core + 2 optional, 8-10 h/week) and 4-6 practice projects built with Claude Code (synthesis)

### Takeaway
Learn GCP through the Pacific Cross stack itself: foundations (IAM/projects/billing) → Cloud Run + CI → storage/events/Tasks → Document AI → Gemini & Claude on Agent Platform → RAG/search → agents + MCP → production ops → architecture/interview practice → optional Agentic Architect or PCD cert. Each week pairs one official resource with one Claude Code-built project milestone in a sandbox project.

### Cited Findings
- Resources used in the plan and their sources: Cloud Run AI cookbook — [docs](https://docs.cloud.google.com/run/docs/ai/cookbook); Document AI skill badges — [Google Skills](https://www.skills.google/public_profiles/1d70d939-cbba-4227-a6e7-9e3a69cfc0af); GenAI for Developers path — [path 183](https://www.skills.google/paths/183); Kaggle AI Agents Intensive — [Google blog](https://blog.google/innovation-and-ai/technology/developers-tools/ai-agents-intensive-recap/?linkId=37787671); Agent Starter Pack — [GitHub](https://github.com/GoogleCloudPlatform/agent-starter-pack); *GenAI on Google Cloud* — [O'Reilly](https://www.oreilly.com/library/view/genai-on-google/9798341623842/ch07.html); Claude Code on Agent Platform — [docs](https://code.claude.com/docs/en/google-vertex-ai.md); remote MCP — [docs](https://docs.cloud.google.com/mcp/configure-mcp-ai-application); MCP Toolbox — [docs](https://googleapis.github.io/genai-toolbox/documentation/introduction); Architecture Center agentic guides — [docs](https://docs.cloud.google.com/architecture/choose-agentic-ai-architecture-components); PCA case studies — [exam guide](https://services.google.com/fh/files/misc/v6.1_pca_professional_cloud_architect_exam_guide_english.pdf); June 2025 postmortem — [status page](https://status.cloud.google.com/incidents/ow5i3PPK96RduMcb1SsW); Agentic Architect cert — [FAQ](https://support.google.com/cloud-certification/answer/18080541?hl=en)

### Inferences

**Week-by-week (≈8-10 h/week)**

| Week | Learn (resource) | Build with Claude Code (sandbox project) |
|---|---|---|
| 1 | Projects, IAM, service accounts, billing, gcloud: "Google Cloud Fundamentals: Core Infrastructure" labs (Google Skills, free credits) | Create sandbox project + budget alerts; set up Claude Code on Agent Platform (wizard, pin Sonnet, `/status`); write a CLAUDE.md with GCP safety rules |
| 2 | Cloud Run deep dive: "Ultimate Cloud Run guide 2026", cookbook "FastAPI chatbot with Gemini", "AI cold starts" | Deploy a FastAPI service from source; Artifact Registry, Secret Manager, dedicated runtime SA; Cloud Run MCP for deploys |
| 3 | GCS, Eventarc, Pub/Sub, **Cloud Tasks**, Firestore (official docs/labs) | Project 1 part A: upload → Eventarc → Cloud Run → Cloud Tasks queue → Firestore status |
| 4 | Document AI skill badges (both) | Project 1 part B: OCR worker with Document AI (Form/Layout parser + custom extractor), idempotent retries, dead-letter |
| 5 | Gemini + Claude on Agent Platform: path 183 RAG/semantic labs; structured output, quotas, global vs regional endpoints | Project 2: extraction/validation service, Gemini primary + Claude fallback, eval set of 50 claims |
| 6 | RAG/search: cookbook "RAG infrastructure with Vertex AI and Vector Search", "Deploy a RAG agent with ADK"; BigQuery vector search | Project 3: claims search (hybrid search; compare Agent Search/Vector Search vs Qdrant on Cloud Run) |
| 7 | Agents: Kaggle 5-Day AI Agents Intensive (self-paced) + Agent Starter Pack | Project 4: adjuster assistant agent (ADK or LangGraph) on Cloud Run with MCP Toolbox → BigQuery/Firestore |
| 8 | MCP + security: remote MCP servers, gcloud MCP, Model Armor codelab, Agent Gateway codelab | Harden Project 4: separate agent SA, read-only tools, Model Armor, audit logs |
| 9 | Production ops: Cloud Logging/Trace/Monitoring, SLOs, CI/CD with Workload Identity Federation, Terraform; read June 2025 postmortem; *GenAI on Google Cloud* ch.5 & ch.7 | Project 5: Terraform + GitHub Actions/Cloud Build pipeline, canary via Cloud Run traffic split, alerting, load test, failure drill write-up |
| 10 | Architecture + interviews: Architecture Center agentic guides, PCA case studies (EHR Healthcare, Cymbal Retail), question banks | Project 6: cost + batch (Cloud Run jobs batch OCR backfill, Gemini batch, BigQuery cost report); mock interviews with Claude Code as interviewer |
| 11-12 (opt.) | Agentic Architect path 4525 (or PCD prep) | Polish portfolio repo + architecture diagrams; book exam |

**Practice projects (mimic a production AI document-processing system)**
1. **Claim intake & OCR pipeline** — GCS upload → Eventarc → Cloud Run (FastAPI) → Cloud Tasks (rate-limit to Document AI quota) → Document AI → Firestore claim state → BigQuery event log. Skills: IAM per SA, idempotency, retries, DLQ, per-page cost.
2. **LLM extraction & validation service** — Gemini (structured JSON output) with Claude-on-Agent-Platform fallback; prompt caching; 429 handling; golden-set evaluation stored in BigQuery; cost per claim dashboard.
3. **Claims/policy search engine (RAG)** — embeddings + BigQuery vector search or Vector Search vs self-hosted Qdrant on Cloud Run/GKE; hybrid keyword+vector; Vietnamese + English documents; latency/quality comparison report.
4. **Adjuster assistant agent** — ADK or LangGraph agent on Cloud Run (or Agent Engine), tools via MCP Toolbox (Firestore/BigQuery read-only), Model Armor, dedicated agent identity, tracing in Langfuse/Cloud Trace.
5. **Production hardening & CI/CD** — Terraform modules, Workload Identity Federation from GitHub, Artifact Registry, Cloud Run revisions + traffic split, Secret Manager, uptime checks, SLO alerting, chaos drill (Document AI disabled / quota exhausted) with a written postmortem.
6. **Batch backfill & FinOps** — Cloud Run jobs for 100k-document backfill, Gemini batch prediction, BigQuery `maximum_bytes_billed`, budget alerts, labels, cleanup script that deletes the lab project.

For each project: Claude Code writes Terraform/code and runs only read-only/plan commands; the learner reviews and applies; ask Claude Code to explain every IAM role and error in simple English (and Vietnamese if useful).

### Gaps
- Time estimates per week are my estimates; actual lab hours for Google Skills paths were not visible.
- No verified Vietnamese-language long-form resources to slot into the plan.
