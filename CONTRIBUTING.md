# Contributing Guide

Thank you for your interest in contributing to the Zero-Downtime Blue-Green Deployment Pipeline project!

## Getting Started

### Prerequisites
- Docker Desktop (with Docker Compose v2)
- Git
- Python 3.11+
- curl
- Bash (for deployment scripts)

### Local Setup

1. **Fork and clone the repository:**
   ```bash
   git clone https://github.com/YOUR-USERNAME/Zero-Downtime-Blue-Green-Deployment-Pipeline.git
   cd Zero-Downtime-Blue-Green-Deployment-Pipeline
   ```

2. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

3. **Set up development environment:**
   ```bash
   # On Linux/macOS
   bash scripts/init-env.sh
   
   # Or using Make
   make setup
   ```

4. **Verify everything works:**
   ```bash
   curl http://localhost/health
   ```

## Development Workflow

### Making Changes

1. **Create a feature branch** (use descriptive names):
   - `feature/add-health-metrics`
   - `fix/nginx-reload-issue`
   - `docs/improve-readme`
   - `test/increase-coverage`

2. **Make your changes:**
   - Keep commits atomic and logical
   - Write clear commit messages
   - Reference issues in commit messages (e.g., "Fix #123")

3. **Test your changes:**
   ```bash
   # Run unit tests
   make test
   
   # Run with coverage
   make test-coverage
   
   # Run linting
   make lint
   
   # Test deployment locally
   make deploy-v2
   make rollback
   ```

### Running Tests

```bash
# Run all tests
cd app
pytest test_app.py -v

# Run specific test
pytest test_app.py::test_health -v

# Run with coverage
pytest test_app.py --cov=. --cov-report=html

# View coverage report
open htmlcov/index.html
```

### Code Quality

#### Python Code Style
- Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/)
- Use 4 spaces for indentation
- Maximum line length: 100 characters
- Use type hints where possible

#### Commit Messages
- Use present tense: "Add feature" not "Added feature"
- Be specific: "Fix race condition in health check" not "Fix bug"
- Reference issues: "Closes #123"
- Limit first line to 50 characters
- Add more detail in body if needed

Example:
```
Add metrics endpoint for deployment monitoring

- Exposes app_requests_total counter
- Adds request duration histogram
- Includes deployment_timestamp gauge

Closes #42
```

### Documentation

Update documentation when:
- Adding new features
- Changing deployment procedures
- Fixing bugs that affect users
- Adding new configuration options

Files to consider:
- `README.md` - Main overview and quick start
- `DEPLOYMENT_GUIDE.md` - Detailed deployment instructions
- `TROUBLESHOOTING.md` - Common issues and fixes
- Code comments for complex logic

## Pull Request Process

### Before Submitting

1. **Ensure tests pass:**
   ```bash
   make test
   make lint
   ```

2. **Update documentation** if needed

3. **Verify locally:**
   ```bash
   make build
   make up
   curl http://localhost/health
   make down
   ```

4. **Rebase on main:**
   ```bash
   git fetch origin
   git rebase origin/main
   ```

### Creating a Pull Request

1. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create PR on GitHub:**
   - Use a descriptive title
   - Link related issues
   - Describe what changed and why
   - Include testing instructions if applicable

3. **PR Template** (fill out when creating):
   ```markdown
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Documentation update
   - [ ] Performance improvement
   
   ## Testing
   How was this tested?
   
   ## Related Issues
   Closes #123
   
   ## Checklist
   - [ ] Tests pass locally
   - [ ] Documentation updated
   - [ ] No breaking changes
   - [ ] Commits are descriptive
   ```

## Areas for Contribution

### High Priority
- [ ] Database migration strategy
- [ ] Multi-region deployment support
- [ ] Canary deployment option
- [ ] Advanced health check metrics
- [ ] Automated performance testing

### Medium Priority
- [ ] Additional monitoring dashboards
- [ ] Kubernetes deployment support
- [ ] Terraform/IaC templates
- [ ] Deployment scheduling
- [ ] Integration tests

### Documentation
- [ ] Architecture diagrams
- [ ] Video tutorials
- [ ] Troubleshooting guides expansion
- [ ] Production deployment checklist
- [ ] Cost optimization guide

### Testing
- [ ] Increase test coverage
- [ ] Add integration tests
- [ ] Add performance benchmarks
- [ ] Add stress tests
- [ ] Add chaos engineering tests

## Reporting Issues

Use GitHub Issues to report:

1. **Bug Reports:**
   - Describe the issue clearly
   - Include steps to reproduce
   - Provide error logs
   - Mention your environment (OS, Docker version, etc.)

2. **Feature Requests:**
   - Explain the use case
   - Describe desired behavior
   - Suggest implementation approach if possible

3. **Questions:**
   - Check existing issues and documentation first
   - Be specific about what's unclear

### Issue Template
```markdown
## Description
Clear description of the issue

## Steps to Reproduce
1. ...
2. ...
3. ...

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: [e.g., macOS 13.0]
- Docker version: [e.g., 24.0.0]
- Docker Compose version: [e.g., v2.20.0]

## Error Logs
```
<logs here>
```

## Additional Context
Any other relevant information
```

## Code Review Guidelines

We appreciate quality contributions. When reviewing code, consider:

- **Functionality**: Does it solve the stated problem?
- **Testing**: Are there tests? Do they pass?
- **Documentation**: Is it clearly documented?
- **Performance**: Any obvious inefficiencies?
- **Security**: Any security concerns?
- **Style**: Does it match project conventions?

### Common Review Feedback

We may ask for:
- Additional tests
- Documentation updates
- Performance improvements
- Refactoring for clarity
- Error handling improvements

Please don't take feedback personally—it's about improving the project together!

## Development Best Practices

### Local Development
```bash
# Watch logs while testing
make logs-app

# Test deployment
make deploy-v2

# Rollback if needed
make rollback

# Monitor traffic during deployment
make verify-traffic
```

### Git Workflow
```bash
# Keep fork in sync
git fetch upstream
git rebase upstream/main

# Before pushing
git rebase -i HEAD~N  # Clean up commits if needed
git push origin feature/your-feature
```

### Debugging

```bash
# Shell into running container
docker compose exec app-blue bash

# Check specific service logs
docker compose logs postgres
docker compose logs nginx

# Full debug mode for deploy
bash -x ./deploy.sh v2
```

## Project Structure Overview

```
Zero-Downtime-Blue-Green-Deployment-Pipeline/
├── app/              # Flask application & tests
├── nginx/            # Nginx reverse proxy config
├── monitoring/       # Prometheus & Grafana stack
├── scripts/          # Helper scripts
├── .github/          # CI/CD workflows
├── deploy.sh         # Main deployment logic
├── rollback.sh       # Rollback script
└── Makefile          # Development commands
```

## Useful Resources

- [Docker Compose Docs](https://docs.docker.com/compose/)
- [Nginx Config Docs](https://nginx.org/en/docs/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Blue-Green Deployment Patterns](https://martinfowler.com/bliki/BlueGreenDeployment.html)

## Questions?

- Open an issue with the `question` label
- Check existing issues and documentation
- Comment on related pull requests

## Code of Conduct

Be respectful and constructive. We're all here to learn and improve!

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (check LICENSE file).

---

Happy contributing! 🚀
