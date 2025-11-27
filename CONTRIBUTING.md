# Contributing to GeoJSON Pipeline

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/geojson-pipeline.git`
3. Create a branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes: `pytest tests/`
6. Commit: `git commit -m "Add your feature"`
7. Push: `git push origin feature/your-feature-name`
8. Open a Pull Request

## Development Setup

### Local Development

```bash
# Setup environment
cp .env.example .env
# Edit .env with your settings

# Start services
docker-compose up --build

# Run tests
pytest tests/ -v
```

### Code Style

- Follow PEP 8 for Python code
- Use meaningful variable names
- Add docstrings to functions and classes
- Keep functions focused and small

## Testing

- Write tests for new features
- Ensure all tests pass: `pytest tests/`
- Aim for good test coverage

## Pull Request Process

1. Update documentation if needed
2. Add tests for new features
3. Ensure all tests pass
4. Update CHANGELOG.md if applicable
5. Request review

## Reporting Issues

When reporting issues, please include:
- Description of the issue
- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment details (OS, Python version, etc.)

## Feature Requests

Feature requests are welcome! Please open an issue with:
- Clear description of the feature
- Use case/justification
- Potential implementation approach (if you have ideas)

## Questions?

Feel free to open an issue for questions or discussions.

Thank you for contributing! 🚀

