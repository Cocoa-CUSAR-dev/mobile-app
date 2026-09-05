// Unit tests for lib/models/task_item_model.dart.

import 'package:cocoa_supply/models/task_item_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskItem.fromJson', () {
    test('parses a fully-populated payload', () {
      final task = TaskItem.fromJson({
        'task_id': 't1',
        'title': 'ตัดหญ้า',
        'description': 'ตัดหญ้า 50 ไร่',
        'handler': 'activity',
        'status': 'COMPLETED',
        'open_at': '2026-01-11T13:40:00.000Z',
        'close_at': '2026-02-11T15:54:00.000Z',
        'answer': {'note': 'done'},
      });

      expect(task.taskId, 't1');
      expect(task.title, 'ตัดหญ้า');
      expect(task.status, 'COMPLETED');
      expect(task.openAt, DateTime.parse('2026-01-11T13:40:00.000Z'));
      expect(task.answer, {'note': 'done'});
    });

    test('defaults missing fields to empty strings and NOT_STARTED status', () {
      final task = TaskItem.fromJson({});
      expect(task.taskId, '');
      expect(task.title, '');
      expect(task.status, 'NOT_STARTED');
      expect(task.openAt, isNull);
    });
  });

  group('statusText', () {
    test('maps each known status to its Thai label', () {
      TaskItem withStatus(String status) => TaskItem(
        taskId: '1',
        title: '',
        description: '',
        handler: '',
        status: status,
      );

      expect(withStatus('COMPLETED').statusText, 'ดำเนินการแล้ว');
      expect(withStatus('PENDING').statusText, 'รออัปโหลด (Offline)');
      expect(withStatus('OVERDUE').statusText, 'เลยกำหนดส่ง');
      expect(withStatus('NOT_STARTED').statusText, 'รอดำเนินการ');
      expect(withStatus('SOMETHING_ELSE').statusText, 'รอดำเนินการ');
    });
  });

  group('canEdit', () {
    test('is false only when status is OVERDUE', () {
      TaskItem withStatus(String status) => TaskItem(
        taskId: '1',
        title: '',
        description: '',
        handler: '',
        status: status,
      );

      expect(withStatus('OVERDUE').canEdit, isFalse);
      expect(withStatus('COMPLETED').canEdit, isTrue);
      expect(withStatus('PENDING').canEdit, isTrue);
      expect(withStatus('NOT_STARTED').canEdit, isTrue);
    });
  });

  group('copyWithPending', () {
    test('preserves identity fields and sets status to PENDING with the new answer', () {
      final original = TaskItem(
        taskId: 't1',
        title: 'ตัดหญ้า',
        description: 'desc',
        handler: 'activity',
        status: 'NOT_STARTED',
      );

      final pending = original.copyWithPending({'note': 'saved offline'});

      expect(pending.taskId, original.taskId);
      expect(pending.title, original.title);
      expect(pending.status, 'PENDING');
      expect(pending.answer, {'note': 'saved offline'});
    });
  });
}
