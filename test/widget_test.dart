import 'package:echo_vault/app/app.dart';
import 'package:echo_vault/app/app_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Welcome explains the purpose and the current build boundary', (
    tester,
  ) async {
    await tester.pumpWidget(const EchoVaultApp());

    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('About EchoVault'));
    await tester.pumpAndSettle();
    expect(find.text(AppIdentity.name), findsOneWidget);
    expect(find.text('My thoughts\nbelong to me.'), findsOneWidget);
    expect(find.text('SESSION PREVIEW'), findsOneWidget);
    expect(find.textContaining('Encryption is not active.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Build information opens and can be dismissed', (tester) async {
    await tester.pumpWidget(const EchoVaultApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('About EchoVault'));
    await tester.pumpAndSettle();

    final aboutButton = find.widgetWithText(FilledButton, 'About this build');
    await tester.ensureVisible(aboutButton);
    await tester.tap(aboutButton);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('What is ready?'), findsOneWidget);
    expect(
      find.textContaining(
        'This build supports creating, editing, and deleting',
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Back to welcome'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(AppIdentity.name), findsOneWidget);
  });

  testWidgets('Welcome and dialog fit a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const EchoVaultApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('About EchoVault'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final aboutButton = find.widgetWithText(FilledButton, 'About this build');
    await tester.ensureVisible(aboutButton);
    await tester.tap(aboutButton);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Back to welcome'));
    await tester.tap(find.text('Back to welcome'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('creates, edits and deletes a journal entry', (tester) async {
    await tester.pumpWidget(const EchoVaultApp());
    await tester.pumpAndSettle();
    expect(find.text('A fresh page'), findsOneWidget);
    await tester.tap(find.text('New entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Save entry'));
    await tester.pumpAndSettle();
    expect(find.text('Write something before saving.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'First day');
    await tester.enterText(
      find.byType(TextFormField).last,
      'A sample thought.',
    );
    await tester.tap(find.byTooltip('Save entry'));
    await tester.pumpAndSettle();
    expect(find.text('First day'), findsOneWidget);
    expect(find.text('1 entry'), findsOneWidget);

    await tester.tap(find.text('First day'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).last,
      'An edited thought.',
    );
    await tester.tap(find.byTooltip('Save entry'));
    await tester.pumpAndSettle();
    expect(find.text('An edited thought.'), findsOneWidget);
    expect(find.text('1 entry'), findsOneWidget);

    await tester.tap(find.text('First day'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    await tester.tap(find.byTooltip('Delete entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('A fresh page'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('protects unsaved writing on system back', (tester) async {
    await tester.pumpWidget(const EchoVaultApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('New entry'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'Unsaved thought');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep writing'));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved thought'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to journal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('A fresh page'), findsOneWidget);
  });

  testWidgets('journal and editor fit small screens, large text and keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(const EchoVaultApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('New entry'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.enterText(
      find.byType(TextFormField).last,
      'A long sample thought ' * 15,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Save entry'));
    await tester.pumpAndSettle();
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.text('1 entry'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Untitled entry'), 150);
    expect(find.text('Untitled entry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
