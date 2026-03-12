import '../shared_constants.dart';

/// D10 - Comments On/Off Creator Control Template
class CommentsControlTemplate {
  CommentsControlTemplate._();

  static String getTableName() => SharedConstants.electionsTable;
  static String getColumnName() => SharedConstants.allowComments;

  static bool getDefaultValue() => true;

  static String getDisabledMessage() => 'Comments disabled by creator';

  static String getImplementationGuide() =>
      '''
D10 - Comments Control Implementation Guide:
1. Table: ${getTableName()}
2. Column: ${getColumnName()} (boolean, default: ${getDefaultValue()})
3. Election creation: add toggle "Allow comments"
4. Vote detail screen: hide comment input if ${getColumnName()} == false
5. Show message: "${getDisabledMessage()}"
6. Web/Mobile sync: same column name ensures cross-platform consistency
''';
}
