import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/core/api/session.dart';
import 'package:matchup/router.dart';

/// The roles screen and the setup run once per account (the login skips them afterwards).
void main() {
  test('an account remembers where it lands once its setup is done', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final session = container.read(sessionProvider.notifier);

    await session.signIn(1);
    expect(await session.setupDoneRoute(), isNull);

    await session.markSetupDone(Routes.home);
    expect(await session.setupDoneRoute(), Routes.home);

    // Another account on the same phone still goes through its own setup.
    await session.signIn(2);
    expect(await session.setupDoneRoute(), isNull);

    // A role chosen but its setup not finished: the next sign-in resumes it, not the roles.
    await session.signIn(3);
    expect(await session.nextRoute(), isNull);
    await session.markRoleChosen('/ply/sports');
    expect(await session.nextRoute(), '/ply/sports');
    await session.markSetupDone(Routes.home);
    expect(await session.nextRoute(), Routes.home);
    await session.signIn(1);

    // Signing out and back in keeps it.
    await session.signOut();
    await session.signIn(1);
    expect(await session.setupDoneRoute(), Routes.home);
  });
}
