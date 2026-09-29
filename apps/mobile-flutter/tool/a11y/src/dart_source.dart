/// A deliberately small Dart reader.
///
/// This is not a parser. It blanks out comments and string literals, then
/// tracks bracket nesting well enough to answer one question: for a colour
/// literal at a given offset, what named argument is it the value of, and
/// which constructors enclose it? That is the minimum needed to tell a
/// gradient stop from a `TextStyle` colour from a `BoxShadow`.
///
/// Blanking preserves every offset and newline, so a line number recovered
/// from the masked text is the line number in the real file.
///
/// Limitation, stated because it matters: string interpolation is blanked
/// along with the string, so a colour literal written inside `${...}` is not
/// seen. Nothing in this app does that, and pretending otherwise would cost
/// a real parser.
library;

/// The source with comments and string bodies replaced by spaces.
class MaskedSource {
  MaskedSource(this.original, this.masked);

  final String original;
  final String masked;

  /// 1-based line of a character offset in the original source.
  int lineAt(int offset) {
    var line = 1;
    for (var i = 0; i < offset && i < masked.length; i++) {
      if (masked.codeUnitAt(i) == 0x0A) {
        line++;
      }
    }
    return line;
  }

  /// Number of lines in the source.
  int get lineCount {
    var n = 1;
    for (var i = 0; i < masked.length; i++) {
      if (masked.codeUnitAt(i) == 0x0A) n++;
    }
    return n;
  }

  /// The source line with 0-based index [index], trailing space trimmed.
  String lineTextByIndex(int index) {
    var start = 0;
    var seen = 0;
    for (var i = 0; i < masked.length; i++) {
      if (masked.codeUnitAt(i) != 0x0A) continue;
      if (seen == index) return original.substring(start, i).trimRight();
      seen++;
      start = i + 1;
    }
    return start >= original.length
        ? ''
        : original.substring(start).trimRight();
  }

  /// Offset of the first character of the line with 0-based index [index].
  int lineStartByIndex(int index) {
    var start = 0;
    var seen = 0;
    for (var i = 0; i < masked.length; i++) {
      if (masked.codeUnitAt(i) != 0x0A) continue;
      if (seen == index) return start;
      seen++;
      start = i + 1;
    }
    return start;
  }

  /// Offset of the first character of the line containing [offset].
  int lineStartAt(int offset) {
    var start = offset;
    while (start > 0 && masked.codeUnitAt(start - 1) != 0x0A) {
      start--;
    }
    return start;
  }

  /// 1-based column of a character offset.
  int columnAt(int offset) {
    var lineStart = offset;
    while (lineStart > 0 && masked.codeUnitAt(lineStart - 1) != 0x0A) {
      lineStart--;
    }
    return offset - lineStart + 1;
  }

  /// The original source line containing [offset], trimmed of trailing space.
  String lineText(int offset) {
    var end = offset;
    while (end < masked.length && masked.codeUnitAt(end) != 0x0A) {
      end++;
    }
    var start = offset;
    while (start > 0 && masked.codeUnitAt(start - 1) != 0x0A) {
      start--;
    }
    return original.substring(start, end).trimRight();
  }
}

