#!/bin/bash

set -e

# --------- Parameters ---------
CIRCUIT_FILENAME=${1:-"example.circom"}
PTAU_FILENAME=${2:-"pot12_final.ptau"}

# --------- Derived Names ---------
ZK_DIR="zk"

CIRCUIT_NAME="${CIRCUIT_FILENAME%.*}"
CIRCUIT_PATH="${ZK_DIR}/circuit/${CIRCUIT_FILENAME}"
PTAU_PATH="${ZK_DIR}/ptau/${PTAU_FILENAME}"

BUILD_DIR="${ZK_DIR}/build/${CIRCUIT_NAME}"
KEY_DIR="${BUILD_DIR}/keys"

echo "📦 Circuit File:     $CIRCUIT_PATH"
echo "🔐 PTAU File:        $PTAU_PATH"
echo "📁 Build Directory:  $BUILD_DIR"
echo "-------------------------------------------"

mkdir -p "build"
mkdir -p "$KEY_DIR"
mkdir -p "$BUILD_DIR"

# 1. Compile circuit
echo "🛠️ Compiling circuit..."
circom "$CIRCUIT_PATH" -o $BUILD_DIR --r1cs --wasm

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

# 4. Solidity verifier
echo "🧾 Exporting Solidity verifier..."
npx snarkjs zkey export solidityverifier "${KEY_DIR}/${CIRCUIT_NAME}_final.zkey" "contracts/${CIRCUIT_NAME}Verifier.sol"

echo "🎉 Done! Output in: ${BUILD_DIR}"
