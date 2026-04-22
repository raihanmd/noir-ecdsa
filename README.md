# zk_ecdsa

A small Noir project that proves two things at once:

1. an ECDSA secp256k1 signature is valid for a given message hash
2. the public key maps to an expected Ethereum address

This repo is no longer a Merkle example. The active circuit is an Ethereum-style ECDSA + address check.

## What is in this repo?

- `src/main.nr` — the Noir circuit entrypoint
- `Nargo.toml` — the Nargo manifest for the `zk_ecdsa` package
- `inputs.txt` — raw hex inputs
- `generate_inputs.sh` — converts `inputs.txt` into `Prover.toml`
- `Prover.toml` — prover inputs used by Nargo
- `target/zk_ecdsa.json` and `target/zk_ecdsa.gz` — compiled circuit artifacts
- `target/vk/` — generated verification key artifacts
- `contracts/Verifier.sol` — generated Solidity verifier

## Dependencies

- `std::ecdsa_secp256k1` — verifies the secp256k1 signature inside the Noir circuit
- `keccak256` — hashes the uncompressed public key so the circuit can derive the Ethereum address

The external Noir dependency is declared in `Nargo.toml`:

```toml
keccak256 = { tag = "v0.1.2", git = "https://github.com/noir-lang/keccak256" }
```

## What the circuit does

The circuit takes these inputs:

### Private inputs

- `pub_key_x: [u8; 32]`
- `pub_key_y: [u8; 32]`
- `signature: [u8; 64]`

### Public inputs

- `hashed_message: pub [u8; 32]`
- `expected_address: pub Field`

Then it:

1. verifies the ECDSA signature with `std::ecdsa_secp256k1::verify_signature(...)`
2. concatenates `pub_key_x ++ pub_key_y`
3. hashes the 64-byte public key with `keccak256`
4. takes the last 20 bytes of that hash as the Ethereum address
5. asserts that the derived address matches `expected_address`

## Workflow

### 1. Prepare inputs

Put your hex values in `inputs.txt`:

- `pub_key_x`
- `pub_key_y`
- `signature`
- `hashed_message`
- `expected_address`

Then generate `Prover.toml`:

```bash
./generate_inputs.sh
```

This script:

- reads hex values from `inputs.txt`
- strips the `0x` prefix from byte-array inputs
- removes the final recovery byte (`v`) from the signature
- writes Noir-friendly decimal byte arrays into `Prover.toml`

### 2. Check and compile

```bash
nargo check
nargo compile
```

Compiled artifacts are written to `target/`.

### 3. Execute, prove, and verify

With `Prover.toml` in place:

```bash
nargo execute
nargo prove
nargo verify
```

### 4. Generate verification key and Solidity verifier

For on-chain verification, generate the verification key with Keccak as the oracle hash:

```bash
bb write_vk -b ./target/zk_ecdsa.json -o ./target/vk --oracle_hash keccak
```

Then generate the Solidity verifier:

```bash
bb write_solidity_verifier -k ./target/vk/vk -o ./contracts/Verifier.sol
```

Keccak is the better choice for this verifier flow because it is more EVM-friendly on-chain, while the default zk-oriented hash choice is optimized for proving systems rather than Solidity execution.

### 5. Run tests

```bash
nargo test
```

## Notes

- `expected_address` is now an active public circuit input.
- `signature` inside the circuit is 64 bytes, so `generate_inputs.sh` strips the last byte from a 65-byte Ethereum signature.
- The generated Solidity verifier currently lives in `contracts/Verifier.sol`.
