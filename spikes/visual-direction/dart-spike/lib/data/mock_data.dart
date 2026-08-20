import 'package:flutter/material.dart';

/// 供应商后台 Dashboard 的 mock 数据。3 个视觉方向共用同一份 ——
/// 让用户比较的是「呈现」,不是「内容」。领域术语见仓库 CONTEXT.md。

class ConnectionStatus {
  final bool connected;
  final String relayUrl;
  final int latencyMs;
  final String uptime;
  final String lastHeartbeat;
  const ConnectionStatus({
    required this.connected,
    required this.relayUrl,
    required this.latencyMs,
    required this.uptime,
    required this.lastHeartbeat,
  });
}

class VendorIdentity {
  final String address;
  final String shortAddr;
  final double balanceUsdt;
  final double pendingUsdt; // 待结算应收
  const VendorIdentity({
    required this.address,
    required this.shortAddr,
    required this.balanceUsdt,
    required this.pendingUsdt,
  });
}

class ModelRow {
  final String name;
  final String relayModel;
  final double inPricePer1k; // USDT / 1k tokens
  final double outPricePer1k;
  final bool stream;
  final int todayReqs;
  final int todayTokens;
  const ModelRow({
    required this.name,
    required this.relayModel,
    required this.inPricePer1k,
    required this.outPricePer1k,
    required this.stream,
    required this.todayReqs,
    required this.todayTokens,
  });
}

class RequestRow {
  final String time;
  final String model;
  final int tokensIn;
  final int tokensOut;
  final String status; // ok | error | cancelled
  final int latencyMs;
  final double costUsdt;
  const RequestRow({
    required this.time,
    required this.model,
    required this.tokensIn,
    required this.tokensOut,
    required this.status,
    required this.latencyMs,
    required this.costUsdt,
  });
}

class SettlementRow {
  final String epoch;
  final String blockTime;
  final double amountUsdt;
  final String txHash;
  final String status; // settled | pending
  const SettlementRow({
    required this.epoch,
    required this.blockTime,
    required this.amountUsdt,
    required this.txHash,
    required this.status,
  });
}

class Throughput {
  final double reqPerMin;
  final double tokensPerMin;
  final double successRate;
  final int p95LatencyMs;
  const Throughput({
    required this.reqPerMin,
    required this.tokensPerMin,
    required this.successRate,
    required this.p95LatencyMs,
  });
}

class DashboardData {
  final ConnectionStatus connection;
  final VendorIdentity vendor;
  final List<ModelRow> models;
  final List<RequestRow> recentRequests;
  final List<SettlementRow> settlements;
  final Throughput throughput;
  // 24h 请求量迷你序列(供 sparkline / 柱图用)
  final List<int> hourlyReqs;
  const DashboardData({
    required this.connection,
    required this.vendor,
    required this.models,
    required this.recentRequests,
    required this.settlements,
    required this.throughput,
    required this.hourlyReqs,
  });
}