/// Replaces the contents of comments and string literals with spaces.
///
/// Newlines inside a multi-line string or block comment are kept so offsets
/// and line numbers survive; only the non-newline bytes are replaced.
MaskedSource maskSource(String source) {
  final out = StringBuffer();
  var i = 0;
  final n = source.length;

  void blank(int from, int to) {
    for (var j = from; j < to; j++) {
      final c = source.codeUnitAt(j);
      out.writeCharCode(c == 0x0A || c == 0x0D ? c : 0x20);
    }
  }

  while (i < n) {
    final c = source[i];

    // Line comment.
    if (c == '/' && i + 1 < n && source[i + 1] == '/') {
      var j = i;
      while (j < n && source[j] != '\n') {
        j++;
      }
      blank(i, j);
      i = j;
      continue;
    }

    // Block comment (Dart allows nesting).
    if (c == '/' && i + 1 < n && source[i + 1] == '*') {
      var depth = 1;
      var j = i + 2;
      while (j < n && depth > 0) {
        if (source[j] == '/' && j + 1 < n && source[j + 1] == '*') {
          depth++;
          j += 2;
        } else if (source[j] == '*' && j + 1 < n && source[j + 1] == '/') {
          depth--;
          j += 2;
        } else {
          j++;
        }
      }
      blank(i, j.clamp(0, n));
      i = j.clamp(0, n);
      continue;
    }

    // Raw string: no escapes, so the terminator scan is a simple scan.
    if (c == 'r' &&
        i + 1 < n &&
        (source[i + 1] == "'" || source[i + 1] == '"')) {
      final quote = source[i + 1];
      final triple =
          i + 3 < n && source[i + 2] == quote && source[i + 3] == quote;
      final terminator = triple ? '$quote$quote$quote' : quote;
      var j = i + 1 + terminator.length;
      while (j < n && !source.startsWith(terminator, j)) {
        j++;
      }
      j = (j + terminator.length).clamp(0, n);
      blank(i, j);
      i = j;
      continue;
    }

    // Ordinary string, including triple-quoted.
    if (c == "'" || c == '"') {
      final quote = c;
      final triple =
          i + 2 < n && source[i + 1] == quote && source[i + 2] == quote;
      final terminator = triple ? '$quote$quote$quote' : quote;
      var j = i + terminator.length;
      while (j < n) {
        if (source[j] == r'\') {
          j += 2;
          continue;
        }
        if (source.startsWith(terminator, j)) {
          j += terminator.length;
          break;
        }
        j++;
      }
      j = j.clamp(0, n);
      blank(i, j);
      i = j;
      continue;
    }

    out.writeCharCode(source.codeUnitAt(i));
    i++;
  }

  return MaskedSource(source, out.toString());
}

/// One level of bracket nesting, with the name of the call it opens.
class _Frame {
  _Frame(this.ctor, {this.inheritedArg});

  /// The identifier before the `(`, e.g. `BoxDecoration`. Empty for a plain
  /// group or a function body.
  final String ctor;

  /// For a list literal, the argument label the list itself is the value of.
  final String? inheritedArg;

  /// The named-argument label most recently seen at this depth, e.g. `color`.
  String? arg;

  /// Set once this frame has seen a `,` at its own depth, which ends a
  /// positional argument and starts a new one. A comma does *not* end a named
  /// argument, because the elements of `colors: [a, b]` are all values of
  /// `colors`.
  bool sawComma = false;

  /// True when [arg] came from an explicit `label:` at this depth rather than
  /// being inherited from an enclosing frame.
  bool get hasOwnArg => ownArg != null;

  String? ownArg;
}

/// What a colour literal is being used as.
enum ColorRole {
  /// A gradient stop: `LinearGradient(colors: [...])`.
  gradientStop,

  /// A container / decoration / background fill.
  surface,

  /// A text or icon colour.
  text,

  /// A hairline border or divider.
  border,

  /// A drop shadow. Shadows are not a text surface and never respond to the
  /// theme by design.
  shadow,

  /// Anything the reader could not place: a bare `const` list, an argument
  /// passed positionally, a value returned from a helper.
  unknown,
}

extension ColorRoleLabel on ColorRole {
  String get label => switch (this) {
        ColorRole.gradientStop => 'gradient stop',
        ColorRole.surface => 'surface',
        ColorRole.text => 'text/icon',
        ColorRole.border => 'border',
        ColorRole.shadow => 'shadow',
        ColorRole.unknown => 'unclassified',
      };
}

/// The syntactic neighbourhood of a colour literal.
class ColorSite {
  const ColorSite({
    required this.offset,
    required this.argLabel,
    required this.argOwner,
    required this.enclosing,
  });

  final int offset;

  /// The named argument this literal is the value of, if any.
  final String? argLabel;

  /// The constructor that declared [argLabel]: `BoxDecoration` for
  /// `BoxDecoration(color: x)`, `all` for `Border.all(color: x)`.
  ///
  /// This is what makes `color:` classifiable at all. `color:` on a
  /// `BoxDecoration` is a fill; `color:` on a `Border.all` is a hairline, and
  /// the enclosing chain is identical in both cases, so only the owner tells
  /// them apart.
  final String? argOwner;

  /// Enclosing constructor names, innermost first, excluding `Color` itself.
  final List<String> enclosing;

  /// The whole chain, for messages: `LinearGradient / BoxDecoration`.
  String get contextLabel =>
      enclosing.isEmpty ? 'top level' : enclosing.join(' / ');
}

