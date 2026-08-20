# 视觉方向原型(wayfinder ticket 08)

> **一次性原型,供取舍 —— 不是最终产品。** 选定方向后,把该方向的 token 展平回
> listening-king 式 `AppColors` / `AppSpacing` / `AppTheme` static 类,删掉变体与 switcher。

回答的问题:**「专业供应商后台」的视觉方向 + 应用外壳长什么样?**

## 跑起来

```bash
cd spikes/visual-direction/dart-spike
flutter run -d macos      # 或 -d windows
```

底部居中有浮动胶囊切换方向;也可用键盘 **← / →** 切换。**把窗口拉窄(< 720px)** 即见
移动 shell(底部导航 + 顶栏替代侧栏),不为移动单开代码路径。

## 三个方向(结构不同,非仅换色)

| 键 | 方向 | 气质 | 关键取舍 |
|----|------|------|----------|
| **A** | Terminal / Console | 暗色 · 等宽数字 · 发丝面板 · 高密度 | 最适合「常驻算力节点」的运维监控感;但暗色 + 等宽偏极客,非管理后台主流 |
| **B** | Light Enterprise SaaS | 浅色 · 卡片 KPI · 柔和阴影 · 克制靛蓝 | 最「后台仪表盘」、最安全;但卡片化信息密度较低,留白多 |
| **C** | Compact Pro Tool | 浅色 · 发丝边框 · 窄侧栏 · 表格为主角 | 信息密度最高、老手高效;但装饰最少,新手第一眼信息量大 |

三者共用**同一份 mock 数据**(连接态 / 模型报价 / 最近请求 / 链上结算 / 余额 / 吞吐),
差异只在「呈现」,不在「内容」—— 便于直接比较。

## token 体系(可迁入真实 app)

- [`lib/tokens/app_spacing.dart`](lib/tokens/app_spacing.dart) — 4px 刻度 + EdgeInsets 预设 + `num.hSpace/wSpace` 扩展。组织方式直接借自 listening-king,刻度本身与方向无关,可原样采用。
- [`lib/tokens/direction_tokens.dart`](lib/tokens/direction_tokens.dart) — `DirPalette`(语义色板,按语义命名非色相)+ `DirTokens`(色板/圆角/阴影/字体策略)。**选方向后**,把胜出方向的 `DirPalette` 展平成 `AppColors` static const 类、把 `DirTokens` 的圆角/阴影并入 `AppSpacing`/`AppTheme`,即得到 listening-king 同构的 token 层。
- 各 Dashboard 用语义 token(`palette.positive/warn/danger/accent`),换方向只换这套值。

## 应用外壳(可迁入真实 app)

- [`lib/shell/app_shell.dart`](lib/shell/app_shell.dart) — 响应式:`≥720px` 左固定侧栏 + 内容(桌面 shell);`<720px` 底部导航 + 顶栏(移动 shell)。结构借自 listening-king 的 `DesktopScaffold`/`SideNavBar`,导航项走 9 个功能页(Dashboard / Keypair / Wallet / Models / Providers / Settlements / Records / Settings / Config)。
- 本原型只实现 **Dashboard 一屏**;其余 nav 项为占位 —— 视觉方向选定后,其余页面沿用同套 token。

## 待你裁决的取舍点

1. **选哪个方向?**(或「A 的状态条 + B 的 KPI 卡 + C 的表格」这种混搭 —— 这是原型真正想要的反馈)
2. **主色**:B 的靛蓝 `#4F46E5` vs C 的近黑 `#111827` vs A 的青 `#38BDF8`?供应商后台更想要「克制可信」还是「算力科技感」?
3. **密度基调**:管理后台(B,舒适)还是运维监控(A/C,高密度)?这关系到侧栏宽度、卡片间距、表格行高的全局基线。
4. **暗色模式**:A 是暗色 —— 真实 app 要不要支持明/暗双主题?(listening-king 目前只有 light)

> 这几点定下来后,在 [08 ticket](../../../.scratch/supplier-portal/issues/08-visual-direction-app-shell.md) 的 `## Answer` 里记裁决,然后按上面「展平」步骤把胜出方向迁入真实 app、删掉本原型。
