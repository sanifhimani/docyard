# Contributing

Thanks for your interest in contributing to Docyard!

## Quick Start

```bash
git clone https://github.com/sanifhimani/docyard.git
cd docyard
bundle install
```

## Development

```bash
# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop

# Test locally
./bin/docyard init my-docs
cd my-docs
../bin/docyard serve
```

## Pull Requests

1. Fork the repo and create a branch from `main`
2. Write tests for new features
3. Ensure tests pass: `bundle exec rspec`
4. Ensure linter passes: `bundle exec rubocop`
5. Use conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`

## Reporting Issues

- Check existing issues before opening a new one
- Include steps to reproduce for bugs
- For feature requests, explain the use case

## Questions?

Open a [discussion](https://github.com/sanifhimani/docyard/discussions) or [issue](https://github.com/sanifhimani/docyard/issues).
