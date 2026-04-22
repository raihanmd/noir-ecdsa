use ::keccak256;
use ::std::ecdsa_secp256k1;

fn main(
    pub_key_x: [u8; 32],
    pub_key_y: [u8; 32],
    signature: [u8; 64],
    hashed_message: pub [u8; 32],
    expected_address: pub Field,
) {
    // 1. verify signature valid untuk pubkey ini
    let is_valid =
        ecdsa_secp256k1::verify_signature(pub_key_x, pub_key_y, signature, hashed_message);
    assert(is_valid, "invalid signature");

    // 2. derive address dari pubkey dan cek cocok
    // address = last 20 bytes of keccak256(pubkey_x ++ pubkey_y)
    let mut pubkey_bytes: [u8; 64] = [0; 64];
    for i in 0..32 {
        pubkey_bytes[i] = pub_key_x[i];
        pubkey_bytes[i + 32] = pub_key_y[i];
    }
    let pubkey_hash = keccak256::keccak256(pubkey_bytes, 64);

    // ambil 20 bytes terakhir = ethereum address
    let mut addr_field: Field = 0;
    for i in 0..20 {
        addr_field = addr_field * 256 + pubkey_hash[i + 12] as Field;
    }
    assert(addr_field == expected_address, "address mismatch");
}
