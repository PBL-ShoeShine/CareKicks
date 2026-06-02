import 'package:carekicks/features/auth/views/login_page.dart';
import 'package:carekicks/features/auth/views/splash_screen.dart';
import 'package:carekicks/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('redirects from splash to login when no session exists', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const CareKicksApp());

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
