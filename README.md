# 距离测试 · The Stall

一份基于厕所空间选择的多情境心理测量工具——用博弈论复盘 + Gerlach (2018) 四类型框架替代 MBTI。

**线上地址**：https://xiaopingfeng.com/app/the-stall/ （或 https://the-stall.pages.dev/app/the-stall/）

---

## 仓库结构

```
.
├── prototype.html                # 距离测试主体（单文件 HTML + Vanilla JS）
├── landing.html                  # xiaopingfeng.com/ 的落地页
├── 02-PRD.md                     # 产品需求文档
├── build.sh                      # 把 source 拼成 dist/ 的构建脚本
├── .github/workflows/deploy.yml  # push 到 main 自动部署到 Cloudflare Pages
└── dist/                         # build 产物（gitignore，不入库）
```

部署后线上路径：

| 路径 | 来源 |
|---|---|
| `/` | `landing.html` |
| `/app/the-stall/` | `prototype.html` |

## 本地开发

```bash
./build.sh                    # 重建 dist/
python3 -m http.server -d dist 4173   # 浏览器打开 http://localhost:4173/
```

直接编辑 `prototype.html` 即可（单文件、无构建工具）。

## 部署

推送到 `main` 分支会触发 GitHub Action 自动部署到 Cloudflare Pages 的 `the-stall` 项目。

需要在仓库 Secrets 中配置：

- `CLOUDFLARE_API_TOKEN` —— Cloudflare → My Profile → API Tokens 创建一个有 **Cloudflare Pages — Edit** 权限的 token
- `CLOUDFLARE_ACCOUNT_ID` —— 在 Cloudflare 仪表板右下角能看到的 Account ID

## 技术栈

- 单文件 HTML + Vanilla JS，无前端框架
- Cloudflare Pages 静态托管
- Supabase 收集匿名研究数据（RLS 保护，仅 `INSERT` 开放）
- GitHub Actions 持续部署
