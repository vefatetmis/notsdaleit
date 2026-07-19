// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, Document> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 8,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _folderMeta = const VerificationMeta('folder');
  @override
  late final GeneratedColumn<String> folder = GeneratedColumn<String>(
    'folder',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Kişisel'),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageSizeMeta = const VerificationMeta(
    'pageSize',
  );
  @override
  late final GeneratedColumn<String> pageSize = GeneratedColumn<String>(
    'page_size',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('serbest'),
  );
  static const VerificationMeta _pageColorMeta = const VerificationMeta(
    'pageColor',
  );
  @override
  late final GeneratedColumn<String> pageColor = GeneratedColumn<String>(
    'page_color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('beyaz'),
  );
  static const VerificationMeta _sharedIdMeta = const VerificationMeta(
    'sharedId',
  );
  @override
  late final GeneratedColumn<String> sharedId = GeneratedColumn<String>(
    'shared_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shareCodeMeta = const VerificationMeta(
    'shareCode',
  );
  @override
  late final GeneratedColumn<String> shareCode = GeneratedColumn<String>(
    'share_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    title,
    folder,
    body,
    filePath,
    pageCount,
    pageSize,
    pageColor,
    sharedId,
    shareCode,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<Document> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('folder')) {
      context.handle(
        _folderMeta,
        folder.isAcceptableOrUnknown(data['folder']!, _folderMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    if (data.containsKey('page_size')) {
      context.handle(
        _pageSizeMeta,
        pageSize.isAcceptableOrUnknown(data['page_size']!, _pageSizeMeta),
      );
    }
    if (data.containsKey('page_color')) {
      context.handle(
        _pageColorMeta,
        pageColor.isAcceptableOrUnknown(data['page_color']!, _pageColorMeta),
      );
    }
    if (data.containsKey('shared_id')) {
      context.handle(
        _sharedIdMeta,
        sharedId.isAcceptableOrUnknown(data['shared_id']!, _sharedIdMeta),
      );
    }
    if (data.containsKey('share_code')) {
      context.handle(
        _shareCodeMeta,
        shareCode.isAcceptableOrUnknown(data['share_code']!, _shareCodeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Document map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Document(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      type:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}type'],
          )!,
      title:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}title'],
          )!,
      folder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}folder'],
          )!,
      body:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}body'],
          )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      ),
      pageSize:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}page_size'],
          )!,
      pageColor:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}page_color'],
          )!,
      sharedId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shared_id'],
      ),
      shareCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}share_code'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }
}

