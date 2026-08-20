// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProviderLogsTable extends ProviderLogs
    with TableInfo<$ProviderLogsTable, ProviderLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _requestIdMeta = const VerificationMeta(
    'requestId',
  );
  @override
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
    'request_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelNameMeta = const VerificationMeta(
    'modelName',
  );
  @override
  late final GeneratedColumn<String> modelName = GeneratedColumn<String>(
    'model_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputTokensMeta = const VerificationMeta(
    'inputTokens',
  );
  @override
  late final GeneratedColumn<int> inputTokens = GeneratedColumn<int>(
    'input_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _outputTokensMeta = const VerificationMeta(
    'outputTokens',
  );
  @override
  late final GeneratedColumn<int> outputTokens = GeneratedColumn<int>(
    'output_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _processingStatusMeta = const VerificationMeta(
    'processingStatus',
  );
  @override
  late final GeneratedColumn<String> processingStatus = GeneratedColumn<String>(
    'processing_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _latencyMsMeta = const VerificationMeta(
    'latencyMs',
  );
  @override
  late final GeneratedColumn<int> latencyMs = GeneratedColumn<int>(
    'latency_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _chainStatusMeta = const VerificationMeta(
    'chainStatus',
  );
  @override
  late final GeneratedColumn<String> chainStatus = GeneratedColumn<String>(
    'chain_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('not_on_chain'),
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _anchorTxMeta = const VerificationMeta(
    'anchorTx',
  );
  @override
  late final GeneratedColumn<String> anchorTx = GeneratedColumn<String>(
    'anchor_tx',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _settleTxMeta = const VerificationMeta(
    'settleTx',
  );
  @override
  late final GeneratedColumn<String> settleTx = GeneratedColumn<String>(
    'settle_tx',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _settleFailedReasonMeta =
      const VerificationMeta('settleFailedReason');
  @override
  late final GeneratedColumn<String> settleFailedReason =
      GeneratedColumn<String>(
        'settle_failed_reason',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _logIndexMeta = const VerificationMeta(
    'logIndex',
  );
  @override
  late final GeneratedColumn<int> logIndex = GeneratedColumn<int>(
    'log_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _providerInputPriceMeta =
      const VerificationMeta('providerInputPrice');
  @override
  late final GeneratedColumn<int> providerInputPrice = GeneratedColumn<int>(
    'provider_input_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _providerOutputPriceMeta =
      const VerificationMeta('providerOutputPrice');
  @override
  late final GeneratedColumn<int> providerOutputPrice = GeneratedColumn<int>(
    'provider_output_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _relayInputTokenMeta = const VerificationMeta(
    'relayInputToken',
  );
  @override
  late final GeneratedColumn<String> relayInputToken = GeneratedColumn<String>(
    'relay_input_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relayOutputTokenMeta = const VerificationMeta(
    'relayOutputToken',
  );
  @override
  late final GeneratedColumn<String> relayOutputToken = GeneratedColumn<String>(
    'relay_output_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relayAmountMeta = const VerificationMeta(
    'relayAmount',
  );
  @override
  late final GeneratedColumn<int> relayAmount = GeneratedColumn<int>(
    'relay_amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relayProcessingStatusMeta =
      const VerificationMeta('relayProcessingStatus');
  @override
  late final GeneratedColumn<String> relayProcessingStatus =
      GeneratedColumn<String>(
        'relay_processing_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    requestId,
    modelName,
    inputTokens,
    outputTokens,
    amount,
    processingStatus,
    latencyMs,
    errorMessage,
    chainStatus,
    batchId,
    anchorTx,
    settleTx,
    settleFailedReason,
    logIndex,
    providerInputPrice,
    providerOutputPrice,
    relayInputToken,
    relayOutputToken,
    relayAmount,
    relayProcessingStatus,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('request_id')) {
      context.handle(
        _requestIdMeta,
        requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta),
      );
    } else if (isInserting) {
      context.missing(_requestIdMeta);
    }
    if (data.containsKey('model_name')) {
      context.handle(
        _modelNameMeta,
        modelName.isAcceptableOrUnknown(data['model_name']!, _modelNameMeta),
      );
    } else if (isInserting) {
      context.missing(_modelNameMeta);
    }
    if (data.containsKey('input_tokens')) {
      context.handle(
        _inputTokensMeta,
        inputTokens.isAcceptableOrUnknown(
          data['input_tokens']!,
          _inputTokensMeta,
        ),
      );
    }
    if (data.containsKey('output_tokens')) {
      context.handle(
        _outputTokensMeta,
        outputTokens.isAcceptableOrUnknown(
          data['output_tokens']!,
          _outputTokensMeta,
        ),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('processing_status')) {
      context.handle(
        _processingStatusMeta,
        processingStatus.isAcceptableOrUnknown(
          data['processing_status']!,
          _processingStatusMeta,
        ),
      );
    }
    if (data.containsKey('latency_ms')) {
      context.handle(
        _latencyMsMeta,
        latencyMs.isAcceptableOrUnknown(data['latency_ms']!, _latencyMsMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('chain_status')) {
      context.handle(
        _chainStatusMeta,
        chainStatus.isAcceptableOrUnknown(
          data['chain_status']!,
          _chainStatusMeta,
        ),
      );
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    }
    if (data.containsKey('anchor_tx')) {
      context.handle(
        _anchorTxMeta,
        anchorTx.isAcceptableOrUnknown(data['anchor_tx']!, _anchorTxMeta),
      );
    }
    if (data.containsKey('settle_tx')) {
      context.handle(
        _settleTxMeta,
        settleTx.isAcceptableOrUnknown(data['settle_tx']!, _settleTxMeta),
      );
    }
    if (data.containsKey('settle_failed_reason')) {
      context.handle(
        _settleFailedReasonMeta,
        settleFailedReason.isAcceptableOrUnknown(
          data['settle_failed_reason']!,
          _settleFailedReasonMeta,
        ),
      );
    }
    if (data.containsKey('log_index')) {
      context.handle(
        _logIndexMeta,
        logIndex.isAcceptableOrUnknown(data['log_index']!, _logIndexMeta),
      );
    }
    if (data.containsKey('provider_input_price')) {
      context.handle(
        _providerInputPriceMeta,
        providerInputPrice.isAcceptableOrUnknown(
          data['provider_input_price']!,
          _providerInputPriceMeta,
        ),
      );
    }
    if (data.containsKey('provider_output_price')) {
      context.handle(
        _providerOutputPriceMeta,
        providerOutputPrice.isAcceptableOrUnknown(
          data['provider_output_price']!,
          _providerOutputPriceMeta,
        ),
      );
    }
    if (data.containsKey('relay_input_token')) {
      context.handle(
        _relayInputTokenMeta,
        relayInputToken.isAcceptableOrUnknown(
          data['relay_input_token']!,
          _relayInputTokenMeta,
        ),
      );
    }
    if (data.containsKey('relay_output_token')) {
      context.handle(
        _relayOutputTokenMeta,
        relayOutputToken.isAcceptableOrUnknown(
          data['relay_output_token']!,
          _relayOutputTokenMeta,
        ),
      );
    }
    if (data.containsKey('relay_amount')) {
      context.handle(
        _relayAmountMeta,
        relayAmount.isAcceptableOrUnknown(
          data['relay_amount']!,
          _relayAmountMeta,
        ),
      );
    }
    if (data.containsKey('relay_processing_status')) {
      context.handle(
        _relayProcessingStatusMeta,
        relayProcessingStatus.isAcceptableOrUnknown(
          data['relay_processing_status']!,
          _relayProcessingStatusMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {requestId};
  @override
  ProviderLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderLogRow(
      requestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_id'],
      )!,
      modelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_name'],
      )!,
      inputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}input_tokens'],
      )!,
      outputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}output_tokens'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      processingStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}processing_status'],
      )!,
      latencyMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}latency_ms'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      )!,
      chainStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chain_status'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      ),
      anchorTx: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchor_tx'],
      ),
      settleTx: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settle_tx'],
      ),
      settleFailedReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settle_failed_reason'],
      ),
      logIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}log_index'],
      ),
      providerInputPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_input_price'],
      )!,
      providerOutputPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_output_price'],
      )!,
      relayInputToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relay_input_token'],
      ),
      relayOutputToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relay_output_token'],
      ),
      relayAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}relay_amount'],
      ),
      relayProcessingStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relay_processing_status'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProviderLogsTable createAlias(String alias) {
    return $ProviderLogsTable(attachedDatabase, alias);
  }
}

