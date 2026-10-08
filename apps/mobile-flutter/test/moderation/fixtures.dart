import 'package:secretmsg_mobile/moderation/crypto/p256_ecdsa.dart';

/// Shared, OpenSSL-generated ES256 bundle fixtures.
///
/// Regenerate with:
/// ```
/// openssl ecparam -name prime256v1 -genkey -noout -out key.pem
/// openssl dgst -sha256 -sign key.pem -out sig.der manifest.json
/// # DER -> raw r||s, base64url (see tool/moderation docs)
/// ```
/// The manifests are compact JSON (no whitespace), exactly as signed.
const String kFixtureKeyId = 'test-key-1';
const String kFixtureKeyX =
    '5234af10c9244a18951ee60ec5503f7e32c33476b530ac0a3637e526f21aa759';
const String kFixtureKeyY =
    'dbc3aa05de049063f2f470f0ab0942f920c8792395cf7b246bf63b23c1c0e328';

const String kFixturePayloadHello = 'hello';
const String kFixturePayloadAbc = 'abc';
const String kFixturePayloadWorld = 'world';
const String kFixturePayloadX = 'x';

const String kFixtureManifestV100 =
    '{"schema":1,"kind":"toxicity_classifier","model_id":"toxicity-multilingual-tiny","version":"1.0.0","language":"mul","payload_file":"payload.bin","payload_size":3,"payload_sha256":"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad","signing_key_id":"test-key-1"}';
const String kFixtureSigV100 =
    '4F_B_HsSD_Q3dJcr7TSkyUTwQ14GmuFXvUzNFoR39Ms2WO4j5Zo8hg5ryDY43TDjxDzeZjZ7F7LZPbUvmOnQUg';

const String kFixtureManifestV120 =
    '{"schema":1,"kind":"toxicity_classifier","model_id":"toxicity-multilingual-tiny","version":"1.2.0","language":"mul","payload_file":"payload.bin","payload_size":5,"payload_sha256":"2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824","signing_key_id":"test-key-1"}';
const String kFixtureSigV120 =
    'vXkCFsX9pvRMs4YMdqaqplWE4FKTOklRi4_BWdg1pWfTnv_UX-mN71BjaHqVwAkD5XnVRJh12t4xsgmupXOAIA';

const String kFixtureManifestV200 =
    '{"schema":1,"kind":"toxicity_classifier","model_id":"toxicity-multilingual-tiny","version":"2.0.0","language":"mul","payload_file":"payload.bin","payload_size":5,"payload_sha256":"486ea46224d1bb4fb680f34f7c9ad96a8f24ec88be73ea8e5a6c65260e9cb8a7","signing_key_id":"test-key-1"}';
const String kFixtureSigV200 =
    '_XKa67SnX3NQ7K9VwKf8MqlGyzGx8wahUS7IZcqIK4kbk8nwvmCfqPw8LUfNHvPx0HWfHwe8iLS3ElWN5CzB0g';

const String kFixtureManifestV300MinApp =
    '{"schema":1,"kind":"toxicity_classifier","model_id":"toxicity-multilingual-tiny","version":"3.0.0","language":"mul","payload_file":"payload.bin","payload_size":5,"payload_sha256":"2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824","signing_key_id":"test-key-1","min_app_version":"99.0.0"}';
const String kFixtureSigV300MinApp =
    'SXYq4yoo4P-gEiFUt13fMmgwt5mZot94xldV0-pz84dapGYXgrUgIz8LOL02E17kcb-I99RdKrU8I2D0XKQKsQ';

const String kFixtureManifestTranslation =
    '{"schema":1,"kind":"translation","model_id":"nmt-en-de","version":"1.0.0","language":"en-de","payload_file":"payload.bin","payload_size":1,"payload_sha256":"2d711642b726b04401627ca9fbac32f5c8530fb1903cc4db02258717921a4881","signing_key_id":"test-key-1"}';
const String kFixtureSigTranslation =
    'plA2V0QRLPmWogs03UBF-NGoumohbKs30OYH5BFyleNsd5e0YMd7fis6zNrK0_s6knvZ3-MRJnPvbKOAxFXRBQ';

P256PublicKey fixtureKey() =>
    P256PublicKey.fromHex('04$kFixtureKeyX$kFixtureKeyY');
