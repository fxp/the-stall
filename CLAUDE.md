# Context for AI Agents

> 这份文档给后续 Agent（Claude Code / Cursor / Codex / 其他）做上下文交接，配合
> 仓库里的 `02-PRD.md` 和 `README.md` 一起读。本仓库属于一个更大的多 app 体系
> （见下文"Repository Ecosystem"），改动时要意识到这点。

---

## 1. What this project is

**距离测试 / The Stall (slug `the-stall`)** —— 单文件 HTML 心理学测试。
- 8 个厕所空间选择场景 → 5 维度（PS / SC / SO / CO / AS）→ 4 类型（Watcher / Coordinator / Claimer / Flow）+ 决策风格
- v0.1 已上线，正在收集真实数据用于后续校准类型原型
- 完整产品需求见 `02-PRD.md`

**核心文件**：`prototype.html`（单文件，约 1700 行 HTML/CSS/JS，无构建工具）。`build.sh` 把它复制成 `dist/index.html`（构建产物，不入库）。

---

## 2. 线上地址

| 地址 | 内容 |
|---|---|
| https://xiaopingfeng.com/app/the-stall/ | **生产 URL**（推荐分享）。Worker 路由代理到 Pages 项目 |
| https://the-stall.pages.dev/ | Pages 项目自带域，等价于上面 |
| https://xiaopingfeng.com/ | 心理学小工具集落地页（`fxp/landing` 仓库） |

---

## 3. Multi-App Architecture（重要）

这个仓库不是孤立项目。`xiaopingfeng.com` 域名背后有一套"多 app 部署体系"，由 4 个仓库 + 1 个 Cloudflare Worker + N 个 Pages 项目组成：

```
                    xiaopingfeng.com
                          │
                          ▼
            ┌──────────────────────────┐
            │ Cloudflare Worker:       │  ← fxp/xiaopingfeng-router
            │ xiaopingfeng-router      │     按 URL path 分发
            └────────────┬─────────────┘
                         │
         ┌───────────────┼────────────────┐
         ▼               ▼                ▼
    landing-cz4    the-stall.        <slug>.pages.dev
    .pages.dev     pages.dev          (未来的 app)
         ▲               ▲
         │               │
    fxp/landing     fxp/the-stall ← 本仓库
         ▲               ▲
         │               │
       deploy.yml ← 共用 → deploy.yml
              ▲       ▲
              │       │
         fxp/deploy-app-action
       (reusable workflow)
```

**路由规则**（在 `fxp/xiaopingfeng-router/src/index.js`）：
- `xiaopingfeng.com/app/<slug>/*` → `<slug>.pages.dev/*`（默认按 slug 派生子域）
- `xiaopingfeng.com/app/`、`/app`、`/apps` → 302 到 `/`
- 其他路径 → `landing-cz4.pages.dev/*`
- `SUBDOMAINS` 表用于覆盖默认派生（仅当 CF 因全局命名冲突给 Pages 项目子域加了后缀时需要——目前只有 `landing` 一项）

---

## 4. Repository Ecosystem

