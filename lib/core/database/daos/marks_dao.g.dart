// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marks_dao.dart';

// ignore_for_file: type=lint
mixin _$MarksDaoMixin on DatabaseAccessor<AppDatabase> {
  $MarkComponentsTable get markComponents => attachedDatabase.markComponents;
  $MarksTable get marks => attachedDatabase.marks;
  MarksDaoManager get managers => MarksDaoManager(this);
}

class MarksDaoManager {
  final _$MarksDaoMixin _db;
  MarksDaoManager(this._db);
  $$MarkComponentsTableTableManager get markComponents =>
      $$MarkComponentsTableTableManager(
        _db.attachedDatabase,
        _db.markComponents,
      );
  $$MarksTableTableManager get marks =>
      $$MarksTableTableManager(_db.attachedDatabase, _db.marks);
}