class ProviderLogRow extends DataClass implements Insertable<ProviderLogRow> {
  final String requestId;
  final String modelName;
  final int inputTokens;
  final int outputTokens;
  final int amount;
  final String processingStatus;
  final int latencyMs;
  final String errorMessage;
  final String chainStatus;
  final String? batchId;
  final String? anchorTx;
  final String? settleTx;
  final String? settleFailedReason;
  final int? logIndex;
  final int providerInputPrice;
  final int providerOutputPrice;
  final String? relayInputToken;
  final String? relayOutputToken;
  final int? relayAmount;
  final String? relayProcessingStatus;
  final int createdAt;
  const ProviderLogRow({
    required this.requestId,
    required this.modelName,
    required this.inputTokens,
    required this.outputTokens,
    required this.amount,
    required this.processingStatus,
    required this.latencyMs,
    required this.errorMessage,
    required this.chainStatus,
    this.batchId,
    this.anchorTx,
    this.settleTx,
    this.settleFailedReason,
    this.logIndex,
    required this.providerInputPrice,
    required this.providerOutputPrice,
    this.relayInputToken,
    this.relayOutputToken,
    this.relayAmount,
    this.relayProcessingStatus,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['request_id'] = Variable<String>(requestId);
    map['model_name'] = Variable<String>(modelName);
    map['input_tokens'] = Variable<int>(inputTokens);
    map['output_tokens'] = Variable<int>(outputTokens);
    map['amount'] = Variable<int>(amount);
    map['processing_status'] = Variable<String>(processingStatus);
    map['latency_ms'] = Variable<int>(latencyMs);
    map['error_message'] = Variable<String>(errorMessage);
    map['chain_status'] = Variable<String>(chainStatus);
    if (!nullToAbsent || batchId != null) {
      map['batch_id'] = Variable<String>(batchId);
    }
    if (!nullToAbsent || anchorTx != null) {
      map['anchor_tx'] = Variable<String>(anchorTx);
    }
    if (!nullToAbsent || settleTx != null) {
      map['settle_tx'] = Variable<String>(settleTx);
    }
    if (!nullToAbsent || settleFailedReason != null) {
      map['settle_failed_reason'] = Variable<String>(settleFailedReason);
    }
    if (!nullToAbsent || logIndex != null) {
      map['log_index'] = Variable<int>(logIndex);
    }
    map['provider_input_price'] = Variable<int>(providerInputPrice);
    map['provider_output_price'] = Variable<int>(providerOutputPrice);
    if (!nullToAbsent || relayInputToken != null) {
      map['relay_input_token'] = Variable<String>(relayInputToken);
    }
    if (!nullToAbsent || relayOutputToken != null) {
      map['relay_output_token'] = Variable<String>(relayOutputToken);
    }
    if (!nullToAbsent || relayAmount != null) {
      map['relay_amount'] = Variable<int>(relayAmount);
    }
    if (!nullToAbsent || relayProcessingStatus != null) {
      map['relay_processing_status'] = Variable<String>(relayProcessingStatus);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ProviderLogsCompanion toCompanion(bool nullToAbsent) {
    return ProviderLogsCompanion(
      requestId: Value(requestId),
      modelName: Value(modelName),
      inputTokens: Value(inputTokens),
      outputTokens: Value(outputTokens),
      amount: Value(amount),
      processingStatus: Value(processingStatus),
      latencyMs: Value(latencyMs),
      errorMessage: Value(errorMessage),
      chainStatus: Value(chainStatus),
      batchId: batchId == null && nullToAbsent
          ? const Value.absent()
          : Value(batchId),
      anchorTx: anchorTx == null && nullToAbsent
          ? const Value.absent()
          : Value(anchorTx),
      settleTx: settleTx == null && nullToAbsent
          ? const Value.absent()
          : Value(settleTx),
      settleFailedReason: settleFailedReason == null && nullToAbsent
          ? const Value.absent()
          : Value(settleFailedReason),
      logIndex: logIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(logIndex),
      providerInputPrice: Value(providerInputPrice),
      providerOutputPrice: Value(providerOutputPrice),
      relayInputToken: relayInputToken == null && nullToAbsent
          ? const Value.absent()
          : Value(relayInputToken),
      relayOutputToken: relayOutputToken == null && nullToAbsent
          ? const Value.absent()
          : Value(relayOutputToken),
      relayAmount: relayAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(relayAmount),
      relayProcessingStatus: relayProcessingStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(relayProcessingStatus),
      createdAt: Value(createdAt),
    );
  }

  factory ProviderLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderLogRow(
      requestId: serializer.fromJson<String>(json['requestId']),
      modelName: serializer.fromJson<String>(json['modelName']),
      inputTokens: serializer.fromJson<int>(json['inputTokens']),
      outputTokens: serializer.fromJson<int>(json['outputTokens']),
      amount: serializer.fromJson<int>(json['amount']),
      processingStatus: serializer.fromJson<String>(json['processingStatus']),
      latencyMs: serializer.fromJson<int>(json['latencyMs']),
      errorMessage: serializer.fromJson<String>(json['errorMessage']),
      chainStatus: serializer.fromJson<String>(json['chainStatus']),
      batchId: serializer.fromJson<String?>(json['batchId']),
      anchorTx: serializer.fromJson<String?>(json['anchorTx']),
      settleTx: serializer.fromJson<String?>(json['settleTx']),
      settleFailedReason: serializer.fromJson<String?>(
        json['settleFailedReason'],
      ),
      logIndex: serializer.fromJson<int?>(json['logIndex']),
      providerInputPrice: serializer.fromJson<int>(json['providerInputPrice']),
      providerOutputPrice: serializer.fromJson<int>(
        json['providerOutputPrice'],
      ),
      relayInputToken: serializer.fromJson<String?>(json['relayInputToken']),
      relayOutputToken: serializer.fromJson<String?>(json['relayOutputToken']),
      relayAmount: serializer.fromJson<int?>(json['relayAmount']),
      relayProcessingStatus: serializer.fromJson<String?>(
        json['relayProcessingStatus'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'requestId': serializer.toJson<String>(requestId),
      'modelName': serializer.toJson<String>(modelName),
      'inputTokens': serializer.toJson<int>(inputTokens),
      'outputTokens': serializer.toJson<int>(outputTokens),
      'amount': serializer.toJson<int>(amount),
      'processingStatus': serializer.toJson<String>(processingStatus),
      'latencyMs': serializer.toJson<int>(latencyMs),
      'errorMessage': serializer.toJson<String>(errorMessage),
      'chainStatus': serializer.toJson<String>(chainStatus),
      'batchId': serializer.toJson<String?>(batchId),
      'anchorTx': serializer.toJson<String?>(anchorTx),
      'settleTx': serializer.toJson<String?>(settleTx),
      'settleFailedReason': serializer.toJson<String?>(settleFailedReason),
      'logIndex': serializer.toJson<int?>(logIndex),
      'providerInputPrice': serializer.toJson<int>(providerInputPrice),
      'providerOutputPrice': serializer.toJson<int>(providerOutputPrice),
      'relayInputToken': serializer.toJson<String?>(relayInputToken),
      'relayOutputToken': serializer.toJson<String?>(relayOutputToken),
      'relayAmount': serializer.toJson<int?>(relayAmount),
      'relayProcessingStatus': serializer.toJson<String?>(
        relayProcessingStatus,
      ),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ProviderLogRow copyWith({
    String? requestId,
    String? modelName,
    int? inputTokens,
    int? outputTokens,
    int? amount,
    String? processingStatus,
    int? latencyMs,
    String? errorMessage,
    String? chainStatus,
    Value<String?> batchId = const Value.absent(),
    Value<String?> anchorTx = const Value.absent(),
    Value<String?> settleTx = const Value.absent(),
    Value<String?> settleFailedReason = const Value.absent(),
    Value<int?> logIndex = const Value.absent(),
    int? providerInputPrice,
    int? providerOutputPrice,
    Value<String?> relayInputToken = const Value.absent(),
    Value<String?> relayOutputToken = const Value.absent(),
    Value<int?> relayAmount = const Value.absent(),
    Value<String?> relayProcessingStatus = const Value.absent(),
    int? createdAt,
  }) => ProviderLogRow(
    requestId: requestId ?? this.requestId,
    modelName: modelName ?? this.modelName,
    inputTokens: inputTokens ?? this.inputTokens,
    outputTokens: outputTokens ?? this.outputTokens,
    amount: amount ?? this.amount,
    processingStatus: processingStatus ?? this.processingStatus,
    latencyMs: latencyMs ?? this.latencyMs,
    errorMessage: errorMessage ?? this.errorMessage,
    chainStatus: chainStatus ?? this.chainStatus,
    batchId: batchId.present ? batchId.value : this.batchId,
    anchorTx: anchorTx.present ? anchorTx.value : this.anchorTx,
    settleTx: settleTx.present ? settleTx.value : this.settleTx,
    settleFailedReason: settleFailedReason.present
        ? settleFailedReason.value
        : this.settleFailedReason,
    logIndex: logIndex.present ? logIndex.value : this.logIndex,
    providerInputPrice: providerInputPrice ?? this.providerInputPrice,
    providerOutputPrice: providerOutputPrice ?? this.providerOutputPrice,
    relayInputToken: relayInputToken.present
        ? relayInputToken.value
        : this.relayInputToken,
    relayOutputToken: relayOutputToken.present
        ? relayOutputToken.value
        : this.relayOutputToken,
    relayAmount: relayAmount.present ? relayAmount.value : this.relayAmount,
    relayProcessingStatus: relayProcessingStatus.present
        ? relayProcessingStatus.value
        : this.relayProcessingStatus,
    createdAt: createdAt ?? this.createdAt,
  );
  ProviderLogRow copyWithCompanion(ProviderLogsCompanion data) {
    return ProviderLogRow(
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
      modelName: data.modelName.present ? data.modelName.value : this.modelName,
      inputTokens: data.inputTokens.present
          ? data.inputTokens.value
          : this.inputTokens,
      outputTokens: data.outputTokens.present
          ? data.outputTokens.value
          : this.outputTokens,
      amount: data.amount.present ? data.amount.value : this.amount,
      processingStatus: data.processingStatus.present
          ? data.processingStatus.value
          : this.processingStatus,
      latencyMs: data.latencyMs.present ? data.latencyMs.value : this.latencyMs,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      chainStatus: data.chainStatus.present
          ? data.chainStatus.value
          : this.chainStatus,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      anchorTx: data.anchorTx.present ? data.anchorTx.value : this.anchorTx,
      settleTx: data.settleTx.present ? data.settleTx.value : this.settleTx,
      settleFailedReason: data.settleFailedReason.present
          ? data.settleFailedReason.value
          : this.settleFailedReason,
      logIndex: data.logIndex.present ? data.logIndex.value : this.logIndex,
      providerInputPrice: data.providerInputPrice.present
          ? data.providerInputPrice.value
          : this.providerInputPrice,
      providerOutputPrice: data.providerOutputPrice.present
          ? data.providerOutputPrice.value
          : this.providerOutputPrice,
      relayInputToken: data.relayInputToken.present
          ? data.relayInputToken.value
          : this.relayInputToken,
      relayOutputToken: data.relayOutputToken.present
          ? data.relayOutputToken.value
          : this.relayOutputToken,
      relayAmount: data.relayAmount.present
          ? data.relayAmount.value
          : this.relayAmount,
      relayProcessingStatus: data.relayProcessingStatus.present
          ? data.relayProcessingStatus.value
          : this.relayProcessingStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderLogRow(')
          ..write('requestId: $requestId, ')
          ..write('modelName: $modelName, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('amount: $amount, ')
          ..write('processingStatus: $processingStatus, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('chainStatus: $chainStatus, ')
          ..write('batchId: $batchId, ')
          ..write('anchorTx: $anchorTx, ')
          ..write('settleTx: $settleTx, ')
          ..write('settleFailedReason: $settleFailedReason, ')
          ..write('logIndex: $logIndex, ')
          ..write('providerInputPrice: $providerInputPrice, ')
          ..write('providerOutputPrice: $providerOutputPrice, ')
          ..write('relayInputToken: $relayInputToken, ')
          ..write('relayOutputToken: $relayOutputToken, ')
          ..write('relayAmount: $relayAmount, ')
          ..write('relayProcessingStatus: $relayProcessingStatus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    requestId,
    modelName,
    inputTokens,
    outputTokens,
    amount,
    processingStatus,
    latencyMs,
    errorMessage,
    chainStatus,
    batchId,
    anchorTx,
    settleTx,
    settleFailedReason,
    logIndex,
    providerInputPrice,
    providerOutputPrice,
    relayInputToken,
    relayOutputToken,
    relayAmount,
    relayProcessingStatus,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderLogRow &&
          other.requestId == this.requestId &&
          other.modelName == this.modelName &&
          other.inputTokens == this.inputTokens &&
          other.outputTokens == this.outputTokens &&
          other.amount == this.amount &&
          other.processingStatus == this.processingStatus &&
          other.latencyMs == this.latencyMs &&
          other.errorMessage == this.errorMessage &&
          other.chainStatus == this.chainStatus &&
          other.batchId == this.batchId &&
          other.anchorTx == this.anchorTx &&
          other.settleTx == this.settleTx &&
          other.settleFailedReason == this.settleFailedReason &&
          other.logIndex == this.logIndex &&
          other.providerInputPrice == this.providerInputPrice &&
          other.providerOutputPrice == this.providerOutputPrice &&
          other.relayInputToken == this.relayInputToken &&
          other.relayOutputToken == this.relayOutputToken &&
          other.relayAmount == this.relayAmount &&
          other.relayProcessingStatus == this.relayProcessingStatus &&
          other.createdAt == this.createdAt);
}

class ProviderLogsCompanion extends UpdateCompanion<ProviderLogRow> {
  final Value<String> requestId;
  final Value<String> modelName;
  final Value<int> inputTokens;
  final Value<int> outputTokens;
  final Value<int> amount;
  final Value<String> processingStatus;
  final Value<int> latencyMs;
  final Value<String> errorMessage;
  final Value<String> chainStatus;
  final Value<String?> batchId;
  final Value<String?> anchorTx;
  final Value<String?> settleTx;
  final Value<String?> settleFailedReason;
  final Value<int?> logIndex;
  final Value<int> providerInputPrice;
  final Value<int> providerOutputPrice;
  final Value<String?> relayInputToken;
  final Value<String?> relayOutputToken;
  final Value<int?> relayAmount;
  final Value<String?> relayProcessingStatus;
  final Value<int> createdAt;
  final Value<int> rowid;
  const ProviderLogsCompanion({
    this.requestId = const Value.absent(),
    this.modelName = const Value.absent(),
    this.inputTokens = const Value.absent(),
    this.outputTokens = const Value.absent(),
    this.amount = const Value.absent(),
    this.processingStatus = const Value.absent(),
    this.latencyMs = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.chainStatus = const Value.absent(),
    this.batchId = const Value.absent(),
    this.anchorTx = const Value.absent(),
    this.settleTx = const Value.absent(),
    this.settleFailedReason = const Value.absent(),
    this.logIndex = const Value.absent(),
    this.providerInputPrice = const Value.absent(),
    this.providerOutputPrice = const Value.absent(),
    this.relayInputToken = const Value.absent(),
    this.relayOutputToken = const Value.absent(),
    this.relayAmount = const Value.absent(),
    this.relayProcessingStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProviderLogsCompanion.insert({
    required String requestId,
    required String modelName,
    this.inputTokens = const Value.absent(),
    this.outputTokens = const Value.absent(),
    this.amount = const Value.absent(),
    this.processingStatus = const Value.absent(),
    this.latencyMs = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.chainStatus = const Value.absent(),
    this.batchId = const Value.absent(),
    this.anchorTx = const Value.absent(),
    this.settleTx = const Value.absent(),
    this.settleFailedReason = const Value.absent(),
    this.logIndex = const Value.absent(),
    this.providerInputPrice = const Value.absent(),
    this.providerOutputPrice = const Value.absent(),
    this.relayInputToken = const Value.absent(),
    this.relayOutputToken = const Value.absent(),
    this.relayAmount = const Value.absent(),
    this.relayProcessingStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : requestId = Value(requestId),
       modelName = Value(modelName);
  static Insertable<ProviderLogRow> custom({
    Expression<String>? requestId,
    Expression<String>? modelName,
    Expression<int>? inputTokens,
    Expression<int>? outputTokens,
    Expression<int>? amount,
    Expression<String>? processingStatus,
    Expression<int>? latencyMs,
    Expression<String>? errorMessage,
    Expression<String>? chainStatus,
    Expression<String>? batchId,
    Expression<String>? anchorTx,
    Expression<String>? settleTx,
    Expression<String>? settleFailedReason,
    Expression<int>? logIndex,
    Expression<int>? providerInputPrice,
    Expression<int>? providerOutputPrice,
    Expression<String>? relayInputToken,
    Expression<String>? relayOutputToken,
    Expression<int>? relayAmount,
    Expression<String>? relayProcessingStatus,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (requestId != null) 'request_id': requestId,
      if (modelName != null) 'model_name': modelName,
      if (inputTokens != null) 'input_tokens': inputTokens,
      if (outputTokens != null) 'output_tokens': outputTokens,
      if (amount != null) 'amount': amount,
      if (processingStatus != null) 'processing_status': processingStatus,
      if (latencyMs != null) 'latency_ms': latencyMs,
      if (errorMessage != null) 'error_message': errorMessage,
      if (chainStatus != null) 'chain_status': chainStatus,
      if (batchId != null) 'batch_id': batchId,
      if (anchorTx != null) 'anchor_tx': anchorTx,
      if (settleTx != null) 'settle_tx': settleTx,
      if (settleFailedReason != null)
        'settle_failed_reason': settleFailedReason,
      if (logIndex != null) 'log_index': logIndex,
      if (providerInputPrice != null)
        'provider_input_price': providerInputPrice,
      if (providerOutputPrice != null)
        'provider_output_price': providerOutputPrice,
      if (relayInputToken != null) 'relay_input_token': relayInputToken,
      if (relayOutputToken != null) 'relay_output_token': relayOutputToken,
      if (relayAmount != null) 'relay_amount': relayAmount,
      if (relayProcessingStatus != null)
        'relay_processing_status': relayProcessingStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProviderLogsCompanion copyWith({
    Value<String>? requestId,
    Value<String>? modelName,
    Value<int>? inputTokens,
    Value<int>? outputTokens,
    Value<int>? amount,
    Value<String>? processingStatus,
    Value<int>? latencyMs,
    Value<String>? errorMessage,
    Value<String>? chainStatus,
    Value<String?>? batchId,
    Value<String?>? anchorTx,
    Value<String?>? settleTx,
    Value<String?>? settleFailedReason,
    Value<int?>? logIndex,
    Value<int>? providerInputPrice,
    Value<int>? providerOutputPrice,
    Value<String?>? relayInputToken,
    Value<String?>? relayOutputToken,
    Value<int?>? relayAmount,
    Value<String?>? relayProcessingStatus,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return ProviderLogsCompanion(
      requestId: requestId ?? this.requestId,
      modelName: modelName ?? this.modelName,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      amount: amount ?? this.amount,
      processingStatus: processingStatus ?? this.processingStatus,
      latencyMs: latencyMs ?? this.latencyMs,
      errorMessage: errorMessage ?? this.errorMessage,
      chainStatus: chainStatus ?? this.chainStatus,
      batchId: batchId ?? this.batchId,
      anchorTx: anchorTx ?? this.anchorTx,
      settleTx: settleTx ?? this.settleTx,
      settleFailedReason: settleFailedReason ?? this.settleFailedReason,
      logIndex: logIndex ?? this.logIndex,
      providerInputPrice: providerInputPrice ?? this.providerInputPrice,
      providerOutputPrice: providerOutputPrice ?? this.providerOutputPrice,
      relayInputToken: relayInputToken ?? this.relayInputToken,
      relayOutputToken: relayOutputToken ?? this.relayOutputToken,
      relayAmount: relayAmount ?? this.relayAmount,
      relayProcessingStatus:
          relayProcessingStatus ?? this.relayProcessingStatus,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
    }
    if (modelName.present) {
      map['model_name'] = Variable<String>(modelName.value);
    }
    if (inputTokens.present) {
      map['input_tokens'] = Variable<int>(inputTokens.value);
    }
    if (outputTokens.present) {
      map['output_tokens'] = Variable<int>(outputTokens.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (processingStatus.present) {
      map['processing_status'] = Variable<String>(processingStatus.value);
    }
    if (latencyMs.present) {
      map['latency_ms'] = Variable<int>(latencyMs.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (chainStatus.present) {
      map['chain_status'] = Variable<String>(chainStatus.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (anchorTx.present) {
      map['anchor_tx'] = Variable<String>(anchorTx.value);
    }
    if (settleTx.present) {
      map['settle_tx'] = Variable<String>(settleTx.value);
    }
    if (settleFailedReason.present) {
      map['settle_failed_reason'] = Variable<String>(settleFailedReason.value);
    }
    if (logIndex.present) {
      map['log_index'] = Variable<int>(logIndex.value);
    }
    if (providerInputPrice.present) {
      map['provider_input_price'] = Variable<int>(providerInputPrice.value);
    }
    if (providerOutputPrice.present) {
      map['provider_output_price'] = Variable<int>(providerOutputPrice.value);
    }
    if (relayInputToken.present) {
      map['relay_input_token'] = Variable<String>(relayInputToken.value);
    }
    if (relayOutputToken.present) {
      map['relay_output_token'] = Variable<String>(relayOutputToken.value);
    }
    if (relayAmount.present) {
      map['relay_amount'] = Variable<int>(relayAmount.value);
    }
    if (relayProcessingStatus.present) {
      map['relay_processing_status'] = Variable<String>(
        relayProcessingStatus.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderLogsCompanion(')
          ..write('requestId: $requestId, ')
          ..write('modelName: $modelName, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('amount: $amount, ')
          ..write('processingStatus: $processingStatus, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('chainStatus: $chainStatus, ')
          ..write('batchId: $batchId, ')
          ..write('anchorTx: $anchorTx, ')
          ..write('settleTx: $settleTx, ')
          ..write('settleFailedReason: $settleFailedReason, ')
          ..write('logIndex: $logIndex, ')
          ..write('providerInputPrice: $providerInputPrice, ')
          ..write('providerOutputPrice: $providerOutputPrice, ')
          ..write('relayInputToken: $relayInputToken, ')
          ..write('relayOutputToken: $relayOutputToken, ')
          ..write('relayAmount: $relayAmount, ')
          ..write('relayProcessingStatus: $relayProcessingStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProviderLlmVendorsTable extends ProviderLlmVendors
    with TableInfo<$ProviderLlmVendorsTable, ProviderLlmVendorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderLlmVendorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _vendorIdMeta = const VerificationMeta(
    'vendorId',
  );
  @override
  late final GeneratedColumn<int> vendorId = GeneratedColumn<int>(
    'vendor_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _vendorNameMeta = const VerificationMeta(
    'vendorName',
  );
  @override
  late final GeneratedColumn<String> vendorName = GeneratedColumn<String>(
    'vendor_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endpointMeta = const VerificationMeta(
    'endpoint',
  );
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
    'endpoint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _apiKeyMeta = const VerificationMeta('apiKey');
  @override
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
    'api_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vendorModelsMeta = const VerificationMeta(
    'vendorModels',
  );
  @override
  late final GeneratedColumn<String> vendorModels = GeneratedColumn<String>(
    'vendor_models',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _adapterTypeMeta = const VerificationMeta(
    'adapterType',
  );
  @override
  late final GeneratedColumn<String> adapterType = GeneratedColumn<String>(
    'adapter_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('openai'),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _supportsStreamMeta = const VerificationMeta(
    'supportsStream',
  );
  @override
  late final GeneratedColumn<bool> supportsStream = GeneratedColumn<bool>(
    'supports_stream',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("supports_stream" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    vendorId,
    vendorName,
    endpoint,
    apiKey,
    vendorModels,
    adapterType,
    isActive,
    supportsStream,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_llm_vendor';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderLlmVendorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('vendor_id')) {
      context.handle(
        _vendorIdMeta,
        vendorId.isAcceptableOrUnknown(data['vendor_id']!, _vendorIdMeta),
      );
    }
    if (data.containsKey('vendor_name')) {
      context.handle(
        _vendorNameMeta,
        vendorName.isAcceptableOrUnknown(data['vendor_name']!, _vendorNameMeta),
      );
    } else if (isInserting) {
      context.missing(_vendorNameMeta);
    }
    if (data.containsKey('endpoint')) {
      context.handle(
        _endpointMeta,
        endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta),
      );
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('api_key')) {
      context.handle(
        _apiKeyMeta,
        apiKey.isAcceptableOrUnknown(data['api_key']!, _apiKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_apiKeyMeta);
    }
    if (data.containsKey('vendor_models')) {
      context.handle(
        _vendorModelsMeta,
        vendorModels.isAcceptableOrUnknown(
          data['vendor_models']!,
          _vendorModelsMeta,
        ),
      );
    }
    if (data.containsKey('adapter_type')) {
      context.handle(
        _adapterTypeMeta,
        adapterType.isAcceptableOrUnknown(
          data['adapter_type']!,
          _adapterTypeMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('supports_stream')) {
      context.handle(
        _supportsStreamMeta,
        supportsStream.isAcceptableOrUnknown(
          data['supports_stream']!,
          _supportsStreamMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {vendorId};
  @override
  ProviderLlmVendorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderLlmVendorRow(
      vendorId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vendor_id'],
      )!,
      vendorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor_name'],
      )!,
      endpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint'],
      )!,
      apiKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}api_key'],
      )!,
      vendorModels: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor_models'],
      )!,
      adapterType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adapter_type'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      supportsStream: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}supports_stream'],
      )!,
    );
  }

  @override
  $ProviderLlmVendorsTable createAlias(String alias) {
    return $ProviderLlmVendorsTable(attachedDatabase, alias);
  }
}

class ProviderLlmVendorRow extends DataClass
    implements Insertable<ProviderLlmVendorRow> {
  final int vendorId;
  final String vendorName;
  final String endpoint;
  final String apiKey;
  final String vendorModels;
  final String adapterType;
  final bool isActive;
  final bool supportsStream;
  const ProviderLlmVendorRow({
    required this.vendorId,
    required this.vendorName,
    required this.endpoint,
    required this.apiKey,
    required this.vendorModels,
    required this.adapterType,
    required this.isActive,
    required this.supportsStream,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['vendor_id'] = Variable<int>(vendorId);
    map['vendor_name'] = Variable<String>(vendorName);
    map['endpoint'] = Variable<String>(endpoint);
    map['api_key'] = Variable<String>(apiKey);
    map['vendor_models'] = Variable<String>(vendorModels);
    map['adapter_type'] = Variable<String>(adapterType);
    map['is_active'] = Variable<bool>(isActive);
    map['supports_stream'] = Variable<bool>(supportsStream);
    return map;
  }

  ProviderLlmVendorsCompanion toCompanion(bool nullToAbsent) {
    return ProviderLlmVendorsCompanion(
      vendorId: Value(vendorId),
      vendorName: Value(vendorName),
      endpoint: Value(endpoint),
      apiKey: Value(apiKey),
      vendorModels: Value(vendorModels),
      adapterType: Value(adapterType),
      isActive: Value(isActive),
      supportsStream: Value(supportsStream),
    );
  }

  factory ProviderLlmVendorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderLlmVendorRow(
      vendorId: serializer.fromJson<int>(json['vendorId']),
      vendorName: serializer.fromJson<String>(json['vendorName']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      apiKey: serializer.fromJson<String>(json['apiKey']),
      vendorModels: serializer.fromJson<String>(json['vendorModels']),
      adapterType: serializer.fromJson<String>(json['adapterType']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      supportsStream: serializer.fromJson<bool>(json['supportsStream']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'vendorId': serializer.toJson<int>(vendorId),
      'vendorName': serializer.toJson<String>(vendorName),
      'endpoint': serializer.toJson<String>(endpoint),
      'apiKey': serializer.toJson<String>(apiKey),
      'vendorModels': serializer.toJson<String>(vendorModels),
      'adapterType': serializer.toJson<String>(adapterType),
      'isActive': serializer.toJson<bool>(isActive),
      'supportsStream': serializer.toJson<bool>(supportsStream),
    };
  }

  ProviderLlmVendorRow copyWith({
    int? vendorId,
    String? vendorName,
    String? endpoint,
    String? apiKey,
    String? vendorModels,
    String? adapterType,
    bool? isActive,
    bool? supportsStream,
  }) => ProviderLlmVendorRow(
    vendorId: vendorId ?? this.vendorId,
    vendorName: vendorName ?? this.vendorName,
    endpoint: endpoint ?? this.endpoint,
    apiKey: apiKey ?? this.apiKey,
    vendorModels: vendorModels ?? this.vendorModels,
    adapterType: adapterType ?? this.adapterType,
    isActive: isActive ?? this.isActive,
    supportsStream: supportsStream ?? this.supportsStream,
  );
  ProviderLlmVendorRow copyWithCompanion(ProviderLlmVendorsCompanion data) {
    return ProviderLlmVendorRow(
      vendorId: data.vendorId.present ? data.vendorId.value : this.vendorId,
      vendorName: data.vendorName.present
          ? data.vendorName.value
          : this.vendorName,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      apiKey: data.apiKey.present ? data.apiKey.value : this.apiKey,
      vendorModels: data.vendorModels.present
          ? data.vendorModels.value
          : this.vendorModels,
      adapterType: data.adapterType.present
          ? data.adapterType.value
          : this.adapterType,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      supportsStream: data.supportsStream.present
          ? data.supportsStream.value
          : this.supportsStream,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderLlmVendorRow(')
          ..write('vendorId: $vendorId, ')
          ..write('vendorName: $vendorName, ')
          ..write('endpoint: $endpoint, ')
          ..write('apiKey: $apiKey, ')
          ..write('vendorModels: $vendorModels, ')
          ..write('adapterType: $adapterType, ')
          ..write('isActive: $isActive, ')
          ..write('supportsStream: $supportsStream')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    vendorId,
    vendorName,
    endpoint,
    apiKey,
    vendorModels,
    adapterType,
    isActive,
    supportsStream,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderLlmVendorRow &&
          other.vendorId == this.vendorId &&
          other.vendorName == this.vendorName &&
          other.endpoint == this.endpoint &&
          other.apiKey == this.apiKey &&
          other.vendorModels == this.vendorModels &&
          other.adapterType == this.adapterType &&
          other.isActive == this.isActive &&
          other.supportsStream == this.supportsStream);
}

class ProviderLlmVendorsCompanion
    extends UpdateCompanion<ProviderLlmVendorRow> {
  final Value<int> vendorId;
  final Value<String> vendorName;
  final Value<String> endpoint;
  final Value<String> apiKey;
  final Value<String> vendorModels;
  final Value<String> adapterType;
  final Value<bool> isActive;
  final Value<bool> supportsStream;
  const ProviderLlmVendorsCompanion({
    this.vendorId = const Value.absent(),
    this.vendorName = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.vendorModels = const Value.absent(),
    this.adapterType = const Value.absent(),
    this.isActive = const Value.absent(),
    this.supportsStream = const Value.absent(),
  });
  ProviderLlmVendorsCompanion.insert({
    this.vendorId = const Value.absent(),
    required String vendorName,
    required String endpoint,
    required String apiKey,
    this.vendorModels = const Value.absent(),
    this.adapterType = const Value.absent(),
    this.isActive = const Value.absent(),
    this.supportsStream = const Value.absent(),
  }) : vendorName = Value(vendorName),
       endpoint = Value(endpoint),
       apiKey = Value(apiKey);
  static Insertable<ProviderLlmVendorRow> custom({
    Expression<int>? vendorId,
    Expression<String>? vendorName,
    Expression<String>? endpoint,
    Expression<String>? apiKey,
    Expression<String>? vendorModels,
    Expression<String>? adapterType,
    Expression<bool>? isActive,
    Expression<bool>? supportsStream,
  }) {
    return RawValuesInsertable({
      if (vendorId != null) 'vendor_id': vendorId,
      if (vendorName != null) 'vendor_name': vendorName,
      if (endpoint != null) 'endpoint': endpoint,
      if (apiKey != null) 'api_key': apiKey,
      if (vendorModels != null) 'vendor_models': vendorModels,
      if (adapterType != null) 'adapter_type': adapterType,
      if (isActive != null) 'is_active': isActive,
      if (supportsStream != null) 'supports_stream': supportsStream,
    });
  }

  ProviderLlmVendorsCompanion copyWith({
    Value<int>? vendorId,
    Value<String>? vendorName,
    Value<String>? endpoint,
    Value<String>? apiKey,
    Value<String>? vendorModels,
    Value<String>? adapterType,
    Value<bool>? isActive,
    Value<bool>? supportsStream,
  }) {
    return ProviderLlmVendorsCompanion(
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      endpoint: endpoint ?? this.endpoint,
      apiKey: apiKey ?? this.apiKey,
      vendorModels: vendorModels ?? this.vendorModels,
      adapterType: adapterType ?? this.adapterType,
      isActive: isActive ?? this.isActive,
      supportsStream: supportsStream ?? this.supportsStream,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (vendorId.present) {
      map['vendor_id'] = Variable<int>(vendorId.value);
    }
    if (vendorName.present) {
      map['vendor_name'] = Variable<String>(vendorName.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (apiKey.present) {
      map['api_key'] = Variable<String>(apiKey.value);
    }
    if (vendorModels.present) {
      map['vendor_models'] = Variable<String>(vendorModels.value);
    }
    if (adapterType.present) {
      map['adapter_type'] = Variable<String>(adapterType.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (supportsStream.present) {
      map['supports_stream'] = Variable<bool>(supportsStream.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderLlmVendorsCompanion(')
          ..write('vendorId: $vendorId, ')
          ..write('vendorName: $vendorName, ')
          ..write('endpoint: $endpoint, ')
          ..write('apiKey: $apiKey, ')
          ..write('vendorModels: $vendorModels, ')
          ..write('adapterType: $adapterType, ')
          ..write('isActive: $isActive, ')
          ..write('supportsStream: $supportsStream')
          ..write(')'))
        .toString();
  }
}

class $ProviderQuotationsTable extends ProviderQuotations
    with TableInfo<$ProviderQuotationsTable, ProviderQuotationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderQuotationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _relayModelNameMeta = const VerificationMeta(
    'relayModelName',
  );
  @override
  late final GeneratedColumn<String> relayModelName = GeneratedColumn<String>(
    'relay_model_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<int> providerId = GeneratedColumn<int>(
    'provider_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _providerModelMeta = const VerificationMeta(
    'providerModel',
  );
  @override
  late final GeneratedColumn<String> providerModel = GeneratedColumn<String>(
    'provider_model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inputPricePer1kMeta = const VerificationMeta(
    'inputPricePer1k',
  );
  @override
  late final GeneratedColumn<int> inputPricePer1k = GeneratedColumn<int>(
    'input_price_per1k',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _outputPricePer1kMeta = const VerificationMeta(
    'outputPricePer1k',
  );
  @override
  late final GeneratedColumn<int> outputPricePer1k = GeneratedColumn<int>(
    'output_price_per1k',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _submittedAtMeta = const VerificationMeta(
    'submittedAt',
  );
  @override
  late final GeneratedColumn<int> submittedAt = GeneratedColumn<int>(
    'submitted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    relayModelName,
    providerId,
    providerModel,
    inputPricePer1k,
    outputPricePer1k,
    submittedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_quotation';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderQuotationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('relay_model_name')) {
      context.handle(
        _relayModelNameMeta,
        relayModelName.isAcceptableOrUnknown(
          data['relay_model_name']!,
          _relayModelNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relayModelNameMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    }
    if (data.containsKey('provider_model')) {
      context.handle(
        _providerModelMeta,
        providerModel.isAcceptableOrUnknown(
          data['provider_model']!,
          _providerModelMeta,
        ),
      );
    }
    if (data.containsKey('input_price_per1k')) {
      context.handle(
        _inputPricePer1kMeta,
        inputPricePer1k.isAcceptableOrUnknown(
          data['input_price_per1k']!,
          _inputPricePer1kMeta,
        ),
      );
    }
    if (data.containsKey('output_price_per1k')) {
      context.handle(
        _outputPricePer1kMeta,
        outputPricePer1k.isAcceptableOrUnknown(
          data['output_price_per1k']!,
          _outputPricePer1kMeta,
        ),
      );
    }
    if (data.containsKey('submitted_at')) {
      context.handle(
        _submittedAtMeta,
        submittedAt.isAcceptableOrUnknown(
          data['submitted_at']!,
          _submittedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {relayModelName};
  @override
  ProviderQuotationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderQuotationRow(
      relayModelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relay_model_name'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_id'],
      ),
      providerModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_model'],
      ),
      inputPricePer1k: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}input_price_per1k'],
      )!,
      outputPricePer1k: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}output_price_per1k'],
      )!,
      submittedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}submitted_at'],
      ),
    );
  }

  @override
  $ProviderQuotationsTable createAlias(String alias) {
    return $ProviderQuotationsTable(attachedDatabase, alias);
  }
}

class ProviderQuotationRow extends DataClass
    implements Insertable<ProviderQuotationRow> {
  final String relayModelName;
  final int? providerId;
  final String? providerModel;
  final int inputPricePer1k;
  final int outputPricePer1k;
  final int? submittedAt;
  const ProviderQuotationRow({
    required this.relayModelName,
    this.providerId,
    this.providerModel,
    required this.inputPricePer1k,
    required this.outputPricePer1k,
    this.submittedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['relay_model_name'] = Variable<String>(relayModelName);
    if (!nullToAbsent || providerId != null) {
      map['provider_id'] = Variable<int>(providerId);
    }
    if (!nullToAbsent || providerModel != null) {
      map['provider_model'] = Variable<String>(providerModel);
    }
    map['input_price_per1k'] = Variable<int>(inputPricePer1k);
    map['output_price_per1k'] = Variable<int>(outputPricePer1k);
    if (!nullToAbsent || submittedAt != null) {
      map['submitted_at'] = Variable<int>(submittedAt);
    }
    return map;
  }

  ProviderQuotationsCompanion toCompanion(bool nullToAbsent) {
    return ProviderQuotationsCompanion(
      relayModelName: Value(relayModelName),
      providerId: providerId == null && nullToAbsent
          ? const Value.absent()
          : Value(providerId),
      providerModel: providerModel == null && nullToAbsent
          ? const Value.absent()
          : Value(providerModel),
      inputPricePer1k: Value(inputPricePer1k),
      outputPricePer1k: Value(outputPricePer1k),
      submittedAt: submittedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(submittedAt),
    );
  }

  factory ProviderQuotationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderQuotationRow(
      relayModelName: serializer.fromJson<String>(json['relayModelName']),
      providerId: serializer.fromJson<int?>(json['providerId']),
      providerModel: serializer.fromJson<String?>(json['providerModel']),
      inputPricePer1k: serializer.fromJson<int>(json['inputPricePer1k']),
      outputPricePer1k: serializer.fromJson<int>(json['outputPricePer1k']),
      submittedAt: serializer.fromJson<int?>(json['submittedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'relayModelName': serializer.toJson<String>(relayModelName),
      'providerId': serializer.toJson<int?>(providerId),
      'providerModel': serializer.toJson<String?>(providerModel),
      'inputPricePer1k': serializer.toJson<int>(inputPricePer1k),
      'outputPricePer1k': serializer.toJson<int>(outputPricePer1k),
      'submittedAt': serializer.toJson<int?>(submittedAt),
    };
  }

  ProviderQuotationRow copyWith({
    String? relayModelName,
    Value<int?> providerId = const Value.absent(),
    Value<String?> providerModel = const Value.absent(),
    int? inputPricePer1k,
    int? outputPricePer1k,
    Value<int?> submittedAt = const Value.absent(),
  }) => ProviderQuotationRow(
    relayModelName: relayModelName ?? this.relayModelName,
    providerId: providerId.present ? providerId.value : this.providerId,
    providerModel: providerModel.present
        ? providerModel.value
        : this.providerModel,
    inputPricePer1k: inputPricePer1k ?? this.inputPricePer1k,
    outputPricePer1k: outputPricePer1k ?? this.outputPricePer1k,
    submittedAt: submittedAt.present ? submittedAt.value : this.submittedAt,
  );
  ProviderQuotationRow copyWithCompanion(ProviderQuotationsCompanion data) {
    return ProviderQuotationRow(
      relayModelName: data.relayModelName.present
          ? data.relayModelName.value
          : this.relayModelName,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      providerModel: data.providerModel.present
          ? data.providerModel.value
          : this.providerModel,
      inputPricePer1k: data.inputPricePer1k.present
          ? data.inputPricePer1k.value
          : this.inputPricePer1k,
      outputPricePer1k: data.outputPricePer1k.present
          ? data.outputPricePer1k.value
          : this.outputPricePer1k,
      submittedAt: data.submittedAt.present
          ? data.submittedAt.value
          : this.submittedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderQuotationRow(')
          ..write('relayModelName: $relayModelName, ')
          ..write('providerId: $providerId, ')
          ..write('providerModel: $providerModel, ')
          ..write('inputPricePer1k: $inputPricePer1k, ')
          ..write('outputPricePer1k: $outputPricePer1k, ')
          ..write('submittedAt: $submittedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    relayModelName,
    providerId,
    providerModel,
    inputPricePer1k,
    outputPricePer1k,
    submittedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderQuotationRow &&
          other.relayModelName == this.relayModelName &&
          other.providerId == this.providerId &&
          other.providerModel == this.providerModel &&
          other.inputPricePer1k == this.inputPricePer1k &&
          other.outputPricePer1k == this.outputPricePer1k &&
          other.submittedAt == this.submittedAt);
}

class ProviderQuotationsCompanion
    extends UpdateCompanion<ProviderQuotationRow> {
  final Value<String> relayModelName;
  final Value<int?> providerId;
  final Value<String?> providerModel;
  final Value<int> inputPricePer1k;
  final Value<int> outputPricePer1k;
  final Value<int?> submittedAt;
  final Value<int> rowid;
  const ProviderQuotationsCompanion({
    this.relayModelName = const Value.absent(),
    this.providerId = const Value.absent(),
    this.providerModel = const Value.absent(),
    this.inputPricePer1k = const Value.absent(),
    this.outputPricePer1k = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProviderQuotationsCompanion.insert({
    required String relayModelName,
    this.providerId = const Value.absent(),
    this.providerModel = const Value.absent(),
    this.inputPricePer1k = const Value.absent(),
    this.outputPricePer1k = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : relayModelName = Value(relayModelName);
  static Insertable<ProviderQuotationRow> custom({
    Expression<String>? relayModelName,
    Expression<int>? providerId,
    Expression<String>? providerModel,
    Expression<int>? inputPricePer1k,
    Expression<int>? outputPricePer1k,
    Expression<int>? submittedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (relayModelName != null) 'relay_model_name': relayModelName,
      if (providerId != null) 'provider_id': providerId,
      if (providerModel != null) 'provider_model': providerModel,
      if (inputPricePer1k != null) 'input_price_per1k': inputPricePer1k,
      if (outputPricePer1k != null) 'output_price_per1k': outputPricePer1k,
      if (submittedAt != null) 'submitted_at': submittedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProviderQuotationsCompanion copyWith({
    Value<String>? relayModelName,
    Value<int?>? providerId,
    Value<String?>? providerModel,
    Value<int>? inputPricePer1k,
    Value<int>? outputPricePer1k,
    Value<int?>? submittedAt,
    Value<int>? rowid,
  }) {
    return ProviderQuotationsCompanion(
      relayModelName: relayModelName ?? this.relayModelName,
      providerId: providerId ?? this.providerId,
      providerModel: providerModel ?? this.providerModel,
      inputPricePer1k: inputPricePer1k ?? this.inputPricePer1k,
      outputPricePer1k: outputPricePer1k ?? this.outputPricePer1k,
      submittedAt: submittedAt ?? this.submittedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (relayModelName.present) {
      map['relay_model_name'] = Variable<String>(relayModelName.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<int>(providerId.value);
    }
    if (providerModel.present) {
      map['provider_model'] = Variable<String>(providerModel.value);
    }
    if (inputPricePer1k.present) {
      map['input_price_per1k'] = Variable<int>(inputPricePer1k.value);
    }
    if (outputPricePer1k.present) {
      map['output_price_per1k'] = Variable<int>(outputPricePer1k.value);
    }
    if (submittedAt.present) {
      map['submitted_at'] = Variable<int>(submittedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderQuotationsCompanion(')
          ..write('relayModelName: $relayModelName, ')
          ..write('providerId: $providerId, ')
          ..write('providerModel: $providerModel, ')
          ..write('inputPricePer1k: $inputPricePer1k, ')
          ..write('outputPricePer1k: $outputPricePer1k, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProviderQuotationBuffersTable extends ProviderQuotationBuffers
    with TableInfo<$ProviderQuotationBuffersTable, ProviderQuotationBufferRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderQuotationBuffersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _relayModelNameMeta = const VerificationMeta(
    'relayModelName',
  );
  @override
  late final GeneratedColumn<String> relayModelName = GeneratedColumn<String>(
    'relay_model_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<int> providerId = GeneratedColumn<int>(
    'provider_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _providerModelMeta = const VerificationMeta(
    'providerModel',
  );
  @override
  late final GeneratedColumn<String> providerModel = GeneratedColumn<String>(
    'provider_model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inputPricePer1kMeta = const VerificationMeta(
    'inputPricePer1k',
  );
  @override
  late final GeneratedColumn<int> inputPricePer1k = GeneratedColumn<int>(
    'input_price_per1k',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _outputPricePer1kMeta = const VerificationMeta(
    'outputPricePer1k',
  );
  @override
  late final GeneratedColumn<int> outputPricePer1k = GeneratedColumn<int>(
    'output_price_per1k',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _submittedAtMeta = const VerificationMeta(
    'submittedAt',
  );
  @override
  late final GeneratedColumn<int> submittedAt = GeneratedColumn<int>(
    'submitted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    relayModelName,
    providerId,
    providerModel,
    inputPricePer1k,
    outputPricePer1k,
    submittedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_quotation_buffer';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderQuotationBufferRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('relay_model_name')) {
      context.handle(
        _relayModelNameMeta,
        relayModelName.isAcceptableOrUnknown(
          data['relay_model_name']!,
          _relayModelNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relayModelNameMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    }
    if (data.containsKey('provider_model')) {
      context.handle(
        _providerModelMeta,
        providerModel.isAcceptableOrUnknown(
          data['provider_model']!,
          _providerModelMeta,
        ),
      );
    }
    if (data.containsKey('input_price_per1k')) {
      context.handle(
        _inputPricePer1kMeta,
        inputPricePer1k.isAcceptableOrUnknown(
          data['input_price_per1k']!,
          _inputPricePer1kMeta,
        ),
      );
    }
    if (data.containsKey('output_price_per1k')) {
      context.handle(
        _outputPricePer1kMeta,
        outputPricePer1k.isAcceptableOrUnknown(
          data['output_price_per1k']!,
          _outputPricePer1kMeta,
        ),
      );
    }
    if (data.containsKey('submitted_at')) {
      context.handle(
        _submittedAtMeta,
        submittedAt.isAcceptableOrUnknown(
          data['submitted_at']!,
          _submittedAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {relayModelName};
  @override
  ProviderQuotationBufferRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderQuotationBufferRow(
      relayModelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relay_model_name'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_id'],
      ),
      providerModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_model'],
      ),
      inputPricePer1k: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}input_price_per1k'],
      )!,
      outputPricePer1k: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}output_price_per1k'],
      )!,
      submittedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}submitted_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProviderQuotationBuffersTable createAlias(String alias) {
    return $ProviderQuotationBuffersTable(attachedDatabase, alias);
  }
}

class ProviderQuotationBufferRow extends DataClass
    implements Insertable<ProviderQuotationBufferRow> {
  final String relayModelName;
  final int? providerId;
  final String? providerModel;
  final int inputPricePer1k;
  final int outputPricePer1k;
  final int? submittedAt;
  final int updatedAt;
  const ProviderQuotationBufferRow({
    required this.relayModelName,
    this.providerId,
    this.providerModel,
    required this.inputPricePer1k,
    required this.outputPricePer1k,
    this.submittedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['relay_model_name'] = Variable<String>(relayModelName);
    if (!nullToAbsent || providerId != null) {
      map['provider_id'] = Variable<int>(providerId);
    }
    if (!nullToAbsent || providerModel != null) {
      map['provider_model'] = Variable<String>(providerModel);
    }
    map['input_price_per1k'] = Variable<int>(inputPricePer1k);
    map['output_price_per1k'] = Variable<int>(outputPricePer1k);
    if (!nullToAbsent || submittedAt != null) {
      map['submitted_at'] = Variable<int>(submittedAt);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ProviderQuotationBuffersCompanion toCompanion(bool nullToAbsent) {
    return ProviderQuotationBuffersCompanion(
      relayModelName: Value(relayModelName),
      providerId: providerId == null && nullToAbsent
          ? const Value.absent()
          : Value(providerId),
      providerModel: providerModel == null && nullToAbsent
          ? const Value.absent()
          : Value(providerModel),
      inputPricePer1k: Value(inputPricePer1k),
      outputPricePer1k: Value(outputPricePer1k),
      submittedAt: submittedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(submittedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProviderQuotationBufferRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderQuotationBufferRow(
      relayModelName: serializer.fromJson<String>(json['relayModelName']),
      providerId: serializer.fromJson<int?>(json['providerId']),
      providerModel: serializer.fromJson<String?>(json['providerModel']),
      inputPricePer1k: serializer.fromJson<int>(json['inputPricePer1k']),
      outputPricePer1k: serializer.fromJson<int>(json['outputPricePer1k']),
      submittedAt: serializer.fromJson<int?>(json['submittedAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'relayModelName': serializer.toJson<String>(relayModelName),
      'providerId': serializer.toJson<int?>(providerId),
      'providerModel': serializer.toJson<String?>(providerModel),
      'inputPricePer1k': serializer.toJson<int>(inputPricePer1k),
      'outputPricePer1k': serializer.toJson<int>(outputPricePer1k),
      'submittedAt': serializer.toJson<int?>(submittedAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ProviderQuotationBufferRow copyWith({
    String? relayModelName,
    Value<int?> providerId = const Value.absent(),
    Value<String?> providerModel = const Value.absent(),
    int? inputPricePer1k,
    int? outputPricePer1k,
    Value<int?> submittedAt = const Value.absent(),
    int? updatedAt,
  }) => ProviderQuotationBufferRow(
    relayModelName: relayModelName ?? this.relayModelName,
    providerId: providerId.present ? providerId.value : this.providerId,
    providerModel: providerModel.present
        ? providerModel.value
        : this.providerModel,
    inputPricePer1k: inputPricePer1k ?? this.inputPricePer1k,
    outputPricePer1k: outputPricePer1k ?? this.outputPricePer1k,
    submittedAt: submittedAt.present ? submittedAt.value : this.submittedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProviderQuotationBufferRow copyWithCompanion(
    ProviderQuotationBuffersCompanion data,
  ) {
    return ProviderQuotationBufferRow(
      relayModelName: data.relayModelName.present
          ? data.relayModelName.value
          : this.relayModelName,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      providerModel: data.providerModel.present
          ? data.providerModel.value
          : this.providerModel,
      inputPricePer1k: data.inputPricePer1k.present
          ? data.inputPricePer1k.value
          : this.inputPricePer1k,
      outputPricePer1k: data.outputPricePer1k.present
          ? data.outputPricePer1k.value
          : this.outputPricePer1k,
      submittedAt: data.submittedAt.present
          ? data.submittedAt.value
          : this.submittedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderQuotationBufferRow(')
          ..write('relayModelName: $relayModelName, ')
          ..write('providerId: $providerId, ')
          ..write('providerModel: $providerModel, ')
          ..write('inputPricePer1k: $inputPricePer1k, ')
          ..write('outputPricePer1k: $outputPricePer1k, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    relayModelName,
    providerId,
    providerModel,
    inputPricePer1k,
    outputPricePer1k,
    submittedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderQuotationBufferRow &&
          other.relayModelName == this.relayModelName &&
          other.providerId == this.providerId &&
          other.providerModel == this.providerModel &&
          other.inputPricePer1k == this.inputPricePer1k &&
          other.outputPricePer1k == this.outputPricePer1k &&
          other.submittedAt == this.submittedAt &&
          other.updatedAt == this.updatedAt);
}

class ProviderQuotationBuffersCompanion
    extends UpdateCompanion<ProviderQuotationBufferRow> {
  final Value<String> relayModelName;
  final Value<int?> providerId;
  final Value<String?> providerModel;
  final Value<int> inputPricePer1k;
  final Value<int> outputPricePer1k;
  final Value<int?> submittedAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ProviderQuotationBuffersCompanion({
    this.relayModelName = const Value.absent(),
    this.providerId = const Value.absent(),
    this.providerModel = const Value.absent(),
    this.inputPricePer1k = const Value.absent(),
    this.outputPricePer1k = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProviderQuotationBuffersCompanion.insert({
    required String relayModelName,
    this.providerId = const Value.absent(),
    this.providerModel = const Value.absent(),
    this.inputPricePer1k = const Value.absent(),
    this.outputPricePer1k = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : relayModelName = Value(relayModelName);
  static Insertable<ProviderQuotationBufferRow> custom({
    Expression<String>? relayModelName,
    Expression<int>? providerId,
    Expression<String>? providerModel,
    Expression<int>? inputPricePer1k,
    Expression<int>? outputPricePer1k,
    Expression<int>? submittedAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (relayModelName != null) 'relay_model_name': relayModelName,
      if (providerId != null) 'provider_id': providerId,
      if (providerModel != null) 'provider_model': providerModel,
      if (inputPricePer1k != null) 'input_price_per1k': inputPricePer1k,
      if (outputPricePer1k != null) 'output_price_per1k': outputPricePer1k,
      if (submittedAt != null) 'submitted_at': submittedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProviderQuotationBuffersCompanion copyWith({
    Value<String>? relayModelName,
    Value<int?>? providerId,
    Value<String?>? providerModel,
    Value<int>? inputPricePer1k,
    Value<int>? outputPricePer1k,
    Value<int?>? submittedAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProviderQuotationBuffersCompanion(
      relayModelName: relayModelName ?? this.relayModelName,
      providerId: providerId ?? this.providerId,
      providerModel: providerModel ?? this.providerModel,
      inputPricePer1k: inputPricePer1k ?? this.inputPricePer1k,
      outputPricePer1k: outputPricePer1k ?? this.outputPricePer1k,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (relayModelName.present) {
      map['relay_model_name'] = Variable<String>(relayModelName.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<int>(providerId.value);
    }
    if (providerModel.present) {
      map['provider_model'] = Variable<String>(providerModel.value);
    }
    if (inputPricePer1k.present) {
      map['input_price_per1k'] = Variable<int>(inputPricePer1k.value);
    }
    if (outputPricePer1k.present) {
      map['output_price_per1k'] = Variable<int>(outputPricePer1k.value);
    }
    if (submittedAt.present) {
      map['submitted_at'] = Variable<int>(submittedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderQuotationBuffersCompanion(')
          ..write('relayModelName: $relayModelName, ')
          ..write('providerId: $providerId, ')
          ..write('providerModel: $providerModel, ')
          ..write('inputPricePer1k: $inputPricePer1k, ')
          ..write('outputPricePer1k: $outputPricePer1k, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProviderQuotationHistoriesTable extends ProviderQuotationHistories
    with
        TableInfo<
          $ProviderQuotationHistoriesTable,
          ProviderQuotationHistoryRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderQuotationHistoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _relayModelNameMeta = const VerificationMeta(
    'relayModelName',
  );
  @override
  late final GeneratedColumn<String> relayModelName = GeneratedColumn<String>(
    'relay_model_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<int> providerId = GeneratedColumn<int>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerModelMeta = const VerificationMeta(
    'providerModel',
  );
  @override
  late final GeneratedColumn<String> providerModel = GeneratedColumn<String>(
    'provider_model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputPricePer1kMeta = const VerificationMeta(
    'inputPricePer1k',
  );
  @override
  late final GeneratedColumn<int> inputPricePer1k = GeneratedColumn<int>(
    'input_price_per1k',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _outputPricePer1kMeta = const VerificationMeta(
    'outputPricePer1k',
  );
  @override
  late final GeneratedColumn<int> outputPricePer1k = GeneratedColumn<int>(
    'output_price_per1k',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _submittedAtMeta = const VerificationMeta(
    'submittedAt',
  );
  @override
  late final GeneratedColumn<int> submittedAt = GeneratedColumn<int>(
    'submitted_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    relayModelName,
    providerId,
    providerModel,
    inputPricePer1k,
    outputPricePer1k,
    submittedAt,
    isDeleted,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_quotation_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderQuotationHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('relay_model_name')) {
      context.handle(
        _relayModelNameMeta,
        relayModelName.isAcceptableOrUnknown(
          data['relay_model_name']!,
          _relayModelNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relayModelNameMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('provider_model')) {
      context.handle(
        _providerModelMeta,
        providerModel.isAcceptableOrUnknown(
          data['provider_model']!,
          _providerModelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerModelMeta);
    }
    if (data.containsKey('input_price_per1k')) {
      context.handle(
        _inputPricePer1kMeta,
        inputPricePer1k.isAcceptableOrUnknown(
          data['input_price_per1k']!,
          _inputPricePer1kMeta,
        ),
      );
    }
    if (data.containsKey('output_price_per1k')) {
      context.handle(
        _outputPricePer1kMeta,
        outputPricePer1k.isAcceptableOrUnknown(
          data['output_price_per1k']!,
          _outputPricePer1kMeta,
        ),
      );
    }
    if (data.containsKey('submitted_at')) {
      context.handle(
        _submittedAtMeta,
        submittedAt.isAcceptableOrUnknown(
          data['submitted_at']!,
          _submittedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_submittedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProviderQuotationHistoryRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderQuotationHistoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      relayModelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relay_model_name'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_id'],
      )!,
      providerModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_model'],
      )!,
      inputPricePer1k: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}input_price_per1k'],
      )!,
      outputPricePer1k: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}output_price_per1k'],
      )!,
      submittedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}submitted_at'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProviderQuotationHistoriesTable createAlias(String alias) {
    return $ProviderQuotationHistoriesTable(attachedDatabase, alias);
  }
}

class ProviderQuotationHistoryRow extends DataClass
    implements Insertable<ProviderQuotationHistoryRow> {
  final int id;
  final String relayModelName;
  final int providerId;
  final String providerModel;
  final int inputPricePer1k;
  final int outputPricePer1k;
  final int submittedAt;
  final bool isDeleted;
  final int createdAt;
  const ProviderQuotationHistoryRow({
    required this.id,
    required this.relayModelName,
    required this.providerId,
    required this.providerModel,
    required this.inputPricePer1k,
    required this.outputPricePer1k,
    required this.submittedAt,
    required this.isDeleted,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['relay_model_name'] = Variable<String>(relayModelName);
    map['provider_id'] = Variable<int>(providerId);
    map['provider_model'] = Variable<String>(providerModel);
    map['input_price_per1k'] = Variable<int>(inputPricePer1k);
    map['output_price_per1k'] = Variable<int>(outputPricePer1k);
    map['submitted_at'] = Variable<int>(submittedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ProviderQuotationHistoriesCompanion toCompanion(bool nullToAbsent) {
    return ProviderQuotationHistoriesCompanion(
      id: Value(id),
      relayModelName: Value(relayModelName),
      providerId: Value(providerId),
      providerModel: Value(providerModel),
      inputPricePer1k: Value(inputPricePer1k),
      outputPricePer1k: Value(outputPricePer1k),
      submittedAt: Value(submittedAt),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
    );
  }

  factory ProviderQuotationHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderQuotationHistoryRow(
      id: serializer.fromJson<int>(json['id']),
      relayModelName: serializer.fromJson<String>(json['relayModelName']),
      providerId: serializer.fromJson<int>(json['providerId']),
      providerModel: serializer.fromJson<String>(json['providerModel']),
      inputPricePer1k: serializer.fromJson<int>(json['inputPricePer1k']),
      outputPricePer1k: serializer.fromJson<int>(json['outputPricePer1k']),
      submittedAt: serializer.fromJson<int>(json['submittedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'relayModelName': serializer.toJson<String>(relayModelName),
      'providerId': serializer.toJson<int>(providerId),
      'providerModel': serializer.toJson<String>(providerModel),
      'inputPricePer1k': serializer.toJson<int>(inputPricePer1k),
      'outputPricePer1k': serializer.toJson<int>(outputPricePer1k),
      'submittedAt': serializer.toJson<int>(submittedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ProviderQuotationHistoryRow copyWith({
    int? id,
    String? relayModelName,
    int? providerId,
    String? providerModel,
    int? inputPricePer1k,
    int? outputPricePer1k,
    int? submittedAt,
    bool? isDeleted,
    int? createdAt,
  }) => ProviderQuotationHistoryRow(
    id: id ?? this.id,
    relayModelName: relayModelName ?? this.relayModelName,
    providerId: providerId ?? this.providerId,
    providerModel: providerModel ?? this.providerModel,
    inputPricePer1k: inputPricePer1k ?? this.inputPricePer1k,
    outputPricePer1k: outputPricePer1k ?? this.outputPricePer1k,
    submittedAt: submittedAt ?? this.submittedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
  );
  ProviderQuotationHistoryRow copyWithCompanion(
    ProviderQuotationHistoriesCompanion data,
  ) {
    return ProviderQuotationHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      relayModelName: data.relayModelName.present
          ? data.relayModelName.value
          : this.relayModelName,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      providerModel: data.providerModel.present
          ? data.providerModel.value
          : this.providerModel,
      inputPricePer1k: data.inputPricePer1k.present
          ? data.inputPricePer1k.value
          : this.inputPricePer1k,
      outputPricePer1k: data.outputPricePer1k.present
          ? data.outputPricePer1k.value
          : this.outputPricePer1k,
      submittedAt: data.submittedAt.present
          ? data.submittedAt.value
          : this.submittedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderQuotationHistoryRow(')
          ..write('id: $id, ')
          ..write('relayModelName: $relayModelName, ')
          ..write('providerId: $providerId, ')
          ..write('providerModel: $providerModel, ')
          ..write('inputPricePer1k: $inputPricePer1k, ')
          ..write('outputPricePer1k: $outputPricePer1k, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    relayModelName,
    providerId,
    providerModel,
    inputPricePer1k,
    outputPricePer1k,
    submittedAt,
    isDeleted,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderQuotationHistoryRow &&
          other.id == this.id &&
          other.relayModelName == this.relayModelName &&
          other.providerId == this.providerId &&
          other.providerModel == this.providerModel &&
          other.inputPricePer1k == this.inputPricePer1k &&
          other.outputPricePer1k == this.outputPricePer1k &&
          other.submittedAt == this.submittedAt &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt);
}

class ProviderQuotationHistoriesCompanion
    extends UpdateCompanion<ProviderQuotationHistoryRow> {
  final Value<int> id;
  final Value<String> relayModelName;
  final Value<int> providerId;
  final Value<String> providerModel;
  final Value<int> inputPricePer1k;
  final Value<int> outputPricePer1k;
  final Value<int> submittedAt;
  final Value<bool> isDeleted;
  final Value<int> createdAt;
  const ProviderQuotationHistoriesCompanion({
    this.id = const Value.absent(),
    this.relayModelName = const Value.absent(),
    this.providerId = const Value.absent(),
    this.providerModel = const Value.absent(),
    this.inputPricePer1k = const Value.absent(),
    this.outputPricePer1k = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProviderQuotationHistoriesCompanion.insert({
    this.id = const Value.absent(),
    required String relayModelName,
    required int providerId,
    required String providerModel,
    this.inputPricePer1k = const Value.absent(),
    this.outputPricePer1k = const Value.absent(),
    required int submittedAt,
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : relayModelName = Value(relayModelName),
       providerId = Value(providerId),
       providerModel = Value(providerModel),
       submittedAt = Value(submittedAt);
  static Insertable<ProviderQuotationHistoryRow> custom({
    Expression<int>? id,
    Expression<String>? relayModelName,
    Expression<int>? providerId,
    Expression<String>? providerModel,
    Expression<int>? inputPricePer1k,
    Expression<int>? outputPricePer1k,
    Expression<int>? submittedAt,
    Expression<bool>? isDeleted,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (relayModelName != null) 'relay_model_name': relayModelName,
      if (providerId != null) 'provider_id': providerId,
      if (providerModel != null) 'provider_model': providerModel,
      if (inputPricePer1k != null) 'input_price_per1k': inputPricePer1k,
      if (outputPricePer1k != null) 'output_price_per1k': outputPricePer1k,
      if (submittedAt != null) 'submitted_at': submittedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProviderQuotationHistoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? relayModelName,
    Value<int>? providerId,
    Value<String>? providerModel,
    Value<int>? inputPricePer1k,
    Value<int>? outputPricePer1k,
    Value<int>? submittedAt,
    Value<bool>? isDeleted,
    Value<int>? createdAt,
  }) {
    return ProviderQuotationHistoriesCompanion(
      id: id ?? this.id,
      relayModelName: relayModelName ?? this.relayModelName,
      providerId: providerId ?? this.providerId,
      providerModel: providerModel ?? this.providerModel,
      inputPricePer1k: inputPricePer1k ?? this.inputPricePer1k,
      outputPricePer1k: outputPricePer1k ?? this.outputPricePer1k,
      submittedAt: submittedAt ?? this.submittedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (relayModelName.present) {
      map['relay_model_name'] = Variable<String>(relayModelName.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<int>(providerId.value);
    }
    if (providerModel.present) {
      map['provider_model'] = Variable<String>(providerModel.value);
    }
    if (inputPricePer1k.present) {
      map['input_price_per1k'] = Variable<int>(inputPricePer1k.value);
    }
    if (outputPricePer1k.present) {
      map['output_price_per1k'] = Variable<int>(outputPricePer1k.value);
    }
    if (submittedAt.present) {
      map['submitted_at'] = Variable<int>(submittedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderQuotationHistoriesCompanion(')
          ..write('id: $id, ')
          ..write('relayModelName: $relayModelName, ')
          ..write('providerId: $providerId, ')
          ..write('providerModel: $providerModel, ')
          ..write('inputPricePer1k: $inputPricePer1k, ')
          ..write('outputPricePer1k: $outputPricePer1k, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ProviderChainSettlementsTable extends ProviderChainSettlements
    with TableInfo<$ProviderChainSettlementsTable, ProviderChainSettlementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderChainSettlementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _txMeta = const VerificationMeta('tx');
  @override
  late final GeneratedColumn<String> tx = GeneratedColumn<String>(
    'tx',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerAddressMeta = const VerificationMeta(
    'providerAddress',
  );
  @override
  late final GeneratedColumn<String> providerAddress = GeneratedColumn<String>(
    'provider_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relayStationAddressMeta =
      const VerificationMeta('relayStationAddress');
  @override
  late final GeneratedColumn<String> relayStationAddress =
      GeneratedColumn<String>(
        'relay_station_address',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _receivedUsdtMeta = const VerificationMeta(
    'receivedUsdt',
  );
  @override
  late final GeneratedColumn<String> receivedUsdt = GeneratedColumn<String>(
    'received_usdt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settledCountMeta = const VerificationMeta(
    'settledCount',
  );
  @override
  late final GeneratedColumn<int> settledCount = GeneratedColumn<int>(
    'settled_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settledAmountMeta = const VerificationMeta(
    'settledAmount',
  );
  @override
  late final GeneratedColumn<String> settledAmount = GeneratedColumn<String>(
    'settled_amount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notSettledCountMeta = const VerificationMeta(
    'notSettledCount',
  );
  @override
  late final GeneratedColumn<int> notSettledCount = GeneratedColumn<int>(
    'not_settled_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notSettledAmountMeta = const VerificationMeta(
    'notSettledAmount',
  );
  @override
  late final GeneratedColumn<String> notSettledAmount = GeneratedColumn<String>(
    'not_settled_amount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logIndexMeta = const VerificationMeta(
    'logIndex',
  );
  @override
  late final GeneratedColumn<int> logIndex = GeneratedColumn<int>(
    'log_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tx,
    providerAddress,
    relayStationAddress,
    receivedUsdt,
    settledCount,
    settledAmount,
    notSettledCount,
    notSettledAmount,
    createdAt,
    logIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_chain_settlement';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderChainSettlementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tx')) {
      context.handle(_txMeta, tx.isAcceptableOrUnknown(data['tx']!, _txMeta));
    } else if (isInserting) {
      context.missing(_txMeta);
    }
    if (data.containsKey('provider_address')) {
      context.handle(
        _providerAddressMeta,
        providerAddress.isAcceptableOrUnknown(
          data['provider_address']!,
          _providerAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerAddressMeta);
    }
    if (data.containsKey('relay_station_address')) {
      context.handle(
        _relayStationAddressMeta,
        relayStationAddress.isAcceptableOrUnknown(
          data['relay_station_address']!,
          _relayStationAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relayStationAddressMeta);
    }
    if (data.containsKey('received_usdt')) {
      context.handle(
        _receivedUsdtMeta,
        receivedUsdt.isAcceptableOrUnknown(
          data['received_usdt']!,
          _receivedUsdtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receivedUsdtMeta);
    }
    if (data.containsKey('settled_count')) {
      context.handle(
        _settledCountMeta,
        settledCount.isAcceptableOrUnknown(
          data['settled_count']!,
          _settledCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_settledCountMeta);
    }
    if (data.containsKey('settled_amount')) {
      context.handle(
        _settledAmountMeta,
        settledAmount.isAcceptableOrUnknown(
          data['settled_amount']!,
          _settledAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_settledAmountMeta);
    }
    if (data.containsKey('not_settled_count')) {
      context.handle(
        _notSettledCountMeta,
        notSettledCount.isAcceptableOrUnknown(
          data['not_settled_count']!,
          _notSettledCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_notSettledCountMeta);
    }
    if (data.containsKey('not_settled_amount')) {
      context.handle(
        _notSettledAmountMeta,
        notSettledAmount.isAcceptableOrUnknown(
          data['not_settled_amount']!,
          _notSettledAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_notSettledAmountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('log_index')) {
      context.handle(
        _logIndexMeta,
        logIndex.isAcceptableOrUnknown(data['log_index']!, _logIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tx};
  @override
  ProviderChainSettlementRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderChainSettlementRow(
      tx: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tx'],
      )!,
      providerAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_address'],
      )!,
      relayStationAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relay_station_address'],
      )!,
      receivedUsdt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}received_usdt'],
      )!,
      settledCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}settled_count'],
      )!,
      settledAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settled_amount'],
      )!,
      notSettledCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}not_settled_count'],
      )!,
      notSettledAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}not_settled_amount'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      logIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}log_index'],
      ),
    );
  }

  @override
  $ProviderChainSettlementsTable createAlias(String alias) {
    return $ProviderChainSettlementsTable(attachedDatabase, alias);
  }
}

class ProviderChainSettlementRow extends DataClass
    implements Insertable<ProviderChainSettlementRow> {
  final String tx;
  final String providerAddress;
  final String relayStationAddress;
  final String receivedUsdt;
  final int settledCount;
  final String settledAmount;
  final int notSettledCount;
  final String notSettledAmount;
  final int createdAt;
  final int? logIndex;
  const ProviderChainSettlementRow({
    required this.tx,
    required this.providerAddress,
    required this.relayStationAddress,
    required this.receivedUsdt,
    required this.settledCount,
    required this.settledAmount,
    required this.notSettledCount,
    required this.notSettledAmount,
    required this.createdAt,
    this.logIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tx'] = Variable<String>(tx);
    map['provider_address'] = Variable<String>(providerAddress);
    map['relay_station_address'] = Variable<String>(relayStationAddress);
    map['received_usdt'] = Variable<String>(receivedUsdt);
    map['settled_count'] = Variable<int>(settledCount);
    map['settled_amount'] = Variable<String>(settledAmount);
    map['not_settled_count'] = Variable<int>(notSettledCount);
    map['not_settled_amount'] = Variable<String>(notSettledAmount);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || logIndex != null) {
      map['log_index'] = Variable<int>(logIndex);
    }
    return map;
  }

  ProviderChainSettlementsCompanion toCompanion(bool nullToAbsent) {
    return ProviderChainSettlementsCompanion(
      tx: Value(tx),
      providerAddress: Value(providerAddress),
      relayStationAddress: Value(relayStationAddress),
      receivedUsdt: Value(receivedUsdt),
      settledCount: Value(settledCount),
      settledAmount: Value(settledAmount),
      notSettledCount: Value(notSettledCount),
      notSettledAmount: Value(notSettledAmount),
      createdAt: Value(createdAt),
      logIndex: logIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(logIndex),
    );
  }

  factory ProviderChainSettlementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderChainSettlementRow(
      tx: serializer.fromJson<String>(json['tx']),
      providerAddress: serializer.fromJson<String>(json['providerAddress']),
      relayStationAddress: serializer.fromJson<String>(
        json['relayStationAddress'],
      ),
      receivedUsdt: serializer.fromJson<String>(json['receivedUsdt']),
      settledCount: serializer.fromJson<int>(json['settledCount']),
      settledAmount: serializer.fromJson<String>(json['settledAmount']),
      notSettledCount: serializer.fromJson<int>(json['notSettledCount']),
      notSettledAmount: serializer.fromJson<String>(json['notSettledAmount']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      logIndex: serializer.fromJson<int?>(json['logIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tx': serializer.toJson<String>(tx),
      'providerAddress': serializer.toJson<String>(providerAddress),
      'relayStationAddress': serializer.toJson<String>(relayStationAddress),
      'receivedUsdt': serializer.toJson<String>(receivedUsdt),
      'settledCount': serializer.toJson<int>(settledCount),
      'settledAmount': serializer.toJson<String>(settledAmount),
      'notSettledCount': serializer.toJson<int>(notSettledCount),
      'notSettledAmount': serializer.toJson<String>(notSettledAmount),
      'createdAt': serializer.toJson<int>(createdAt),
      'logIndex': serializer.toJson<int?>(logIndex),
    };
  }

  ProviderChainSettlementRow copyWith({
    String? tx,
    String? providerAddress,
    String? relayStationAddress,
    String? receivedUsdt,
    int? settledCount,
    String? settledAmount,
    int? notSettledCount,
    String? notSettledAmount,
    int? createdAt,
    Value<int?> logIndex = const Value.absent(),
  }) => ProviderChainSettlementRow(
    tx: tx ?? this.tx,
    providerAddress: providerAddress ?? this.providerAddress,
    relayStationAddress: relayStationAddress ?? this.relayStationAddress,
    receivedUsdt: receivedUsdt ?? this.receivedUsdt,
    settledCount: settledCount ?? this.settledCount,
    settledAmount: settledAmount ?? this.settledAmount,
    notSettledCount: notSettledCount ?? this.notSettledCount,
    notSettledAmount: notSettledAmount ?? this.notSettledAmount,
    createdAt: createdAt ?? this.createdAt,
    logIndex: logIndex.present ? logIndex.value : this.logIndex,
  );
  ProviderChainSettlementRow copyWithCompanion(
    ProviderChainSettlementsCompanion data,
  ) {
    return ProviderChainSettlementRow(
      tx: data.tx.present ? data.tx.value : this.tx,
      providerAddress: data.providerAddress.present
          ? data.providerAddress.value
          : this.providerAddress,
      relayStationAddress: data.relayStationAddress.present
          ? data.relayStationAddress.value
          : this.relayStationAddress,
      receivedUsdt: data.receivedUsdt.present
          ? data.receivedUsdt.value
          : this.receivedUsdt,
      settledCount: data.settledCount.present
          ? data.settledCount.value
          : this.settledCount,
      settledAmount: data.settledAmount.present
          ? data.settledAmount.value
          : this.settledAmount,
      notSettledCount: data.notSettledCount.present
          ? data.notSettledCount.value
          : this.notSettledCount,
      notSettledAmount: data.notSettledAmount.present
          ? data.notSettledAmount.value
          : this.notSettledAmount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      logIndex: data.logIndex.present ? data.logIndex.value : this.logIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderChainSettlementRow(')
          ..write('tx: $tx, ')
          ..write('providerAddress: $providerAddress, ')
          ..write('relayStationAddress: $relayStationAddress, ')
          ..write('receivedUsdt: $receivedUsdt, ')
          ..write('settledCount: $settledCount, ')
          ..write('settledAmount: $settledAmount, ')
          ..write('notSettledCount: $notSettledCount, ')
          ..write('notSettledAmount: $notSettledAmount, ')
          ..write('createdAt: $createdAt, ')
          ..write('logIndex: $logIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tx,
    providerAddress,
    relayStationAddress,
    receivedUsdt,
    settledCount,
    settledAmount,
    notSettledCount,
    notSettledAmount,
    createdAt,
    logIndex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderChainSettlementRow &&
          other.tx == this.tx &&
          other.providerAddress == this.providerAddress &&
          other.relayStationAddress == this.relayStationAddress &&
          other.receivedUsdt == this.receivedUsdt &&
          other.settledCount == this.settledCount &&
          other.settledAmount == this.settledAmount &&
          other.notSettledCount == this.notSettledCount &&
          other.notSettledAmount == this.notSettledAmount &&
          other.createdAt == this.createdAt &&
          other.logIndex == this.logIndex);
}

class ProviderChainSettlementsCompanion
    extends UpdateCompanion<ProviderChainSettlementRow> {
  final Value<String> tx;
  final Value<String> providerAddress;
  final Value<String> relayStationAddress;
  final Value<String> receivedUsdt;
  final Value<int> settledCount;
  final Value<String> settledAmount;
  final Value<int> notSettledCount;
  final Value<String> notSettledAmount;
  final Value<int> createdAt;
  final Value<int?> logIndex;
  final Value<int> rowid;
  const ProviderChainSettlementsCompanion({
    this.tx = const Value.absent(),
    this.providerAddress = const Value.absent(),
    this.relayStationAddress = const Value.absent(),
    this.receivedUsdt = const Value.absent(),
    this.settledCount = const Value.absent(),
    this.settledAmount = const Value.absent(),
    this.notSettledCount = const Value.absent(),
    this.notSettledAmount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.logIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProviderChainSettlementsCompanion.insert({
    required String tx,
    required String providerAddress,
    required String relayStationAddress,
    required String receivedUsdt,
    required int settledCount,
    required String settledAmount,
    required int notSettledCount,
    required String notSettledAmount,
    required int createdAt,
    this.logIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tx = Value(tx),
       providerAddress = Value(providerAddress),
       relayStationAddress = Value(relayStationAddress),
       receivedUsdt = Value(receivedUsdt),
       settledCount = Value(settledCount),
       settledAmount = Value(settledAmount),
       notSettledCount = Value(notSettledCount),
       notSettledAmount = Value(notSettledAmount),
       createdAt = Value(createdAt);
  static Insertable<ProviderChainSettlementRow> custom({
    Expression<String>? tx,
    Expression<String>? providerAddress,
    Expression<String>? relayStationAddress,
    Expression<String>? receivedUsdt,
    Expression<int>? settledCount,
    Expression<String>? settledAmount,
    Expression<int>? notSettledCount,
    Expression<String>? notSettledAmount,
    Expression<int>? createdAt,
    Expression<int>? logIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tx != null) 'tx': tx,
      if (providerAddress != null) 'provider_address': providerAddress,
      if (relayStationAddress != null)
        'relay_station_address': relayStationAddress,
      if (receivedUsdt != null) 'received_usdt': receivedUsdt,
      if (settledCount != null) 'settled_count': settledCount,
      if (settledAmount != null) 'settled_amount': settledAmount,
      if (notSettledCount != null) 'not_settled_count': notSettledCount,
      if (notSettledAmount != null) 'not_settled_amount': notSettledAmount,
      if (createdAt != null) 'created_at': createdAt,
      if (logIndex != null) 'log_index': logIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProviderChainSettlementsCompanion copyWith({
    Value<String>? tx,
    Value<String>? providerAddress,
    Value<String>? relayStationAddress,
    Value<String>? receivedUsdt,
    Value<int>? settledCount,
    Value<String>? settledAmount,
    Value<int>? notSettledCount,
    Value<String>? notSettledAmount,
    Value<int>? createdAt,
    Value<int?>? logIndex,
    Value<int>? rowid,
  }) {
    return ProviderChainSettlementsCompanion(
      tx: tx ?? this.tx,
      providerAddress: providerAddress ?? this.providerAddress,
      relayStationAddress: relayStationAddress ?? this.relayStationAddress,
      receivedUsdt: receivedUsdt ?? this.receivedUsdt,
      settledCount: settledCount ?? this.settledCount,
      settledAmount: settledAmount ?? this.settledAmount,
      notSettledCount: notSettledCount ?? this.notSettledCount,
      notSettledAmount: notSettledAmount ?? this.notSettledAmount,
      createdAt: createdAt ?? this.createdAt,
      logIndex: logIndex ?? this.logIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tx.present) {
      map['tx'] = Variable<String>(tx.value);
    }
    if (providerAddress.present) {
      map['provider_address'] = Variable<String>(providerAddress.value);
    }
    if (relayStationAddress.present) {
      map['relay_station_address'] = Variable<String>(
        relayStationAddress.value,
      );
    }
    if (receivedUsdt.present) {
      map['received_usdt'] = Variable<String>(receivedUsdt.value);
    }
    if (settledCount.present) {
      map['settled_count'] = Variable<int>(settledCount.value);
    }
    if (settledAmount.present) {
      map['settled_amount'] = Variable<String>(settledAmount.value);
    }
    if (notSettledCount.present) {
      map['not_settled_count'] = Variable<int>(notSettledCount.value);
    }
    if (notSettledAmount.present) {
      map['not_settled_amount'] = Variable<String>(notSettledAmount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (logIndex.present) {
      map['log_index'] = Variable<int>(logIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderChainSettlementsCompanion(')
          ..write('tx: $tx, ')
          ..write('providerAddress: $providerAddress, ')
          ..write('relayStationAddress: $relayStationAddress, ')
          ..write('receivedUsdt: $receivedUsdt, ')
          ..write('settledCount: $settledCount, ')
          ..write('settledAmount: $settledAmount, ')
          ..write('notSettledCount: $notSettledCount, ')
          ..write('notSettledAmount: $notSettledAmount, ')
          ..write('createdAt: $createdAt, ')
          ..write('logIndex: $logIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChainSyncCursorsTable extends ChainSyncCursors
    with TableInfo<$ChainSyncCursorsTable, ChainSyncCursorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChainSyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastBlockMeta = const VerificationMeta(
    'lastBlock',
  );
  @override
  late final GeneratedColumn<int> lastBlock = GeneratedColumn<int>(
    'last_block',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [scope, lastBlock, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chain_sync_cursor';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChainSyncCursorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('last_block')) {
      context.handle(
        _lastBlockMeta,
        lastBlock.isAcceptableOrUnknown(data['last_block']!, _lastBlockMeta),
      );
    } else if (isInserting) {
      context.missing(_lastBlockMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scope};
  @override
  ChainSyncCursorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChainSyncCursorRow(
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      lastBlock: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_block'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ChainSyncCursorsTable createAlias(String alias) {
    return $ChainSyncCursorsTable(attachedDatabase, alias);
  }
}

class ChainSyncCursorRow extends DataClass
    implements Insertable<ChainSyncCursorRow> {
  final String scope;
  final int lastBlock;
  final int updatedAt;
  const ChainSyncCursorRow({
    required this.scope,
    required this.lastBlock,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scope'] = Variable<String>(scope);
    map['last_block'] = Variable<int>(lastBlock);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ChainSyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return ChainSyncCursorsCompanion(
      scope: Value(scope),
      lastBlock: Value(lastBlock),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChainSyncCursorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChainSyncCursorRow(
      scope: serializer.fromJson<String>(json['scope']),
      lastBlock: serializer.fromJson<int>(json['lastBlock']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scope': serializer.toJson<String>(scope),
      'lastBlock': serializer.toJson<int>(lastBlock),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ChainSyncCursorRow copyWith({
    String? scope,
    int? lastBlock,
    int? updatedAt,
  }) => ChainSyncCursorRow(
    scope: scope ?? this.scope,
    lastBlock: lastBlock ?? this.lastBlock,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ChainSyncCursorRow copyWithCompanion(ChainSyncCursorsCompanion data) {
    return ChainSyncCursorRow(
      scope: data.scope.present ? data.scope.value : this.scope,
      lastBlock: data.lastBlock.present ? data.lastBlock.value : this.lastBlock,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChainSyncCursorRow(')
          ..write('scope: $scope, ')
          ..write('lastBlock: $lastBlock, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scope, lastBlock, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChainSyncCursorRow &&
          other.scope == this.scope &&
          other.lastBlock == this.lastBlock &&
          other.updatedAt == this.updatedAt);
}

class ChainSyncCursorsCompanion extends UpdateCompanion<ChainSyncCursorRow> {
  final Value<String> scope;
  final Value<int> lastBlock;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ChainSyncCursorsCompanion({
    this.scope = const Value.absent(),
    this.lastBlock = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChainSyncCursorsCompanion.insert({
    required String scope,
    required int lastBlock,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : scope = Value(scope),
       lastBlock = Value(lastBlock),
       updatedAt = Value(updatedAt);
  static Insertable<ChainSyncCursorRow> custom({
    Expression<String>? scope,
    Expression<int>? lastBlock,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scope != null) 'scope': scope,
      if (lastBlock != null) 'last_block': lastBlock,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChainSyncCursorsCompanion copyWith({
    Value<String>? scope,
    Value<int>? lastBlock,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return ChainSyncCursorsCompanion(
      scope: scope ?? this.scope,
      lastBlock: lastBlock ?? this.lastBlock,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (lastBlock.present) {
      map['last_block'] = Variable<int>(lastBlock.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChainSyncCursorsCompanion(')
          ..write('scope: $scope, ')
          ..write('lastBlock: $lastBlock, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnmatchedSettledEventsTable extends UnmatchedSettledEvents
    with TableInfo<$UnmatchedSettledEventsTable, UnmatchedSettledEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnmatchedSettledEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _txMeta = const VerificationMeta('tx');
  @override
  late final GeneratedColumn<String> tx = GeneratedColumn<String>(
    'tx',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logIndexMeta = const VerificationMeta(
    'logIndex',
  );
  @override
  late final GeneratedColumn<int> logIndex = GeneratedColumn<int>(
    'log_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerAddressMeta = const VerificationMeta(
    'providerAddress',
  );
  @override
  late final GeneratedColumn<String> providerAddress = GeneratedColumn<String>(
    'provider_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedUsdtMeta = const VerificationMeta(
    'receivedUsdt',
  );
  @override
  late final GeneratedColumn<String> receivedUsdt = GeneratedColumn<String>(
    'received_usdt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settledCountMeta = const VerificationMeta(
    'settledCount',
  );
  @override
  late final GeneratedColumn<int> settledCount = GeneratedColumn<int>(
    'settled_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settledAmountMeta = const VerificationMeta(
    'settledAmount',
  );
  @override
  late final GeneratedColumn<String> settledAmount = GeneratedColumn<String>(
    'settled_amount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notSettledCountMeta = const VerificationMeta(
    'notSettledCount',
  );
  @override
  late final GeneratedColumn<int> notSettledCount = GeneratedColumn<int>(
    'not_settled_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notSettledAmountMeta = const VerificationMeta(
    'notSettledAmount',
  );
  @override
  late final GeneratedColumn<String> notSettledAmount = GeneratedColumn<String>(
    'not_settled_amount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blockTimestampMeta = const VerificationMeta(
    'blockTimestamp',
  );
  @override
  late final GeneratedColumn<int> blockTimestamp = GeneratedColumn<int>(
    'block_timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detectedAtMeta = const VerificationMeta(
    'detectedAt',
  );
  @override
  late final GeneratedColumn<int> detectedAt = GeneratedColumn<int>(
    'detected_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastRetryAtMeta = const VerificationMeta(
    'lastRetryAt',
  );
  @override
  late final GeneratedColumn<int> lastRetryAt = GeneratedColumn<int>(
    'last_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    tx,
    logIndex,
    providerAddress,
    receivedUsdt,
    settledCount,
    settledAmount,
    notSettledCount,
    notSettledAmount,
    blockTimestamp,
    detectedAt,
    lastRetryAt,
    retryCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unmatched_settled_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<UnmatchedSettledEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tx')) {
      context.handle(_txMeta, tx.isAcceptableOrUnknown(data['tx']!, _txMeta));
    } else if (isInserting) {
      context.missing(_txMeta);
    }
    if (data.containsKey('log_index')) {
      context.handle(
        _logIndexMeta,
        logIndex.isAcceptableOrUnknown(data['log_index']!, _logIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_logIndexMeta);
    }
    if (data.containsKey('provider_address')) {
      context.handle(
        _providerAddressMeta,
        providerAddress.isAcceptableOrUnknown(
          data['provider_address']!,
          _providerAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerAddressMeta);
    }
    if (data.containsKey('received_usdt')) {
      context.handle(
        _receivedUsdtMeta,
        receivedUsdt.isAcceptableOrUnknown(
          data['received_usdt']!,
          _receivedUsdtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receivedUsdtMeta);
    }
    if (data.containsKey('settled_count')) {
      context.handle(
        _settledCountMeta,
        settledCount.isAcceptableOrUnknown(
          data['settled_count']!,
          _settledCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_settledCountMeta);
    }
    if (data.containsKey('settled_amount')) {
      context.handle(
        _settledAmountMeta,
        settledAmount.isAcceptableOrUnknown(
          data['settled_amount']!,
          _settledAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_settledAmountMeta);
    }
    if (data.containsKey('not_settled_count')) {
      context.handle(
        _notSettledCountMeta,
        notSettledCount.isAcceptableOrUnknown(
          data['not_settled_count']!,
          _notSettledCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_notSettledCountMeta);
    }
    if (data.containsKey('not_settled_amount')) {
      context.handle(
        _notSettledAmountMeta,
        notSettledAmount.isAcceptableOrUnknown(
          data['not_settled_amount']!,
          _notSettledAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_notSettledAmountMeta);
    }
    if (data.containsKey('block_timestamp')) {
      context.handle(
        _blockTimestampMeta,
        blockTimestamp.isAcceptableOrUnknown(
          data['block_timestamp']!,
          _blockTimestampMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_blockTimestampMeta);
    }
    if (data.containsKey('detected_at')) {
      context.handle(
        _detectedAtMeta,
        detectedAt.isAcceptableOrUnknown(data['detected_at']!, _detectedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_detectedAtMeta);
    }
    if (data.containsKey('last_retry_at')) {
      context.handle(
        _lastRetryAtMeta,
        lastRetryAt.isAcceptableOrUnknown(
          data['last_retry_at']!,
          _lastRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tx, logIndex};
  @override
  UnmatchedSettledEventRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnmatchedSettledEventRow(
      tx: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tx'],
      )!,
      logIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}log_index'],
      )!,
      providerAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_address'],
      )!,
      receivedUsdt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}received_usdt'],
      )!,
      settledCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}settled_count'],
      )!,
      settledAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settled_amount'],
      )!,
      notSettledCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}not_settled_count'],
      )!,
      notSettledAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}not_settled_amount'],
      )!,
      blockTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}block_timestamp'],
      )!,
      detectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}detected_at'],
      )!,
      lastRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_retry_at'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
    );
  }

  @override
  $UnmatchedSettledEventsTable createAlias(String alias) {
    return $UnmatchedSettledEventsTable(attachedDatabase, alias);
  }
}

class UnmatchedSettledEventRow extends DataClass
    implements Insertable<UnmatchedSettledEventRow> {
  final String tx;
  final int logIndex;
  final String providerAddress;
  final String receivedUsdt;
  final int settledCount;
  final String settledAmount;
  final int notSettledCount;
  final String notSettledAmount;
  final int blockTimestamp;
  final int detectedAt;
  final int? lastRetryAt;
  final int retryCount;
  const UnmatchedSettledEventRow({
    required this.tx,
    required this.logIndex,
    required this.providerAddress,
    required this.receivedUsdt,
    required this.settledCount,
    required this.settledAmount,
    required this.notSettledCount,
    required this.notSettledAmount,
    required this.blockTimestamp,
    required this.detectedAt,
    this.lastRetryAt,
    required this.retryCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tx'] = Variable<String>(tx);
    map['log_index'] = Variable<int>(logIndex);
    map['provider_address'] = Variable<String>(providerAddress);
    map['received_usdt'] = Variable<String>(receivedUsdt);
    map['settled_count'] = Variable<int>(settledCount);
    map['settled_amount'] = Variable<String>(settledAmount);
    map['not_settled_count'] = Variable<int>(notSettledCount);
    map['not_settled_amount'] = Variable<String>(notSettledAmount);
    map['block_timestamp'] = Variable<int>(blockTimestamp);
    map['detected_at'] = Variable<int>(detectedAt);
    if (!nullToAbsent || lastRetryAt != null) {
      map['last_retry_at'] = Variable<int>(lastRetryAt);
    }
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  UnmatchedSettledEventsCompanion toCompanion(bool nullToAbsent) {
    return UnmatchedSettledEventsCompanion(
      tx: Value(tx),
      logIndex: Value(logIndex),
      providerAddress: Value(providerAddress),
      receivedUsdt: Value(receivedUsdt),
      settledCount: Value(settledCount),
      settledAmount: Value(settledAmount),
      notSettledCount: Value(notSettledCount),
      notSettledAmount: Value(notSettledAmount),
      blockTimestamp: Value(blockTimestamp),
      detectedAt: Value(detectedAt),
      lastRetryAt: lastRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRetryAt),
      retryCount: Value(retryCount),
    );
  }

  factory UnmatchedSettledEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnmatchedSettledEventRow(
      tx: serializer.fromJson<String>(json['tx']),
      logIndex: serializer.fromJson<int>(json['logIndex']),
      providerAddress: serializer.fromJson<String>(json['providerAddress']),
      receivedUsdt: serializer.fromJson<String>(json['receivedUsdt']),
      settledCount: serializer.fromJson<int>(json['settledCount']),
      settledAmount: serializer.fromJson<String>(json['settledAmount']),
      notSettledCount: serializer.fromJson<int>(json['notSettledCount']),
      notSettledAmount: serializer.fromJson<String>(json['notSettledAmount']),
      blockTimestamp: serializer.fromJson<int>(json['blockTimestamp']),
      detectedAt: serializer.fromJson<int>(json['detectedAt']),
      lastRetryAt: serializer.fromJson<int?>(json['lastRetryAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tx': serializer.toJson<String>(tx),
      'logIndex': serializer.toJson<int>(logIndex),
      'providerAddress': serializer.toJson<String>(providerAddress),
      'receivedUsdt': serializer.toJson<String>(receivedUsdt),
      'settledCount': serializer.toJson<int>(settledCount),
      'settledAmount': serializer.toJson<String>(settledAmount),
      'notSettledCount': serializer.toJson<int>(notSettledCount),
      'notSettledAmount': serializer.toJson<String>(notSettledAmount),
      'blockTimestamp': serializer.toJson<int>(blockTimestamp),
      'detectedAt': serializer.toJson<int>(detectedAt),
      'lastRetryAt': serializer.toJson<int?>(lastRetryAt),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  UnmatchedSettledEventRow copyWith({
    String? tx,
    int? logIndex,
    String? providerAddress,
    String? receivedUsdt,
    int? settledCount,
    String? settledAmount,
    int? notSettledCount,
    String? notSettledAmount,
    int? blockTimestamp,
    int? detectedAt,
    Value<int?> lastRetryAt = const Value.absent(),
    int? retryCount,
  }) => UnmatchedSettledEventRow(
    tx: tx ?? this.tx,
    logIndex: logIndex ?? this.logIndex,
    providerAddress: providerAddress ?? this.providerAddress,
    receivedUsdt: receivedUsdt ?? this.receivedUsdt,
    settledCount: settledCount ?? this.settledCount,
    settledAmount: settledAmount ?? this.settledAmount,
    notSettledCount: notSettledCount ?? this.notSettledCount,
    notSettledAmount: notSettledAmount ?? this.notSettledAmount,
    blockTimestamp: blockTimestamp ?? this.blockTimestamp,
    detectedAt: detectedAt ?? this.detectedAt,
    lastRetryAt: lastRetryAt.present ? lastRetryAt.value : this.lastRetryAt,
    retryCount: retryCount ?? this.retryCount,
  );
  UnmatchedSettledEventRow copyWithCompanion(
    UnmatchedSettledEventsCompanion data,
  ) {
    return UnmatchedSettledEventRow(
      tx: data.tx.present ? data.tx.value : this.tx,
      logIndex: data.logIndex.present ? data.logIndex.value : this.logIndex,
      providerAddress: data.providerAddress.present
          ? data.providerAddress.value
          : this.providerAddress,
      receivedUsdt: data.receivedUsdt.present
          ? data.receivedUsdt.value
          : this.receivedUsdt,
      settledCount: data.settledCount.present
          ? data.settledCount.value
          : this.settledCount,
      settledAmount: data.settledAmount.present
          ? data.settledAmount.value
          : this.settledAmount,
      notSettledCount: data.notSettledCount.present
          ? data.notSettledCount.value
          : this.notSettledCount,
      notSettledAmount: data.notSettledAmount.present
          ? data.notSettledAmount.value
          : this.notSettledAmount,
      blockTimestamp: data.blockTimestamp.present
          ? data.blockTimestamp.value
          : this.blockTimestamp,
      detectedAt: data.detectedAt.present
          ? data.detectedAt.value
          : this.detectedAt,
      lastRetryAt: data.lastRetryAt.present
          ? data.lastRetryAt.value
          : this.lastRetryAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnmatchedSettledEventRow(')
          ..write('tx: $tx, ')
          ..write('logIndex: $logIndex, ')
          ..write('providerAddress: $providerAddress, ')
          ..write('receivedUsdt: $receivedUsdt, ')
          ..write('settledCount: $settledCount, ')
          ..write('settledAmount: $settledAmount, ')
          ..write('notSettledCount: $notSettledCount, ')
          ..write('notSettledAmount: $notSettledAmount, ')
          ..write('blockTimestamp: $blockTimestamp, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('lastRetryAt: $lastRetryAt, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tx,
    logIndex,
    providerAddress,
    receivedUsdt,
    settledCount,
    settledAmount,
    notSettledCount,
    notSettledAmount,
    blockTimestamp,
    detectedAt,
    lastRetryAt,
    retryCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnmatchedSettledEventRow &&
          other.tx == this.tx &&
          other.logIndex == this.logIndex &&
          other.providerAddress == this.providerAddress &&
          other.receivedUsdt == this.receivedUsdt &&
          other.settledCount == this.settledCount &&
          other.settledAmount == this.settledAmount &&
          other.notSettledCount == this.notSettledCount &&
          other.notSettledAmount == this.notSettledAmount &&
          other.blockTimestamp == this.blockTimestamp &&
          other.detectedAt == this.detectedAt &&
          other.lastRetryAt == this.lastRetryAt &&
          other.retryCount == this.retryCount);
}

class UnmatchedSettledEventsCompanion
    extends UpdateCompanion<UnmatchedSettledEventRow> {
  final Value<String> tx;
  final Value<int> logIndex;
  final Value<String> providerAddress;
  final Value<String> receivedUsdt;
  final Value<int> settledCount;
  final Value<String> settledAmount;
  final Value<int> notSettledCount;
  final Value<String> notSettledAmount;
  final Value<int> blockTimestamp;
  final Value<int> detectedAt;
  final Value<int?> lastRetryAt;
  final Value<int> retryCount;
  final Value<int> rowid;
  const UnmatchedSettledEventsCompanion({
    this.tx = const Value.absent(),
    this.logIndex = const Value.absent(),
    this.providerAddress = const Value.absent(),
    this.receivedUsdt = const Value.absent(),
    this.settledCount = const Value.absent(),
    this.settledAmount = const Value.absent(),
    this.notSettledCount = const Value.absent(),
    this.notSettledAmount = const Value.absent(),
    this.blockTimestamp = const Value.absent(),
    this.detectedAt = const Value.absent(),
    this.lastRetryAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnmatchedSettledEventsCompanion.insert({
    required String tx,
    required int logIndex,
    required String providerAddress,
    required String receivedUsdt,
    required int settledCount,
    required String settledAmount,
    required int notSettledCount,
    required String notSettledAmount,
    required int blockTimestamp,
    required int detectedAt,
    this.lastRetryAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tx = Value(tx),
       logIndex = Value(logIndex),
       providerAddress = Value(providerAddress),
       receivedUsdt = Value(receivedUsdt),
       settledCount = Value(settledCount),
       settledAmount = Value(settledAmount),
       notSettledCount = Value(notSettledCount),
       notSettledAmount = Value(notSettledAmount),
       blockTimestamp = Value(blockTimestamp),
       detectedAt = Value(detectedAt);
  static Insertable<UnmatchedSettledEventRow> custom({
    Expression<String>? tx,
    Expression<int>? logIndex,
    Expression<String>? providerAddress,
    Expression<String>? receivedUsdt,
    Expression<int>? settledCount,
    Expression<String>? settledAmount,
    Expression<int>? notSettledCount,
    Expression<String>? notSettledAmount,
    Expression<int>? blockTimestamp,
    Expression<int>? detectedAt,
    Expression<int>? lastRetryAt,
    Expression<int>? retryCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tx != null) 'tx': tx,
      if (logIndex != null) 'log_index': logIndex,
      if (providerAddress != null) 'provider_address': providerAddress,
      if (receivedUsdt != null) 'received_usdt': receivedUsdt,
      if (settledCount != null) 'settled_count': settledCount,
      if (settledAmount != null) 'settled_amount': settledAmount,
      if (notSettledCount != null) 'not_settled_count': notSettledCount,
      if (notSettledAmount != null) 'not_settled_amount': notSettledAmount,
      if (blockTimestamp != null) 'block_timestamp': blockTimestamp,
      if (detectedAt != null) 'detected_at': detectedAt,
      if (lastRetryAt != null) 'last_retry_at': lastRetryAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnmatchedSettledEventsCompanion copyWith({
    Value<String>? tx,
    Value<int>? logIndex,
    Value<String>? providerAddress,
    Value<String>? receivedUsdt,
    Value<int>? settledCount,
    Value<String>? settledAmount,
    Value<int>? notSettledCount,
    Value<String>? notSettledAmount,
    Value<int>? blockTimestamp,
    Value<int>? detectedAt,
    Value<int?>? lastRetryAt,
    Value<int>? retryCount,
    Value<int>? rowid,
  }) {
    return UnmatchedSettledEventsCompanion(
      tx: tx ?? this.tx,
      logIndex: logIndex ?? this.logIndex,
      providerAddress: providerAddress ?? this.providerAddress,
      receivedUsdt: receivedUsdt ?? this.receivedUsdt,
      settledCount: settledCount ?? this.settledCount,
      settledAmount: settledAmount ?? this.settledAmount,
      notSettledCount: notSettledCount ?? this.notSettledCount,
      notSettledAmount: notSettledAmount ?? this.notSettledAmount,
      blockTimestamp: blockTimestamp ?? this.blockTimestamp,
      detectedAt: detectedAt ?? this.detectedAt,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
      retryCount: retryCount ?? this.retryCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tx.present) {
      map['tx'] = Variable<String>(tx.value);
    }
    if (logIndex.present) {
      map['log_index'] = Variable<int>(logIndex.value);
    }
    if (providerAddress.present) {
      map['provider_address'] = Variable<String>(providerAddress.value);
    }
    if (receivedUsdt.present) {
      map['received_usdt'] = Variable<String>(receivedUsdt.value);
    }
    if (settledCount.present) {
      map['settled_count'] = Variable<int>(settledCount.value);
    }
    if (settledAmount.present) {
      map['settled_amount'] = Variable<String>(settledAmount.value);
    }
    if (notSettledCount.present) {
      map['not_settled_count'] = Variable<int>(notSettledCount.value);
    }
    if (notSettledAmount.present) {
      map['not_settled_amount'] = Variable<String>(notSettledAmount.value);
    }
    if (blockTimestamp.present) {
      map['block_timestamp'] = Variable<int>(blockTimestamp.value);
    }
    if (detectedAt.present) {
      map['detected_at'] = Variable<int>(detectedAt.value);
    }
    if (lastRetryAt.present) {
      map['last_retry_at'] = Variable<int>(lastRetryAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnmatchedSettledEventsCompanion(')
          ..write('tx: $tx, ')
          ..write('logIndex: $logIndex, ')
          ..write('providerAddress: $providerAddress, ')
          ..write('receivedUsdt: $receivedUsdt, ')
          ..write('settledCount: $settledCount, ')
          ..write('settledAmount: $settledAmount, ')
          ..write('notSettledCount: $notSettledCount, ')
          ..write('notSettledAmount: $notSettledAmount, ')
          ..write('blockTimestamp: $blockTimestamp, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('lastRetryAt: $lastRetryAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProviderModelsTable extends ProviderModels
    with TableInfo<$ProviderModelsTable, ProviderModelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _modelNameMeta = const VerificationMeta(
    'modelName',
  );
  @override
  late final GeneratedColumn<String> modelName = GeneratedColumn<String>(
    'model_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contextWindowMeta = const VerificationMeta(
    'contextWindow',
  );
  @override
  late final GeneratedColumn<int> contextWindow = GeneratedColumn<int>(
    'context_window',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxOutputTokensMeta = const VerificationMeta(
    'maxOutputTokens',
  );
  @override
  late final GeneratedColumn<int> maxOutputTokens = GeneratedColumn<int>(
    'max_output_tokens',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modalityMeta = const VerificationMeta(
    'modality',
  );
  @override
  late final GeneratedColumn<String> modality = GeneratedColumn<String>(
    'modality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _promptPriceMeta = const VerificationMeta(
    'promptPrice',
  );
  @override
  late final GeneratedColumn<double> promptPrice = GeneratedColumn<double>(
    'prompt_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completionPriceMeta = const VerificationMeta(
    'completionPrice',
  );
  @override
  late final GeneratedColumn<double> completionPrice = GeneratedColumn<double>(
    'completion_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    modelName,
    displayName,
    description,
    contextWindow,
    maxOutputTokens,
    modality,
    promptPrice,
    completionPrice,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_models';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderModelRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('model_name')) {
      context.handle(
        _modelNameMeta,
        modelName.isAcceptableOrUnknown(data['model_name']!, _modelNameMeta),
      );
    } else if (isInserting) {
      context.missing(_modelNameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('context_window')) {
      context.handle(
        _contextWindowMeta,
        contextWindow.isAcceptableOrUnknown(
          data['context_window']!,
          _contextWindowMeta,
        ),
      );
    }
    if (data.containsKey('max_output_tokens')) {
      context.handle(
        _maxOutputTokensMeta,
        maxOutputTokens.isAcceptableOrUnknown(
          data['max_output_tokens']!,
          _maxOutputTokensMeta,
        ),
      );
    }
    if (data.containsKey('modality')) {
      context.handle(
        _modalityMeta,
        modality.isAcceptableOrUnknown(data['modality']!, _modalityMeta),
      );
    }
    if (data.containsKey('prompt_price')) {
      context.handle(
        _promptPriceMeta,
        promptPrice.isAcceptableOrUnknown(
          data['prompt_price']!,
          _promptPriceMeta,
        ),
      );
    }
    if (data.containsKey('completion_price')) {
      context.handle(
        _completionPriceMeta,
        completionPrice.isAcceptableOrUnknown(
          data['completion_price']!,
          _completionPriceMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {modelName};
  @override
  ProviderModelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderModelRow(
      modelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_name'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      contextWindow: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}context_window'],
      ),
      maxOutputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_output_tokens'],
      ),
      modality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modality'],
      )!,
      promptPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}prompt_price'],
      ),
      completionPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}completion_price'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProviderModelsTable createAlias(String alias) {
    return $ProviderModelsTable(attachedDatabase, alias);
  }
}

class ProviderModelRow extends DataClass
    implements Insertable<ProviderModelRow> {
  final String modelName;
  final String displayName;
  final String description;
  final int? contextWindow;
  final int? maxOutputTokens;
  final String modality;
  final double? promptPrice;
  final double? completionPrice;
  final int updatedAt;
  const ProviderModelRow({
    required this.modelName,
    required this.displayName,
    required this.description,
    this.contextWindow,
    this.maxOutputTokens,
    required this.modality,
    this.promptPrice,
    this.completionPrice,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['model_name'] = Variable<String>(modelName);
    map['display_name'] = Variable<String>(displayName);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || contextWindow != null) {
      map['context_window'] = Variable<int>(contextWindow);
    }
    if (!nullToAbsent || maxOutputTokens != null) {
      map['max_output_tokens'] = Variable<int>(maxOutputTokens);
    }
    map['modality'] = Variable<String>(modality);
    if (!nullToAbsent || promptPrice != null) {
      map['prompt_price'] = Variable<double>(promptPrice);
    }
    if (!nullToAbsent || completionPrice != null) {
      map['completion_price'] = Variable<double>(completionPrice);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ProviderModelsCompanion toCompanion(bool nullToAbsent) {
    return ProviderModelsCompanion(
      modelName: Value(modelName),
      displayName: Value(displayName),
      description: Value(description),
      contextWindow: contextWindow == null && nullToAbsent
          ? const Value.absent()
          : Value(contextWindow),
      maxOutputTokens: maxOutputTokens == null && nullToAbsent
          ? const Value.absent()
          : Value(maxOutputTokens),
      modality: Value(modality),
      promptPrice: promptPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(promptPrice),
      completionPrice: completionPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(completionPrice),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProviderModelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderModelRow(
      modelName: serializer.fromJson<String>(json['modelName']),
      displayName: serializer.fromJson<String>(json['displayName']),
      description: serializer.fromJson<String>(json['description']),
      contextWindow: serializer.fromJson<int?>(json['contextWindow']),
      maxOutputTokens: serializer.fromJson<int?>(json['maxOutputTokens']),
      modality: serializer.fromJson<String>(json['modality']),
      promptPrice: serializer.fromJson<double?>(json['promptPrice']),
      completionPrice: serializer.fromJson<double?>(json['completionPrice']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'modelName': serializer.toJson<String>(modelName),
      'displayName': serializer.toJson<String>(displayName),
      'description': serializer.toJson<String>(description),
      'contextWindow': serializer.toJson<int?>(contextWindow),
      'maxOutputTokens': serializer.toJson<int?>(maxOutputTokens),
      'modality': serializer.toJson<String>(modality),
      'promptPrice': serializer.toJson<double?>(promptPrice),
      'completionPrice': serializer.toJson<double?>(completionPrice),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ProviderModelRow copyWith({
    String? modelName,
    String? displayName,
    String? description,
    Value<int?> contextWindow = const Value.absent(),
    Value<int?> maxOutputTokens = const Value.absent(),
    String? modality,
    Value<double?> promptPrice = const Value.absent(),
    Value<double?> completionPrice = const Value.absent(),
    int? updatedAt,
  }) => ProviderModelRow(
    modelName: modelName ?? this.modelName,
    displayName: displayName ?? this.displayName,
    description: description ?? this.description,
    contextWindow: contextWindow.present
        ? contextWindow.value
        : this.contextWindow,
    maxOutputTokens: maxOutputTokens.present
        ? maxOutputTokens.value
        : this.maxOutputTokens,
    modality: modality ?? this.modality,
    promptPrice: promptPrice.present ? promptPrice.value : this.promptPrice,
    completionPrice: completionPrice.present
        ? completionPrice.value
        : this.completionPrice,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProviderModelRow copyWithCompanion(ProviderModelsCompanion data) {
    return ProviderModelRow(
      modelName: data.modelName.present ? data.modelName.value : this.modelName,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      description: data.description.present
          ? data.description.value
          : this.description,
      contextWindow: data.contextWindow.present
          ? data.contextWindow.value
          : this.contextWindow,
      maxOutputTokens: data.maxOutputTokens.present
          ? data.maxOutputTokens.value
          : this.maxOutputTokens,
      modality: data.modality.present ? data.modality.value : this.modality,
      promptPrice: data.promptPrice.present
          ? data.promptPrice.value
          : this.promptPrice,
      completionPrice: data.completionPrice.present
          ? data.completionPrice.value
          : this.completionPrice,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderModelRow(')
          ..write('modelName: $modelName, ')
          ..write('displayName: $displayName, ')
          ..write('description: $description, ')
          ..write('contextWindow: $contextWindow, ')
          ..write('maxOutputTokens: $maxOutputTokens, ')
          ..write('modality: $modality, ')
          ..write('promptPrice: $promptPrice, ')
          ..write('completionPrice: $completionPrice, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    modelName,
    displayName,
    description,
    contextWindow,
    maxOutputTokens,
    modality,
    promptPrice,
    completionPrice,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderModelRow &&
          other.modelName == this.modelName &&
          other.displayName == this.displayName &&
          other.description == this.description &&
          other.contextWindow == this.contextWindow &&
          other.maxOutputTokens == this.maxOutputTokens &&
          other.modality == this.modality &&
          other.promptPrice == this.promptPrice &&
          other.completionPrice == this.completionPrice &&
          other.updatedAt == this.updatedAt);
}

class ProviderModelsCompanion extends UpdateCompanion<ProviderModelRow> {
  final Value<String> modelName;
  final Value<String> displayName;
  final Value<String> description;
  final Value<int?> contextWindow;
  final Value<int?> maxOutputTokens;
  final Value<String> modality;
  final Value<double?> promptPrice;
  final Value<double?> completionPrice;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ProviderModelsCompanion({
    this.modelName = const Value.absent(),
    this.displayName = const Value.absent(),
    this.description = const Value.absent(),
    this.contextWindow = const Value.absent(),
    this.maxOutputTokens = const Value.absent(),
    this.modality = const Value.absent(),
    this.promptPrice = const Value.absent(),
    this.completionPrice = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProviderModelsCompanion.insert({
    required String modelName,
    this.displayName = const Value.absent(),
    this.description = const Value.absent(),
    this.contextWindow = const Value.absent(),
    this.maxOutputTokens = const Value.absent(),
    this.modality = const Value.absent(),
    this.promptPrice = const Value.absent(),
    this.completionPrice = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : modelName = Value(modelName);
  static Insertable<ProviderModelRow> custom({
    Expression<String>? modelName,
    Expression<String>? displayName,
    Expression<String>? description,
    Expression<int>? contextWindow,
    Expression<int>? maxOutputTokens,
    Expression<String>? modality,
    Expression<double>? promptPrice,
    Expression<double>? completionPrice,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (modelName != null) 'model_name': modelName,
      if (displayName != null) 'display_name': displayName,
      if (description != null) 'description': description,
      if (contextWindow != null) 'context_window': contextWindow,
      if (maxOutputTokens != null) 'max_output_tokens': maxOutputTokens,
      if (modality != null) 'modality': modality,
      if (promptPrice != null) 'prompt_price': promptPrice,
      if (completionPrice != null) 'completion_price': completionPrice,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProviderModelsCompanion copyWith({
    Value<String>? modelName,
    Value<String>? displayName,
    Value<String>? description,
    Value<int?>? contextWindow,
    Value<int?>? maxOutputTokens,
    Value<String>? modality,
    Value<double?>? promptPrice,
    Value<double?>? completionPrice,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProviderModelsCompanion(
      modelName: modelName ?? this.modelName,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      contextWindow: contextWindow ?? this.contextWindow,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      modality: modality ?? this.modality,
      promptPrice: promptPrice ?? this.promptPrice,
      completionPrice: completionPrice ?? this.completionPrice,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (modelName.present) {
      map['model_name'] = Variable<String>(modelName.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (contextWindow.present) {
      map['context_window'] = Variable<int>(contextWindow.value);
    }
    if (maxOutputTokens.present) {
      map['max_output_tokens'] = Variable<int>(maxOutputTokens.value);
    }
    if (modality.present) {
      map['modality'] = Variable<String>(modality.value);
    }
    if (promptPrice.present) {
      map['prompt_price'] = Variable<double>(promptPrice.value);
    }
    if (completionPrice.present) {
      map['completion_price'] = Variable<double>(completionPrice.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderModelsCompanion(')
          ..write('modelName: $modelName, ')
          ..write('displayName: $displayName, ')
          ..write('description: $description, ')
          ..write('contextWindow: $contextWindow, ')
          ..write('maxOutputTokens: $maxOutputTokens, ')
          ..write('modality: $modality, ')
          ..write('promptPrice: $promptPrice, ')
          ..write('completionPrice: $completionPrice, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final String key;
  final String value;
  const SettingsRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingsRow copyWith({String? key, String? value}) =>
      SettingsRow(key: key ?? this.key, value: value ?? this.value);
  SettingsRow copyWithCompanion(AppSettingsCompanion data) {
    return SettingsRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingsRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProviderLogsTable providerLogs = $ProviderLogsTable(this);
  late final $ProviderLlmVendorsTable providerLlmVendors =
      $ProviderLlmVendorsTable(this);
  late final $ProviderQuotationsTable providerQuotations =
      $ProviderQuotationsTable(this);
  late final $ProviderQuotationBuffersTable providerQuotationBuffers =
      $ProviderQuotationBuffersTable(this);
  late final $ProviderQuotationHistoriesTable providerQuotationHistories =
      $ProviderQuotationHistoriesTable(this);
  late final $ProviderChainSettlementsTable providerChainSettlements =
      $ProviderChainSettlementsTable(this);
  late final $ChainSyncCursorsTable chainSyncCursors = $ChainSyncCursorsTable(
    this,
  );
  late final $UnmatchedSettledEventsTable unmatchedSettledEvents =
      $UnmatchedSettledEventsTable(this);
  late final $ProviderModelsTable providerModels = $ProviderModelsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final Index idxProviderLogStatus = Index(
    'idx_provider_log_status',
    'CREATE INDEX idx_provider_log_status ON provider_log (processing_status)',
  );
  late final Index idxProviderLogChainStatus = Index(
    'idx_provider_log_chain_status',
    'CREATE INDEX idx_provider_log_chain_status ON provider_log (chain_status)',
  );
  late final Index idxProviderLogCreatedAt = Index(
    'idx_provider_log_created_at',
    'CREATE INDEX idx_provider_log_created_at ON provider_log (created_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    providerLogs,
    providerLlmVendors,
    providerQuotations,
    providerQuotationBuffers,
    providerQuotationHistories,
    providerChainSettlements,
    chainSyncCursors,
    unmatchedSettledEvents,
    providerModels,
    appSettings,
    idxProviderLogStatus,
    idxProviderLogChainStatus,
    idxProviderLogCreatedAt,
  ];
}

typedef $$ProviderLogsTableCreateCompanionBuilder =
    ProviderLogsCompanion Function({
      required String requestId,
      required String modelName,
      Value<int> inputTokens,
      Value<int> outputTokens,
      Value<int> amount,
      Value<String> processingStatus,
      Value<int> latencyMs,
      Value<String> errorMessage,
      Value<String> chainStatus,
      Value<String?> batchId,
      Value<String?> anchorTx,
      Value<String?> settleTx,
      Value<String?> settleFailedReason,
      Value<int?> logIndex,
      Value<int> providerInputPrice,
      Value<int> providerOutputPrice,
      Value<String?> relayInputToken,
      Value<String?> relayOutputToken,
      Value<int?> relayAmount,
      Value<String?> relayProcessingStatus,
      Value<int> createdAt,
      Value<int> rowid,
    });
typedef $$ProviderLogsTableUpdateCompanionBuilder =
    ProviderLogsCompanion Function({
      Value<String> requestId,
      Value<String> modelName,
      Value<int> inputTokens,
      Value<int> outputTokens,
      Value<int> amount,
      Value<String> processingStatus,
      Value<int> latencyMs,
      Value<String> errorMessage,
      Value<String> chainStatus,
      Value<String?> batchId,
      Value<String?> anchorTx,
      Value<String?> settleTx,
      Value<String?> settleFailedReason,
      Value<int?> logIndex,
      Value<int> providerInputPrice,
      Value<int> providerOutputPrice,
      Value<String?> relayInputToken,
      Value<String?> relayOutputToken,
      Value<int?> relayAmount,
      Value<String?> relayProcessingStatus,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$ProviderLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ProviderLogsTable> {
  $$ProviderLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latencyMs => $composableBuilder(
    column: $table.latencyMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chainStatus => $composableBuilder(
    column: $table.chainStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anchorTx => $composableBuilder(
    column: $table.anchorTx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settleTx => $composableBuilder(
    column: $table.settleTx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settleFailedReason => $composableBuilder(
    column: $table.settleFailedReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get logIndex => $composableBuilder(
    column: $table.logIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get providerInputPrice => $composableBuilder(
    column: $table.providerInputPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get providerOutputPrice => $composableBuilder(
    column: $table.providerOutputPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relayInputToken => $composableBuilder(
    column: $table.relayInputToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relayOutputToken => $composableBuilder(
    column: $table.relayOutputToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get relayAmount => $composableBuilder(
    column: $table.relayAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relayProcessingStatus => $composableBuilder(
    column: $table.relayProcessingStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProviderLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProviderLogsTable> {
  $$ProviderLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latencyMs => $composableBuilder(
    column: $table.latencyMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chainStatus => $composableBuilder(
    column: $table.chainStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchorTx => $composableBuilder(
    column: $table.anchorTx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settleTx => $composableBuilder(
    column: $table.settleTx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settleFailedReason => $composableBuilder(
    column: $table.settleFailedReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get logIndex => $composableBuilder(
    column: $table.logIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get providerInputPrice => $composableBuilder(
    column: $table.providerInputPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get providerOutputPrice => $composableBuilder(
    column: $table.providerOutputPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relayInputToken => $composableBuilder(
    column: $table.relayInputToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relayOutputToken => $composableBuilder(
    column: $table.relayOutputToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get relayAmount => $composableBuilder(
    column: $table.relayAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relayProcessingStatus => $composableBuilder(
    column: $table.relayProcessingStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProviderLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProviderLogsTable> {
  $$ProviderLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get requestId =>
      $composableBuilder(column: $table.requestId, builder: (column) => column);

  GeneratedColumn<String> get modelName =>
      $composableBuilder(column: $table.modelName, builder: (column) => column);

  GeneratedColumn<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get latencyMs =>
      $composableBuilder(column: $table.latencyMs, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get chainStatus => $composableBuilder(
    column: $table.chainStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<String> get anchorTx =>
      $composableBuilder(column: $table.anchorTx, builder: (column) => column);

  GeneratedColumn<String> get settleTx =>
      $composableBuilder(column: $table.settleTx, builder: (column) => column);

  GeneratedColumn<String> get settleFailedReason => $composableBuilder(
    column: $table.settleFailedReason,
    builder: (column) => column,
  );

  GeneratedColumn<int> get logIndex =>
      $composableBuilder(column: $table.logIndex, builder: (column) => column);

  GeneratedColumn<int> get providerInputPrice => $composableBuilder(
    column: $table.providerInputPrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get providerOutputPrice => $composableBuilder(
    column: $table.providerOutputPrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relayInputToken => $composableBuilder(
    column: $table.relayInputToken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relayOutputToken => $composableBuilder(
    column: $table.relayOutputToken,
    builder: (column) => column,
  );

  GeneratedColumn<int> get relayAmount => $composableBuilder(
    column: $table.relayAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relayProcessingStatus => $composableBuilder(
    column: $table.relayProcessingStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProviderLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProviderLogsTable,
          ProviderLogRow,
          $$ProviderLogsTableFilterComposer,
          $$ProviderLogsTableOrderingComposer,
          $$ProviderLogsTableAnnotationComposer,
          $$ProviderLogsTableCreateCompanionBuilder,
          $$ProviderLogsTableUpdateCompanionBuilder,
          (
            ProviderLogRow,
            BaseReferences<_$AppDatabase, $ProviderLogsTable, ProviderLogRow>,
          ),
          ProviderLogRow,
          PrefetchHooks Function()
        > {
  $$ProviderLogsTableTableManager(_$AppDatabase db, $ProviderLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProviderLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProviderLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> requestId = const Value.absent(),
                Value<String> modelName = const Value.absent(),
                Value<int> inputTokens = const Value.absent(),
                Value<int> outputTokens = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> processingStatus = const Value.absent(),
                Value<int> latencyMs = const Value.absent(),
                Value<String> errorMessage = const Value.absent(),
                Value<String> chainStatus = const Value.absent(),
                Value<String?> batchId = const Value.absent(),
                Value<String?> anchorTx = const Value.absent(),
                Value<String?> settleTx = const Value.absent(),
                Value<String?> settleFailedReason = const Value.absent(),
                Value<int?> logIndex = const Value.absent(),
                Value<int> providerInputPrice = const Value.absent(),
                Value<int> providerOutputPrice = const Value.absent(),
                Value<String?> relayInputToken = const Value.absent(),
                Value<String?> relayOutputToken = const Value.absent(),
                Value<int?> relayAmount = const Value.absent(),
                Value<String?> relayProcessingStatus = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderLogsCompanion(
                requestId: requestId,
                modelName: modelName,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                amount: amount,
                processingStatus: processingStatus,
                latencyMs: latencyMs,
                errorMessage: errorMessage,
                chainStatus: chainStatus,
                batchId: batchId,
                anchorTx: anchorTx,
                settleTx: settleTx,
                settleFailedReason: settleFailedReason,
                logIndex: logIndex,
                providerInputPrice: providerInputPrice,
                providerOutputPrice: providerOutputPrice,
                relayInputToken: relayInputToken,
                relayOutputToken: relayOutputToken,
                relayAmount: relayAmount,
                relayProcessingStatus: relayProcessingStatus,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String requestId,
                required String modelName,
                Value<int> inputTokens = const Value.absent(),
                Value<int> outputTokens = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> processingStatus = const Value.absent(),
                Value<int> latencyMs = const Value.absent(),
                Value<String> errorMessage = const Value.absent(),
                Value<String> chainStatus = const Value.absent(),
                Value<String?> batchId = const Value.absent(),
                Value<String?> anchorTx = const Value.absent(),
                Value<String?> settleTx = const Value.absent(),
                Value<String?> settleFailedReason = const Value.absent(),
                Value<int?> logIndex = const Value.absent(),
                Value<int> providerInputPrice = const Value.absent(),
                Value<int> providerOutputPrice = const Value.absent(),
                Value<String?> relayInputToken = const Value.absent(),
                Value<String?> relayOutputToken = const Value.absent(),
                Value<int?> relayAmount = const Value.absent(),
                Value<String?> relayProcessingStatus = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderLogsCompanion.insert(
                requestId: requestId,
                modelName: modelName,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                amount: amount,
                processingStatus: processingStatus,
                latencyMs: latencyMs,
                errorMessage: errorMessage,
                chainStatus: chainStatus,
                batchId: batchId,
                anchorTx: anchorTx,
                settleTx: settleTx,
                settleFailedReason: settleFailedReason,
                logIndex: logIndex,
                providerInputPrice: providerInputPrice,
                providerOutputPrice: providerOutputPrice,
                relayInputToken: relayInputToken,
                relayOutputToken: relayOutputToken,
                relayAmount: relayAmount,
                relayProcessingStatus: relayProcessingStatus,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProviderLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProviderLogsTable,
      ProviderLogRow,
      $$ProviderLogsTableFilterComposer,
      $$ProviderLogsTableOrderingComposer,
      $$ProviderLogsTableAnnotationComposer,
      $$ProviderLogsTableCreateCompanionBuilder,
      $$ProviderLogsTableUpdateCompanionBuilder,
      (
        ProviderLogRow,
        BaseReferences<_$AppDatabase, $ProviderLogsTable, ProviderLogRow>,
      ),
      ProviderLogRow,
      PrefetchHooks Function()
    >;
typedef $$ProviderLlmVendorsTableCreateCompanionBuilder =
    ProviderLlmVendorsCompanion Function({
      Value<int> vendorId,
      required String vendorName,
      required String endpoint,
      required String apiKey,
      Value<String> vendorModels,
      Value<String> adapterType,
      Value<bool> isActive,
      Value<bool> supportsStream,
    });
typedef $$ProviderLlmVendorsTableUpdateCompanionBuilder =
    ProviderLlmVendorsCompanion Function({
      Value<int> vendorId,
      Value<String> vendorName,
      Value<String> endpoint,
      Value<String> apiKey,
      Value<String> vendorModels,
      Value<String> adapterType,
      Value<bool> isActive,
      Value<bool> supportsStream,
    });

class $$ProviderLlmVendorsTableFilterComposer
    extends Composer<_$AppDatabase, $ProviderLlmVendorsTable> {
  $$ProviderLlmVendorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get vendorId => $composableBuilder(
    column: $table.vendorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendorName => $composableBuilder(
    column: $table.vendorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendorModels => $composableBuilder(
    column: $table.vendorModels,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adapterType => $composableBuilder(
    column: $table.adapterType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get supportsStream => $composableBuilder(
    column: $table.supportsStream,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProviderLlmVendorsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProviderLlmVendorsTable> {
  $$ProviderLlmVendorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get vendorId => $composableBuilder(
    column: $table.vendorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendorName => $composableBuilder(
    column: $table.vendorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendorModels => $composableBuilder(
    column: $table.vendorModels,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adapterType => $composableBuilder(
    column: $table.adapterType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get supportsStream => $composableBuilder(
    column: $table.supportsStream,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProviderLlmVendorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProviderLlmVendorsTable> {
  $$ProviderLlmVendorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get vendorId =>
      $composableBuilder(column: $table.vendorId, builder: (column) => column);

  GeneratedColumn<String> get vendorName => $composableBuilder(
    column: $table.vendorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get apiKey =>
      $composableBuilder(column: $table.apiKey, builder: (column) => column);

  GeneratedColumn<String> get vendorModels => $composableBuilder(
    column: $table.vendorModels,
    builder: (column) => column,
  );

  GeneratedColumn<String> get adapterType => $composableBuilder(
    column: $table.adapterType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get supportsStream => $composableBuilder(
    column: $table.supportsStream,
    builder: (column) => column,
  );
}

class $$ProviderLlmVendorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProviderLlmVendorsTable,
          ProviderLlmVendorRow,
          $$ProviderLlmVendorsTableFilterComposer,
          $$ProviderLlmVendorsTableOrderingComposer,
          $$ProviderLlmVendorsTableAnnotationComposer,
          $$ProviderLlmVendorsTableCreateCompanionBuilder,
          $$ProviderLlmVendorsTableUpdateCompanionBuilder,
          (
            ProviderLlmVendorRow,
            BaseReferences<
              _$AppDatabase,
              $ProviderLlmVendorsTable,
              ProviderLlmVendorRow
            >,
          ),
          ProviderLlmVendorRow,
          PrefetchHooks Function()
        > {
  $$ProviderLlmVendorsTableTableManager(
    _$AppDatabase db,
    $ProviderLlmVendorsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderLlmVendorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProviderLlmVendorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProviderLlmVendorsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> vendorId = const Value.absent(),
                Value<String> vendorName = const Value.absent(),
                Value<String> endpoint = const Value.absent(),
                Value<String> apiKey = const Value.absent(),
                Value<String> vendorModels = const Value.absent(),
                Value<String> adapterType = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> supportsStream = const Value.absent(),
              }) => ProviderLlmVendorsCompanion(
                vendorId: vendorId,
                vendorName: vendorName,
                endpoint: endpoint,
                apiKey: apiKey,
                vendorModels: vendorModels,
                adapterType: adapterType,
                isActive: isActive,
                supportsStream: supportsStream,
              ),
          createCompanionCallback:
              ({
                Value<int> vendorId = const Value.absent(),
                required String vendorName,
                required String endpoint,
                required String apiKey,
                Value<String> vendorModels = const Value.absent(),
                Value<String> adapterType = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> supportsStream = const Value.absent(),
              }) => ProviderLlmVendorsCompanion.insert(
                vendorId: vendorId,
                vendorName: vendorName,
                endpoint: endpoint,
                apiKey: apiKey,
                vendorModels: vendorModels,
                adapterType: adapterType,
                isActive: isActive,
                supportsStream: supportsStream,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProviderLlmVendorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProviderLlmVendorsTable,
      ProviderLlmVendorRow,
      $$ProviderLlmVendorsTableFilterComposer,
      $$ProviderLlmVendorsTableOrderingComposer,
      $$ProviderLlmVendorsTableAnnotationComposer,
      $$ProviderLlmVendorsTableCreateCompanionBuilder,
      $$ProviderLlmVendorsTableUpdateCompanionBuilder,
      (
        ProviderLlmVendorRow,
        BaseReferences<
          _$AppDatabase,
          $ProviderLlmVendorsTable,
          ProviderLlmVendorRow
        >,
      ),
      ProviderLlmVendorRow,
      PrefetchHooks Function()
    >;
typedef $$ProviderQuotationsTableCreateCompanionBuilder =
    ProviderQuotationsCompanion Function({
      required String relayModelName,
      Value<int?> providerId,
      Value<String?> providerModel,
      Value<int> inputPricePer1k,
      Value<int> outputPricePer1k,
      Value<int?> submittedAt,
      Value<int> rowid,
    });
typedef $$ProviderQuotationsTableUpdateCompanionBuilder =
    ProviderQuotationsCompanion Function({
      Value<String> relayModelName,
      Value<int?> providerId,
      Value<String?> providerModel,
      Value<int> inputPricePer1k,
      Value<int> outputPricePer1k,
      Value<int?> submittedAt,
      Value<int> rowid,
    });

class $$ProviderQuotationsTableFilterComposer
    extends Composer<_$AppDatabase, $ProviderQuotationsTable> {
  $$ProviderQuotationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get relayModelName => $composableBuilder(
    column: $table.relayModelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerModel => $composableBuilder(
    column: $table.providerModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inputPricePer1k => $composableBuilder(
    column: $table.inputPricePer1k,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outputPricePer1k => $composableBuilder(
    column: $table.outputPricePer1k,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProviderQuotationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProviderQuotationsTable> {
  $$ProviderQuotationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get relayModelName => $composableBuilder(
    column: $table.relayModelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerModel => $composableBuilder(
    column: $table.providerModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inputPricePer1k => $composableBuilder(
    column: $table.inputPricePer1k,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outputPricePer1k => $composableBuilder(
    column: $table.outputPricePer1k,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProviderQuotationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProviderQuotationsTable> {
  $$ProviderQuotationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get relayModelName => $composableBuilder(
    column: $table.relayModelName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get providerModel => $composableBuilder(
    column: $table.providerModel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get inputPricePer1k => $composableBuilder(
    column: $table.inputPricePer1k,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outputPricePer1k => $composableBuilder(
    column: $table.outputPricePer1k,
    builder: (column) => column,
  );

  GeneratedColumn<int> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => column,
  );
}

class $$ProviderQuotationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProviderQuotationsTable,
          ProviderQuotationRow,
          $$ProviderQuotationsTableFilterComposer,
          $$ProviderQuotationsTableOrderingComposer,
          $$ProviderQuotationsTableAnnotationComposer,
          $$ProviderQuotationsTableCreateCompanionBuilder,
          $$ProviderQuotationsTableUpdateCompanionBuilder,
          (
            ProviderQuotationRow,
            BaseReferences<
              _$AppDatabase,
              $ProviderQuotationsTable,
              ProviderQuotationRow
            >,
          ),
          ProviderQuotationRow,
          PrefetchHooks Function()
        > {
  $$ProviderQuotationsTableTableManager(
    _$AppDatabase db,
    $ProviderQuotationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderQuotationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProviderQuotationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProviderQuotationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> relayModelName = const Value.absent(),
                Value<int?> providerId = const Value.absent(),
                Value<String?> providerModel = const Value.absent(),
                Value<int> inputPricePer1k = const Value.absent(),
                Value<int> outputPricePer1k = const Value.absent(),
                Value<int?> submittedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderQuotationsCompanion(
                relayModelName: relayModelName,
                providerId: providerId,
                providerModel: providerModel,
                inputPricePer1k: inputPricePer1k,
                outputPricePer1k: outputPricePer1k,
                submittedAt: submittedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String relayModelName,
                Value<int?> providerId = const Value.absent(),
                Value<String?> providerModel = const Value.absent(),
                Value<int> inputPricePer1k = const Value.absent(),
                Value<int> outputPricePer1k = const Value.absent(),
                Value<int?> submittedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderQuotationsCompanion.insert(
                relayModelName: relayModelName,
                providerId: providerId,
                providerModel: providerModel,
                inputPricePer1k: inputPricePer1k,
                outputPricePer1k: outputPricePer1k,
                submittedAt: submittedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProviderQuotationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProviderQuotationsTable,
      ProviderQuotationRow,
      $$ProviderQuotationsTableFilterComposer,
      $$ProviderQuotationsTableOrderingComposer,
      $$ProviderQuotationsTableAnnotationComposer,
      $$ProviderQuotationsTableCreateCompanionBuilder,
      $$ProviderQuotationsTableUpdateCompanionBuilder,
      (
        ProviderQuotationRow,
        BaseReferences<
          _$AppDatabase,
          $ProviderQuotationsTable,
          ProviderQuotationRow
        >,
      ),
      ProviderQuotationRow,
      PrefetchHooks Function()
    >;
typedef $$ProviderQuotationBuffersTableCreateCompanionBuilder =
    ProviderQuotationBuffersCompanion Function({
      required String relayModelName,
      Value<int?> providerId,
      Value<String?> providerModel,
      Value<int> inputPricePer1k,
      Value<int> outputPricePer1k,
      Value<int?> submittedAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });
typedef $$ProviderQuotationBuffersTableUpdateCompanionBuilder =
    ProviderQuotationBuffersCompanion Function({
      Value<String> relayModelName,
      Value<int?> providerId,
      Value<String?> providerModel,
      Value<int> inputPricePer1k,
      Value<int> outputPricePer1k,
      Value<int?> submittedAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$ProviderQuotationBuffersTableFilterComposer
    extends Composer<_$AppDatabase, $ProviderQuotationBuffersTable> {
  $$ProviderQuotationBuffersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get relayModelName => $composableBuilder(
    column: $table.relayModelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerModel => $composableBuilder(
    column: $table.providerModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inputPricePer1k => $composableBuilder(
    column: $table.inputPricePer1k,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outputPricePer1k => $composableBuilder(
    column: $table.outputPricePer1k,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProviderQuotationBuffersTableOrderingComposer
    extends Composer<_$AppDatabase, $ProviderQuotationBuffersTable> {
  $$ProviderQuotationBuffersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get relayModelName => $composableBuilder(
    column: $table.relayModelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerModel => $composableBuilder(
    column: $table.providerModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inputPricePer1k => $composableBuilder(
    column: $table.inputPricePer1k,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outputPricePer1k => $composableBuilder(
    column: $table.outputPricePer1k,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProviderQuotationBuffersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProviderQuotationBuffersTable> {
  $$ProviderQuotationBuffersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get relayModelName => $composableBuilder(
    column: $table.relayModelName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get providerModel => $composableBuilder(
    column: $table.providerModel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get inputPricePer1k => $composableBuilder(
    column: $table.inputPricePer1k,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outputPricePer1k => $composableBuilder(
    column: $table.outputPricePer1k,
    builder: (column) => column,
  );

  GeneratedColumn<int> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProviderQuotationBuffersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProviderQuotationBuffersTable,
          ProviderQuotationBufferRow,
          $$ProviderQuotationBuffersTableFilterComposer,
          $$ProviderQuotationBuffersTableOrderingComposer,
          $$ProviderQuotationBuffersTableAnnotationComposer,
          $$ProviderQuotationBuffersTableCreateCompanionBuilder,
          $$ProviderQuotationBuffersTableUpdateCompanionBuilder,
          (
            ProviderQuotationBufferRow,
            BaseReferences<
              _$AppDatabase,
              $ProviderQuotationBuffersTable,
              ProviderQuotationBufferRow
            >,
          ),
          ProviderQuotationBufferRow,
          PrefetchHooks Function()
        > {
  $$ProviderQuotationBuffersTableTableManager(
    _$AppDatabase db,
    $ProviderQuotationBuffersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderQuotationBuffersTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ProviderQuotationBuffersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProviderQuotationBuffersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> relayModelName = const Value.absent(),
                Value<int?> providerId = const Value.absent(),
                Value<String?> providerModel = const Value.absent(),
                Value<int> inputPricePer1k = const Value.absent(),
                Value<int> outputPricePer1k = const Value.absent(),
                Value<int?> submittedAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderQuotationBuffersCompanion(
                relayModelName: relayModelName,
                providerId: providerId,
                providerModel: providerModel,
                inputPricePer1k: inputPricePer1k,
                outputPricePer1k: outputPricePer1k,
                submittedAt: submittedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String relayModelName,
                Value<int?> providerId = const Value.absent(),
                Value<String?> providerModel = const Value.absent(),
                Value<int> inputPricePer1k = const Value.absent(),
                Value<int> outputPricePer1k = const Value.absent(),
                Value<int?> submittedAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderQuotationBuffersCompanion.insert(
                relayModelName: relayModelName,
                providerId: providerId,
                providerModel: providerModel,
                inputPricePer1k: inputPricePer1k,
                outputPricePer1k: outputPricePer1k,
                submittedAt: submittedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProviderQuotationBuffersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProviderQuotationBuffersTable,
      ProviderQuotationBufferRow,
      $$ProviderQuotationBuffersTableFilterComposer,
      $$ProviderQuotationBuffersTableOrderingComposer,
      $$ProviderQuotationBuffersTableAnnotationComposer,
      $$ProviderQuotationBuffersTableCreateCompanionBuilder,
      $$ProviderQuotationBuffersTableUpdateCompanionBuilder,
      (
        ProviderQuotationBufferRow,
        BaseReferences<
          _$AppDatabase,
          $ProviderQuotationBuffersTable,
          ProviderQuotationBufferRow
        >,
      ),
      ProviderQuotationBufferRow,
      PrefetchHooks Function()
    >;
typedef $$ProviderQuotationHistoriesTableCreateCompanionBuilder =
    ProviderQuotationHistoriesCompanion Function({
      Value<int> id,
      required String relayModelName,
      required int providerId,
      required String providerModel,
      Value<int> inputPricePer1k,
      Value<int> outputPricePer1k,
      required int submittedAt,
      Value<bool> isDeleted,
      Value<int> createdAt,
    });
typedef $$ProviderQuotationHistoriesTableUpdateCompanionBuilder =
    ProviderQuotationHistoriesCompanion Function({
      Value<int> id,
      Value<String> relayModelName,
      Value<int> providerId,
      Value<String> providerModel,
      Value<int> inputPricePer1k,
      Value<int> outputPricePer1k,
      Value<int> submittedAt,
      Value<bool> isDeleted,
      Value<int> createdAt,
    });

class $$ProviderQuotationHistoriesTableFilterComposer
    extends Composer<_$AppDatabase, $ProviderQuotationHistoriesTable> {
  $$ProviderQuotationHistoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relayModelName => $composableBuilder(
    column: $table.relayModelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerModel => $composableBuilder(
    column: $table.providerModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inputPricePer1k => $composableBuilder(
    column: $table.inputPricePer1k,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outputPricePer1k => $composableBuilder(
    column: $table.outputPricePer1k,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProviderQuotationHistoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProviderQuotationHistoriesTable> {
  $$ProviderQuotationHistoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relayModelName => $composableBuilder(
    column: $table.relayModelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerModel => $composableBuilder(
    column: $table.providerModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inputPricePer1k => $composableBuilder(
    column: $table.inputPricePer1k,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outputPricePer1k => $composableBuilder(
    column: $table.outputPricePer1k,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProviderQuotationHistoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProviderQuotationHistoriesTable> {
  $$ProviderQuotationHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get relayModelName => $composableBuilder(
    column: $table.relayModelName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get providerModel => $composableBuilder(
    column: $table.providerModel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get inputPricePer1k => $composableBuilder(
    column: $table.inputPricePer1k,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outputPricePer1k => $composableBuilder(
    column: $table.outputPricePer1k,
    builder: (column) => column,
  );

  GeneratedColumn<int> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProviderQuotationHistoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProviderQuotationHistoriesTable,
          ProviderQuotationHistoryRow,
          $$ProviderQuotationHistoriesTableFilterComposer,
          $$ProviderQuotationHistoriesTableOrderingComposer,
          $$ProviderQuotationHistoriesTableAnnotationComposer,
          $$ProviderQuotationHistoriesTableCreateCompanionBuilder,
          $$ProviderQuotationHistoriesTableUpdateCompanionBuilder,
          (
            ProviderQuotationHistoryRow,
            BaseReferences<
              _$AppDatabase,
              $ProviderQuotationHistoriesTable,
              ProviderQuotationHistoryRow
            >,
          ),
          ProviderQuotationHistoryRow,
          PrefetchHooks Function()
        > {
  $$ProviderQuotationHistoriesTableTableManager(
    _$AppDatabase db,
    $ProviderQuotationHistoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderQuotationHistoriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ProviderQuotationHistoriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProviderQuotationHistoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> relayModelName = const Value.absent(),
                Value<int> providerId = const Value.absent(),
                Value<String> providerModel = const Value.absent(),
                Value<int> inputPricePer1k = const Value.absent(),
                Value<int> outputPricePer1k = const Value.absent(),
                Value<int> submittedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => ProviderQuotationHistoriesCompanion(
                id: id,
                relayModelName: relayModelName,
                providerId: providerId,
                providerModel: providerModel,
                inputPricePer1k: inputPricePer1k,
                outputPricePer1k: outputPricePer1k,
                submittedAt: submittedAt,
                isDeleted: isDeleted,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String relayModelName,
                required int providerId,
                required String providerModel,
                Value<int> inputPricePer1k = const Value.absent(),
                Value<int> outputPricePer1k = const Value.absent(),
                required int submittedAt,
                Value<bool> isDeleted = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => ProviderQuotationHistoriesCompanion.insert(
                id: id,
                relayModelName: relayModelName,
                providerId: providerId,
                providerModel: providerModel,
                inputPricePer1k: inputPricePer1k,
                outputPricePer1k: outputPricePer1k,
                submittedAt: submittedAt,
                isDeleted: isDeleted,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProviderQuotationHistoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProviderQuotationHistoriesTable,
      ProviderQuotationHistoryRow,
      $$ProviderQuotationHistoriesTableFilterComposer,
      $$ProviderQuotationHistoriesTableOrderingComposer,
      $$ProviderQuotationHistoriesTableAnnotationComposer,
      $$ProviderQuotationHistoriesTableCreateCompanionBuilder,
      $$ProviderQuotationHistoriesTableUpdateCompanionBuilder,
      (
        ProviderQuotationHistoryRow,
        BaseReferences<
          _$AppDatabase,
          $ProviderQuotationHistoriesTable,
          ProviderQuotationHistoryRow
        >,
      ),
      ProviderQuotationHistoryRow,
      PrefetchHooks Function()
    >;
typedef $$ProviderChainSettlementsTableCreateCompanionBuilder =
    ProviderChainSettlementsCompanion Function({
      required String tx,
      required String providerAddress,
      required String relayStationAddress,
      required String receivedUsdt,
      required int settledCount,
      required String settledAmount,
      required int notSettledCount,
      required String notSettledAmount,
      required int createdAt,
      Value<int?> logIndex,
      Value<int> rowid,
    });
typedef $$ProviderChainSettlementsTableUpdateCompanionBuilder =
    ProviderChainSettlementsCompanion Function({
      Value<String> tx,
      Value<String> providerAddress,
      Value<String> relayStationAddress,
      Value<String> receivedUsdt,
      Value<int> settledCount,
      Value<String> settledAmount,
      Value<int> notSettledCount,
      Value<String> notSettledAmount,
      Value<int> createdAt,
      Value<int?> logIndex,
      Value<int> rowid,
    });

class $$ProviderChainSettlementsTableFilterComposer
    extends Composer<_$AppDatabase, $ProviderChainSettlementsTable> {
  $$ProviderChainSettlementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tx => $composableBuilder(
    column: $table.tx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerAddress => $composableBuilder(
    column: $table.providerAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relayStationAddress => $composableBuilder(
    column: $table.relayStationAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receivedUsdt => $composableBuilder(
    column: $table.receivedUsdt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get settledCount => $composableBuilder(
    column: $table.settledCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settledAmount => $composableBuilder(
    column: $table.settledAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notSettledCount => $composableBuilder(
    column: $table.notSettledCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notSettledAmount => $composableBuilder(
    column: $table.notSettledAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get logIndex => $composableBuilder(
    column: $table.logIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProviderChainSettlementsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProviderChainSettlementsTable> {
  $$ProviderChainSettlementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tx => $composableBuilder(
    column: $table.tx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerAddress => $composableBuilder(
    column: $table.providerAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relayStationAddress => $composableBuilder(
    column: $table.relayStationAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receivedUsdt => $composableBuilder(
    column: $table.receivedUsdt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get settledCount => $composableBuilder(
    column: $table.settledCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settledAmount => $composableBuilder(
    column: $table.settledAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notSettledCount => $composableBuilder(
    column: $table.notSettledCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notSettledAmount => $composableBuilder(
    column: $table.notSettledAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get logIndex => $composableBuilder(
    column: $table.logIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProviderChainSettlementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProviderChainSettlementsTable> {
  $$ProviderChainSettlementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tx =>
      $composableBuilder(column: $table.tx, builder: (column) => column);

  GeneratedColumn<String> get providerAddress => $composableBuilder(
    column: $table.providerAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relayStationAddress => $composableBuilder(
    column: $table.relayStationAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receivedUsdt => $composableBuilder(
    column: $table.receivedUsdt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get settledCount => $composableBuilder(
    column: $table.settledCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get settledAmount => $composableBuilder(
    column: $table.settledAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get notSettledCount => $composableBuilder(
    column: $table.notSettledCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notSettledAmount => $composableBuilder(
    column: $table.notSettledAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get logIndex =>
      $composableBuilder(column: $table.logIndex, builder: (column) => column);
}

class $$ProviderChainSettlementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProviderChainSettlementsTable,
          ProviderChainSettlementRow,
          $$ProviderChainSettlementsTableFilterComposer,
          $$ProviderChainSettlementsTableOrderingComposer,
          $$ProviderChainSettlementsTableAnnotationComposer,
          $$ProviderChainSettlementsTableCreateCompanionBuilder,
          $$ProviderChainSettlementsTableUpdateCompanionBuilder,
          (
            ProviderChainSettlementRow,
            BaseReferences<
              _$AppDatabase,
              $ProviderChainSettlementsTable,
              ProviderChainSettlementRow
            >,
          ),
          ProviderChainSettlementRow,
          PrefetchHooks Function()
        > {
  $$ProviderChainSettlementsTableTableManager(
    _$AppDatabase db,
    $ProviderChainSettlementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderChainSettlementsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ProviderChainSettlementsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProviderChainSettlementsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tx = const Value.absent(),
                Value<String> providerAddress = const Value.absent(),
                Value<String> relayStationAddress = const Value.absent(),
                Value<String> receivedUsdt = const Value.absent(),
                Value<int> settledCount = const Value.absent(),
                Value<String> settledAmount = const Value.absent(),
                Value<int> notSettledCount = const Value.absent(),
                Value<String> notSettledAmount = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> logIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderChainSettlementsCompanion(
                tx: tx,
                providerAddress: providerAddress,
                relayStationAddress: relayStationAddress,
                receivedUsdt: receivedUsdt,
                settledCount: settledCount,
                settledAmount: settledAmount,
                notSettledCount: notSettledCount,
                notSettledAmount: notSettledAmount,
                createdAt: createdAt,
                logIndex: logIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tx,
                required String providerAddress,
                required String relayStationAddress,
                required String receivedUsdt,
                required int settledCount,
                required String settledAmount,
                required int notSettledCount,
                required String notSettledAmount,
                required int createdAt,
                Value<int?> logIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderChainSettlementsCompanion.insert(
                tx: tx,
                providerAddress: providerAddress,
                relayStationAddress: relayStationAddress,
                receivedUsdt: receivedUsdt,
                settledCount: settledCount,
                settledAmount: settledAmount,
                notSettledCount: notSettledCount,
                notSettledAmount: notSettledAmount,
                createdAt: createdAt,
                logIndex: logIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProviderChainSettlementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProviderChainSettlementsTable,
      ProviderChainSettlementRow,
      $$ProviderChainSettlementsTableFilterComposer,
      $$ProviderChainSettlementsTableOrderingComposer,
      $$ProviderChainSettlementsTableAnnotationComposer,
      $$ProviderChainSettlementsTableCreateCompanionBuilder,
      $$ProviderChainSettlementsTableUpdateCompanionBuilder,
      (
        ProviderChainSettlementRow,
        BaseReferences<
          _$AppDatabase,
          $ProviderChainSettlementsTable,
          ProviderChainSettlementRow
        >,
      ),
      ProviderChainSettlementRow,
      PrefetchHooks Function()
    >;
typedef $$ChainSyncCursorsTableCreateCompanionBuilder =
    ChainSyncCursorsCompanion Function({
      required String scope,
      required int lastBlock,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$ChainSyncCursorsTableUpdateCompanionBuilder =
    ChainSyncCursorsCompanion Function({
      Value<String> scope,
      Value<int> lastBlock,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$ChainSyncCursorsTableFilterComposer
    extends Composer<_$AppDatabase, $ChainSyncCursorsTable> {
  $$ChainSyncCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastBlock => $composableBuilder(
    column: $table.lastBlock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChainSyncCursorsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChainSyncCursorsTable> {
  $$ChainSyncCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastBlock => $composableBuilder(
    column: $table.lastBlock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChainSyncCursorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChainSyncCursorsTable> {
  $$ChainSyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<int> get lastBlock =>
      $composableBuilder(column: $table.lastBlock, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ChainSyncCursorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChainSyncCursorsTable,
          ChainSyncCursorRow,
          $$ChainSyncCursorsTableFilterComposer,
          $$ChainSyncCursorsTableOrderingComposer,
          $$ChainSyncCursorsTableAnnotationComposer,
          $$ChainSyncCursorsTableCreateCompanionBuilder,
          $$ChainSyncCursorsTableUpdateCompanionBuilder,
          (
            ChainSyncCursorRow,
            BaseReferences<
              _$AppDatabase,
              $ChainSyncCursorsTable,
              ChainSyncCursorRow
            >,
          ),
          ChainSyncCursorRow,
          PrefetchHooks Function()
        > {
  $$ChainSyncCursorsTableTableManager(
    _$AppDatabase db,
    $ChainSyncCursorsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChainSyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChainSyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChainSyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> scope = const Value.absent(),
                Value<int> lastBlock = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChainSyncCursorsCompanion(
                scope: scope,
                lastBlock: lastBlock,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scope,
                required int lastBlock,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ChainSyncCursorsCompanion.insert(
                scope: scope,
                lastBlock: lastBlock,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChainSyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChainSyncCursorsTable,
      ChainSyncCursorRow,
      $$ChainSyncCursorsTableFilterComposer,
      $$ChainSyncCursorsTableOrderingComposer,
      $$ChainSyncCursorsTableAnnotationComposer,
      $$ChainSyncCursorsTableCreateCompanionBuilder,
      $$ChainSyncCursorsTableUpdateCompanionBuilder,
      (
        ChainSyncCursorRow,
        BaseReferences<
          _$AppDatabase,
          $ChainSyncCursorsTable,
          ChainSyncCursorRow
        >,
      ),
      ChainSyncCursorRow,
      PrefetchHooks Function()
    >;
typedef $$UnmatchedSettledEventsTableCreateCompanionBuilder =
    UnmatchedSettledEventsCompanion Function({
      required String tx,
      required int logIndex,
      required String providerAddress,
      required String receivedUsdt,
      required int settledCount,
      required String settledAmount,
      required int notSettledCount,
      required String notSettledAmount,
      required int blockTimestamp,
      required int detectedAt,
      Value<int?> lastRetryAt,
      Value<int> retryCount,
      Value<int> rowid,
    });
typedef $$UnmatchedSettledEventsTableUpdateCompanionBuilder =
    UnmatchedSettledEventsCompanion Function({
      Value<String> tx,
      Value<int> logIndex,
      Value<String> providerAddress,
      Value<String> receivedUsdt,
      Value<int> settledCount,
      Value<String> settledAmount,
      Value<int> notSettledCount,
      Value<String> notSettledAmount,
      Value<int> blockTimestamp,
      Value<int> detectedAt,
      Value<int?> lastRetryAt,
      Value<int> retryCount,
      Value<int> rowid,
    });

class $$UnmatchedSettledEventsTableFilterComposer
    extends Composer<_$AppDatabase, $UnmatchedSettledEventsTable> {
  $$UnmatchedSettledEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tx => $composableBuilder(
    column: $table.tx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get logIndex => $composableBuilder(
    column: $table.logIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerAddress => $composableBuilder(
    column: $table.providerAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receivedUsdt => $composableBuilder(
    column: $table.receivedUsdt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get settledCount => $composableBuilder(
    column: $table.settledCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settledAmount => $composableBuilder(
    column: $table.settledAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notSettledCount => $composableBuilder(
    column: $table.notSettledCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notSettledAmount => $composableBuilder(
    column: $table.notSettledAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get blockTimestamp => $composableBuilder(
    column: $table.blockTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastRetryAt => $composableBuilder(
    column: $table.lastRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UnmatchedSettledEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $UnmatchedSettledEventsTable> {
  $$UnmatchedSettledEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tx => $composableBuilder(
    column: $table.tx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get logIndex => $composableBuilder(
    column: $table.logIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerAddress => $composableBuilder(
    column: $table.providerAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receivedUsdt => $composableBuilder(
    column: $table.receivedUsdt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get settledCount => $composableBuilder(
    column: $table.settledCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settledAmount => $composableBuilder(
    column: $table.settledAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notSettledCount => $composableBuilder(
    column: $table.notSettledCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notSettledAmount => $composableBuilder(
    column: $table.notSettledAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get blockTimestamp => $composableBuilder(
    column: $table.blockTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastRetryAt => $composableBuilder(
    column: $table.lastRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UnmatchedSettledEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnmatchedSettledEventsTable> {
  $$UnmatchedSettledEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tx =>
      $composableBuilder(column: $table.tx, builder: (column) => column);

  GeneratedColumn<int> get logIndex =>
      $composableBuilder(column: $table.logIndex, builder: (column) => column);

  GeneratedColumn<String> get providerAddress => $composableBuilder(
    column: $table.providerAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receivedUsdt => $composableBuilder(
    column: $table.receivedUsdt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get settledCount => $composableBuilder(
    column: $table.settledCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get settledAmount => $composableBuilder(
    column: $table.settledAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get notSettledCount => $composableBuilder(
    column: $table.notSettledCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notSettledAmount => $composableBuilder(
    column: $table.notSettledAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get blockTimestamp => $composableBuilder(
    column: $table.blockTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastRetryAt => $composableBuilder(
    column: $table.lastRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );
}

class $$UnmatchedSettledEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UnmatchedSettledEventsTable,
          UnmatchedSettledEventRow,
          $$UnmatchedSettledEventsTableFilterComposer,
          $$UnmatchedSettledEventsTableOrderingComposer,
          $$UnmatchedSettledEventsTableAnnotationComposer,
          $$UnmatchedSettledEventsTableCreateCompanionBuilder,
          $$UnmatchedSettledEventsTableUpdateCompanionBuilder,
          (
            UnmatchedSettledEventRow,
            BaseReferences<
              _$AppDatabase,
              $UnmatchedSettledEventsTable,
              UnmatchedSettledEventRow
            >,
          ),
          UnmatchedSettledEventRow,
          PrefetchHooks Function()
        > {
  $$UnmatchedSettledEventsTableTableManager(
    _$AppDatabase db,
    $UnmatchedSettledEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnmatchedSettledEventsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$UnmatchedSettledEventsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UnmatchedSettledEventsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tx = const Value.absent(),
                Value<int> logIndex = const Value.absent(),
                Value<String> providerAddress = const Value.absent(),
                Value<String> receivedUsdt = const Value.absent(),
                Value<int> settledCount = const Value.absent(),
                Value<String> settledAmount = const Value.absent(),
                Value<int> notSettledCount = const Value.absent(),
                Value<String> notSettledAmount = const Value.absent(),
                Value<int> blockTimestamp = const Value.absent(),
                Value<int> detectedAt = const Value.absent(),
                Value<int?> lastRetryAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnmatchedSettledEventsCompanion(
                tx: tx,
                logIndex: logIndex,
                providerAddress: providerAddress,
                receivedUsdt: receivedUsdt,
                settledCount: settledCount,
                settledAmount: settledAmount,
                notSettledCount: notSettledCount,
                notSettledAmount: notSettledAmount,
                blockTimestamp: blockTimestamp,
                detectedAt: detectedAt,
                lastRetryAt: lastRetryAt,
                retryCount: retryCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tx,
                required int logIndex,
                required String providerAddress,
                required String receivedUsdt,
                required int settledCount,
                required String settledAmount,
                required int notSettledCount,
                required String notSettledAmount,
                required int blockTimestamp,
                required int detectedAt,
                Value<int?> lastRetryAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnmatchedSettledEventsCompanion.insert(
                tx: tx,
                logIndex: logIndex,
                providerAddress: providerAddress,
                receivedUsdt: receivedUsdt,
                settledCount: settledCount,
                settledAmount: settledAmount,
                notSettledCount: notSettledCount,
                notSettledAmount: notSettledAmount,
                blockTimestamp: blockTimestamp,
                detectedAt: detectedAt,
                lastRetryAt: lastRetryAt,
                retryCount: retryCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UnmatchedSettledEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UnmatchedSettledEventsTable,
      UnmatchedSettledEventRow,
      $$UnmatchedSettledEventsTableFilterComposer,
      $$UnmatchedSettledEventsTableOrderingComposer,
      $$UnmatchedSettledEventsTableAnnotationComposer,
      $$UnmatchedSettledEventsTableCreateCompanionBuilder,
      $$UnmatchedSettledEventsTableUpdateCompanionBuilder,
      (
        UnmatchedSettledEventRow,
        BaseReferences<
          _$AppDatabase,
          $UnmatchedSettledEventsTable,
          UnmatchedSettledEventRow
        >,
      ),
      UnmatchedSettledEventRow,
      PrefetchHooks Function()
    >;
typedef $$ProviderModelsTableCreateCompanionBuilder =
    ProviderModelsCompanion Function({
      required String modelName,
      Value<String> displayName,
      Value<String> description,
      Value<int?> contextWindow,
      Value<int?> maxOutputTokens,
      Value<String> modality,
      Value<double?> promptPrice,
      Value<double?> completionPrice,
      Value<int> updatedAt,
      Value<int> rowid,
    });
typedef $$ProviderModelsTableUpdateCompanionBuilder =
    ProviderModelsCompanion Function({
      Value<String> modelName,
      Value<String> displayName,
      Value<String> description,
      Value<int?> contextWindow,
      Value<int?> maxOutputTokens,
      Value<String> modality,
      Value<double?> promptPrice,
      Value<double?> completionPrice,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$ProviderModelsTableFilterComposer
    extends Composer<_$AppDatabase, $ProviderModelsTable> {
  $$ProviderModelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get contextWindow => $composableBuilder(
    column: $table.contextWindow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxOutputTokens => $composableBuilder(
    column: $table.maxOutputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modality => $composableBuilder(
    column: $table.modality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get promptPrice => $composableBuilder(
    column: $table.promptPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get completionPrice => $composableBuilder(
    column: $table.completionPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProviderModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProviderModelsTable> {
  $$ProviderModelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get contextWindow => $composableBuilder(
    column: $table.contextWindow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxOutputTokens => $composableBuilder(
    column: $table.maxOutputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modality => $composableBuilder(
    column: $table.modality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get promptPrice => $composableBuilder(
    column: $table.promptPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get completionPrice => $composableBuilder(
    column: $table.completionPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProviderModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProviderModelsTable> {
  $$ProviderModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get modelName =>
      $composableBuilder(column: $table.modelName, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get contextWindow => $composableBuilder(
    column: $table.contextWindow,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxOutputTokens => $composableBuilder(
    column: $table.maxOutputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modality =>
      $composableBuilder(column: $table.modality, builder: (column) => column);

  GeneratedColumn<double> get promptPrice => $composableBuilder(
    column: $table.promptPrice,
    builder: (column) => column,
  );

  GeneratedColumn<double> get completionPrice => $composableBuilder(
    column: $table.completionPrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProviderModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProviderModelsTable,
          ProviderModelRow,
          $$ProviderModelsTableFilterComposer,
          $$ProviderModelsTableOrderingComposer,
          $$ProviderModelsTableAnnotationComposer,
          $$ProviderModelsTableCreateCompanionBuilder,
          $$ProviderModelsTableUpdateCompanionBuilder,
          (
            ProviderModelRow,
            BaseReferences<
              _$AppDatabase,
              $ProviderModelsTable,
              ProviderModelRow
            >,
          ),
          ProviderModelRow,
          PrefetchHooks Function()
        > {
  $$ProviderModelsTableTableManager(
    _$AppDatabase db,
    $ProviderModelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderModelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProviderModelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProviderModelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> modelName = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int?> contextWindow = const Value.absent(),
                Value<int?> maxOutputTokens = const Value.absent(),
                Value<String> modality = const Value.absent(),
                Value<double?> promptPrice = const Value.absent(),
                Value<double?> completionPrice = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderModelsCompanion(
                modelName: modelName,
                displayName: displayName,
                description: description,
                contextWindow: contextWindow,
                maxOutputTokens: maxOutputTokens,
                modality: modality,
                promptPrice: promptPrice,
                completionPrice: completionPrice,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String modelName,
                Value<String> displayName = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int?> contextWindow = const Value.absent(),
                Value<int?> maxOutputTokens = const Value.absent(),
                Value<String> modality = const Value.absent(),
                Value<double?> promptPrice = const Value.absent(),
                Value<double?> completionPrice = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderModelsCompanion.insert(
                modelName: modelName,
                displayName: displayName,
                description: description,
                contextWindow: contextWindow,
                maxOutputTokens: maxOutputTokens,
                modality: modality,
                promptPrice: promptPrice,
                completionPrice: completionPrice,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProviderModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProviderModelsTable,
      ProviderModelRow,
      $$ProviderModelsTableFilterComposer,
      $$ProviderModelsTableOrderingComposer,
      $$ProviderModelsTableAnnotationComposer,
      $$ProviderModelsTableCreateCompanionBuilder,
      $$ProviderModelsTableUpdateCompanionBuilder,
      (
        ProviderModelRow,
        BaseReferences<_$AppDatabase, $ProviderModelsTable, ProviderModelRow>,
      ),
      ProviderModelRow,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          SettingsRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, SettingsRow>,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      SettingsRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        SettingsRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, SettingsRow>,
      ),
      SettingsRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProviderLogsTableTableManager get providerLogs =>
      $$ProviderLogsTableTableManager(_db, _db.providerLogs);
  $$ProviderLlmVendorsTableTableManager get providerLlmVendors =>
      $$ProviderLlmVendorsTableTableManager(_db, _db.providerLlmVendors);
  $$ProviderQuotationsTableTableManager get providerQuotations =>
      $$ProviderQuotationsTableTableManager(_db, _db.providerQuotations);
  $$ProviderQuotationBuffersTableTableManager get providerQuotationBuffers =>
      $$ProviderQuotationBuffersTableTableManager(
        _db,
        _db.providerQuotationBuffers,
      );
  $$ProviderQuotationHistoriesTableTableManager
  get providerQuotationHistories =>
      $$ProviderQuotationHistoriesTableTableManager(
        _db,
        _db.providerQuotationHistories,
      );
  $$ProviderChainSettlementsTableTableManager get providerChainSettlements =>
      $$ProviderChainSettlementsTableTableManager(
        _db,
        _db.providerChainSettlements,
      );
  $$ChainSyncCursorsTableTableManager get chainSyncCursors =>
      $$ChainSyncCursorsTableTableManager(_db, _db.chainSyncCursors);
  $$UnmatchedSettledEventsTableTableManager get unmatchedSettledEvents =>
      $$UnmatchedSettledEventsTableTableManager(
        _db,
        _db.unmatchedSettledEvents,
      );
  $$ProviderModelsTableTableManager get providerModels =>
      $$ProviderModelsTableTableManager(_db, _db.providerModels);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
