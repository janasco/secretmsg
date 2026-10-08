import 'dart:typed_data';

/// Minimal, dependency-free SHA-256 (FIPS 180-4).
///
/// Why hand-rolled: model-bundle verification must run on the de-Googled
/// sideload track with no Play Services and the app deliberately ships a tiny
/// dependency set; `package:crypto` is currently only a transitive dependency
/// and pulling it in as a direct dependency was judged out of scope for this
/// change. The implementation is covered by FIPS 180-4 test vectors in
/// `test/moderation/crypto_test.dart`.
///
/// Not constant-time. It hashes public model-bundle bytes, never secrets.
class Sha256 {
  static const int blockSize = 64;
  static const int digestSize = 32;

  static const List<int> _k = <int>[
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];

  final List<int> _h = <int>[
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ];

  final Uint8List _buffer = Uint8List(blockSize);
  final Uint32List _w = Uint32List(64);
  int _bufferLength = 0;
  int _totalLength = 0;
  bool _finalized = false;

  /// One-shot digest of [data].
  static Uint8List hash(List<int> data) {
    final sha = Sha256();
    sha.update(data);
    return sha.digest();
  }

  /// Lowercase hex one-shot digest, the form used in bundle manifests.
  static String hex(List<int> data) => toHex(hash(data));

  /// Streaming update. Must not be called after [digest].
  void update(List<int> data) {
    if (_finalized) {
      throw StateError('Sha256.update called after digest()');
    }
    _update(data);
  }

  void _update(List<int> data) {
    var offset = 0;
    _totalLength += data.length;
    if (_bufferLength > 0) {
      final remaining = data.length - offset;
      final space = blockSize - _bufferLength;
      final take = space < remaining ? space : remaining;
      _buffer.setRange(_bufferLength, _bufferLength + take, data, offset);
      _bufferLength += take;
      offset += take;
      if (_bufferLength == blockSize) {
        _compress(_buffer, 0);
        _bufferLength = 0;
      }
    }
    while (data.length - offset >= blockSize) {
      _compress(data, offset);
      offset += blockSize;
    }
    if (offset < data.length) {
      _buffer.setRange(0, data.length - offset, data, offset);
      _bufferLength = data.length - offset;
    }
  }

  /// Finishes the digest. Call exactly once.
  Uint8List digest() {
    if (_finalized) {
      throw StateError('Sha256.digest called twice');
    }
    _finalized = true;
    final bitLength = _totalLength * 8;

    // Pad: 0x80, zeros, 64-bit big-endian message length in bits.
    final padding = Uint8List((_bufferLength < 56 ? 56 : 120) - _bufferLength + 8);
    padding[0] = 0x80;
    for (var i = 0; i < 8; i++) {
      padding[padding.length - 1 - i] = (bitLength >> (8 * i)) & 0xff;
    }
    _update(padding);

    final out = Uint8List(digestSize);
    for (var i = 0; i < 8; i++) {
      out[i * 4] = (_h[i] >> 24) & 0xff;
      out[i * 4 + 1] = (_h[i] >> 16) & 0xff;
      out[i * 4 + 2] = (_h[i] >> 8) & 0xff;
      out[i * 4 + 3] = _h[i] & 0xff;
    }
    return out;
  }

  void _compress(List<int> block, int offset) {
    final w = _w;
    for (var i = 0; i < 16; i++) {
      final j = offset + i * 4;
      w[i] = (block[j] << 24) |
          (block[j + 1] << 16) |
          (block[j + 2] << 8) |
          block[j + 3];
    }
    for (var i = 16; i < 64; i++) {
      final w15 = w[i - 15];
      final w2 = w[i - 2];
      final s0 = _rotr(w15, 7) ^ _rotr(w15, 18) ^ (w15 >> 3);
      final s1 = _rotr(w2, 17) ^ _rotr(w2, 19) ^ (w2 >> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
    }

    var a = _h[0];
    var b = _h[1];
    var c = _h[2];
    var d = _h[3];
    var e = _h[4];
    var f = _h[5];
    var g = _h[6];
    var h = _h[7];

    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ (~e & g);
      final temp1 = (h + s1 + ch + _k[i] + w[i]) & 0xffffffff;
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = (s0 + maj) & 0xffffffff;

      h = g;
      g = f;
      f = e;
      e = (d + temp1) & 0xffffffff;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) & 0xffffffff;
    }

    _h[0] = (_h[0] + a) & 0xffffffff;
    _h[1] = (_h[1] + b) & 0xffffffff;
    _h[2] = (_h[2] + c) & 0xffffffff;
    _h[3] = (_h[3] + d) & 0xffffffff;
    _h[4] = (_h[4] + e) & 0xffffffff;
    _h[5] = (_h[5] + f) & 0xffffffff;
    _h[6] = (_h[6] + g) & 0xffffffff;
    _h[7] = (_h[7] + h) & 0xffffffff;
  }

  static int _rotr(int value, int amount) =>
      ((value >> amount) | (value << (32 - amount))) & 0xffffffff;

  /// Lowercase hex encoding.
  static String toHex(List<int> bytes) {
    const hexDigits = '0123456789abcdef';
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer
        ..write(hexDigits[(byte >> 4) & 0xf])
        ..write(hexDigits[byte & 0xf]);
    }
    return buffer.toString();
  }
}
