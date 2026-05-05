# 厕所选择测试 · 产品需求文档（PRD）

**版本**：v0.1（移动端测试版）
**目标**：可在 1 周内开发完成的最小可测产品
**配套文档**：[01-product-flow.md](./01-product-flow.md)

---

## 1. 产品定位

### 1.1 一句话定位
基于厕所空间选择的多情境心理测量工具，定位"严肃的趣味性"——用博弈论复盘 + Gerlach 四类型框架替代 MBTI。

### 1.2 核心价值主张
- **教学价值**：让用户体验自己的直觉与博弈论最优解的差距
- **身份价值**：4 类型 + 5 维度 + 决策风格的多层身份标签
- **传播价值**：场景设计本身具有话题性，结果页可分享

### 1.3 非目标
- 不做职业匹配工具（伦理风险高）
- 不做"哪个类型更好"的横向比较
- v0.1 不做女厕场景、不做团队/组织扩展

---

## 2. 5 维度定义

每个维度 0–100 分，每个用户初始 50 分。

| 代码 | 内部名 | 用户呈现名 | 高分含义 | 低分含义 |
|---|---|---|---|---|
| PS | Personal Space | 空间感 | 强烈追求物理边界 | 不在意身体距离 |
| SC | Social Calibration | 社会嗅觉 | 敏感于他人身份/情绪/规范 | 对社会信号迟钝 |
| SO | Strategic Optimization | 棋盘思维 | 多步推演、最优化 | 直觉、就近 |
| CO | Conscientious Order | 秩序心 | 守规、利他细节 | 效率优先、不拘小节 |
| AS | Assertive Stance | 占位力 | 不让步、占有利位 | 退避、让位 |

---

## 3. 8 个场景的完整数据结构

每个场景的 JSON 结构示例（场景 1）：

```json
{
  "id": "S1",
  "title": "空厕所",
  "subtitle": "你刚进入，里面没有人。",
  "context": "5 个小便池都空着。请选择你会站的位置。",
  "layout": {
    "type": "urinal_row",
    "count": 5,
    "occupants": [null, null, null, null, null],
    "entry_side": "left"
  },
  "options": [
    { "id": "A1", "label": "最靠门", "scores": { "PS": -5, "SC": 0, "SO": -10, "CO": -5, "AS": 10 } },
    { "id": "A2", "label": "次靠门", "scores": { "PS": 0, "SC": 0, "SO": -5, "CO": 0, "AS": 0 } },
    { "id": "A3", "label": "正中", "scores": { "PS": -5, "SC": 0, "SO": -10, "CO": 0, "AS": 5 } },
    { "id": "A4", "label": "次靠里", "scores": { "PS": 5, "SC": 5, "SO": 5, "CO": 5, "AS": -5 } },
    { "id": "A5", "label": "最里", "scores": { "PS": 15, "SC": 10, "SO": 15, "CO": 10, "AS": -10 } }
  ],
  "optimal_choice": "A5",
  "replay_message_template": {
    "optimal": "你天生懂博弈论。",
    "near_optimal": "你接近最优，但少了一步推演。",
    "suboptimal": "你不在意被打扰，这是另一种自由。"
  }
}
```

### 完整场景列表（精简版 - 详细见原型代码）

| ID | 场景 | 选项数 | 主激活维度 |
|---|---|---|---|
| S1 | 空厕所 | 5 | SO, AS |
| S2 | 两端被占（中年男 + 西装中年）| 4 (含等待) | PS, AS |
| S3 | 强制相邻（仅 3 位，中间被大学生占）| 3 (含等待) | PS, SO |
| S4 | 纹身大哥与小学生 | 3 | SC, AS |
| S5 | 洗手台（漏水 + 老人 + 时间压力 6 选项 2×2 矩阵）| 6 | CO, SC |
| S6 | 大声打电话者 | 5 (含等待) | SC, PS |
| S7 | 镜子前（有人在整理头发）| 6 | PS, AS |
| S8 | 离场让门 | 5 | SC, CO |

**关键诊断切口**：S5 的选项 C（关水龙头但不理老人）vs 选项 D（理老人但不关水龙头）总分接近，但维度结构相反——前者高 CO 低 SC，后者高 SC 低 CO。这是测试"结构型尽责"vs"情境型共情"的核心诊断点，是 v0.1 比单维利他量表更有诊断力的关键设计。

**8 个场景总计可调整分数范围**：每个维度理论上 -85 到 +85，结合初始 50 分，最终落在 0–100 区间。

---

## 4. 4 类型原型与映射算法

### 4.1 类型原型（理论值）

| 类型 | PS | SC | SO | CO | AS |
|---|---|---|---|---|---|
| 守望者 Watcher | 80 | 75 | 60 | 65 | 35 |
| 协调者 Coordinator | 55 | 80 | 85 | 80 | 55 |
| 占位者 Claimer | 35 | 35 | 55 | 35 | 80 |
| 随波者 Flow | 50 | 55 | 45 | 55 | 50 |

### 4.2 映射算法

