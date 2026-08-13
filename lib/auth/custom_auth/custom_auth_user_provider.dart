import 'package:rxdart/rxdart.dart';

import 'custom_auth_manager.dart';

class Zoc1AuthUser {
  Zoc1AuthUser({required this.loggedIn, this.uid});

  bool loggedIn;
  String? uid;
}

/// Generates a stream of the authenticated user.
BehaviorSubject<Zoc1AuthUser> zoc1AuthUserSubject =
    BehaviorSubject.seeded(Zoc1AuthUser(loggedIn: false));
Stream<Zoc1AuthUser> zoc1AuthUserStream() =>
    zoc1AuthUserSubject.asBroadcastStream().map((user) => currentUser = user);