class Document extends DataClass implements Insertable<Document> {
  final int id;
  final String type;
  final String title;
  final String folder;
  final String body;
  final String? filePath;
  final int? pageCount;
  final String pageSize;
  final String pageColor;
  final String? sharedId;
  final String? shareCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Document({
    required this.id,
    required this.type,
    required this.title,
    required this.folder,
    required this.body,
    this.filePath,
    this.pageCount,
    required this.pageSize,
    required this.pageColor,
    this.sharedId,
    this.shareCode,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['folder'] = Variable<String>(folder);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || pageCount != null) {
      map['page_count'] = Variable<int>(pageCount);
    }
    map['page_size'] = Variable<String>(pageSize);
    map['page_color'] = Variable<String>(pageColor);
    if (!nullToAbsent || sharedId != null) {
      map['shared_id'] = Variable<String>(sharedId);
    }
    if (!nullToAbsent || shareCode != null) {
      map['share_code'] = Variable<String>(shareCode);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      id: Value(id),
      type: Value(type),
      title: Value(title),
      folder: Value(folder),
      body: Value(body),
      filePath:
          filePath == null && nullToAbsent
              ? const Value.absent()
              : Value(filePath),
      pageCount:
          pageCount == null && nullToAbsent
              ? const Value.absent()
              : Value(pageCount),
      pageSize: Value(pageSize),
      pageColor: Value(pageColor),
      sharedId:
          sharedId == null && nullToAbsent
              ? const Value.absent()
              : Value(sharedId),
      shareCode:
          shareCode == null && nullToAbsent
              ? const Value.absent()
              : Value(shareCode),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Document.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Document(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      folder: serializer.fromJson<String>(json['folder']),
      body: serializer.fromJson<String>(json['body']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      pageCount: serializer.fromJson<int?>(json['pageCount']),
      pageSize: serializer.fromJson<String>(json['pageSize']),
      pageColor: serializer.fromJson<String>(json['pageColor']),
      sharedId: serializer.fromJson<String?>(json['sharedId']),
      shareCode: serializer.fromJson<String?>(json['shareCode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'folder': serializer.toJson<String>(folder),
      'body': serializer.toJson<String>(body),
      'filePath': serializer.toJson<String?>(filePath),
      'pageCount': serializer.toJson<int?>(pageCount),
      'pageSize': serializer.toJson<String>(pageSize),
      'pageColor': serializer.toJson<String>(pageColor),
      'sharedId': serializer.toJson<String?>(sharedId),
      'shareCode': serializer.toJson<String?>(shareCode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Document copyWith({
    int? id,
    String? type,
    String? title,
    String? folder,
    String? body,
    Value<String?> filePath = const Value.absent(),
    Value<int?> pageCount = const Value.absent(),
    String? pageSize,
    String? pageColor,
    Value<String?> sharedId = const Value.absent(),
    Value<String?> shareCode = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Document(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title ?? this.title,
    folder: folder ?? this.folder,
    body: body ?? this.body,
    filePath: filePath.present ? filePath.value : this.filePath,
    pageCount: pageCount.present ? pageCount.value : this.pageCount,
    pageSize: pageSize ?? this.pageSize,
    pageColor: pageColor ?? this.pageColor,
    sharedId: sharedId.present ? sharedId.value : this.sharedId,
    shareCode: shareCode.present ? shareCode.value : this.shareCode,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Document copyWithCompanion(DocumentsCompanion data) {
    return Document(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      folder: data.folder.present ? data.folder.value : this.folder,
      body: data.body.present ? data.body.value : this.body,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      pageSize: data.pageSize.present ? data.pageSize.value : this.pageSize,
      pageColor: data.pageColor.present ? data.pageColor.value : this.pageColor,
      sharedId: data.sharedId.present ? data.sharedId.value : this.sharedId,
      shareCode: data.shareCode.present ? data.shareCode.value : this.shareCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Document(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('folder: $folder, ')
          ..write('body: $body, ')
          ..write('filePath: $filePath, ')
          ..write('pageCount: $pageCount, ')
          ..write('pageSize: $pageSize, ')
          ..write('pageColor: $pageColor, ')
          ..write('sharedId: $sharedId, ')
          ..write('shareCode: $shareCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    title,
    folder,
    body,
    filePath,
    pageCount,
    pageSize,
    pageColor,
    sharedId,
    shareCode,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Document &&
          other.id == this.id &&
          other.type == this.type &&
          other.title == this.title &&
          other.folder == this.folder &&
          other.body == this.body &&
          other.filePath == this.filePath &&
          other.pageCount == this.pageCount &&
          other.pageSize == this.pageSize &&
          other.pageColor == this.pageColor &&
          other.sharedId == this.sharedId &&
          other.shareCode == this.shareCode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DocumentsCompanion extends UpdateCompanion<Document> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> title;
  final Value<String> folder;
  final Value<String> body;
  final Value<String?> filePath;
  final Value<int?> pageCount;
  final Value<String> pageSize;
  final Value<String> pageColor;
  final Value<String?> sharedId;
  final Value<String?> shareCode;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DocumentsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.folder = const Value.absent(),
    this.body = const Value.absent(),
    this.filePath = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.pageSize = const Value.absent(),
    this.pageColor = const Value.absent(),
    this.sharedId = const Value.absent(),
    this.shareCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DocumentsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    this.title = const Value.absent(),
    this.folder = const Value.absent(),
    this.body = const Value.absent(),
    this.filePath = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.pageSize = const Value.absent(),
    this.pageColor = const Value.absent(),
    this.sharedId = const Value.absent(),
    this.shareCode = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Document> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? folder,
    Expression<String>? body,
    Expression<String>? filePath,
    Expression<int>? pageCount,
    Expression<String>? pageSize,
    Expression<String>? pageColor,
    Expression<String>? sharedId,
    Expression<String>? shareCode,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (folder != null) 'folder': folder,
      if (body != null) 'body': body,
      if (filePath != null) 'file_path': filePath,
      if (pageCount != null) 'page_count': pageCount,
      if (pageSize != null) 'page_size': pageSize,
      if (pageColor != null) 'page_color': pageColor,
      if (sharedId != null) 'shared_id': sharedId,
      if (shareCode != null) 'share_code': shareCode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DocumentsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<String>? title,
    Value<String>? folder,
    Value<String>? body,
    Value<String?>? filePath,
    Value<int?>? pageCount,
    Value<String>? pageSize,
    Value<String>? pageColor,
    Value<String?>? sharedId,
    Value<String?>? shareCode,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return DocumentsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      folder: folder ?? this.folder,
      body: body ?? this.body,
      filePath: filePath ?? this.filePath,
      pageCount: pageCount ?? this.pageCount,
      pageSize: pageSize ?? this.pageSize,
      pageColor: pageColor ?? this.pageColor,
      sharedId: sharedId ?? this.sharedId,
      shareCode: shareCode ?? this.shareCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (folder.present) {
      map['folder'] = Variable<String>(folder.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (pageSize.present) {
      map['page_size'] = Variable<String>(pageSize.value);
    }
    if (pageColor.present) {
      map['page_color'] = Variable<String>(pageColor.value);
    }
    if (sharedId.present) {
      map['shared_id'] = Variable<String>(sharedId.value);
    }
    if (shareCode.present) {
      map['share_code'] = Variable<String>(shareCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('folder: $folder, ')
          ..write('body: $body, ')
          ..write('filePath: $filePath, ')
          ..write('pageCount: $pageCount, ')
          ..write('pageSize: $pageSize, ')
          ..write('pageColor: $pageColor, ')
          ..write('sharedId: $sharedId, ')
          ..write('shareCode: $shareCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $StrokesTable extends Strokes with TableInfo<$StrokesTable, Stroke> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StrokesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _docIdMeta = const VerificationMeta('docId');
  @override
  late final GeneratedColumn<int> docId = GeneratedColumn<int>(
    'doc_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES documents (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _toolMeta = const VerificationMeta('tool');
  @override
  late final GeneratedColumn<String> tool = GeneratedColumn<String>(
    'tool',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF262626),
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<double> width = GeneratedColumn<double>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<String> points = GeneratedColumn<String>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    docId,
    page,
    tool,
    color,
    width,
    points,
    remoteId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'strokes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Stroke> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('doc_id')) {
      context.handle(
        _docIdMeta,
        docId.isAcceptableOrUnknown(data['doc_id']!, _docIdMeta),
      );
    } else if (isInserting) {
      context.missing(_docIdMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    }
    if (data.containsKey('tool')) {
      context.handle(
        _toolMeta,
        tool.isAcceptableOrUnknown(data['tool']!, _toolMeta),
      );
    } else if (isInserting) {
      context.missing(_toolMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    } else if (isInserting) {
      context.missing(_pointsMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Stroke map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Stroke(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      docId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}doc_id'],
          )!,
      page:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}page'],
          )!,
      tool:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}tool'],
          )!,
      color:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}color'],
          )!,
      width:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}width'],
          )!,
      points:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}points'],
          )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $StrokesTable createAlias(String alias) {
    return $StrokesTable(attachedDatabase, alias);
  }
}

class Stroke extends DataClass implements Insertable<Stroke> {
  final int id;
  final int docId;
  final int page;
  final String tool;
  final int color;
  final double width;
  final String points;
  final String? remoteId;
  final DateTime createdAt;
  const Stroke({
    required this.id,
    required this.docId,
    required this.page,
    required this.tool,
    required this.color,
    required this.width,
    required this.points,
    this.remoteId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['doc_id'] = Variable<int>(docId);
    map['page'] = Variable<int>(page);
    map['tool'] = Variable<String>(tool);
    map['color'] = Variable<int>(color);
    map['width'] = Variable<double>(width);
    map['points'] = Variable<String>(points);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StrokesCompanion toCompanion(bool nullToAbsent) {
    return StrokesCompanion(
      id: Value(id),
      docId: Value(docId),
      page: Value(page),
      tool: Value(tool),
      color: Value(color),
      width: Value(width),
      points: Value(points),
      remoteId:
          remoteId == null && nullToAbsent
              ? const Value.absent()
              : Value(remoteId),
      createdAt: Value(createdAt),
    );
  }

  factory Stroke.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Stroke(
      id: serializer.fromJson<int>(json['id']),
      docId: serializer.fromJson<int>(json['docId']),
      page: serializer.fromJson<int>(json['page']),
      tool: serializer.fromJson<String>(json['tool']),
      color: serializer.fromJson<int>(json['color']),
      width: serializer.fromJson<double>(json['width']),
      points: serializer.fromJson<String>(json['points']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'docId': serializer.toJson<int>(docId),
      'page': serializer.toJson<int>(page),
      'tool': serializer.toJson<String>(tool),
      'color': serializer.toJson<int>(color),
      'width': serializer.toJson<double>(width),
      'points': serializer.toJson<String>(points),
      'remoteId': serializer.toJson<String?>(remoteId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Stroke copyWith({
    int? id,
    int? docId,
    int? page,
    String? tool,
    int? color,
    double? width,
    String? points,
    Value<String?> remoteId = const Value.absent(),
    DateTime? createdAt,
  }) => Stroke(
    id: id ?? this.id,
    docId: docId ?? this.docId,
    page: page ?? this.page,
    tool: tool ?? this.tool,
    color: color ?? this.color,
    width: width ?? this.width,
    points: points ?? this.points,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    createdAt: createdAt ?? this.createdAt,
  );
  Stroke copyWithCompanion(StrokesCompanion data) {
    return Stroke(
      id: data.id.present ? data.id.value : this.id,
      docId: data.docId.present ? data.docId.value : this.docId,
      page: data.page.present ? data.page.value : this.page,
      tool: data.tool.present ? data.tool.value : this.tool,
      color: data.color.present ? data.color.value : this.color,
      width: data.width.present ? data.width.value : this.width,
      points: data.points.present ? data.points.value : this.points,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Stroke(')
          ..write('id: $id, ')
          ..write('docId: $docId, ')
          ..write('page: $page, ')
          ..write('tool: $tool, ')
          ..write('color: $color, ')
          ..write('width: $width, ')
          ..write('points: $points, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    docId,
    page,
    tool,
    color,
    width,
    points,
    remoteId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Stroke &&
          other.id == this.id &&
          other.docId == this.docId &&
          other.page == this.page &&
          other.tool == this.tool &&
          other.color == this.color &&
          other.width == this.width &&
          other.points == this.points &&
          other.remoteId == this.remoteId &&
          other.createdAt == this.createdAt);
}

class StrokesCompanion extends UpdateCompanion<Stroke> {
  final Value<int> id;
  final Value<int> docId;
  final Value<int> page;
  final Value<String> tool;
  final Value<int> color;
  final Value<double> width;
  final Value<String> points;
  final Value<String?> remoteId;
  final Value<DateTime> createdAt;
  const StrokesCompanion({
    this.id = const Value.absent(),
    this.docId = const Value.absent(),
    this.page = const Value.absent(),
    this.tool = const Value.absent(),
    this.color = const Value.absent(),
    this.width = const Value.absent(),
    this.points = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  StrokesCompanion.insert({
    this.id = const Value.absent(),
    required int docId,
    this.page = const Value.absent(),
    required String tool,
    this.color = const Value.absent(),
    this.width = const Value.absent(),
    required String points,
    this.remoteId = const Value.absent(),
    required DateTime createdAt,
  }) : docId = Value(docId),
       tool = Value(tool),
       points = Value(points),
       createdAt = Value(createdAt);
  static Insertable<Stroke> custom({
    Expression<int>? id,
    Expression<int>? docId,
    Expression<int>? page,
    Expression<String>? tool,
    Expression<int>? color,
    Expression<double>? width,
    Expression<String>? points,
    Expression<String>? remoteId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (docId != null) 'doc_id': docId,
      if (page != null) 'page': page,
      if (tool != null) 'tool': tool,
      if (color != null) 'color': color,
      if (width != null) 'width': width,
      if (points != null) 'points': points,
      if (remoteId != null) 'remote_id': remoteId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  StrokesCompanion copyWith({
    Value<int>? id,
    Value<int>? docId,
    Value<int>? page,
    Value<String>? tool,
    Value<int>? color,
    Value<double>? width,
    Value<String>? points,
    Value<String?>? remoteId,
    Value<DateTime>? createdAt,
  }) {
    return StrokesCompanion(
      id: id ?? this.id,
      docId: docId ?? this.docId,
      page: page ?? this.page,
      tool: tool ?? this.tool,
      color: color ?? this.color,
      width: width ?? this.width,
      points: points ?? this.points,
      remoteId: remoteId ?? this.remoteId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (docId.present) {
      map['doc_id'] = Variable<int>(docId.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (tool.present) {
      map['tool'] = Variable<String>(tool.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (width.present) {
      map['width'] = Variable<double>(width.value);
    }
    if (points.present) {
      map['points'] = Variable<String>(points.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StrokesCompanion(')
          ..write('id: $id, ')
          ..write('docId: $docId, ')
          ..write('page: $page, ')
          ..write('tool: $tool, ')
          ..write('color: $color, ')
          ..write('width: $width, ')
          ..write('points: $points, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
    'done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remindAtMeta = const VerificationMeta(
    'remindAt',
  );
  @override
  late final GeneratedColumn<DateTime> remindAt = GeneratedColumn<DateTime>(
    'remind_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    done,
    dueDate,
    remindAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('remind_at')) {
      context.handle(
        _remindAtMeta,
        remindAt.isAcceptableOrUnknown(data['remind_at']!, _remindAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      title:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}title'],
          )!,
      done:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}done'],
          )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      remindAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}remind_at'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final int id;
  final String title;
  final bool done;
  final DateTime? dueDate;
  final DateTime? remindAt;
  final DateTime createdAt;
  const Task({
    required this.id,
    required this.title,
    required this.done,
    this.dueDate,
    this.remindAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['done'] = Variable<bool>(done);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || remindAt != null) {
      map['remind_at'] = Variable<DateTime>(remindAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      done: Value(done),
      dueDate:
          dueDate == null && nullToAbsent
              ? const Value.absent()
              : Value(dueDate),
      remindAt:
          remindAt == null && nullToAbsent
              ? const Value.absent()
              : Value(remindAt),
      createdAt: Value(createdAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      done: serializer.fromJson<bool>(json['done']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      remindAt: serializer.fromJson<DateTime?>(json['remindAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'done': serializer.toJson<bool>(done),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'remindAt': serializer.toJson<DateTime?>(remindAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Task copyWith({
    int? id,
    String? title,
    bool? done,
    Value<DateTime?> dueDate = const Value.absent(),
    Value<DateTime?> remindAt = const Value.absent(),
    DateTime? createdAt,
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    done: done ?? this.done,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    remindAt: remindAt.present ? remindAt.value : this.remindAt,
    createdAt: createdAt ?? this.createdAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      done: data.done.present ? data.done.value : this.done,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      remindAt: data.remindAt.present ? data.remindAt.value : this.remindAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('done: $done, ')
          ..write('dueDate: $dueDate, ')
          ..write('remindAt: $remindAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, done, dueDate, remindAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.done == this.done &&
          other.dueDate == this.dueDate &&
          other.remindAt == this.remindAt &&
          other.createdAt == this.createdAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<String> title;
  final Value<bool> done;
  final Value<DateTime?> dueDate;
  final Value<DateTime?> remindAt;
  final Value<DateTime> createdAt;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.done = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.done = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.remindAt = const Value.absent(),
    required DateTime createdAt,
  }) : title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<Task> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<bool>? done,
    Expression<DateTime>? dueDate,
    Expression<DateTime>? remindAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (done != null) 'done': done,
      if (dueDate != null) 'due_date': dueDate,
      if (remindAt != null) 'remind_at': remindAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TasksCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<bool>? done,
    Value<DateTime?>? dueDate,
    Value<DateTime?>? remindAt,
    Value<DateTime>? createdAt,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      done: done ?? this.done,
      dueDate: dueDate ?? this.dueDate,
      remindAt: remindAt ?? this.remindAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (remindAt.present) {
      map['remind_at'] = Variable<DateTime>(remindAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('done: $done, ')
          ..write('dueDate: $dueDate, ')
          ..write('remindAt: $remindAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DayNotesTable extends DayNotes with TableInfo<$DayNotesTable, DayNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayNotesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, day, body, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DayNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayNote(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      day:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}day'],
          )!,
      body:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}body'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $DayNotesTable createAlias(String alias) {
    return $DayNotesTable(attachedDatabase, alias);
  }
}

class DayNote extends DataClass implements Insertable<DayNote> {
  final int id;
  final DateTime day;
  final String body;
  final DateTime updatedAt;
  const DayNote({
    required this.id,
    required this.day,
    required this.body,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day'] = Variable<DateTime>(day);
    map['body'] = Variable<String>(body);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DayNotesCompanion toCompanion(bool nullToAbsent) {
    return DayNotesCompanion(
      id: Value(id),
      day: Value(day),
      body: Value(body),
      updatedAt: Value(updatedAt),
    );
  }

  factory DayNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayNote(
      id: serializer.fromJson<int>(json['id']),
      day: serializer.fromJson<DateTime>(json['day']),
      body: serializer.fromJson<String>(json['body']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'day': serializer.toJson<DateTime>(day),
      'body': serializer.toJson<String>(body),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DayNote copyWith({
    int? id,
    DateTime? day,
    String? body,
    DateTime? updatedAt,
  }) => DayNote(
    id: id ?? this.id,
    day: day ?? this.day,
    body: body ?? this.body,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DayNote copyWithCompanion(DayNotesCompanion data) {
    return DayNote(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      body: data.body.present ? data.body.value : this.body,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayNote(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('body: $body, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, day, body, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayNote &&
          other.id == this.id &&
          other.day == this.day &&
          other.body == this.body &&
          other.updatedAt == this.updatedAt);
}

class DayNotesCompanion extends UpdateCompanion<DayNote> {
  final Value<int> id;
  final Value<DateTime> day;
  final Value<String> body;
  final Value<DateTime> updatedAt;
  const DayNotesCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.body = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DayNotesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime day,
    this.body = const Value.absent(),
    required DateTime updatedAt,
  }) : day = Value(day),
       updatedAt = Value(updatedAt);
  static Insertable<DayNote> custom({
    Expression<int>? id,
    Expression<DateTime>? day,
    Expression<String>? body,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (body != null) 'body': body,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DayNotesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? day,
    Value<String>? body,
    Value<DateTime>? updatedAt,
  }) {
    return DayNotesCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayNotesCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('body: $body, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $RoutinesTable extends Routines with TableInfo<$RoutinesTable, Routine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutinesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _daysMeta = const VerificationMeta('days');
  @override
  late final GeneratedColumn<String> days = GeneratedColumn<String>(
    'days',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('1111111'),
  );
  static const VerificationMeta _remindAtMeta = const VerificationMeta(
    'remindAt',
  );
  @override
  late final GeneratedColumn<int> remindAt = GeneratedColumn<int>(
    'remind_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, days, remindAt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routines';
  @override
  VerificationContext validateIntegrity(
    Insertable<Routine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('days')) {
      context.handle(
        _daysMeta,
        days.isAcceptableOrUnknown(data['days']!, _daysMeta),
      );
    }
    if (data.containsKey('remind_at')) {
      context.handle(
        _remindAtMeta,
        remindAt.isAcceptableOrUnknown(data['remind_at']!, _remindAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Routine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Routine(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      title:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}title'],
          )!,
      days:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}days'],
          )!,
      remindAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remind_at'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $RoutinesTable createAlias(String alias) {
    return $RoutinesTable(attachedDatabase, alias);
  }
}

class Routine extends DataClass implements Insertable<Routine> {
  final int id;
  final String title;
  final String days;
  final int? remindAt;
  final DateTime createdAt;
  const Routine({
    required this.id,
    required this.title,
    required this.days,
    this.remindAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['days'] = Variable<String>(days);
    if (!nullToAbsent || remindAt != null) {
      map['remind_at'] = Variable<int>(remindAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RoutinesCompanion toCompanion(bool nullToAbsent) {
    return RoutinesCompanion(
      id: Value(id),
      title: Value(title),
      days: Value(days),
      remindAt:
          remindAt == null && nullToAbsent
              ? const Value.absent()
              : Value(remindAt),
      createdAt: Value(createdAt),
    );
  }

  factory Routine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Routine(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      days: serializer.fromJson<String>(json['days']),
      remindAt: serializer.fromJson<int?>(json['remindAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'days': serializer.toJson<String>(days),
      'remindAt': serializer.toJson<int?>(remindAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Routine copyWith({
    int? id,
    String? title,
    String? days,
    Value<int?> remindAt = const Value.absent(),
    DateTime? createdAt,
  }) => Routine(
    id: id ?? this.id,
    title: title ?? this.title,
    days: days ?? this.days,
    remindAt: remindAt.present ? remindAt.value : this.remindAt,
    createdAt: createdAt ?? this.createdAt,
  );
  Routine copyWithCompanion(RoutinesCompanion data) {
    return Routine(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      days: data.days.present ? data.days.value : this.days,
      remindAt: data.remindAt.present ? data.remindAt.value : this.remindAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Routine(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('days: $days, ')
          ..write('remindAt: $remindAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, days, remindAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Routine &&
          other.id == this.id &&
          other.title == this.title &&
          other.days == this.days &&
          other.remindAt == this.remindAt &&
          other.createdAt == this.createdAt);
}

class RoutinesCompanion extends UpdateCompanion<Routine> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> days;
  final Value<int?> remindAt;
  final Value<DateTime> createdAt;
  const RoutinesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.days = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RoutinesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.days = const Value.absent(),
    this.remindAt = const Value.absent(),
    required DateTime createdAt,
  }) : title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<Routine> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? days,
    Expression<int>? remindAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (days != null) 'days': days,
      if (remindAt != null) 'remind_at': remindAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RoutinesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? days,
    Value<int?>? remindAt,
    Value<DateTime>? createdAt,
  }) {
    return RoutinesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      days: days ?? this.days,
      remindAt: remindAt ?? this.remindAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (days.present) {
      map['days'] = Variable<String>(days.value);
    }
    if (remindAt.present) {
      map['remind_at'] = Variable<int>(remindAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutinesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('days: $days, ')
          ..write('remindAt: $remindAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $RoutineChecksTable extends RoutineChecks
    with TableInfo<$RoutineChecksTable, RoutineCheck> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutineChecksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _routineIdMeta = const VerificationMeta(
    'routineId',
  );
  @override
  late final GeneratedColumn<int> routineId = GeneratedColumn<int>(
    'routine_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES routines (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, routineId, day, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routine_checks';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoutineCheck> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('routine_id')) {
      context.handle(
        _routineIdMeta,
        routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routineIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoutineCheck map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineCheck(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      routineId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}routine_id'],
          )!,
      day:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}day'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $RoutineChecksTable createAlias(String alias) {
    return $RoutineChecksTable(attachedDatabase, alias);
  }
}

class RoutineCheck extends DataClass implements Insertable<RoutineCheck> {
  final int id;
  final int routineId;
  final DateTime day;
  final DateTime createdAt;
  const RoutineCheck({
    required this.id,
    required this.routineId,
    required this.day,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['routine_id'] = Variable<int>(routineId);
    map['day'] = Variable<DateTime>(day);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RoutineChecksCompanion toCompanion(bool nullToAbsent) {
    return RoutineChecksCompanion(
      id: Value(id),
      routineId: Value(routineId),
      day: Value(day),
      createdAt: Value(createdAt),
    );
  }

  factory RoutineCheck.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineCheck(
      id: serializer.fromJson<int>(json['id']),
      routineId: serializer.fromJson<int>(json['routineId']),
      day: serializer.fromJson<DateTime>(json['day']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'routineId': serializer.toJson<int>(routineId),
      'day': serializer.toJson<DateTime>(day),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RoutineCheck copyWith({
    int? id,
    int? routineId,
    DateTime? day,
    DateTime? createdAt,
  }) => RoutineCheck(
    id: id ?? this.id,
    routineId: routineId ?? this.routineId,
    day: day ?? this.day,
    createdAt: createdAt ?? this.createdAt,
  );
  RoutineCheck copyWithCompanion(RoutineChecksCompanion data) {
    return RoutineCheck(
      id: data.id.present ? data.id.value : this.id,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      day: data.day.present ? data.day.value : this.day,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineCheck(')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('day: $day, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, routineId, day, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineCheck &&
          other.id == this.id &&
          other.routineId == this.routineId &&
          other.day == this.day &&
          other.createdAt == this.createdAt);
}

class RoutineChecksCompanion extends UpdateCompanion<RoutineCheck> {
  final Value<int> id;
  final Value<int> routineId;
  final Value<DateTime> day;
  final Value<DateTime> createdAt;
  const RoutineChecksCompanion({
    this.id = const Value.absent(),
    this.routineId = const Value.absent(),
    this.day = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RoutineChecksCompanion.insert({
    this.id = const Value.absent(),
    required int routineId,
    required DateTime day,
    required DateTime createdAt,
  }) : routineId = Value(routineId),
       day = Value(day),
       createdAt = Value(createdAt);
  static Insertable<RoutineCheck> custom({
    Expression<int>? id,
    Expression<int>? routineId,
    Expression<DateTime>? day,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (routineId != null) 'routine_id': routineId,
      if (day != null) 'day': day,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RoutineChecksCompanion copyWith({
    Value<int>? id,
    Value<int>? routineId,
    Value<DateTime>? day,
    Value<DateTime>? createdAt,
  }) {
    return RoutineChecksCompanion(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      day: day ?? this.day,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<int>(routineId.value);
    }
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutineChecksCompanion(')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('day: $day, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FoldersTable extends Folders with TableInfo<$FoldersTable, Folder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Folder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Folder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Folder(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class Folder extends DataClass implements Insertable<Folder> {
  final int id;
  final String name;
  final DateTime createdAt;
  const Folder({required this.id, required this.name, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory Folder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Folder(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Folder copyWith({int? id, String? name, DateTime? createdAt}) => Folder(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );
  Folder copyWithCompanion(FoldersCompanion data) {
    return Folder(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Folder(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Folder &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class FoldersCompanion extends UpdateCompanion<Folder> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FoldersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required DateTime createdAt,
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Folder> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FoldersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
  }) {
    return FoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  late final $StrokesTable strokes = $StrokesTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $DayNotesTable dayNotes = $DayNotesTable(this);
  late final $RoutinesTable routines = $RoutinesTable(this);
  late final $RoutineChecksTable routineChecks = $RoutineChecksTable(this);
  late final $FoldersTable folders = $FoldersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    documents,
    strokes,
    tasks,
    dayNotes,
    routines,
    routineChecks,
    folders,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('strokes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'routines',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('routine_checks', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$DocumentsTableCreateCompanionBuilder =
    DocumentsCompanion Function({
      Value<int> id,
      required String type,
      Value<String> title,
      Value<String> folder,
      Value<String> body,
      Value<String?> filePath,
      Value<int?> pageCount,
      Value<String> pageSize,
      Value<String> pageColor,
      Value<String?> sharedId,
      Value<String?> shareCode,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$DocumentsTableUpdateCompanionBuilder =
    DocumentsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<String> title,
      Value<String> folder,
      Value<String> body,
      Value<String?> filePath,
      Value<int?> pageCount,
      Value<String> pageSize,
      Value<String> pageColor,
      Value<String?> sharedId,
      Value<String?> shareCode,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$DocumentsTableReferences
    extends BaseReferences<_$AppDatabase, $DocumentsTable, Document> {
  $$DocumentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StrokesTable, List<Stroke>> _strokesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.strokes,
    aliasName: $_aliasNameGenerator(db.documents.id, db.strokes.docId),
  );

  $$StrokesTableProcessedTableManager get strokesRefs {
    final manager = $$StrokesTableTableManager(
      $_db,
      $_db.strokes,
    ).filter((f) => f.docId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_strokesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pageSize => $composableBuilder(
    column: $table.pageSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pageColor => $composableBuilder(
    column: $table.pageColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sharedId => $composableBuilder(
    column: $table.sharedId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shareCode => $composableBuilder(
    column: $table.shareCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> strokesRefs(
    Expression<bool> Function($$StrokesTableFilterComposer f) f,
  ) {
    final $$StrokesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.strokes,
      getReferencedColumn: (t) => t.docId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StrokesTableFilterComposer(
            $db: $db,
            $table: $db.strokes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pageSize => $composableBuilder(
    column: $table.pageSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pageColor => $composableBuilder(
    column: $table.pageColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sharedId => $composableBuilder(
    column: $table.sharedId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shareCode => $composableBuilder(
    column: $table.shareCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get folder =>
      $composableBuilder(column: $table.folder, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<String> get pageSize =>
      $composableBuilder(column: $table.pageSize, builder: (column) => column);

  GeneratedColumn<String> get pageColor =>
      $composableBuilder(column: $table.pageColor, builder: (column) => column);

  GeneratedColumn<String> get sharedId =>
      $composableBuilder(column: $table.sharedId, builder: (column) => column);

  GeneratedColumn<String> get shareCode =>
      $composableBuilder(column: $table.shareCode, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> strokesRefs<T extends Object>(
    Expression<T> Function($$StrokesTableAnnotationComposer a) f,
  ) {
    final $$StrokesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.strokes,
      getReferencedColumn: (t) => t.docId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StrokesTableAnnotationComposer(
            $db: $db,
            $table: $db.strokes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentsTable,
          Document,
          $$DocumentsTableFilterComposer,
          $$DocumentsTableOrderingComposer,
          $$DocumentsTableAnnotationComposer,
          $$DocumentsTableCreateCompanionBuilder,
          $$DocumentsTableUpdateCompanionBuilder,
          (Document, $$DocumentsTableReferences),
          Document,
          PrefetchHooks Function({bool strokesRefs})
        > {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> folder = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<int?> pageCount = const Value.absent(),
                Value<String> pageSize = const Value.absent(),
                Value<String> pageColor = const Value.absent(),
                Value<String?> sharedId = const Value.absent(),
                Value<String?> shareCode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DocumentsCompanion(
                id: id,
                type: type,
                title: title,
                folder: folder,
                body: body,
                filePath: filePath,
                pageCount: pageCount,
                pageSize: pageSize,
                pageColor: pageColor,
                sharedId: sharedId,
                shareCode: shareCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                Value<String> title = const Value.absent(),
                Value<String> folder = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<int?> pageCount = const Value.absent(),
                Value<String> pageSize = const Value.absent(),
                Value<String> pageColor = const Value.absent(),
                Value<String?> sharedId = const Value.absent(),
                Value<String?> shareCode = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => DocumentsCompanion.insert(
                id: id,
                type: type,
                title: title,
                folder: folder,
                body: body,
                filePath: filePath,
                pageCount: pageCount,
                pageSize: pageSize,
                pageColor: pageColor,
                sharedId: sharedId,
                shareCode: shareCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$DocumentsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({strokesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (strokesRefs) db.strokes],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (strokesRefs)
                    await $_getPrefetchedData<
                      Document,
                      $DocumentsTable,
                      Stroke
                    >(
                      currentTable: table,
                      referencedTable: $$DocumentsTableReferences
                          ._strokesRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$DocumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).strokesRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) =>
                              referencedItems.where((e) => e.docId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentsTable,
      Document,
      $$DocumentsTableFilterComposer,
      $$DocumentsTableOrderingComposer,
      $$DocumentsTableAnnotationComposer,
      $$DocumentsTableCreateCompanionBuilder,
      $$DocumentsTableUpdateCompanionBuilder,
      (Document, $$DocumentsTableReferences),
      Document,
      PrefetchHooks Function({bool strokesRefs})
    >;
typedef $$StrokesTableCreateCompanionBuilder =
    StrokesCompanion Function({
      Value<int> id,
      required int docId,
      Value<int> page,
      required String tool,
      Value<int> color,
      Value<double> width,
      required String points,
      Value<String?> remoteId,
      required DateTime createdAt,
    });
typedef $$StrokesTableUpdateCompanionBuilder =
    StrokesCompanion Function({
      Value<int> id,
      Value<int> docId,
      Value<int> page,
      Value<String> tool,
      Value<int> color,
      Value<double> width,
      Value<String> points,
      Value<String?> remoteId,
      Value<DateTime> createdAt,
    });

final class $$StrokesTableReferences
    extends BaseReferences<_$AppDatabase, $StrokesTable, Stroke> {
  $$StrokesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DocumentsTable _docIdTable(_$AppDatabase db) => db.documents
      .createAlias($_aliasNameGenerator(db.strokes.docId, db.documents.id));

  $$DocumentsTableProcessedTableManager get docId {
    final $_column = $_itemColumn<int>('doc_id')!;

    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_docIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StrokesTableFilterComposer
    extends Composer<_$AppDatabase, $StrokesTable> {
  $$StrokesTableFilterComposer({
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

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tool => $composableBuilder(
    column: $table.tool,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DocumentsTableFilterComposer get docId {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.docId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StrokesTableOrderingComposer
    extends Composer<_$AppDatabase, $StrokesTable> {
  $$StrokesTableOrderingComposer({
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

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tool => $composableBuilder(
    column: $table.tool,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DocumentsTableOrderingComposer get docId {
    final $$DocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.docId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StrokesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StrokesTable> {
  $$StrokesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<String> get tool =>
      $composableBuilder(column: $table.tool, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<double> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<String> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DocumentsTableAnnotationComposer get docId {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.docId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StrokesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StrokesTable,
          Stroke,
          $$StrokesTableFilterComposer,
          $$StrokesTableOrderingComposer,
          $$StrokesTableAnnotationComposer,
          $$StrokesTableCreateCompanionBuilder,
          $$StrokesTableUpdateCompanionBuilder,
          (Stroke, $$StrokesTableReferences),
          Stroke,
          PrefetchHooks Function({bool docId})
        > {
  $$StrokesTableTableManager(_$AppDatabase db, $StrokesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$StrokesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$StrokesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$StrokesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> docId = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<String> tool = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<double> width = const Value.absent(),
                Value<String> points = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => StrokesCompanion(
                id: id,
                docId: docId,
                page: page,
                tool: tool,
                color: color,
                width: width,
                points: points,
                remoteId: remoteId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int docId,
                Value<int> page = const Value.absent(),
                required String tool,
                Value<int> color = const Value.absent(),
                Value<double> width = const Value.absent(),
                required String points,
                Value<String?> remoteId = const Value.absent(),
                required DateTime createdAt,
              }) => StrokesCompanion.insert(
                id: id,
                docId: docId,
                page: page,
                tool: tool,
                color: color,
                width: width,
                points: points,
                remoteId: remoteId,
                createdAt: createdAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$StrokesTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({docId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (docId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.docId,
                            referencedTable: $$StrokesTableReferences
                                ._docIdTable(db),
                            referencedColumn:
                                $$StrokesTableReferences._docIdTable(db).id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StrokesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StrokesTable,
      Stroke,
      $$StrokesTableFilterComposer,
      $$StrokesTableOrderingComposer,
      $$StrokesTableAnnotationComposer,
      $$StrokesTableCreateCompanionBuilder,
      $$StrokesTableUpdateCompanionBuilder,
      (Stroke, $$StrokesTableReferences),
      Stroke,
      PrefetchHooks Function({bool docId})
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      required String title,
      Value<bool> done,
      Value<DateTime?> dueDate,
      Value<DateTime?> remindAt,
      required DateTime createdAt,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<bool> done,
      Value<DateTime?> dueDate,
      Value<DateTime?> remindAt,
      Value<DateTime> createdAt,
    });

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get remindAt =>
      $composableBuilder(column: $table.remindAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
          Task,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> done = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<DateTime?> remindAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                done: done,
                dueDate: dueDate,
                remindAt: remindAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<bool> done = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<DateTime?> remindAt = const Value.absent(),
                required DateTime createdAt,
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                done: done,
                dueDate: dueDate,
                remindAt: remindAt,
                createdAt: createdAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
      Task,
      PrefetchHooks Function()
    >;
typedef $$DayNotesTableCreateCompanionBuilder =
    DayNotesCompanion Function({
      Value<int> id,
      required DateTime day,
      Value<String> body,
      required DateTime updatedAt,
    });
typedef $$DayNotesTableUpdateCompanionBuilder =
    DayNotesCompanion Function({
      Value<int> id,
      Value<DateTime> day,
      Value<String> body,
      Value<DateTime> updatedAt,
    });

class $$DayNotesTableFilterComposer
    extends Composer<_$AppDatabase, $DayNotesTable> {
  $$DayNotesTableFilterComposer({
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

  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $DayNotesTable> {
  $$DayNotesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayNotesTable> {
  $$DayNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DayNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayNotesTable,
          DayNote,
          $$DayNotesTableFilterComposer,
          $$DayNotesTableOrderingComposer,
          $$DayNotesTableAnnotationComposer,
          $$DayNotesTableCreateCompanionBuilder,
          $$DayNotesTableUpdateCompanionBuilder,
          (DayNote, BaseReferences<_$AppDatabase, $DayNotesTable, DayNote>),
          DayNote,
          PrefetchHooks Function()
        > {
  $$DayNotesTableTableManager(_$AppDatabase db, $DayNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$DayNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$DayNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$DayNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> day = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DayNotesCompanion(
                id: id,
                day: day,
                body: body,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime day,
                Value<String> body = const Value.absent(),
                required DateTime updatedAt,
              }) => DayNotesCompanion.insert(
                id: id,
                day: day,
                body: body,
                updatedAt: updatedAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayNotesTable,
      DayNote,
      $$DayNotesTableFilterComposer,
      $$DayNotesTableOrderingComposer,
      $$DayNotesTableAnnotationComposer,
      $$DayNotesTableCreateCompanionBuilder,
      $$DayNotesTableUpdateCompanionBuilder,
      (DayNote, BaseReferences<_$AppDatabase, $DayNotesTable, DayNote>),
      DayNote,
      PrefetchHooks Function()
    >;
typedef $$RoutinesTableCreateCompanionBuilder =
    RoutinesCompanion Function({
      Value<int> id,
      required String title,
      Value<String> days,
      Value<int?> remindAt,
      required DateTime createdAt,
    });
typedef $$RoutinesTableUpdateCompanionBuilder =
    RoutinesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> days,
      Value<int?> remindAt,
      Value<DateTime> createdAt,
    });

final class $$RoutinesTableReferences
    extends BaseReferences<_$AppDatabase, $RoutinesTable, Routine> {
  $$RoutinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RoutineChecksTable, List<RoutineCheck>>
  _routineChecksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.routineChecks,
    aliasName: $_aliasNameGenerator(db.routines.id, db.routineChecks.routineId),
  );

  $$RoutineChecksTableProcessedTableManager get routineChecksRefs {
    final manager = $$RoutineChecksTableTableManager(
      $_db,
      $_db.routineChecks,
    ).filter((f) => f.routineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_routineChecksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RoutinesTableFilterComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> routineChecksRefs(
    Expression<bool> Function($$RoutineChecksTableFilterComposer f) f,
  ) {
    final $$RoutineChecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routineChecks,
      getReferencedColumn: (t) => t.routineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutineChecksTableFilterComposer(
            $db: $db,
            $table: $db.routineChecks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoutinesTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RoutinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get days =>
      $composableBuilder(column: $table.days, builder: (column) => column);

  GeneratedColumn<int> get remindAt =>
      $composableBuilder(column: $table.remindAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> routineChecksRefs<T extends Object>(
    Expression<T> Function($$RoutineChecksTableAnnotationComposer a) f,
  ) {
    final $$RoutineChecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routineChecks,
      getReferencedColumn: (t) => t.routineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutineChecksTableAnnotationComposer(
            $db: $db,
            $table: $db.routineChecks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoutinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoutinesTable,
          Routine,
          $$RoutinesTableFilterComposer,
          $$RoutinesTableOrderingComposer,
          $$RoutinesTableAnnotationComposer,
          $$RoutinesTableCreateCompanionBuilder,
          $$RoutinesTableUpdateCompanionBuilder,
          (Routine, $$RoutinesTableReferences),
          Routine,
          PrefetchHooks Function({bool routineChecksRefs})
        > {
  $$RoutinesTableTableManager(_$AppDatabase db, $RoutinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$RoutinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$RoutinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$RoutinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> days = const Value.absent(),
                Value<int?> remindAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => RoutinesCompanion(
                id: id,
                title: title,
                days: days,
                remindAt: remindAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String> days = const Value.absent(),
                Value<int?> remindAt = const Value.absent(),
                required DateTime createdAt,
              }) => RoutinesCompanion.insert(
                id: id,
                title: title,
                days: days,
                remindAt: remindAt,
                createdAt: createdAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$RoutinesTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({routineChecksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (routineChecksRefs) db.routineChecks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (routineChecksRefs)
                    await $_getPrefetchedData<
                      Routine,
                      $RoutinesTable,
                      RoutineCheck
                    >(
                      currentTable: table,
                      referencedTable: $$RoutinesTableReferences
                          ._routineChecksRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$RoutinesTableReferences(
                                db,
                                table,
                                p0,
                              ).routineChecksRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.routineId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RoutinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoutinesTable,
      Routine,
      $$RoutinesTableFilterComposer,
      $$RoutinesTableOrderingComposer,
      $$RoutinesTableAnnotationComposer,
      $$RoutinesTableCreateCompanionBuilder,
      $$RoutinesTableUpdateCompanionBuilder,
      (Routine, $$RoutinesTableReferences),
      Routine,
      PrefetchHooks Function({bool routineChecksRefs})
    >;
typedef $$RoutineChecksTableCreateCompanionBuilder =
    RoutineChecksCompanion Function({
      Value<int> id,
      required int routineId,
      required DateTime day,
      required DateTime createdAt,
    });
typedef $$RoutineChecksTableUpdateCompanionBuilder =
    RoutineChecksCompanion Function({
      Value<int> id,
      Value<int> routineId,
      Value<DateTime> day,
      Value<DateTime> createdAt,
    });

final class $$RoutineChecksTableReferences
    extends BaseReferences<_$AppDatabase, $RoutineChecksTable, RoutineCheck> {
  $$RoutineChecksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RoutinesTable _routineIdTable(_$AppDatabase db) =>
      db.routines.createAlias(
        $_aliasNameGenerator(db.routineChecks.routineId, db.routines.id),
      );

  $$RoutinesTableProcessedTableManager get routineId {
    final $_column = $_itemColumn<int>('routine_id')!;

    final manager = $$RoutinesTableTableManager(
      $_db,
      $_db.routines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RoutineChecksTableFilterComposer
    extends Composer<_$AppDatabase, $RoutineChecksTable> {
  $$RoutineChecksTableFilterComposer({
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

  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RoutinesTableFilterComposer get routineId {
    final $$RoutinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutinesTableFilterComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutineChecksTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutineChecksTable> {
  $$RoutineChecksTableOrderingComposer({
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

  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RoutinesTableOrderingComposer get routineId {
    final $$RoutinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutinesTableOrderingComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutineChecksTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutineChecksTable> {
  $$RoutineChecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$RoutinesTableAnnotationComposer get routineId {
    final $$RoutinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutinesTableAnnotationComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutineChecksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoutineChecksTable,
          RoutineCheck,
          $$RoutineChecksTableFilterComposer,
          $$RoutineChecksTableOrderingComposer,
          $$RoutineChecksTableAnnotationComposer,
          $$RoutineChecksTableCreateCompanionBuilder,
          $$RoutineChecksTableUpdateCompanionBuilder,
          (RoutineCheck, $$RoutineChecksTableReferences),
          RoutineCheck,
          PrefetchHooks Function({bool routineId})
        > {
  $$RoutineChecksTableTableManager(_$AppDatabase db, $RoutineChecksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$RoutineChecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$RoutineChecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$RoutineChecksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> routineId = const Value.absent(),
                Value<DateTime> day = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => RoutineChecksCompanion(
                id: id,
                routineId: routineId,
                day: day,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int routineId,
                required DateTime day,
                required DateTime createdAt,
              }) => RoutineChecksCompanion.insert(
                id: id,
                routineId: routineId,
                day: day,
                createdAt: createdAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$RoutineChecksTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({routineId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (routineId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.routineId,
                            referencedTable: $$RoutineChecksTableReferences
                                ._routineIdTable(db),
                            referencedColumn:
                                $$RoutineChecksTableReferences
                                    ._routineIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RoutineChecksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoutineChecksTable,
      RoutineCheck,
      $$RoutineChecksTableFilterComposer,
      $$RoutineChecksTableOrderingComposer,
      $$RoutineChecksTableAnnotationComposer,
      $$RoutineChecksTableCreateCompanionBuilder,
      $$RoutineChecksTableUpdateCompanionBuilder,
      (RoutineCheck, $$RoutineChecksTableReferences),
      RoutineCheck,
      PrefetchHooks Function({bool routineId})
    >;
typedef $$FoldersTableCreateCompanionBuilder =
    FoldersCompanion Function({
      Value<int> id,
      required String name,
      required DateTime createdAt,
    });
typedef $$FoldersTableUpdateCompanionBuilder =
    FoldersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> createdAt,
    });

class $$FoldersTableFilterComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoldersTable,
          Folder,
          $$FoldersTableFilterComposer,
          $$FoldersTableOrderingComposer,
          $$FoldersTableAnnotationComposer,
          $$FoldersTableCreateCompanionBuilder,
          $$FoldersTableUpdateCompanionBuilder,
          (Folder, BaseReferences<_$AppDatabase, $FoldersTable, Folder>),
          Folder,
          PrefetchHooks Function()
        > {
  $$FoldersTableTableManager(_$AppDatabase db, $FoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FoldersCompanion(id: id, name: name, createdAt: createdAt),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required DateTime createdAt,
              }) => FoldersCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoldersTable,
      Folder,
      $$FoldersTableFilterComposer,
      $$FoldersTableOrderingComposer,
      $$FoldersTableAnnotationComposer,
      $$FoldersTableCreateCompanionBuilder,
      $$FoldersTableUpdateCompanionBuilder,
      (Folder, BaseReferences<_$AppDatabase, $FoldersTable, Folder>),
      Folder,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
  $$StrokesTableTableManager get strokes =>
      $$StrokesTableTableManager(_db, _db.strokes);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$DayNotesTableTableManager get dayNotes =>
      $$DayNotesTableTableManager(_db, _db.dayNotes);
  $$RoutinesTableTableManager get routines =>
      $$RoutinesTableTableManager(_db, _db.routines);
  $$RoutineChecksTableTableManager get routineChecks =>
      $$RoutineChecksTableTableManager(_db, _db.routineChecks);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
}