```javascript
function mapToType(userScores) {
  const prototypes = {
    watcher:     { PS: 80, SC: 75, SO: 60, CO: 65, AS: 35 },
    coordinator: { PS: 55, SC: 80, SO: 85, CO: 80, AS: 55 },
    claimer:     { PS: 35, SC: 35, SO: 55, CO: 35, AS: 80 },
    flow:        { PS: 50, SC: 55, SO: 45, CO: 55, AS: 50 }
  };

  const distances = {};
  for (const [type, proto] of Object.entries(prototypes)) {
    distances[type] = Math.sqrt(
      Object.keys(proto).reduce((sum, dim) =>
        sum + Math.pow(userScores[dim] - proto[dim], 2), 0)
    );
  }

  // 主类型：距离最小
  const sorted = Object.entries(distances).sort((a, b) => a[1] - b[1]);
  const primary = sorted[0][0];
  const secondary = sorted[1][0];

  // 混合比例：基于距离反比
  const ratio = sorted[1][1] / (sorted[0][1] + sorted[1][1]);

  // 如果差距 > 70%，认定为纯类型；否则混合
  const isPure = ratio > 0.6;

  return {
    primary,
    secondary: isPure ? null : secondary,
    primaryWeight: Math.round(ratio * 100),
    secondaryWeight: isPure ? 0 : Math.round((1 - ratio) * 100)
  };
}
```

### 4.3 决策风格标签

```javascript
function getDecisionStyle(rtArray, changeCountArray) {
  const avgRT = mean(rtArray);
  const totalChanges = sum(changeCountArray);

  if (avgRT < 2000 && totalChanges === 0) return "lightning"; // 闪电决策者
  if (avgRT > 5000 && totalChanges <= 2) return "deliberate"; // 审慎权衡者
  if (totalChanges > 3) return "iterative";                   // 反复推演者
  if (avgRT > 4000 && totalChanges > 2) return "swaying";     // 直觉摇摆者
  return "balanced";                                           // 平衡型（默认）
}
```

---

## 5. 数据结构（用户测试结果）

```typescript
interface TestResult {
  // 元数据
  anonymous_id: string;        // UUID, localStorage 保存
  start_time: number;          // Unix timestamp
  end_time: number;
  total_duration: number;      // 毫秒
  user_agent: string;          // 设备信息（用于跨设备分析）

  // 8 个场景的原始数据
  scenes: Array<{
    scene_id: string;
    final_choice: string;       // 最终选项 id
    initial_choice: string;     // 第一次点击的选项（如有改变）
    response_time: number;      // 进入到首次点击的时间（ms）
    decision_time: number;      // 进入到最终确认的时间（ms）
    change_count: number;       // 改变选择的次数
  }>;

  // 计算结果
  scores: {
    PS: number;
    SC: number;
    SO: number;
    CO: number;
    AS: number;
  };

  type_result: {
    primary: "watcher" | "coordinator" | "claimer" | "flow";
    secondary: string | null;
    primaryWeight: number;
    secondaryWeight: number;
  };

  decision_style: "lightning" | "deliberate" | "iterative" | "swaying" | "balanced";
}
```

---

## 6. 结果页详细文案

### 6.1 区块 1：身份揭晓（4 个类型完整文案）

#### 守望者 The Watcher
- slogan: "距离即自由"
- 副标题: "你天生懂得：最舒服的状态，是看得见所有人，但没人离你太近。"
- 群体占比锚点: "约 22% 是守望者"

#### 协调者 The Coordinator
- slogan: "考虑下一个人，是因为你也曾是下一个人"
- 副标题: "你做选择时，脑中有一张看不见的地图——上面不仅有你自己，还有还没出现的人。"
- 群体占比锚点: "约 24% 是协调者"

#### 占位者 The Claimer
- slogan: "你来晚了，不是我的问题"
- 副标题: "你看到资源就拿，看到位置就占。在效率和礼貌之间，你毫不犹豫选前者。"
- 群体占比锚点: "约 18% 是占位者"

#### 随波者 The Flow
- slogan: "大多数人怎么做，我就怎么做"
- 副标题: "你不浪费时间纠结。规范在哪里，你的脚就在哪里——这是被严重低估的智慧。"
- 群体占比锚点: "约 36% 是随波者"

### 6.2 区块 2：博弈论复盘文案模板

每个场景三档文案（"最优 / 次优 / 反直觉"），共 8 × 3 = 24 条。详细列表见 [04-prototype.html] 中的 SCENES 数据结构 `replay_message_template` 字段。

### 6.3 区块 3：维度雷达图

- 5 角雷达，外环 100，每 20 一格
- 用户分数填充色块（半透明品牌色）
- 类型原型轮廓（虚线）作为对比
- 每个维度名称外加一个简短副标签（高分注解）

### 6.4 区块 4：完整人物志

每个类型 350-450 字，结构：
1. 开场白（1 段）：行为模式描述
2. 优势（1 段）：独特能力
3. 代价（1 段）：对应的盲点
4. 适合的工作环境（1 段）
5. 反思问题（1 句）：留给用户思考

