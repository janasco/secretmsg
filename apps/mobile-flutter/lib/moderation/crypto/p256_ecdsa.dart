import 'dart:convert';
import 'dart:typed_data';

/// NIST P-256 (secp256r1) ECDSA verification, dependency-free.
///
/// Why hand-rolled: the sideload (de-Googled) track must verify signed model
/// bundles without Play Services, and the app deliberately does not add a
/// crypto package for a read-only verification path. This is the full curve
/// group over `BigInt`; correctness is pinned by OpenSSL-generated vectors in
/// `test/moderation/crypto_test.dart`.
///
/// Verification only. There is intentionally no signing code here: bundle
/// signing happens in a build/CI environment with the private key, which never
/// ships in the app.
///
/// Not constant-time. It verifies public model-bundle signatures; there is no
/// secret input.
class P256PublicKey {
  final BigInt x;
  final BigInt y;

  const P256PublicKey(this.x, this.y);

  /// Parses `x||y` hex (128 chars) or uncompressed `04||x||y` (130 chars).
  factory P256PublicKey.fromHex(String hex) {
    var text = hex.trim().toLowerCase();
    if (text.startsWith('0x')) text = text.substring(2);
    if (text.length == 130 && text.startsWith('04')) {
      text = text.substring(2);
    }
    if (text.length != 128 || !RegExp(r'^[0-9a-f]+$').hasMatch(text)) {
      throw FormatException('P-256 public key must be 128 hex chars', hex);
    }
    return P256PublicKey(
      BigInt.parse(text.substring(0, 64), radix: 16),
      BigInt.parse(text.substring(64), radix: 16),
    );
  }

  /// Byte form `x||y` (64 bytes) or uncompressed SEC1 (65 bytes, `04` prefix).
  factory P256PublicKey.fromBytes(Uint8List bytes) {
    if (bytes.length == 65 && bytes[0] == 0x04) {
      return P256PublicKey.fromBytes(Uint8List.sublistView(bytes, 1));
    }
    if (bytes.length != 64) {
      throw const FormatException('P-256 public key must be 64 or 65 bytes');
    }
    BigInt read(int start) {
      var value = BigInt.zero;
      for (var i = start; i < start + 32; i++) {
        value = (value << 8) | BigInt.from(bytes[i]);
      }
      return value;
    }

    return P256PublicKey(read(0), read(32));
  }

  /// Curve equation check; also enforces field ranges.
  bool get isOnCurve => P256Ecdsa.isOnCurve(this);
}

class P256Ecdsa {
  static final BigInt p = _fromHex(
    'ffffffff00000001000000000000000000000000ffffffffffffffffffffffff',
  );
  static final BigInt _a = p - BigInt.from(3);
  static final BigInt b = _fromHex(
    '5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b',
  );
  static final BigInt n = _fromHex(
    'ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551',
  );
  static final BigInt _gx = _fromHex(
    '6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296',
  );
  static final BigInt _gy = _fromHex(
    '4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5',
  );

  static final _Point _g = _Point(_gx, _gy, BigInt.one);
  static final _Point _infinity = _Point(BigInt.zero, BigInt.one, BigInt.zero);

  /// Verifies a raw 64-byte `r||s` signature over [digest].
  ///
  /// [digest] must be a SHA-256 digest (32 bytes); anything else fails closed.
  static bool verify({
    required P256PublicKey publicKey,
    required List<int> digest,
    required List<int> signature,
  }) {
    if (digest.length != 32 || signature.length != 64) return false;
    if (!isOnCurve(publicKey)) return false;

    final r = _bytesToBigInt(signature, 0);
    final s = _bytesToBigInt(signature, 32);
    if (r <= BigInt.zero || r >= n) return false;
    if (s <= BigInt.zero || s >= n) return false;

    final e = _bytesToBigInt(digest, 0);
    final BigInt w;
    try {
      w = s.modInverse(n);
    } catch (_) {
      return false; // non-invertible s; cannot happen for prime n, fail closed
    }
    final u1 = (e * w) % n;
    final u2 = (r * w) % n;

    final point = _add(_multiply(_g, u1), _multiply(_toAffinePoint(publicKey), u2));
    if (point.z == BigInt.zero) return false;

    final zInv = point.z.modInverse(p);
    final zInv2 = (zInv * zInv) % p;
    final x = (point.x * zInv2) % p;
    return x % n == r;
  }

