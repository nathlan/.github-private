# Quick Start Guide - Terraform Module Creator

## 🚀 Get Started in 3 Steps

### 1. Setup Complete ✅
The `copilot-setup-steps.yml` file will automatically install using GitHub Marketplace Actions:
- **Terraform** - hashicorp/setup-terraform@v3
- **TFLint** - terraform-linters/setup-tflint@v4
- **Checkov** - pip3 installation

No manual installation needed! All tools use official, maintained actions.

### 2. Invoke the Agent
In GitHub Copilot Chat, use:
```
@terraform-module-creator [your request]
```

### 3. Create Your First Module

#### Example 1: Simple Storage Account
```
@terraform-module-creator create a storage account module using AVM
```

#### Example 2: Virtual Network with Subnets
```
@terraform-module-creator create a VNet module with 3 subnets using AVM
```

#### Example 3: Update Existing Module
```
@terraform-module-creator add private endpoint support to the storage module
```

## 📁 What Gets Created

Every module includes:
```
my-module/
├── main.tf              # Resources
├── variables.tf         # Inputs
├── outputs.tf           # Outputs
├── versions.tf          # Version constraints
├── README.md            # Documentation
├── .tflint.hcl          # Linting config
└── examples/
    └── basic/
        ├── main.tf
        └── README.md
```

## ✅ Automatic Validation

The agent runs these checks automatically:
1. ✨ `terraform fmt` - Formatting
2. 🔍 `terraform validate` - Syntax
3. 📋 `tflint` - Best practices
4. 🔒 `checkov` - Security

## 🎯 Common Commands

### Create Module
```
@terraform-module-creator create a [service] module
```

### Update Module  
```
@terraform-module-creator add [feature] to [module]
```

### Create PR
```
@terraform-module-creator create PR for [changes]
```

### Version Release
```
@terraform-module-creator release version [X.Y.Z]
```

## 📚 Need More Info?

See `TERRAFORM_MODULE_CREATOR_GUIDE.md` for:
- Detailed usage examples
- Best practices
- Troubleshooting
- Advanced features

## 🎓 Pro Tips

1. **Be Specific** - More detail = better results
2. **Iterate** - Refine modules through conversation
3. **Trust Validation** - Agent enforces security
4. **Review PRs** - Check generated code before merge
5. **Use Examples** - Test modules locally

## 🔧 Configuration Templates

Use these templates in your modules:
- `.tflint.hcl.template` - Copy to your module as `.tflint.hcl`
- `.checkov.yaml.template` - Copy to your module as `.checkov.yaml`

## 🆘 Need Help?

Common issues and solutions:

**Agent not responding?**
- Check agent is in `agents/` directory
- Verify `.github-private` repo access

**Validation failing?**
- Review error messages
- Agent will try to auto-fix
- Check `TERRAFORM_MODULE_CREATOR_GUIDE.md` troubleshooting

**Module issues?**
- Verify AVM module versions
- Check provider constraints
- Test examples locally

## 🎉 You're Ready!

Start creating Terraform modules with:
```
@terraform-module-creator help me create my first module
```

The agent will guide you through the process step-by-step.
