#!/bin/bash

# Update system packages
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Remove old Go version (if exists)
echo "Removing old Go version..."
sudo rm -rf /usr/local/go

# Install Go (version 1.23)
echo "Installing Go..."
wget https://go.dev/dl/go1.23.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.linux-amd64.tar.gz

# Ensure Go is added to PATH
echo "Adding Go to PATH..."
echo "export PATH=/usr/local/go/bin:\$PATH" >> ~/.bashrc
export PATH=/usr/local/go/bin:$PATH
source ~/.bashrc

# Verify Go installation
if ! command -v go &> /dev/null; then
    echo "Go installation failed! Exiting..."
    exit 1
fi
go version

# Install Rust (version 1.81.0 or higher)
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# Verify Rust installation
rustc --version

# Install Risc0 Toolchain
echo "Installing Risc0 Toolchain..."
curl -L https://risczero.com/install | bash
~/.cargo/bin/rzup install

# Ensure Cargo is in PATH
if ! command -v cargo &> /dev/null; then
    echo "Cargo not found! Adding it to PATH..."
    echo "export PATH=\$HOME/.cargo/bin:\$PATH" >> ~/.bashrc
    export PATH=$HOME/.cargo/bin:$PATH
    source ~/.bashrc
fi

# Prompt user for their private key securely
read -sp "Please enter your private key: " PRIVATE_KEY
echo  # Move to a new line after input
echo "Private key recorded!"

# Clone the LayerEdge light node repository
echo "Cloning LayerEdge light node repository..."
git clone https://github.com/Layer-Edge/light-node.git
cd light-node

# Create .env file after inputting private key
echo "Creating .env file..."
cat <<EOF > .env
GRPC_URL=34.31.74.109:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=http://127.0.0.1:8080
PRIVATE_KEY=$PRIVATE_KEY
EOF

# Load environment variables
export $(grep -v '^#' .env | xargs)

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
if [[ ! -f "./light-node" ]]; then
    echo "Error: light-node binary not found! Build failed."
    exit 1
fi
./light-node &

echo "LayerEdge light node setup complete!"