const sampleData = DashboardData(
  connection: ConnectionStatus(
    connected: true,
    relayUrl: 'wss://relay.example:3003',
    latencyMs: 42,
    uptime: '3d 14h 07m',
    lastHeartbeat: '2s ago',
  ),
  vendor: VendorIdentity(
    address: '0x7A29bF4E3aC1...dD92',
    shortAddr: '0x7A29…dD92',
    balanceUsdt: 1284.55,
    pendingUsdt: 73.20,
  ),
  models: [
    ModelRow(
        name: 'GPT-4o',
        relayModel: 'gpt-4o',
        inPricePer1k: 2.5,
        outPricePer1k: 10.0,
        stream: true,
        todayReqs: 1820,
        todayTokens: 942000),
    ModelRow(
        name: 'Claude 3.5 Sonnet',
        relayModel: 'claude-3-5-sonnet',
        inPricePer1k: 3.0,
        outPricePer1k: 15.0,
        stream: true,
        todayReqs: 940,
        todayTokens: 410500),
    ModelRow(
        name: 'DeepSeek V3',
        relayModel: 'deepseek-chat',
        inPricePer1k: 0.14,
        outPricePer1k: 0.28,
        stream: true,
        todayReqs: 3120,
        todayTokens: 1280000),
    ModelRow(
        name: 'Gemini 1.5 Pro',
        relayModel: 'gemini-1.5-pro',
        inPricePer1k: 1.25,
        outPricePer1k: 5.0,
        stream: true,
        todayReqs: 610,
        todayTokens: 220400),
  ],
  recentRequests: [
    RequestRow(
        time: '14:32:18',
        model: 'gpt-4o',
        tokensIn: 1820,
        tokensOut: 640,
        status: 'ok',
        latencyMs: 1840,
        costUsdt: 0.011),
    RequestRow(
        time: '14:32:11',
        model: 'deepseek-chat',
        tokensIn: 940,
        tokensOut: 410,
        status: 'ok',
        latencyMs: 920,
        costUsdt: 0.0003),
    RequestRow(
        time: '14:31:59',
        model: 'claude-3-5-sonnet',
        tokensIn: 2210,
        tokensOut: 1180,
        status: 'ok',
        latencyMs: 2640,
        costUsdt: 0.024),
    RequestRow(
        time: '14:31:42',
        model: 'gpt-4o',
        tokensIn: 540,
        tokensOut: 0,
        status: 'error',
        latencyMs: 8300,
        costUsdt: 0.0),
    RequestRow(
        time: '14:31:30',
        model: 'gemini-1.5-pro',
        tokensIn: 1200,
        tokensOut: 530,
        status: 'ok',
        latencyMs: 1410,
        costUsdt: 0.004),
    RequestRow(
        time: '14:31:12',
        model: 'deepseek-chat',
        tokensIn: 760,
        tokensOut: 290,
        status: 'cancelled',
        latencyMs: 210,
        costUsdt: 0.0),
    RequestRow(
        time: '14:30:58',
        model: 'gpt-4o',
        tokensIn: 1610,
        tokensOut: 720,
        status: 'ok',
        latencyMs: 1720,
        costUsdt: 0.010),
  ],
  settlements: [
    SettlementRow(
        epoch: '#1284',
        blockTime: '2026-08-08 12:00',
        amountUsdt: 212.40,
        txHash: '0x9af3…b21c',
        status: 'settled'),
    SettlementRow(
        epoch: '#1283',
        blockTime: '2026-08-08 06:00',
        amountUsdt: 198.05,
        txHash: '0x4c1d…77e0',
        status: 'settled'),
    SettlementRow(
        epoch: '#1282',
        blockTime: '2026-08-08 00:00',
        amountUsdt: 73.20,
        txHash: '0x2b8e…0a44',
        status: 'pending'),
  ],
  throughput: Throughput(
    reqPerMin: 12.4,
    tokensPerMin: 6200,
    successRate: 99.6,
    p95LatencyMs: 2400,
  ),
  hourlyReqs: [4, 6, 5, 8, 12, 18, 22, 28, 31, 26, 24, 30, 35, 33, 29, 27, 31, 34, 30, 25, 21, 17, 12, 9],
);

/// 9 个功能页(provider-portal 对齐,见 07 范围)。供侧栏 / 底部导航用。
class NavEntry {
  final String label;
  final IconData icon;
  const NavEntry(this.label, this.icon);
}

const navEntries = [
  NavEntry('Dashboard', Icons.dashboard_outlined),
  NavEntry('Keypair', Icons.vpn_key_outlined),
  NavEntry('Wallet', Icons.account_balance_wallet_outlined),
  NavEntry('Models', Icons.tune_outlined),
  NavEntry('Providers', Icons.dns_outlined),
  NavEntry('Settlements', Icons.receipt_long_outlined),
  NavEntry('Records', Icons.list_alt_outlined),
  NavEntry('Settings', Icons.settings_outlined),
  NavEntry('Config', Icons.build_outlined), // 原 .env → 应用配置
];
