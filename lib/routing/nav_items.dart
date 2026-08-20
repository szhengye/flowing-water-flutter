import 'package:flutter/material.dart';

/// 侧栏导航项。顺序 = go_router StatefulShellRoute branches 顺序(用 index 切换)。
///
/// 对齐 web3-api provider-portal 侧栏;.env 配置页折叠进 Settings(app 无 .env)。
/// `milestone` 标注该页真实实现所属阶段(M1–M5),供 M0 占位页提示。
@immutable
class NavItem {
  final String label;
  final IconData icon;
  final String path;
  final String? milestone;
  const NavItem(this.label, this.icon, this.path, {this.milestone});
}

const appNavItems = <NavItem>[
  NavItem('Dashboard', Icons.dashboard_outlined, '/', milestone: 'M5'),
  NavItem('LLM 厂商', Icons.dns_outlined, '/providers', milestone: 'M3'),
  NavItem('模型报价', Icons.psychology_outlined, '/models', milestone: 'M3'),
  NavItem('中转流水', Icons.receipt_long_outlined, '/records', milestone: 'M5'),
  NavItem('链上结算', Icons.task_alt_outlined, '/settlements', milestone: 'M4'),
  NavItem('链上钱包', Icons.account_balance_wallet_outlined, '/wallet', milestone: 'M4'),
  NavItem('系统设置', Icons.settings_outlined, '/settings', milestone: 'M2'),
  NavItem('私钥管理', Icons.lock_outline, '/keypair', milestone: 'M1'),
];
