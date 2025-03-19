#!/bin/bash

# Update system packages
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Remove any existing Go installation
echo "Removing any existing Go installation..."
sudo rm -rf /usr/local/go /usr/bin/go /usr/local/bin/go

# Install Go 1.23
GO_VERSION="1.23"
GO_URL="https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"

echo "Installing Go $GO_VERSION..."
wget $GO_URL
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
rm go${GO_VERSION}.linux-amd64.tar.gz

# Add Go to the PATH
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
export PATH=$PATH:/usr/local/go/bin
source ~/.bashrc

# Verify Go installation
go version

# Install Rust (version 1.81.0 or higher)
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# Verify Rust installation
rustc --version

# Ensure Cargo is in PATH before installing Risc0
if ! command -v cargo &> /dev/null; then
    echo "Cargo not found in PATH. Adding it now..."
    export PATH="$HOME/.cargo/bin:$PATH"
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
else
    echo "Cargo is already in PATH."
fi

# Install Risc0 Toolchain
echo "Installing Risc0 Toolchain..."
curl -L https://risczero.com/install | bash
source $HOME/.cargo/env  # Ensure Cargo environment is loaded
rzup install

# Prompt the user for their private key securely
read -sp "Please enter your private key: " PRIVATE_KEY
echo -e "\nPrivate key recorded!"

# Set environment variables
echo "Setting environment variables..."
export GRPC_URL=34.31.74.109:9090
export CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
export ZK_PROVER_URL=http://127.0.0.1:3001
export API_REQUEST_TIMEOUT=100
export POINTS_API=http://127.0.0.1:8080
export PRIVATE_KEY

# Clone the LayerEdge light node repository
echo "Cloning LayerEdge light node repository..."
git clone https://github.com/Layer-Edge/light-node.git
cd light-node

# Start the Merkle service
echo "Starting the Merkle service..."
cd risc0-merkle-service
cargo build
cargo run &

# Return to the light-node directory
cd ..

# Build and run the LayerEdge light node
echo "Building and running the LayerEdge light node..."
go build

# Check if the binary exists before running
if [ -f "./light-node" ]; then
    ./light-node &
    echo "LayerEdge light node setup complete!"
else
    echo "Error: light-node binary not found. Build may have failed."
    exit 1
fi