  /// True when the point satisfies `y^2 = x^3 - 3x + b (mod p)` and the
  /// coordinates are in range. Rejects the identity implicitly.
  static bool isOnCurve(P256PublicKey key) {
    if (key.x < BigInt.zero || key.x >= p) return false;
    if (key.y < BigInt.zero || key.y >= p) return false;
    final left = (key.y * key.y) % p;
    final x2 = (key.x * key.x) % p;
    final right = ((x2 * key.x) + (_a * key.x) + b) % p;
    return left == right;
  }

  /// Parses a 64-byte `r||s` signature from base64url or base64 text.
  static Uint8List parseSignature(String text) {
    final normalized = text.trim().replaceAll('-', '+').replaceAll('_', '/');
    final padded = normalized.padRight(
      normalized.length + (4 - normalized.length % 4) % 4,
      '=',
    );
    final bytes = base64.decode(padded);
    if (bytes.length != 64) {
      throw const FormatException('ECDSA signature must be 64 raw bytes');
    }
    return bytes;
  }

  static _Point _toAffinePoint(P256PublicKey key) =>
      _Point(key.x, key.y, BigInt.one);

  static _Point _double(_Point point) {
    if (point.z == BigInt.zero || point.y == BigInt.zero) return _infinity;
    final x2 = (point.x * point.x) % p;
    final y2 = (point.y * point.y) % p;
    final y4 = (y2 * y2) % p;
    final z2 = (point.z * point.z) % p;
    // For a = -3: M = 3(x - z^2)(x + z^2).
    final m = (BigInt.from(3) * ((point.x - z2) * (point.x + z2) % p)) % p;
    final xSum = (point.x + y2) % p;
    final s = (BigInt.from(2) * ((xSum * xSum - x2 - y4) % p)) % p;
    final nx = (m * m - BigInt.from(2) * s) % p;
    final ny = (m * (((s - nx) % p)) - BigInt.from(8) * y4) % p;
    final nz = (BigInt.from(2) * point.y * point.z) % p;
    return _Point(_mod(nx), _mod(ny), _mod(nz));
  }

  static _Point _add(_Point a, _Point b) {
    if (a.z == BigInt.zero) return b;
    if (b.z == BigInt.zero) return a;
    final z1z1 = (a.z * a.z) % p;
    final z2z2 = (b.z * b.z) % p;
    final u1 = (a.x * z2z2) % p;
    final u2 = (b.x * z1z1) % p;
    final s1 = ((a.y * b.z) % p * z2z2) % p;
    final s2 = ((b.y * a.z) % p * z1z1) % p;
    final h = _mod(u2 - u1);
    final r = _mod(s2 - s1);
    if (h == BigInt.zero) {
      if (r == BigInt.zero) return _double(a);
      return _infinity;
    }
    final h2 = (h * h) % p;
    final h3 = (h * h2) % p;
    final u1h2 = (u1 * h2) % p;
    final nx = (r * r - h3 - BigInt.from(2) * u1h2) % p;
    final ny = (r * (u1h2 - nx) - s1 * h3) % p;
    final nz = (a.z * b.z % p * h) % p;
    return _Point(_mod(nx), _mod(ny), _mod(nz));
  }

  static _Point _multiply(_Point point, BigInt scalar) {
    var result = _infinity;
    for (var i = scalar.bitLength - 1; i >= 0; i--) {
      result = _double(result);
      if (((scalar >> i) & BigInt.one) == BigInt.one) {
        result = _add(result, point);
      }
    }
    return result;
  }

  static BigInt _mod(BigInt value) {
    final mod = value % p;
    return mod.isNegative ? mod + p : mod;
  }

  static BigInt _bytesToBigInt(List<int> bytes, int start) {
    var value = BigInt.zero;
    for (var i = start; i < start + 32; i++) {
      value = (value << 8) | BigInt.from(bytes[i]);
    }
    return value;
  }

  static BigInt _fromHex(String hex) => BigInt.parse(hex, radix: 16);
}

class _Point {
  final BigInt x;
  final BigInt y;
  final BigInt z;

  const _Point(this.x, this.y, this.z);
}
