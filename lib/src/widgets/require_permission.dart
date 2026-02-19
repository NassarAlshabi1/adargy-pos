import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/auth/auth_provider.dart';
import '../models/user_model.dart';

/// Widget helper to show/hide content based on permissions
class RequirePermission extends StatelessWidget {
  const RequirePermission({
    super.key,
    this.permission,
    this.anyOf,
    this.allOf,
    required this.child,
    this.fallback,
  });

  final UserPermission? permission;
  final List<UserPermission>? anyOf;
  final List<UserPermission>? allOf;
  final Widget child;
  final Widget? fallback;

  bool _evaluate(AuthProvider auth) {
    if (permission != null) {
      return auth.hasPermission(permission!);
    }
    if (anyOf != null && anyOf!.isNotEmpty) {
      for (final p in anyOf!) {
        if (auth.hasPermission(p)) return true;
      }
      return false;
    }
    if (allOf != null && allOf!.isNotEmpty) {
      for (final p in allOf!) {
        if (!auth.hasPermission(p)) return false;
      }
      return true;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ok = _evaluate(auth);
    if (ok) return child;
    return fallback ?? const SizedBox.shrink();
  }
}
