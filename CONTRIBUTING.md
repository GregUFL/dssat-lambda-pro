# Contributing to DSSAT Lambda Pro

Thank you for your interest in contributing to DSSAT Lambda Pro! This guide will help you get started.

## 📋 Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Code Standards](#code-standards)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Documentation](#documentation)

## 🚀 Getting Started

### Prerequisites
- AWS CLI configured with appropriate permissions
- Docker installed and running
- Python 3.11+
- Git for version control

### Development Environment
```bash
# Clone the repository
git clone https://github.com/GregUFL/dssat-lambda-pro.git
cd dssat-lambda-pro

# Set up local development
./scripts/local_invoke.sh
```

## 🛠️ Development Setup

### Local Testing
```bash
# Run comprehensive tests
./scripts/test_comprehensive.sh

# Validate code quality
./scripts/validate_code.sh

# Test specific functionality
./scripts/test_local_real.sh
```

### Docker Development
```bash
# Build local image
docker build -f infra/Dockerfile -t dssat-lambda-local .

# Test locally
docker run --rm dssat-lambda-local
```

## 📏 Code Standards

### Python Style Guide
- Follow PEP 8 style guidelines
- Use meaningful variable and function names
- Add docstrings for all functions and classes
- Maintain backward compatibility when possible

### File Organization
```
src/
├── handler.py          # Main Lambda entry point
├── stage_inputs.py     # Input file organization
├── run_dssat.py        # DSSAT execution logic
└── collect_outputs.py  # Output processing
```

### Error Handling
- Use appropriate exception types
- Provide meaningful error messages
- Log errors appropriately for debugging
- Handle AWS service errors gracefully

## 🧪 Testing

### Test Requirements
- All new features must include tests
- Existing tests must continue to pass
- Test with realistic DSSAT data when possible

### Test Categories
1. **Unit Tests**: Individual function testing
2. **Integration Tests**: Component interaction testing  
3. **End-to-End Tests**: Full workflow validation
4. **AWS Tests**: Production environment validation

### Running Tests
```bash
# Full test suite
./scripts/test_comprehensive.sh

# Specific test scenarios
python tests/realistic_scenarios/test_improvements.py

# AWS Lambda testing
aws lambda invoke --function-name dssat-lambda-pro \
  --payload file://tests/test_event.json response.json
```

## 📝 Submitting Changes

### Pull Request Process
1. **Fork** the repository
2. **Create** a feature branch from `main`
3. **Make** your changes with appropriate tests
4. **Update** documentation as needed
5. **Submit** a pull request with clear description

### Commit Message Format
Use conventional commit format:
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

Examples:
```bash
feat(handler): add individual file processing support
fix(stage_inputs): resolve crop type detection for .WHX files
docs(readme): update API examples for v5.0
```

### Branch Naming
- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation updates
- `refactor/description` - Code improvements

## 📚 Documentation

### Documentation Standards
- Update README.md for user-facing changes
- Add/update docstrings for code changes
- Update API documentation for interface changes
- Include examples for new features

### Documentation Files
- `README.md` - Project overview and getting started
- `EXECUTIVE_SUMMARY.md` - Business impact summary
- `USAGE.md` - Detailed API usage guide
- `DEPLOYMENT.md` - AWS deployment instructions

### Business Documentation
When making significant changes, update:
- Executive summary for business impact
- Technical documentation for implementation details
- Presentation materials for stakeholder communication

## 🔍 Code Review Guidelines

### For Contributors
- Ensure all tests pass
- Update documentation
- Keep changes focused and atomic
- Write clear commit messages

### For Reviewers
- Check functionality and test coverage
- Verify documentation updates
- Ensure backward compatibility
- Validate AWS deployment compatibility

## 🐛 Bug Reports

### Reporting Issues
Please include:
- Clear description of the issue
- Steps to reproduce
- Expected vs. actual behavior
- Environment details (AWS region, Python version, etc.)
- Sample input files (if applicable)

### Security Issues
For security vulnerabilities, please email directly rather than creating public issues.

## 📞 Getting Help

### Resources
- Check existing documentation in the repository
- Review test examples for usage patterns
- Look at recent pull requests for similar changes

### Contact
- Create an issue for questions or suggestions
- Tag maintainers in pull requests for review

## 🎯 Development Priorities

### Current Focus Areas
1. **Additional Crop Models**: Expanding crop type support
2. **Performance Optimization**: Reducing cold start times
3. **Enhanced Analytics**: Better output processing
4. **API Versioning**: Supporting multiple API versions

### Future Enhancements
- Real-time monitoring and alerting
- Enhanced error recovery mechanisms
- Integration with other agricultural platforms
- Advanced batch processing capabilities

---

Thank you for contributing to DSSAT Lambda Pro! Your efforts help make agricultural simulation more accessible and powerful. 🌾
