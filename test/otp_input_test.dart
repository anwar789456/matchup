import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/theme/theme.dart';
import 'package:matchup/ui/ui.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('after a wrong code, typing starts a new code', (tester) async {
    final code = TextEditingController();
    String? error;
    late StateSetter setState;
    await tester.pumpWidget(MaterialApp(
      theme: MuTheme.light(),
      home: Scaffold(
        body: StatefulBuilder(builder: (context, set) {
          setState = set;
          return MuOtpInput(controller: code, error: error, autofocus: true);
        }),
      ),
    ));
    await tester.enterText(find.byType(TextField), '482915');
    setState(() => error = 'Code incorrect. Il te reste 2 essais.');
    await tester.pump();
    expect(code.text, '482915', reason: 'the digits stay after an error');

    // The platform appends the next keystroke to the full value.
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: '4829151',
      selection: TextSelection.collapsed(offset: 7),
    ));
    await tester.pump();
    expect(code.text, '1');
  });

  testWidgets('codes are capped at 6 digits and keep digits only', (tester) async {
    final code = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      theme: MuTheme.light(),
      home: Scaffold(body: MuOtpInput(controller: code)),
    ));
    await tester.enterText(find.byType(TextField), '12a34567');
    expect(code.text, '123456');
  });
}
