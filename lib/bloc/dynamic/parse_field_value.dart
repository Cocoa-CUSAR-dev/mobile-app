// APP-3: extracted from DynamicBloc._parseValue (was a private method, so
// nothing outside dynamic.dart -- including a test file -- could reach it
// at all, Dart privacy being per-file). Pulled out as a top-level pure
// function specifically so this coercion logic (one of the few genuinely
// pure, easily-testable pieces in the dynamic form pipeline) can have real
// unit tests without needing to stand up a whole DynamicBloc + TaskBloc +
// mocked HTTP layer just to reach it.
dynamic parseFieldValue(dynamic value, String? inputType) {
  if (value == null || value.toString().isEmpty) return null;
  switch (inputType) {
    case 'INT':
      return int.tryParse(value.toString());
    case 'FLOAT':
      return double.tryParse(value.toString());
    case 'BOOLEAN':
      return value is bool ? value : value.toString().toLowerCase() == 'true';
    default:
      // VARCHAR, OPTION (submits the selected choice's id), DATE,
      // DATETIME, GEODATA all pass through as-is (matches prior behaviour).
      return value.toString();
  }
}
