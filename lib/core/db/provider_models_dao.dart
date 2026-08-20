import 'package:drift/drift.dart';

import 'database.dart';

/// provider_models DAO —— 从 relay 同步下来的模型目录(02 sync-model-params)。
///
/// 这里的 `modelName` 是 **relay 规范模型名**(relay 的 `relay_models` 目录)——
/// 报价(`provider_quotation.relay_model_name`)必须**从此表选**,不能自造。
/// `provider_model`(厂商实际模型,如 llama-3.1-8b-instant)是固定值,属 vendor。
class ProviderModelsDao {
  ProviderModelsDao(this.db);
  final AppDatabase db;

  /// 把 relay 返回的 relay_models 行 upsert(覆盖)进 provider_models。
  /// 行字段蛇形(model_name / display_name / context_window / max_output_tokens /
  /// modality / prompt_price / completion_price),来自 relay;兼容驼峰。
  /// 返回写入行数(跳过无 model_name 的行)。
  Future<int> upsertAll(List<Map<String, dynamic>> rows) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var n = 0;
    for (final r in rows) {
      final name = (r['model_name'] ?? r['modelName']) as String?;
      if (name == null || name.isEmpty) continue;
      await db.into(db.providerModels).insert(
            ProviderModelsCompanion.insert(
              modelName: name,
              displayName: Value(_str(r, 'display_name', 'displayName')),
              description: Value(_str(r, 'description', 'description')),
              contextWindow: Value(_asInt(r, 'context_window', 'contextWindow')),
              maxOutputTokens:
                  Value(_asInt(r, 'max_output_tokens', 'maxOutputTokens')),
              modality: Value(_str(r, 'modality', 'modality')),
              promptPrice: Value(_asDouble(r, 'prompt_price', 'promptPrice')),
              completionPrice:
                  Value(_asDouble(r, 'completion_price', 'completionPrice')),
              updatedAt: Value(now),
            ),
            mode: InsertMode.insertOrReplace,
          );
      n++;
    }
    return n;
  }

  /// 列表(Models 页展示同步下来的 relay 目录;watch 自动刷新)。
  Stream<List<ProviderModelRow>> watchAll() =>
      (db.select(db.providerModels)
            ..orderBy([(t) => OrderingTerm.asc(t.modelName)]))
          .watch();

  Future<List<ProviderModelRow>> all() =>
      (db.select(db.providerModels)
            ..orderBy([(t) => OrderingTerm.asc(t.modelName)]))
          .get();

  String _str(Map<String, dynamic> r, String a, String b) {
    final v = r[a] ?? r[b];
    return v == null ? '' : v.toString();
  }

  int? _asInt(Map<String, dynamic> r, String a, String b) {
    final v = r[a] ?? r[b];
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  double? _asDouble(Map<String, dynamic> r, String a, String b) {
    final v = r[a] ?? r[b];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
