import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretary_app/core/network/token_provider.dart';
import 'package:secretary_app/domain/models/auth_requests.dart';
import 'package:secretary_app/domain/models/token_response.dart';
import 'package:secretary_app/presentation/providers/repository_provider.dart';
import 'package:secretary_app/presentation/providers/viewmodel_provider.dart';

import 'fakes.dart';

/// Changing a password revokes every other session for the account — that is
/// what stops a session opened with the old password from outliving it, which
/// was the whole gap. The device doing the changing is spared and handed a
/// replacement pair, and these tests pin the client half of that contract:
/// the app must name its own session, and must store what comes back.
class _RecordingAuthRepository extends FakeAuthRepository {
  ChangePasswordRequest? lastRequest;

  /// Null models the server signing this device out along with the others.
  _RecordingAuthRepository({this.session = _defaultSession});

  final TokenResponse? session;

  static const _defaultSession = TokenResponse(
    accessToken: 'access-after-change',
    refreshToken: 'refresh-after-change',
  );

  @override
  Future<TokenResponse?> changePassword(ChangePasswordRequest request) async {
    lastRequest = request;
    return session;
  }
}

void main() {
  // TokenNotifier writes through to flutter_secure_storage, which is a
  // platform channel with no implementation under `flutter test`. Standing in
  // an in-memory map keeps these tests about the token flow rather than about
  // the plugin.
  TestWidgetsFlutterBinding.ensureInitialized();

  final stored = <String, String>{};

  setUp(() {
    stored.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async {
            switch (call.method) {
              case 'write':
                stored[call.arguments['key'] as String] =
                    call.arguments['value'] as String;
                return null;
              case 'read':
                return stored[call.arguments['key'] as String];
              case 'readAll':
                return Map<String, String>.from(stored);
              case 'delete':
                stored.remove(call.arguments['key'] as String);
                return null;
              case 'deleteAll':
                stored.clear();
                return null;
              default:
                return null;
            }
          },
        );
  });

  /// A signed-in container, since a password change only happens from one.
  Future<ProviderContainer> signedIn(FakeAuthRepository repo) async {
    final container = ProviderContainer(
      overrides: [
        ...fakeOverrides(),
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(tokenProvider.notifier)
        .saveTokens('access-before', 'refresh-before');

    return container;
  }

  test('the app names its own session so the server can spare it', () async {
    final repo = _RecordingAuthRepository();
    final container = await signedIn(repo);

    final ok = await container
        .read(authViewModelProvider.notifier)
        .changePassword('a-long-enough-password');

    expect(ok, isTrue);
    expect(
      repo.lastRequest?.refreshToken,
      'refresh-before',
      reason: 'without this the server cannot tell which session to keep, and '
          'the user is signed out of the device they just used',
    );
  });

  test('the replacement session is stored, not discarded', () async {
    final container = await signedIn(_RecordingAuthRepository());

    await container
        .read(authViewModelProvider.notifier)
        .changePassword('a-long-enough-password');

    final token = container.read(tokenProvider);
    expect(token.accessToken, 'access-after-change');
    expect(token.refreshToken, 'refresh-after-change');
    expect(
      token.isLoggedIn,
      isTrue,
      reason: 'the old tokens are revoked by now, so keeping them would leave '
          'the app holding a session the server has already ended',
    );
  });

  test('no replacement session signs this device out too', () async {
    final container = await signedIn(_RecordingAuthRepository(session: null));

    final ok = await container
        .read(authViewModelProvider.notifier)
        .changePassword('a-long-enough-password');

    // The change did happen, so it is reported as a success...
    expect(ok, isTrue);
    expect(container.read(authViewModelProvider).passwordChanged, isTrue);
    // ...but nothing was kept, and AuthGate routes to login on exactly this.
    expect(container.read(tokenProvider).isLoggedIn, isFalse);
  });

  test('a failed change leaves the existing session untouched', () async {
    final container = await signedIn(_ThrowingAuthRepository());

    final ok = await container
        .read(authViewModelProvider.notifier)
        .changePassword('a-long-enough-password');

    expect(ok, isFalse);
    expect(container.read(authViewModelProvider).error, isNotNull);
    // Nothing was revoked server-side, so signing the user out here would lose
    // a working session over a change that never happened.
    expect(container.read(tokenProvider).accessToken, 'access-before');
    expect(container.read(tokenProvider).refreshToken, 'refresh-before');
  });
}

class _ThrowingAuthRepository extends FakeAuthRepository {
  @override
  Future<TokenResponse?> changePassword(ChangePasswordRequest request) async {
    throw Exception('Password must be at least 8 characters');
  }
}
