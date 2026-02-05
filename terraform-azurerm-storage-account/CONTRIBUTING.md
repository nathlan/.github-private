# Contributing

Thank you for your interest in contributing to this Terraform module!

## Development Setup

1. Install required tools:
   - [Terraform](https://www.terraform.io/downloads) >= 1.9.0
   - [TFLint](https://github.com/terraform-linters/tflint)
   - [Checkov](https://www.checkov.io/)

2. Clone the repository:
   ```bash
   git clone https://github.com/nathlan/terraform-azurerm-storage-blob.git
   cd terraform-azurerm-storage-blob
   ```

## Making Changes

1. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes following these guidelines:
   - All variables must have descriptions
   - All outputs must have descriptions
   - Follow existing code style and conventions
   - Update documentation as needed

3. Validate your changes:
   ```bash
   # Format code
   terraform fmt -recursive

   # Validate configuration
   terraform validate

   # Run linter
   tflint --recursive

   # Run security scan
   checkov -d . --compact --quiet
   ```

4. Test your changes:
   - Test the example in `examples/basic`
   - Ensure all use cases still work

5. Commit your changes:
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

6. Push and create a pull request:
   ```bash
   git push origin feature/your-feature-name
   ```

## Pull Request Guidelines

- Use clear, descriptive titles
- Include a detailed description of changes
- Reference any related issues
- Ensure all validation checks pass
- Update documentation for any API changes

## Code Style

- Use `snake_case` for variables, outputs, and locals
- Use descriptive names
- Add comments for complex logic
- Keep functions focused and single-purpose

## Questions?

Feel free to open an issue for any questions or concerns.