| Repo | 类型 | 作用 | 何时改 |
|---|---|---|---|
| [`fxp/the-stall`](https://github.com/fxp/the-stall) | App | 距离测试本身（本仓库） | 改测试逻辑/文案/UI |
| [`fxp/landing`](https://github.com/fxp/landing) | App | xiaopingfeng.com/ 落地页 | 加新 app 卡片，改首页文案 |
| [`fxp/deploy-app-action`](https://github.com/fxp/deploy-app-action) | Infra | Reusable GitHub Actions workflow，所有 app 共用 | 改部署流程 |
| [`fxp/xiaopingfeng-router`](https://github.com/fxp/xiaopingfeng-router) | Infra | Cloudflare Worker，做 path → Pages 项目分发 | 仅当 CF 给新 Pages 项目子域加后缀时 |

本地拷贝（如果需要）通常在 `~/projects-infra/<name>`。

---

## 5. Cloudflare Resources

**Account**
- 邮箱：`fxp007@gmail.com`
- Account ID：`0356d59ccdcff356bf3bbdb580bbaa60`

**Pages 项目**
| 项目名 | 实际子域 | 内容来源 |
|---|---|---|
| `the-stall` | `the-stall.pages.dev` | fxp/the-stall（dist/index.html） |
| `landing` | `landing-cz4.pages.dev` ⚠️ 因命名冲突被加后缀 | fxp/landing（index.html） |

**Worker**
- 名称：`xiaopingfeng-router`
- 路由：`xiaopingfeng.com/*`、`www.xiaopingfeng.com/*`
- 部署：在 `fxp/xiaopingfeng-router` 目录下 `wrangler deploy`（用 wrangler OAuth 登录的账号）

**Domain**
- `xiaopingfeng.com` 在该 CF 账号的 zone 里。Worker 路由生效后没有传统意义的"原站"。

---

## 6. Supabase Backend

收集匿名研究数据的后端。

**Project**
- URL：`https://xwrejjytrbpkundisuyr.supabase.co`
- Project ref：`xwrejjytrbpkundisuyr`
- Publishable key（前端用，安全暴露）：`sb_publishable_XBIxHbOkqvgQwoVmyuuUYg_dPmYsfr5`

**Schema**（多项目支持）

```
projects                    test_results
├ slug (PK)         ←──┐    ├ id (UUID PK)
├ name                  └── ├ project_slug (FK → projects.slug)
├ version                   ├ project_version
├ description               ├ anonymous_id
├ is_active                 ├ started_at / completed_at / duration_ms
└ created_at                ├ user_agent
                            ├ payload (jsonb) — 测试原始作答
                            ├ summary (jsonb) — 计算结果
                            ├ meta (jsonb) — 兜底扩展
                            └ created_at
```

**关键设计**：
- 多项目共享一张 `test_results`，靠 `project_slug` 区分。加新心理测试时只要 `insert into projects` 一行 + 客户端换 `PROJECT_SLUG` 常量。
- `payload` vs `summary` 分离：`summary` 存高层结果（scores / type / style）便于跨项目聚合查询，`payload` 存原始作答便于回溯。
- `started_at` / `completed_at` 用 `timestamptz`，不是 epoch ms。
- RLS 启用，仅 `INSERT` 对 anon role 开放：客户端能写入但不能读（保护研究数据集）。
- FK 约束 `project_slug → projects.slug` 防止脏数据。
- 已注册 project：`distance` / 距离测试 / v0.1。

**前端调用**（在 `prototype.html`）：

```js
const SUPABASE_URL = 'https://xwrejjytrbpkundisuyr.supabase.co';
const SUPABASE_KEY = 'sb_publishable_XBIxHbOkqvgQwoVmyuuUYg_dPmYsfr5';
const PROJECT_SLUG = 'distance';
const PROJECT_VERSION = 'v0.1';

// finalizeAndRender() 之后异步调用 uploadResult(state.fullRecord)
// 失败静默——不阻塞用户看结果
```

**常用分析查询**（用 service role 或 SQL Editor）：

```sql
-- 4 类型分布
select summary->'type_result'->>'primary' as primary_type, count(*)
from test_results where project_slug='distance' group by 1;

-- 同一用户多次测试
select project_slug, completed_at, summary
from test_results where anonymous_id='xxx' order by created_at;

-- 5 维度均值
select avg((summary->'scores'->>'PS')::int) as ps, ...
from test_results where project_slug='distance';
```

---

## 7. Local Development

```bash
# 改 prototype.html 后：
./build.sh                                # 生成 dist/
python3 -m http.server -d dist 4173       # http://localhost:4173/

# 直接对生产改一次（绕过 CI，需要 wrangler OAuth 已登录）：
wrangler pages deploy dist --project-name=the-stall --branch=main --commit-dirty=true
```

**JS 健康检查**（任何提交前都该跑）：

```bash
node -e "
const m = require('fs').readFileSync('prototype.html','utf8').match(/<script>([\s\S]*?)<\/script>/);
new Function(m[1]); console.log('JS parse OK,', m[1].length, 'chars');
"
```

---

## 8. CI/CD

Push 到 `main` → GitHub Actions 跑 `.github/workflows/deploy.yml`，调用
`fxp/deploy-app-action/.github/workflows/pages.yml@main`，最终
`wrangler pages deploy dist --project-name=the-stall`。

**仓库 Secrets**（必需）：
- `CLOUDFLARE_API_TOKEN`（Cloudflare → Pages → Edit 权限的 API token）
- `CLOUDFLARE_ACCOUNT_ID`（已设：`0356d59ccdcff356bf3bbdb580bbaa60`）

**当前状态**（截至上次会话）：⚠️ `CLOUDFLARE_API_TOKEN` 在 `fxp/the-stall` 和 `fxp/landing` 都还没设。CI 跑会 `startup_failure`。临时绕过靠手动 `wrangler pages deploy`。需要用户去 https://dash.cloudflare.com/profile/api-tokens 创建 token 然后：

```bash
gh secret set CLOUDFLARE_API_TOKEN --repo fxp/the-stall
gh secret set CLOUDFLARE_API_TOKEN --repo fxp/landing
```

---

## 9. Skill: `/xpf-app`

**位置**：`~/.claude/skills/xpf-app/SKILL.md`

加新心理学测试到这套体系的标准流程都封装在这个 skill 里。从一个新项目目录调用 `/xpf-app` 或描述"部署到 xiaopingfeng.com"、"加到我的多 app 体系"会触发。涵盖：
1. 与用户对齐 slug
2. 项目里写 `build.sh` + `.github/workflows/deploy.yml`
3. `wrangler pages project create`
4. `gh repo create fxp/<slug> --push`
5. 设 secrets
6.（必要时）改 router worker 的 SUBDOMAINS 映射并 redeploy
7. 在 `fxp/landing/index.html` 加一张 app 卡片
8. 触发首次部署 + curl 验证

---

## 10. Current State Snapshot

✅ **已验证工作**
- 距离测试在 https://xiaopingfeng.com/app/the-stall/ 端到端跑通
- Supabase RLS 已通过 API 测试（INSERT 201、SELECT 被挡空、FK 拒绝未知 slug）
- Worker 路由分发正确（curl 测试 4 种路径都符合预期）
- 雷达图标签裁剪 bug 已修（`viewBox="-30 0 420 360"`）
- Skill `/xpf-app` 注册到 `~/.claude/skills/xpf-app/SKILL.md`

⚠️ **待办**
- `CLOUDFLARE_API_TOKEN` secret 没设到任何 app 仓库 → CI 自动部署不工作
- 用户在早前会话里贴过 Supabase Personal Access Token（`sbp_b1f9...`）。要 revoke：https://supabase.com/dashboard/account/tokens
- xiaopingfeng.com 还没在 dashboard 显式绑到任何 Pages 项目的 custom domain（**不需要**——Worker 路由就够了，但如果未来拆 Worker 要注意）

---

## 11. Past Decisions（不要重新讨论）

| 决策 | 原因 |
|---|---|
| 路径 2（多仓库 + Worker 路由）而不是 monorepo | 用户希望每个心理测试独立迭代/可能开源 |
| 共用一个 Pages 项目跨 app **不行** | Pages 部署是整树原子替换，多 app 共用会互相清掉 |
| Worker 默认按 slug 派生子域，SUBDOMAINS 表只记异常 | 减少手工维护，加新 app 通常不动 Worker |
| Supabase 单表 `test_results` + `project_slug` 区分 | 跨项目分析方便（同一 anonymous_id 多个测试），加新测试零 schema 变更 |
| `payload` vs `summary` 拆开存 | summary 直接给聚合，payload 只在回溯时用 |
| Publishable key 写死在 prototype.html | 设计就是 public，RLS 保护数据；不需要环境变量 |
| 选 Supabase 而非 PostHog / D1 | 项目核心是研究数据集（要 SQL 查），不是产品分析漏斗 |
| 选 Cloudflare Pages 而非 Vercel | 用户已有 CF 账号 + 域名 + Worker 体系 |

---

## 12. Cheatsheet

```bash
# 看 the-stall 最近一次 CI 状态
gh run list --repo fxp/the-stall --limit 5

# 手动触发某 app 重新部署
gh workflow run deploy.yml --repo fxp/<slug>

# 直接看生产
curl -sS -o /dev/null -w 'HTTP %{http_code}\n' https://xiaopingfeng.com/app/the-stall/

# 查 Supabase 最近 N 条记录（需 service role 或 SQL Editor）
select project_slug, anonymous_id, summary->'type_result'->>'primary' as type, created_at
from test_results order by created_at desc limit 20;

# 修 Worker 之后重发
cd ~/projects-infra/xiaopingfeng-router && wrangler deploy

# 列出当前账号下的 Pages 项目
wrangler pages project list
```

---

## 13. Files / Directories Reference

```
the-stall/                          ← 本仓库
├── CLAUDE.md                       ← 本文件
├── README.md                       ← 项目简介（面向人）
├── 02-PRD.md                       ← 产品需求（含 5 维度 / 4 类型定义、场景全部 JSON）
├── prototype.html                  ← 单文件实现（HTML+CSS+JS）
├── build.sh                        ← 把 prototype.html 复制成 dist/index.html
├── .github/workflows/deploy.yml    ← 调用 fxp/deploy-app-action 的 thin caller
├── .gitignore
└── dist/                           ← build 产物（gitignore）
```

附：用户的工作目录在 iCloud 同步路径下：
`/Users/xiaopingfeng/Library/Mobile Documents/iCloud~md~obsidian/Documents/Projects/The Stall/`
（注意空格、尖头波浪号——cd 时记得加引号）