/// Resolves the syntactic site of every colour literal at the given offsets.
///
/// One pass, one bracket stack. The stack has to be *carried* across targets:
/// an earlier version restarted it per literal, so every literal after the
/// first in a file was reported as "top level" and classified `unknown`. That
/// is the whole class of finding this tool exists for, silently dropped.
List<ColorSite> resolveSites(MaskedSource src, List<int> offsets) {
  final sites = <ColorSite>[];
  final stack = <_Frame>[];
  var pendingCtor = '';
  var next = 0;
  var i = 0;

  while (i < src.masked.length) {
    while (next < offsets.length && offsets[next] == i) {
      final owner = _innermostArgOwner(stack);
      sites.add(ColorSite(
        offset: i,
        argLabel: owner?.label,
        argOwner: owner?.owner,
        enclosing: [
          for (final f in stack.reversed)
            if (f.ctor.isNotEmpty) f.ctor,
        ],
      ));
      next++;
    }
    if (next >= offsets.length) {
      break;
    }

    final ch = src.masked[i];

    if (_isIdentStart(ch)) {
      final word = _readIdent(src.masked, i);
      final after = _skipSpace(src.masked, word.end);

      // `foo:` at this depth names an argument of the enclosing call.
      if (after < src.masked.length && src.masked[after] == ':') {
        if (stack.isNotEmpty) {
          stack.last.arg = word.text;
          stack.last.ownArg = word.text;
          stack.last.sawComma = false;
        }
        i = word.end;
        continue;
      }

      // `foo(` opens a call named `foo`. `Border.all(` and `EdgeInsets.only(`
      // are also calls, and the part after the dot is the one that matters for
      // classification, so a dotted name keeps only its last segment here and
      // the full dotted name is recorded for the message.
      if (after < src.masked.length && src.masked[after] == '(') {
        final open = _skipSpace(src.masked, after);
        stack.add(_Frame(_dottedName(src.masked, i, open)));
        pendingCtor = _dottedName(src.masked, i, open);
        i = open + 1;
        continue;
      }

      i = word.end;
      continue;
    }

    if (ch == '(' || ch == '[' || ch == '{') {
      // A list or set literal is transparent for classification: the element
      // of `colors: [a, b]` is a gradient stop, not an unknown value.
      final inherited = _innermostArgOwner(stack)?.label ?? '';
      stack.add(_Frame(ch == '(' ? pendingCtor : '', inheritedArg: inherited));
      pendingCtor = '';
      i++;
      continue;
    }

    if (ch == ')' || ch == ']' || ch == '}') {
      if (stack.isNotEmpty) {
        stack.removeLast();
      }
      i++;
      continue;
    }

    if (ch == ',') {
      if (stack.isNotEmpty) {
        stack.last.sawComma = true;
        // A comma ends a positional argument but not a named one: inside
        // `colors: [a, b]` the `b` is still the value of `colors`.
        if (!stack.last.hasOwnArg) {
          stack.last.arg = null;
        }
      }
      i++;
      continue;
    }

    if (ch == ';') {
      stack.clear();
      pendingCtor = '';
      i++;
      continue;
    }

    i++;
  }

  return sites;
}

class _Ident {
  const _Ident(this.text, this.end);

  final String text;
  final int end;
}

_Ident _readIdent(String masked, int start) {
  var j = start;
  while (j < masked.length && _isIdentPart(masked[j])) {
    j++;
  }
  return _Ident(masked.substring(start, j), j);
}

int _skipSpace(String masked, int from) {
  var j = from;
  while (j < masked.length && _isSpace(masked[j])) {
    j++;
  }
  return j;
}

/// The call name ending at the `(` at [open], dotted parts included.
///
/// `Border.all(` yields `all` for classification and `Border.all` for the
/// report. Only the last segment is classified against, because that is the
/// constructor the argument actually belongs to.
String _dottedName(String masked, int wordStart, int open) {
  var last = _readIdent(masked, wordStart);
  var probe = last;
  while (true) {
    final dot = _skipSpace(masked, probe.end);
    if (dot >= masked.length || masked[dot] != '.') {
      break;
    }
    final afterDot = _skipSpace(masked, dot + 1);
    if (afterDot >= masked.length || !_isIdentStart(masked[afterDot])) {
      break;
    }
    last = _readIdent(masked, afterDot);
    probe = last;
  }
  // If what followed the dot was itself followed by `(`, the dotted form is
  // the constructor; otherwise the bare word was.
  return last.text;
}

/// A named argument and the constructor that declared it.
class _ArgOwner {
  const _ArgOwner(this.label, this.owner);

  final String label;
  final String owner;
}

/// The nearest named-argument label, looking through list literals, together
/// with the frame that declared it.
_ArgOwner? _innermostArgOwner(List<_Frame> stack) {
  for (final f in stack.reversed) {
    final arg = f.arg;
    if (arg != null && arg.isNotEmpty) {
      return _ArgOwner(arg, f.ctor);
    }
  }
  return null;
}

