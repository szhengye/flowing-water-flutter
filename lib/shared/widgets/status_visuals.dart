import 'package:flutter/material.dart';

import 'package:flowing_water/core/chain/chain_watcher_service.dart';
import 'package:flowing_water/core/relay/node_service.dart';
import 'package:flowing_water/shared/design/app_colors.dart';

/// 节点 / 链监听状态 → (中文标签, 语义色) 的共享映射(04 抽出,供 AppShell pill
/// 与 Dashboard 健康卡共用,避免两处 6 态映射漂移)。

(String, Color) nodeStatusVisual(NodeStatus s) => switch (s) {
      NodeStatus.connected => ('已连接', AppColors.positive),
      NodeStatus.connecting => ('连接中…', AppColors.warn),
      NodeStatus.authenticating => ('鉴权中…', AppColors.warn),
      NodeStatus.reconnecting => ('重连中…', AppColors.warn),
      NodeStatus.failed => ('鉴权失败', AppColors.danger),
      NodeStatus.stopped => ('未连接', AppColors.textMuted),
    };

(String, Color) chainWatcherStatusVisual(ChainWatcherStatus s) => switch (s) {
      ChainWatcherStatus.running => ('监听中', AppColors.positive),
      ChainWatcherStatus.reconnecting => ('重连中…', AppColors.warn),
      ChainWatcherStatus.stopped => ('未监听', AppColors.textMuted),
      ChainWatcherStatus.disabled => ('未配置', AppColors.textMuted),
    };
