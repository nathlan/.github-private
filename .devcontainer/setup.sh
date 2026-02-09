#!/bin/bash
set -e

echo "Setting up development environment..."

# Install terraform-docs
echo "Installing terraform-docs..."
TERRAFORM_DOCS_VERSION="0.19.0"
curl -Lo ./terraform-docs.tar.gz "https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz"
tar -xzf terraform-docs.tar.gz
chmod +x terraform-docs
sudo mv terraform-docs /usr/local/bin/
rm terraform-docs.tar.gz
echo "terraform-docs version: $(terraform-docs --version)"

# Install Python tools (Checkov and pre-commit)
echo "Installing Python tools..."
python3 -m pip install --upgrade pip
python3 -m pip install checkov pre-commit
echo "Checkov version: $(checkov --version)"
echo "pre-commit version: $(pre-commit --version)"

# Initialize TFLint plugins
echo "Initializing TFLint..."
tflint --init

# Install pre-commit hooks
echo "Installing pre-commit hooks..."
pre-commit install

# Create Terraform plugin cache directory
mkdir -p .terraform.d/plugin-cache

echo "Development environment setup complete!"
echo ""
echo "Available tools:"
echo "  - Terraform: $(terraform --version | head -n1)"
echo "  - TFLint: $(tflint --version)"
echo "  - terraform-docs: $(terraform-docs --version)"
echo "  - Checkov: $(checkov --version)"
echo "  - pre-commit: $(pre-commit --version)"
echo "  - Node.js: $(node --version)"
echo "  - Python: $(python3 --version)"
echo "  - GitHub CLI: $(gh --version | head -n1)"
