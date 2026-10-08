// NOT CRYPTOGRAPHICALLY REVIEWED. See lib/crypto/README.md and the header of
// crypto_constants.dart. Crypto bugs fail silently.
//
// Per-device X25519 keypair storage.
//
// One keypair per app install ("device"), generated on first use and kept in
// flutter_secure_storage (Android Keystore-backed encrypted preferences).
// There is no key escrow and no server-side backup of the private key: see
// reinstall_policy.dart for the user-facing consequence. Losing the install
// means losing the ability to decrypt envelopes wrapped to the old key — the
// honest behaviour is to say so, not to silently upload a recovery copy.
library;

import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'crypto_constants.dart';
import 'crypto_encoding.dart';

const String kDeviceIdKey = 'secretmsg_e2e_device_id';
const String kDevicePrivateKeyKey = 'secretmsg_e2e_x25519_private';
const String kDevicePublicKeyKey = 'secretmsg_e2e_x25519_public';

/// Minimal storage seam so tests do not need a platform channel. Production
/// uses [SecureDeviceSecretStore]; tests inject an in-memory implementation.
abstract class DeviceSecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// flutter_secure_storage-backed implementation.
class SecureDeviceSecretStore implements DeviceSecretStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  const SecureDeviceSecretStore();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// A device keypair in raw byte form.
class DeviceKey {
  /// Opaque, non-secret device identifier. Sent to the server with the public
  /// key so a device can replace its own previous key on reinstall.
  final String deviceId;

  /// Raw 32-byte X25519 private key. Never leaves the device.
  final Uint8List privateKeyBytes;

  /// Raw 32-byte X25519 public key. Published to the server.
  final Uint8List publicKeyBytes;

  DeviceKey({
    required this.deviceId,
    required List<int> privateKeyBytes,
    required List<int> publicKeyBytes,
  })  : privateKeyBytes = Uint8List.fromList(privateKeyBytes),
        publicKeyBytes = Uint8List.fromList(publicKeyBytes);

  String get publicKeyB64 => CryptoEncoding.b64url(publicKeyBytes);
}

class DeviceKeyStore {
  final DeviceSecretStore store;

  DeviceKeyStore({DeviceSecretStore? store})
      : store = store ?? const SecureDeviceSecretStore();

  /// Loads the device keypair, or returns null when this install has none.
  ///
  /// Null is the normal post-reinstall state and must be handled honestly:
  /// old encrypted messages cannot be read and must not be rendered as if
  /// they could. A half-present keypair (public without private, or vice
  /// versa) is treated as absent, not repaired with mismatched halves.
  Future<DeviceKey?> load() async {
    try {
      final deviceId = await store.read(kDeviceIdKey);
      final priv = await store.read(kDevicePrivateKeyKey);
      final pub = await store.read(kDevicePublicKeyKey);
      if (deviceId == null ||
          deviceId.isEmpty ||
          priv == null ||
          priv.isEmpty ||
          pub == null ||
          pub.isEmpty) {
        return null;
      }
      final privBytes = CryptoEncoding.b64urlDecode(priv);
      final pubBytes = CryptoEncoding.b64urlDecode(pub);
      if (privBytes.length != kX25519KeyLength ||
          pubBytes.length != kX25519KeyLength) {
        return null;
      }
      return DeviceKey(
        deviceId: deviceId,
        privateKeyBytes: privBytes,
        publicKeyBytes: pubBytes,
      );
    } catch (_) {
      // Unreadable storage counts as key loss, not as a reason to crash the
      // inbox; the caller shows the reinstall notice.
      return null;
    }
  }

  /// Loads the existing keypair or generates, persists, and returns a new one.
  ///
  /// Generation uses package:cryptography's X25519 key generation, which seeds
  /// from the platform CSPRNG. The private key is written before the public
  /// key so a crash mid-write leaves an obvious half-state that [load] treats
  /// as absent instead of a mismatched pair.
  Future<DeviceKey> loadOrCreate() async {
    final existing = await load();
    if (existing != null) return existing;

    final keyPair = await X25519().newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateBytes = await keyPair.extractPrivateKeyBytes();

    final deviceId = _randomDeviceId();
    await store.write(
        kDevicePrivateKeyKey, CryptoEncoding.b64url(privateBytes));
    await store.write(kDevicePublicKeyKey, CryptoEncoding.b64url(publicKey.bytes));
    await store.write(kDeviceIdKey, deviceId);

    return DeviceKey(
      deviceId: deviceId,
      privateKeyBytes: privateBytes,
      publicKeyBytes: publicKey.bytes,
    );
  }

  /// Deletes the keypair. Used by account wipe; afterwards old envelopes are
  /// unreadable on this device, by design and without a recovery path.
  Future<void> clear() async {
    await store.delete(kDevicePrivateKeyKey);
    await store.delete(kDevicePublicKeyKey);
    await store.delete(kDeviceIdKey);
  }

  static String _randomDeviceId() {
    final rng = Random.secure();
    final bytes =
        Uint8List.fromList(List<int>.generate(16, (_) => rng.nextInt(256)));
    return CryptoEncoding.b64url(bytes);
  }
}
