# 距离测试 · The Stall

一份基于厕所空间选择的多情境心理测量工具——用博弈论复盘 + Gerlach (2018) 四类型框架替代 MBTI。

**线上**：https://xiaopingfeng.com/app/the-stall/ （由 Worker 路由代理到 `the-stall.pages.dev`）

---

## 仓库结构

```
.
├── prototype.html                # 距离测试主体（单文件 HTML + Vanilla JS）
├── 02-PRD.md                     # 产品需求文档
├── build.sh                      # 拼出 dist/index.html
├── .github/workflows/deploy.yml  # 调用 fxp/deploy-app-action 的 reusable workflow
└── dist/                         # build 产物（gitignore）
```

## 本地开发

```bash
./build.sh                                  # 生成 dist/
python3 -m http.server -d dist 4173         # http://localhost:4173/
```

直接编辑 `prototype.html`（单文件、无构建工具）。

## 部署

push 到 `main` → GitHub Action 调 reusable workflow → 部署到 Pages 项目 `the-stall`。

仓库 secrets 需要：
- `CLOUDFLARE_API_TOKEN` — Cloudflare API 令牌（Pages — Edit 权限）
- `CLOUDFLARE_ACCOUNT_ID` — Cloudflare 账号 ID

## 架构

这个仓库是 `xiaopingfeng.com` 多 app 体系下的一个：

```
xiaopingfeng.com (Worker: fxp/xiaopingfeng-router)
   ├── /                   → fxp/landing → landing.pages.dev
   ├── /app/the-stall/*    → fxp/the-stall (本仓库) → the-stall.pages.dev
   └── /app/<slug>/*       → fxp/<slug> → <slug>.pages.dev
```

## 数据后端

匿名研究数据收集到 Supabase（项目 `xwrejjytrbpkundisuyr`）的 `test_results` 表。schema 支持多项目（`project_slug` 列），新心理测试加进来时只要在 `projects` 表注册一行 + 客户端换 slug 即可。

详见 [02-PRD.md](./02-PRD.md)。
