import 'package:drift/drift.dart';

import '../app_database.dart';
import '../database_tables/mark_components_table.dart';
import '../database_tables/marks_table.dart';

part 'marks_dao.g.dart';

@DriftAccessor(
  tables: [
    MarkComponents,
    Marks,
  ],
)
class MarksDao extends DatabaseAccessor<AppDatabase>
    with _$MarksDaoMixin {
  MarksDao(super.db);

  // ============================================================
  // MARK COMPONENTS
  // ============================================================

  Stream<List<MarkComponent>> watchComponentsForSubject(
    int subjectId,
  ) {
    return (select(markComponents)
          ..where(
            (tbl) => tbl.subjectId.equals(subjectId),
          )
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.sortOrder,
                  mode: OrderingMode.asc,
                ),
            (tbl) => OrderingTerm(
                  expression: tbl.id,
                  mode: OrderingMode.asc,
                ),
          ]))
        .watch();
  }

  Future<List<MarkComponent>> getComponentsForSubject(
    int subjectId,
  ) {
    return (select(markComponents)
          ..where(
            (tbl) => tbl.subjectId.equals(subjectId),
          )
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.sortOrder,
                  mode: OrderingMode.asc,
                ),
            (tbl) => OrderingTerm(
                  expression: tbl.id,
                  mode: OrderingMode.asc,
                ),
          ]))
        .get();
  }

  Future<MarkComponent?> getComponent(int id) {
    return (select(markComponents)
          ..where(
            (tbl) => tbl.id.equals(id),
          ))
        .getSingleOrNull();
  }

  Future<int> insertComponent(
    MarkComponentsCompanion entry,
  ) {
    return into(markComponents).insert(entry);
  }

  Future<bool> updateComponent(
    int id,
    MarkComponentsCompanion entry,
  ) async {
    final count = await (update(markComponents)
          ..where(
            (tbl) => tbl.id.equals(id),
          ))
        .write(entry);

    return count > 0;
  }

  Future<void> deleteComponent(int id) async {
    await transaction(() async {
      await (delete(marks)
            ..where(
              (tbl) => tbl.componentId.equals(id),
            ))
          .go();

      await (delete(markComponents)
            ..where(
              (tbl) => tbl.id.equals(id),
            ))
          .go();
    });
  }

  // ============================================================
  // MARKS
  // ============================================================

  Stream<List<Mark>> watchAllMarks() {
    return (select(marks)
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.id,
                  mode: OrderingMode.asc,
                ),
          ]))
        .watch();
  }

  Stream<List<Mark>> watchMarksForSubject(
    int subjectId,
  ) {
    return (select(marks)
          ..where(
            (tbl) => tbl.subjectId.equals(subjectId),
          )
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.componentId,
                  mode: OrderingMode.asc,
                ),
          ]))
        .watch();
  }

  Future<List<Mark>> getMarksForSubject(
    int subjectId,
  ) {
    return (select(marks)
          ..where(
            (tbl) => tbl.subjectId.equals(subjectId),
          )
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.componentId,
                  mode: OrderingMode.asc,
                ),
          ]))
        .get();
  }

  Future<Mark?> getMark({
    required int subjectId,
    required int componentId,
  }) {
    return (select(marks)
          ..where(
            (tbl) =>
                tbl.subjectId.equals(subjectId) &
                tbl.componentId.equals(componentId),
          ))
        .getSingleOrNull();
  }

  Future<int> insertMark(
    MarksCompanion entry,
  ) {
    return into(marks).insert(entry);
  }

  Future<bool> updateMark(
    int id,
    MarksCompanion entry,
  ) async {
    final count = await (update(marks)
          ..where(
            (tbl) => tbl.id.equals(id),
          ))
        .write(entry);

    return count > 0;
  }

  Future<void> deleteMark(int id) async {
    await (delete(marks)
          ..where(
            (tbl) => tbl.id.equals(id),
          ))
        .go();
  }

  // ============================================================
  // SAVE / UPSERT MARK
  // ============================================================

  Future<int> saveMark({
    required int subjectId,
    required int componentId,
    required double? obtainedMarks,
  }) async {
    final existing = await getMark(
      subjectId: subjectId,
      componentId: componentId,
    );

    if (existing != null) {
      await updateMark(
        existing.id,
        MarksCompanion(
          obtainedMarks: Value(obtainedMarks),
          updatedAt: Value(DateTime.now()),
        ),
      );

      return existing.id;
    }

    return insertMark(
      MarksCompanion.insert(
        subjectId: subjectId,
        componentId: componentId,
        obtainedMarks: Value(obtainedMarks),
      ),
    );
  }
}