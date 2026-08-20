import 'package:flutter/material.dart';
import '../tokens/direction_tokens.dart';

/// 浮动变体切换器 —— UI.md 里 web「floating bottom bar」的 Flutter 等价物。
/// 底部居中、高对比胶囊,明显不属于被评估的设计本身。←/→ 切换 + 显示当前方向名。
class VariantSwitcher extends StatelessWidget {
  final List<DirTokens> dirs;
  final int index;
  final ValueChanged<int> onCycle; // 接收新 index(已 wrap)

  const VariantSwitcher({
    super.key,
    required this.dirs,
    required this.index,
    required this.onCycle,
  });

  @override
  Widget build(BuildContext context) {
    final current = dirs[index];
    return Positioned(
      left: 0,
      right: 0,
      bottom: 18,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 6)),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _arrow(Icons.chevron_left, () => onCycle((index - 1) % dirs.length)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${current.key} · ${current.name}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 1),
                Text(current.blurb,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
              ]),
            ),
            _arrow(Icons.chevron_right, () => onCycle((index + 1) % dirs.length)),
          ]),
        ),
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      );
}
