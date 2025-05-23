#!/bin/bash

set -e

# --------- Parameters ---------
CIRCUIT_FILENAME=${1:-"example.circom"}
INPUT_FILENAME=${2:-"input.json"}
PTAU_FILENAME=${3:-"pot12_final.ptau"}

# --------- Derived Names ---------
ZK_DIR="zk"

CIRCUIT_NAME="${CIRCUIT_FILENAME%.*}"
CIRCUIT_PATH="${ZK_DIR}/circuit/${CIRCUIT_FILENAME}"
INPUT_PATH="${ZK_DIR}/input/${INPUT_FILENAME}"
PTAU_PATH="${ZK_DIR}/ptau/${PTAU_FILENAME}"

BUILD_DIR="${ZK_DIR}/build/${CIRCUIT_NAME}"
KEY_DIR="${BUILD_DIR}/keys"

echo "📦 Circuit File:     $CIRCUIT_PATH"
echo "📥 Input File:       $INPUT_PATH"
echo "🔐 PTAU File:        $PTAU_PATH"
echo "📁 Build Directory:  $BUILD_DIR"
echo "-------------------------------------------"

mkdir -p "build"
mkdir -p "$KEY_DIR"
mkdir -p "$BUILD_DIR"

# 1. Compile circuit
echo "🛠️ Compiling circuit..."
npx circom "$CIRCUIT_PATH" -r "${BUILD_DIR}/${CIRCUIT_NAME}.r1cs" -w "${BUILD_DIR}/${CIRCUIT_NAME}.wasm" -s "${BUILD_DIR}/${CIRCUIT_NAME}.sym"

# 2. Trusted setup (if needed)
if [ ! -f "$PTAU_PATH" ]; then
    echo "🔐 Generating new Powers of Tau..."
    npx snarkjs powersoftau new bn128 12 ${BUILD_DIR}/pot12_0000.ptau -v
    npx snarkjs powersoftau contribute ${BUILD_DIR}/pot12_0000.ptau ${BUILD_DIR}/pot12_0001.ptau --name="First Contributor" -v
    npx snarkjs powersoftau prepare phase2 ${BUILD_DIR}/pot12_0001.ptau "${PTAU_PATH}" -v
else
    echo "✅ Using existing PTAU file: $PTAU_PATH"
fi

# 3. Setup phase 2
echo "🔑 Generating proving/verification keys..."
npx snarkjs groth16 setup "${BUILD_DIR}/${CIRCUIT_NAME}.r1cs" "$PTAU_PATH" "${KEY_DIR}/${CIRCUIT_NAME}_0000.zkey"
npx snarkjs zkey contribute "${KEY_DIR}/${CIRCUIT_NAME}_0000.zkey" "${KEY_DIR}/${CIRCUIT_NAME}_final.zkey" --name="1st Contributor" -v
npx snarkjs zkey export verificationkey "${KEY_DIR}/${CIRCUIT_NAME}_final.zkey" "${KEY_DIR}/verification_key.json"

# 4. Witness
echo "📥 Generating witness..."
npx snarkjs wtns calculate "${BUILD_DIR}/${CIRCUIT_NAME}.wasm" "${INPUT_PATH}" "${BUILD_DIR}/witness.wtns"

# 5. Proof
echo "📜 Generating proof..."
npx snarkjs groth16 prove "${KEY_DIR}/${CIRCUIT_NAME}_final.zkey" "${BUILD_DIR}/witness.wtns" "${BUILD_DIR}/proof.json" "${BUILD_DIR}/public.json"

# 6. Verify
echo "✅ Verifying proof..."
npx snarkjs groth16 verify "${KEY_DIR}/verification_key.json" "${BUILD_DIR}/public.json" "${BUILD_DIR}/proof.json"

# 7. Solidity verifier
echo "🧾 Exporting Solidity verifier..."
npx snarkjs zkey export solidityverifier "${KEY_DIR}/${CIRCUIT_NAME}_final.zkey" "contracts/${CIRCUIT_NAME}Verifier.sol"

echo "🎉 Done! Output in: ${BUILD_DIR}"
