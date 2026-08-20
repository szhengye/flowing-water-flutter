# 12 — Dashboard 厂商维度汇总(04 进阶,从 Fog 毕业)

Type: task
Blocked by: (无;依赖 04 Dashboard + provider_quotation / provider_llm_vendor 已就位)
Status: resolved (2026-08-09)

## Question

Dashboard 加「厂商明细」面板:按上游 LLM 厂商(OpenAI / Anthropic / …)聚合周期内收益(USDT)+ 调用数,与既有「模型明细」并列。完成 04 Done-list 的「厂商汇总」(原 [进阶] defer 到 Fog,现毕业)。

## Done looks like

- **厂商映射**:provider_log 无 vendor 列,经 `provider_quotation.relayModelName → providerId → provider_llm_vendor.vendorName` join 得 `{relayModel: vendorName}`。
- **厂商明细面板**:Dashboard 新卡,按厂商聚合(completed)收益(nUSD → USDT /1e9,镜像 `formatNusd`)+ 调用数,按收益倒序;镜像「模型明细」样式。未映射模型归「未知」。
- **周期联动**:沿用 `DashboardPeriod`(24h/7d/30d/累计)。

## Context

- 从 04 Fog「厂商汇总」毕业(模型明细 group by modelName 已落地;厂商汇总需 join)。
- 复用 04 的 `watchRecordsSince` + nUSD/1e9 换算。
- 实现草案:DAO `relayModelToVendorMap()`(quotation + vendor join)+ 纯函数 `computeVendorBreakdown(rows, map)` + `dashboardVendorBreakdownProvider`(async* 先取 map 再 map 行流)+ Dashboard 卡 + 单测。

## Answer

Dashboard 加「厂商明细」面板,完成 04 Done-list 的「厂商汇总」(从 Fog 毕业)。

**代码**:
- `lib/core/db/quotation_dao.dart` —— 加 `relayModelToVendorMap()`:`provider_quotation` join `provider_llm_vendor`(`providerId → vendorId`)→ `{relayModelName: vendorName}`;未绑 vendor(`providerId` null)排除。
- `lib/core/db/provider_log_dao.dart` —— 加 `VendorBreakdown` 模型 + 纯函数 `computeVendorBreakdown(rows, map)`:按厂商聚合 completed 收益/调用,未映射归「未知」,按收益倒序(同 `computeLlmMetrics` 口径:只计 completed)。
- `lib/core/providers.dart` —— `quotationDaoProvider` + `dashboardVendorBreakdownProvider`(`async*`:先取 map 再 map 行流;周期/provider 重建时重取映射)。
- `lib/features/dashboard/dashboard_screen.dart` —— 新 `_VendorBreakdownCard`(厂商 / 调用 / 收益 USDT,nUSD/1e9 镜像 `formatNusd`;前 8,按收益倒序),接在「模型明细」后。

**关键决策**:
1. **厂商映射经 quotation→vendor join**(provider_log 无 vendor 列);模型→厂商关系来自供应商配置的报价绑定。
2. **同口径**:收益/调用只计 `completed`(对齐 `computeLlmMetrics`);未映射模型归「未知」(不丢数据)。
3. **map 在 provider 内 `async*` 先取一次**:避免每个行变更都重查 join;周期变化 / provider 重建时重取(vendor CRUD 后 `reportProviderInfo` 会触发刷新,可接受)。

**测试**(+3 → 235):quotation `relayModelToVendorMap` join(未绑排除)+ `computeVendorBreakdown` 纯函数(按厂商聚合 / 未映射归未知 / 倒序 + 空 rows)+ Dashboard widget(厂商明细卡,`scrollUntilVisible` 至底部可见)。lib+test analyze 干净。

**Fog 更新**:厂商汇总已毕业;「告警[进阶](失败率 / 低余额)」仍在 Fog(数据齐,缺阈值 / 通道)。