/// Named arguments whose value is drawn as a glyph.
const Set<String> kTextArgumentLabels = {
  'style',
  'textStyle',
  'labelStyle',
  'hintStyle',
  'titleTextStyle',
  'contentTextStyle',
  'cursorColor',
  'selectionColor',
  'selectionHandleColor',
  'foregroundColor',
};

/// Classifies a literal from its syntactic neighbourhood.
///
/// The rules are ordered and each one is a real idiom in this app. Anything
/// that does not match is [ColorRole.unknown] rather than a guess: a
/// mislabelled finding is worse than an unlabelled one, because the report
/// is read as a triage list.
ColorRole classifySite(ColorSite site) {
  final arg = site.argLabel;
  final owner = site.argOwner ?? '';
  final chain = site.enclosing;

  bool has(Set<String> names) => chain.any(names.contains);

  // Shadows first: a `BoxShadow(color:)` is unambiguous and legitimate.
  if (has(kShadowCtorNames) || arg == 'shadowColor') {
    return ColorRole.shadow;
  }

  // Gradient stops. Checked before the generic `color:` rules because a
  // `LinearGradient` has no other kind of colour argument.
  if (has(kGradientCtorNames)) {
    return ColorRole.gradientStop;
  }

  // Icon and progress indicators.
  if (has(kIconCtorNames)) {
    return ColorRole.text;
  }

  // Text styles.
  if (has(kTextCtorNames)) {
    return ColorRole.text;
  }
  if (arg != null && kTextArgumentLabels.contains(arg)) {
    return ColorRole.text;
  }

  // Borders, decided by the constructor that owns the argument rather than by
  // the enclosing chain, which is the same for a border and a fill.
  if (has(kBorderCtorNames) ||
      (owner.isNotEmpty && kBorderCtorNames.contains(owner))) {
    return ColorRole.border;
  }
  if (arg != null && kBorderArgumentLabels.contains(arg)) {
    return ColorRole.border;
  }

  // Fills.
  if (arg != null && kSurfaceArgumentLabels.contains(arg)) {
    return ColorRole.surface;
  }
  if (has(kSurfaceCtorNames) || kSurfaceCtorNames.contains(owner)) {
    return ColorRole.surface;
  }

  return ColorRole.unknown;
}

/// Constructors whose `color:` is a drop shadow.
const Set<String> kShadowCtorNames = {'BoxShadow'};

/// Gradient constructors; every colour inside one is a surface.
const Set<String> kGradientCtorNames = {
  'LinearGradient',
  'RadialGradient',
  'SweepGradient',
};

/// Constructors whose colour is drawn as a glyph.
const Set<String> kIconCtorNames = {
  'Icon',
  'IconTheme',
  'IconThemeData',
  'CircularProgressIndicator',
  'LinearProgressIndicator',
};

/// Constructors whose colour is a glyph colour.
const Set<String> kTextCtorNames = {
  'TextStyle',
  'DefaultTextStyle',
  'TextTheme'
};

/// Constructors whose `color:` is a hairline, not a fill.
const Set<String> kBorderCtorNames = {
  'BorderSide',
  'Border',
  'OutlineInputBorder',
  'InputBorder',
  'all',
};

/// Arguments whose value is a border colour.
const Set<String> kBorderArgumentLabels = {
  'borderSide',
  'side',
  'dividerColor',
  'borderColor',
};

/// Arguments whose value is a background fill.
const Set<String> kSurfaceArgumentLabels = {
  'backgroundColor',
  'fillColor',
  'scaffoldBackgroundColor',
  'surfaceTintColor',
  'overlayColor',
};

/// Constructors that paint a fill.
const Set<String> kSurfaceCtorNames = {
  'BoxDecoration',
  'ShapeDecoration',
  'Container',
  'AnimatedContainer',
  'Material',
  'Card',
  'ColoredBox',
  'DecoratedBox',
  'Sheet',
  'Dialog',
  'Drawer',
};

bool _isSpace(String c) => c == ' ' || c == '\t' || c == '\n' || c == '\r';

bool _isIdentStart(String c) {
  final u = c.codeUnitAt(0);
  return (u >= 65 && u <= 90) || (u >= 97 && u <= 122) || c == '_' || c == r'$';
}

bool _isIdentPart(String c) =>
    _isIdentStart(c) || (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57);
