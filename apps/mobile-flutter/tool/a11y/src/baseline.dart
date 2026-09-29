/// Recorded, deliberate exceptions, and the strictness policy that decides
/// what the gate fails on.
///
/// Two separate ideas live here and it matters that they do:
///
///   * A **baseline** records something already known. A palette pairing that
///     fails today is not a regression, so a tool that starts failing the
///     build on it would be turned off within a day. It stays visible in the
///     report forever, and the moment someone pairs those two tokens in a
///     screen the entry is what stops them.
///
///   * A **strictness level** decides which classes of new finding are fatal.
///     The default fails the build on a new theme-blind *surface* literal,
///     because that is the defect class that actually shipped, and does not
///     fail on a theme-blind text literal or a palette shortfall, because
///     those are the two this codebase has never had a policy for and failing
///     on them would mean a red gate on day one with no bug to point at.
library;

import 'dart:convert';

import 'dart_source.dart';

/// How much the gate treats as fatal.
enum Strictness {
  /// Report only. Never exits non-zero. For triage and for `--explain`.
  report('report', 'report only, never fails'),

  /// The default. Fails on a new theme-blind surface or gradient-stop literal
  /// outside the baseline.
  surface('surface', 'fails on new theme-blind surface literals'),

  /// Also fails on a new theme-blind text/icon literal outside the baseline.
  text('text', 'also fails on new theme-blind text literals'),

  /// Fails on anything new, including palette pairings absent from the
  /// baseline. Use once the baseline is empty, or in a branch that intends to
  /// empty it.
  strict('strict', 'fails on any new finding, including palette pairings');

  const Strictness(this.id, this.blurb);

  final String id;
  final String blurb;

  static Strictness parse(String raw) {
    for (final s in Strictness.values) {
      if (s.id == raw) {
        return s;
      }
    }
    throw FormatException(
      'unknown strictness "$raw"; expected one of '
      '${Strictness.values.map((s) => s.id).join(', ')}',
    );
  }
}

/// One recorded exception, with the reason it exists.
class BaselineEntry {
  const BaselineEntry({
    required this.path,
    required this.line,
    required this.role,
    required this.reason,
  });

  final String path;
  final int line;
  final String role;
  final String reason;

  String get key => '$path:$line:$role';
}

/// A palette pairing already known to fall short.
/// A group of palette pairings that are below AA and accepted for now, with
/// the reason they are accepted.
///
/// The baseline stores these in groups rather than one entry per cell: 94
/// cells collapse into 33 reasons, and a reviewer reads 33 paragraphs rather
/// than 94 near-duplicate lines. Membership is by exact key, so a cell that
/// stops failing simply drops out and the group's count tells you.
class KnownPairing {
  const KnownPairing({
    required this.keys,
    required this.worst,
    required this.reason,
  });

  /// `theme/textToken/surfaceToken` for every cell in the group.
  final List<String> keys;

  /// The lowest-ratio cell in the group, for the report.
  final String worst;

  final String reason;

  String get key => keys.isEmpty ? '' : keys.first;
}

/// The contents of `a11y_baseline.json`.
class Baseline {
  const Baseline({
    this.literals = const [],
    this.pairings = const [],
  });

  /// Path/literals the tool is expected to keep finding. Their presence in a
  /// report is a *warning that the exception is still load-bearing*, not an
  /// error: a baseline entry pointing at code that has since changed is stale
  /// and should be deleted, but a tool that fails the build for having an
  /// accurate baseline is a tool nobody trusts.
  final List<BaselineEntry> literals;

  /// Palette pairings below AA that are accepted for now.
  final List<KnownPairing> pairings;

  static Baseline parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw FormatException(
        'baseline must be a JSON object of string keys, got '
        '${decoded.runtimeType}',
      );
    }
    final literals = <BaselineEntry>[];
    final pairings = <KnownPairing>[];

    final litList = decoded['literals'];
    if (litList is List) {
      for (final item in litList) {
        if (item is Map) {
          literals.add(BaselineEntry(
            path: '${item['path'] ?? ''}',
            line: _asInt(item['line']),
            role: '${item['role'] ?? ''}',
            reason: '${item['reason'] ?? ''}',
          ));
        }
      }
    }

    final pairList = decoded['pairings'];
    if (pairList is List) {
      for (final item in pairList) {
        if (item is Map) {
          pairings.add(KnownPairing(
            keys: _asStringList(item['pairings']),
            worst: '${item['worst'] ?? ''}',
            reason: '${item['reason'] ?? ''}',
          ));
        }
      }
    }

    return Baseline(literals: literals, pairings: pairings);
  }

  bool hasLiteral(String path, int line, ColorRole role) => literals
      .any((e) => e.path == path && e.line == line && e.role == role.label);

  bool hasPairing(String theme, String text, String surface) {
    final key = '$theme/$text/$surface';
    return pairings.any((p) => p.keys.contains(key));
  }

  /// The recorded reason for a cell, if it is recorded.
  String? reasonForPairingKey(String key) {
    for (final p in pairings) {
      if (p.keys.contains(key)) return p.reason;
    }
    return null;
  }

  String? reasonForLiteral(String path, int line, ColorRole role) {
    for (final e in literals) {
      if (e.path == path && e.line == line && e.role == role.label) {
        return e.reason;
      }
    }
    return null;
  }

  /// Baseline literal entries whose file:line no longer holds, which means the
  /// exception can be deleted.
  List<BaselineEntry> staleAgainst(Set<String> liveKeys) =>
      literals.where((e) => !liveKeys.contains(e.key)).toList();
}

List<String> _asStringList(Object? v) {
  if (v is! List) return const [];
  return [for (final e in v) '$e'];
}

int _asInt(Object? v) {
  if (v is int) {
    return v;
  }
  if (v is num) {
    return v.toInt();
  }
  if (v is String) {
    return int.tryParse(v) ?? -1;
  }
  return -1;
}
