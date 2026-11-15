import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthhub/core/network/api_exception.dart';
import 'package:healthhub/core/storage/token_storage.dart';
import 'package:healthhub/features/auth/domain/auth.dart';
import 'package:healthhub/features/auth/presentation/session_cubit.dart';

const patient = User(id: '1', name: 'Sara Ali', email: 'sara@test.local', roles: ['Patient']);
const doctor = User(id: '2', name: 'Ahmed Hassan', email: 'doc@test.local', roles: ['Patient', 'Doctor']);

class FakeAuth implements AuthRepository {
  FakeAuth({this.user, this.sessionSaved = false, this.meError});

  User? user;
  bool sessionSaved;
  ApiException? meError;
  bool loggedOut = false;

  @override
  bool get hasSession => sessionSaved;

  @override
  Future<User> me() async {
    if (meError != null) throw meError!;
    return user!;
  }

  @override
  Future<User> login(String login, String password) async {
    if (password != 'ok') throw const ApiException('Email Or Password Incorrect', statusCode: 401);
    sessionSaved = true;
    return user!;
  }

  @override
  Future<void> logout() async {
    loggedOut = true;
    sessionSaved = false;
  }

  @override
  Future<void> register(RegisterData data) async {}
  @override
  Future<void> forgotPassword(String email) async {}
  @override
  Future<void> resetPassword(String code, String newPassword) async {}
  @override
  Future<User> changePhoto(List<int> bytes, String fileName) async => user!;
  @override
  Future<void> useToken(String token) async {}
}

void main() {
  blocTest<SessionCubit, SessionState>(
    'no saved token: logged out',
    build: () => SessionCubit(FakeAuth(), TokenStorage.memory()),
    act: (c) => c.restore(),
    expect: () => [const SessionState(status: SessionStatus.loggedOut, onboarded: false)],
  );

  blocTest<SessionCubit, SessionState>(
    'saved token: restores the user and picks the doctor workspace for a doctor',
    build: () => SessionCubit(FakeAuth(user: doctor, sessionSaved: true), TokenStorage.memory('t')),
    act: (c) => c.restore(),
    expect: () => [const SessionState(status: SessionStatus.loggedIn, user: doctor, workspace: Workspace.doctor)],
  );

  blocTest<SessionCubit, SessionState>(
    'expired token: logs out and clears it',
    build: () => SessionCubit(FakeAuth(user: doctor, sessionSaved: true, meError: const ApiException('x', statusCode: 401)), TokenStorage.memory('t')),
    act: (c) => c.restore(),
    expect: () => [const SessionState(status: SessionStatus.loggedOut)],
  );

  blocTest<SessionCubit, SessionState>(
    'login success goes to the patient workspace',
    build: () => SessionCubit(FakeAuth(user: patient), TokenStorage.memory()),
    act: (c) => c.login('sara@test.local', 'ok'),
    expect: () => [const SessionState(status: SessionStatus.loggedIn, user: patient)],
  );

  blocTest<SessionCubit, SessionState>(
    'login failure throws and leaves the state alone',
    build: () => SessionCubit(FakeAuth(user: patient), TokenStorage.memory()),
    act: (c) => expectLater(c.login('sara@test.local', 'bad'), throwsA(isA<ApiException>())),
    expect: () => <SessionState>[],
  );

  blocTest<SessionCubit, SessionState>(
    'a patient cannot switch to the doctor workspace',
    build: () => SessionCubit(FakeAuth(user: patient), TokenStorage.memory()),
    act: (c) async {
      await c.login('sara@test.local', 'ok');
      await c.switchWorkspace(Workspace.doctor);
    },
    expect: () => [const SessionState(status: SessionStatus.loggedIn, user: patient)],
  );

  blocTest<SessionCubit, SessionState>(
    'a doctor can switch to the patient workspace and logout clears everything',
    build: () => SessionCubit(FakeAuth(user: doctor), TokenStorage.memory()),
    act: (c) async {
      await c.login('doc@test.local', 'ok');
      await c.switchWorkspace(Workspace.patient);
      await c.logout();
    },
    expect: () => [
      const SessionState(status: SessionStatus.loggedIn, user: doctor, workspace: Workspace.doctor),
      const SessionState(status: SessionStatus.loggedIn, user: doctor, workspace: Workspace.patient),
      const SessionState(status: SessionStatus.loggedOut),
    ],
  );
}
