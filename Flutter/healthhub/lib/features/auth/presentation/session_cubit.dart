import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth.dart';

enum SessionStatus { unknown, loggedOut, loggedIn }

class SessionState extends Equatable {
  const SessionState({this.status = SessionStatus.unknown, this.user, this.workspace = Workspace.patient, this.onboarded = true});

  final SessionStatus status;
  final User? user;
  final Workspace workspace;
  final bool onboarded;

  SessionState copyWith({SessionStatus? status, User? user, Workspace? workspace, bool? onboarded}) => SessionState(
        status: status ?? this.status,
        user: user ?? this.user,
        workspace: workspace ?? this.workspace,
        onboarded: onboarded ?? this.onboarded,
      );

  @override
  List<Object?> get props => [status, user, workspace, onboarded];
}

/// App-wide login state: who is logged in and which workspace they're using.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._auth, this._tokens) : super(const SessionState());

  final AuthRepository _auth;
  final TokenStorage _tokens;

  /// Called once on start-up: restores the last session if the token is still valid.
  Future<void> restore() async {
    if (!_auth.hasSession) {
      emit(SessionState(status: SessionStatus.loggedOut, onboarded: _tokens.onboardingDone));
      return;
    }
    try {
      final user = await _auth.me();
      emit(SessionState(status: SessionStatus.loggedIn, user: user, workspace: _pickWorkspace(user, _tokens.workspace)));
    } on ApiException catch (e) {
      if (e.isUnauthorized || e.isForbidden) await _auth.logout();
      emit(const SessionState(status: SessionStatus.loggedOut));
    } catch (_) {
      emit(const SessionState(status: SessionStatus.loggedOut));
    }
  }

  /// Throws [ApiException] so the login form can show the message.
  Future<void> login(String login, String password) async {
    final user = await _auth.login(login, password);
    emit(SessionState(status: SessionStatus.loggedIn, user: user, workspace: _pickWorkspace(user, null)));
  }

  /// Reloads the profile, e.g. after a role was granted or the photo changed.
  Future<void> refresh() async {
    try {
      final user = await _auth.me();
      emit(state.copyWith(user: user, workspace: _pickWorkspace(user, state.workspace.name)));
    } catch (_) {
      // keep the current user on network errors
    }
  }

  void updateUser(User user) => emit(state.copyWith(user: user));

  Future<void> finishOnboarding() async {
    await _tokens.setOnboardingDone();
    emit(state.copyWith(onboarded: true));
  }

  Future<void> switchWorkspace(Workspace w) async {
    if (state.user?.workspaces.contains(w) != true) return;
    await _tokens.saveWorkspace(w.name);
    emit(state.copyWith(workspace: w));
  }

  Future<void> logout() async {
    await _auth.logout();
    emit(const SessionState(status: SessionStatus.loggedOut));
  }

  /// Use the saved workspace if still allowed, otherwise the most specific role the user has.
  static Workspace _pickWorkspace(User user, String? saved) {
    final allowed = user.workspaces;
    final previous = Workspace.byName(saved);
    if (previous != null && allowed.contains(previous)) return previous;
    return allowed.last;
  }
}