完整文案见前一轮对话的"完整人物志"部分。

### 6.5 区块 5：决策风格 + 分享

- 决策风格标签（5 选 1）+ 一句话注解
- 名人映射（虚构/历史人物，避免真实在世名人）
- "复制研究数据"按钮
- "挑战朋友"链接生成
- 诚实声明（不可省略）

---

## 7. 视觉设计规范

### 7.1 整体风格定位
**编辑性 / 中文报刊感 / 临床克制**

不要：
- 紫色渐变 / 5 像素圆角 / 通用 SaaS 卡片
- 拟物化的厕所图（3D 渲染、写实贴图）
- emoji 过度使用

要：
- 纸质质感的米色背景 + 墨黑文字
- 一个非常克制的强调色（建议红土色 #C44536 或 深橄榄 #5C6B47）
- 中文衬线字体（Noto Serif SC 或类似）做标题，无衬线做正文
- 厕所示意用纯几何（圆角矩形 + 简笔小人）
- 适度的网格线、刻度线、序号——增加"研究器械感"

### 7.2 色彩规范

```css
:root {
  /* 主色板 */
  --paper:      #F5F1E8;  /* 纸张米色背景 */
  --paper-dark: #E8E2D3;  /* 次背景 */
  --ink:        #1A1714;  /* 主文字 - 接近黑但带暖 */
  --ink-soft:   #4A4540;  /* 次文字 */
  --ink-faint:  #8A8278;  /* 辅助文字 */

  /* 强调色 */
  --accent:     #C44536;  /* 红土色 - 高亮、品牌锚点 */
  --accent-soft: #E8B5A8; /* 强调色弱化版 */

  /* 功能色 */
  --line:       #D4CCB8;  /* 分隔线、边框 */
  --shadow:     rgba(26, 23, 20, 0.08);
}
```

### 7.3 字体规范

```css
/* 标题：中文衬线 + 西文衬线 */
font-family: 'Noto Serif SC', 'Source Han Serif SC', 'Songti SC', serif;

/* 正文：中文黑体 + 西文无衬线 */
font-family: 'Noto Sans SC', 'PingFang SC', 'Helvetica Neue', sans-serif;

/* 强调数字：等宽 */
font-family: 'JetBrains Mono', 'Fira Code', monospace;
```

字号：
- H1（首屏类型名）：44px
- H2（区块标题）：28px
- H3（场景标题）：20px
- 正文：16px
- 辅助：13px

### 7.4 间距与布局
- 容器最大宽度：480px（移动端友好）
- 主要内边距：24px
- 卡片之间：16px
- 段落之间：12px

---

## 8. 技术规范

### 8.1 技术栈选择
**单文件 HTML + Vanilla JS**（不使用 React/Vue）

理由：
- 用户要"拿出去测试"，单文件最方便部署
- 测试逻辑简单，不需要复杂状态管理
- 易于第三方修改（学术合作者审阅时）

### 8.2 浏览器支持
- iOS Safari 14+
- Android Chrome 90+
- 桌面 Chrome / Firefox / Safari 最新版

### 8.3 关键 API 使用
- `localStorage` - 保存测试结果，支持回访
- `Date.now()` / `performance.now()` - 时间戳记录
- `crypto.randomUUID()` - 匿名 ID 生成
- `navigator.clipboard.writeText()` - 复制研究数据

### 8.4 文件结构
```
prototype.html           # 单文件，包含 HTML + CSS + JS
└── 内嵌字体（Google Fonts CDN）
```

---

## 9. 验收标准（v0.1）

### 9.1 功能完整性
- [ ] 8 个场景全部可完成
- [ ] 5 维度计算正确
- [ ] 4 类型映射正确
- [ ] 决策风格标签正确
- [ ] 结果页 5 个区块全部展示
- [ ] localStorage 持久化
- [ ] "复制研究数据"功能可用

### 9.2 移动端体验
- [ ] iPhone SE (375px) 无横向滚动
- [ ] 所有按钮触控友好（≥44px）
- [ ] 加载到首屏 < 1.5s（4G 网络）
- [ ] 全程可在不联网情况下完成

### 9.3 视觉质量
- [ ] 字体加载有 fallback
- [ ] 无 AI 通用美学痕迹
- [ ] 结果页可截图分享

---

## 10. 后续版本路线图

### v0.2（v0.1 测试后 2-4 周）
- 添加后端数据收集
- 基于真实数据重新校准类型原型
- "挑战朋友"裂变机制
- 结果页分享卡片自动生成

### v1.0（3 个月内）
- 女性版本（女厕场景重新设计）
- 多语言（英文版）
- 跨文化对比模块（中/日/美用户分布对比）
- 与已有人格量表（BFI-2）的相关性研究合作

### v2.0（6 个月内）
- 移动 App（iOS/Android）
- 团队版本（团队 5 维分布可视化）
- 学术合作发表 SSCI/CSSCI 论文
