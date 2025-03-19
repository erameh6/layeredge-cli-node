#!/bin/bash

# Function to check command existence
command_exists() {
    command -v "$1" &> /dev/null
}

# Update system packages
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Remove old Go version if installed
if command_exists go; then
    echo "Removing old Go version..."
    sudo rm -rf /usr/local/go
fi

# Install Go 1.22.1 (since 1.23 doesn't exist)
GO_VERSION="1.22.1"
echo "Installing Go $GO_VERSION..."
wget "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
rm "go${GO_VERSION}.linux-amd64.tar.gz"

# Add Go to PATH
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
export PATH=$PATH:/usr/local/go/bin
source ~/.bashrc
go version || { echo "Go installation failed! Exiting..."; exit 1; }

# Install Rust if not installed
if ! command_exists rustc; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi
rustc --version || { echo "Rust installation failed! Exiting..."; exit 1; }

# Ensure Cargo is in PATH
if ! command_exists cargo; then
    echo "Adding Cargo to PATH..."
    echo 'export PATH=$HOME/.cargo/bin:$PATH' >> ~/.bashrc
    export PATH=$HOME/.cargo/bin:$PATH
    source ~/.bashrc
fi

# Install Risc0 Toolchain
echo "Installing Risc0 Toolchain..."
curl -L https://risczero.com/install | bash
~/.cargo/bin/rzup install || { echo "Risc0 installation failed! Exiting..."; exit 1; }

# Prompt user for private key securely
read -sp "Please enter your private key: " PRIVATE_KEY
echo -e "\nPrivate key recorded successfully!"

# Set environment variables
echo "Setting environment variables..."
export GRPC_URL=34.31.74.109:9090
export CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
export ZK_PROVER_URL=http://127.0.0.1:3001
export API_REQUEST_TIMEOUT=100
export POINTS_API=http://127.0.0.1:8080
export PRIVATE_KEY

# Create .env file
echo "Creating .env file..."
cat <<EOF > ~/.env
GRPC_URL=34.31.74.109:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=http://127.0.0.1:8080
PRIVATE_KEY=$PRIVATE_KEY
EOF

# Clone LayerEdge light node repository
echo "Cloning LayerEdge light node repository..."
git clone https://github.com/Layer-Edge/light-node.git
cd light-node

# Start Merkle service
echo "Starting the Merkle service..."
cd risc0-merkle-service
cargo build
cargo run &

# Return to main light-node directory
cd ..

# Fix Go module dependencies
echo "Tidying Go modules..."
go mod tidy

# Build and run the LayerEdge light node
echo "Building and running the LayerEdge light node..."
go build || { echo "Go build failed! Exiting..."; exit 1; }
./light-node &

echo "✅ LayerEdge light node setup complete!"
