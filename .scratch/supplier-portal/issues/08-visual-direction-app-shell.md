# 08 — 视觉方向与应用外壳(原型)

Type: prototype
Status: resolved (2026-08-08, supplier-portal session)

## Question

专业供应商后台风的视觉方向 + 应用外壳长什么样?产出**一次性原型**供反应(不做最终产品):

- token 体系:色板 / 字距 / 间距(4px 基准)/ 圆角 / 阴影。
- 桌面侧栏 shell(macOS/Windows)+ 移动 shell(iOS/Android)。
- Dashboard 一屏(数据密集、清晰、中性专业)。

借 listening-king 的 **token 组织方式**(`app_colors` / `app_spacing` / `app_text_styles` / `app_theme`),换中性专业色板,**不照搬 Duolingo 活泼风**。桌面优先(管理后台桌面为主)。

## Context

- listening-king token:`../listening-king/lib/utils/app_colors.dart` / `app_spacing.dart` / `app_text_styles.dart` / `app_theme.dart`。
- desktop shell:`listening-king/lib/widgets/macos/desktop_scaffold.dart`、`side_nav_bar.dart`。
- 设计规约:`listening-king/docs/design-system.md`。
- 用 /prototype 技能。

## Done looks like

可跑 / 可看的 shell 原型(资产链接)+ token 定义文件。一次性、供取舍,不在此过度打磨细节。

## Answer(原型已交付 · 视觉方向裁决待用户)

**交付物**:`spikes/visual-direction/dart-spike/`(Flutter 桌面包,沿用 `spikes/<topic>/dart-spike` 约定)
- README:`spikes/visual-direction/dart-spike/README.md`(运行 + 3 方向取舍 + 迁入指南)。
- token:`lib/tokens/app_spacing.dart`(4px 刻度 + EdgeInsets + `num.hSpace/wSpace`,借 listening-king 组织,可原样采用)+ `lib/tokens/direction_tokens.dart`(`DirPalette` 语义色板 + `DirTokens` 色板/圆角/阴影/字体)。
- shell:`lib/shell/app_shell.dart`(响应式:≥720px 侧栏 / <720px 底部导航,借 `DesktopScaffold`/`SideNavBar`,9 功能页导航)。
- 3 个结构不同的 Dashboard:`variant_a_terminal`(暗色等宽高密度)/ `variant_b_enterprise`(浅色卡片克制)/ `variant_c_compact`(浅色发丝表格密集),共用 `data/mock_data.dart` 同一份数据。
- 浮动 switcher:`lib/switcher/variant_switcher.dart`(底部胶囊 ←/→ + 键盘 ←/→)。

**验证**:`flutter analyze` 零问题;`flutter build macos --debug` 编译成功(`dart_spike.app` 可运行)。运行:`cd spikes/visual-direction/dart-spike && flutter run -d macos`,←/→ 切方向,拉窄窗口看移动 shell。

**三个方向(结构不同,非仅换色)**:
- **A Terminal/Console** — 暗色 · 等宽数字 · 发丝面板 · 高密度。最贴「常驻算力节点」运维监控感;偏极客,非管理后台主流。
- **B Light Enterprise SaaS** — 浅色 · 卡片 KPI · 柔和阴影 · 克制靛蓝 `#4F46E5`。最「后台仪表盘」、最安全;密度较低。
- **C Compact Pro Tool** — 浅色 · 发丝边框 · 窄侧栏 · 表格为主角 · 近黑 `#111827`。密度最高、老手高效;新手第一眼信息量大。

**裁决(用户授权按推荐,2026-08-08)** —— app 双重身份(always-on 算力节点 = 监控;9 页管理后台 = 管理),故取混搭而非单一方向:

| 维度 | 决定 | 理由 |
|---|---|---|
| 布局/密度 | **C 骨架**:发丝边框、无重阴影、窄侧栏 208、圆角 3–5、紧凑 | 常驻节点 = 监控优先 → 密度;扁平 = 可信工具非消费 app |
| 顶部摘要 | 嫁接 **B**:4 KPI 卡(余额/应收/req-min/成功率)+ 绿「Connected · Xms」pill | 运营者首眼状态层,兼顾管理页清晰 |
| 主色 | 结构/文字/边框 = 近黑 `#111827`;accent = 克制蓝 `#2563EB`(active 导航/链接/焦点/主操作);语义色 green/amber/red 不变 | 可信稳重 > 活泼;单一蓝 accent 保扫描性 |
| 主题 | **light 默认**;暗色延后(A 的 terminal 色板日后作暗主题蓝本) | 表单/管理页 light 更清晰;长时监控要暗色但晚于核心 |
| 外壳 | 采纳响应式 **AppShell**(宽屏侧栏 / 窄屏底部导航),方向无关 | 已就绪,直接可用 |

否决:纯 A(太极客,管理表单在暗色别扭)、纯 B(监控面太空)、纯 C(首眼状态慢)。

> **展平迁移**(下游实现,非本 ticket):真实 app 脚手架时,把上述裁决落成 listening-king 同构的 `AppColors`(近黑结构 + 蓝 accent + 语义色)/ `AppSpacing`(4px 刻度)/ `AppTheme`(light),并把 `AppShell` + Dashboard(顶部 B 摘要 + C 表格身)搬入。本原型 `spikes/visual-direction/dart-spike/` 作为蓝本保留到那时再删。暗色模式双主题的 token 结构(是否 `DirPalette` 拆 light/dark)→ 见 map Fog。
