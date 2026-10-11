import 'package:cocoa_supply/bloc/dynamic/form_questions.dart';
import 'package:flutter_test/flutter_test.dart';

// US2-13: what Kotlin's form detail sends for a dependent question -- plot_id
// with dependsOn: "farm_id", each plot carrying its farm as parentId.
Map<String, dynamic> farmQuestion() => {
      'fieldName': 'farm_id',
      'inputType': 'OPTION',
      'choices': [
        {'id': 'farm-a', 'name': 'ฟาร์ม A'},
        {'id': 'farm-b', 'name': 'ฟาร์ม B'},
      ],
    };

Map<String, dynamic> plotQuestion() => {
      'fieldName': 'plot_id',
      'inputType': 'OPTION',
      'dependsOn': 'farm_id',
      'choices': [
        {'id': 'plot-a1', 'name': 'แปลง A1', 'parentId': 'farm-a'},
        {'id': 'plot-a2', 'name': 'แปลง A2', 'parentId': 'farm-a'},
        {'id': 'plot-b1', 'name': 'แปลง B1', 'parentId': 'farm-b'},
      ],
    };

List<String> ids(List<Map<String, dynamic>> choices) =>
    choices.map((c) => c['id'] as String).toList();

void main() {
  group('visibleChoices', () {
    test('offers only the plots of the farm already picked', () {
      expect(
        ids(visibleChoices(plotQuestion(), {'farm_id': 'farm-a'})),
        ['plot-a1', 'plot-a2'],
      );
    });

    test('offers every plot while no farm is picked yet', () {
      expect(ids(visibleChoices(plotQuestion(), {})), hasLength(3));
    });

    test('leaves a question without dependsOn untouched', () {
      expect(ids(visibleChoices(farmQuestion(), {'farm_id': 'farm-a'})), ['farm-a', 'farm-b']);
    });

    test('keeps the choice shape the dropdown reads by position (id, name)', () {
      final choice = visibleChoices(plotQuestion(), {'farm_id': 'farm-b'}).single;
      expect(choice.values.first, 'plot-b1');
      expect(choice.values.elementAt(1), 'แปลง B1');
    });
  });

  group('staleDependentAnswers', () {
    test('clears a plot that is not on the newly picked farm', () {
      final answers = {'farm_id': 'farm-b', 'plot_id': 'plot-a1'};
      expect(
        staleDependentAnswers([farmQuestion(), plotQuestion()], 'farm_id', answers),
        ['plot_id'],
      );
    });

    test('keeps a plot that still belongs to the farm', () {
      final answers = {'farm_id': 'farm-a', 'plot_id': 'plot-a2'};
      expect(staleDependentAnswers([farmQuestion(), plotQuestion()], 'farm_id', answers), isEmpty);
    });

    test('cascades: a cleared district also clears its subdistrict', () {
      final questions = [
        {
          'fieldName': 'district_id',
          'dependsOn': 'province_id',
          'choices': [
            {'id': 'd1', 'name': 'อำเภอ 1', 'parentId': 'p1'},
            {'id': 'd2', 'name': 'อำเภอ 2', 'parentId': 'p2'},
          ],
        },
        {
          'fieldName': 'subdistrict_id',
          'dependsOn': 'district_id',
          'choices': [
            {'id': 's1', 'name': 'ตำบล 1', 'parentId': 'd1'},
          ],
        },
      ];
      final answers = {'province_id': 'p2', 'district_id': 'd1', 'subdistrict_id': 's1'};

      expect(
        staleDependentAnswers(questions, 'province_id', answers),
        ['district_id', 'subdistrict_id'],
      );
    });
  });
}
