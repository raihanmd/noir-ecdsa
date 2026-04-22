# Noir ECDSA

A small Noir project for verifying a secp256k1 ECDSA signature.

Despite the repo name, the current circuit is not building a Merkle tree. It checks that a signature is valid for a given hashed message and public key.

## What is in this repo?

- `src/main.nr` — the Noir circuit entrypoint
- `Nargo.toml` — the Nargo project manifest
- `inputs.txt` — raw hex inputs
- `generate_inputs.sh` — converts `inputs.txt` into `Prover.toml`
- `Prover.toml` — circuit inputs used by Nargo
- `target/` — compiled circuit artifacts
- `out/` — generated proof and verification artifacts

## What the circuit does

The circuit takes:

- `pub_key_x`: 32-byte public key x-coordinate
- `pub_key_y`: 32-byte public key y-coordinate
- `signature`: 64-byte ECDSA signature
- `hashed_message`: 32-byte message hash

It then calls Noir's `std::ecdsa_secp256k1::verify_signature(...)` and asserts that the signature is valid.

## Workflow

### 1. Prepare inputs

Put your hex values in `inputs.txt`:

- `pub_key_x`
- `pub_key_y`
- `signature`
- `hashed_message`

Then generate `Prover.toml`:

```bash
./generate_inputs.sh
```

This script converts hex strings into the decimal byte arrays expected by Noir.

### 2. Check or compile the circuit

```bash
nargo check
nargo compile
```

Compiled artifacts are written to `target/`.

### 3. Run, prove, or verify

With `Prover.toml` in place, you can use the standard Nargo flow:

```bash
nargo execute
nargo prove
nargo verify
```

Proof-related outputs are written to `out/`.

### 4. Run tests

```bash
nargo test
```

## Notes

- `generate_inputs.sh` still writes an `expected_address` field to `Prover.toml`, but the active circuit in `src/main.nr` does not currently use it.
- The active circuit is a direct signature-validity check, not an address recovery check.
- If you want to generate a verification key for a Solidity smart-contract verifier, use `bb write_vk` with `--oracle_hash keccak` instead of the default hash setting. Keccak is the better choice for on-chain verification because it is optimized for EVM execution, while the default Poseidon-style choice is optimized for zk circuits.

```bash
bb write_vk -b ./target/merkle.json -o ./target --oracle_hash keccak
```
