# Contributing

Thanks for wanting to contribute to Docyard!

## Development Setup

```bash
git clone https://github.com/YOUR_USERNAME/docyard.git
cd docyard
bundle install

# Run tests
bundle exec rspec
bundle exec rubocop

# Test locally
./bin/docyard init
./bin/docyard serve
```

## Pull Requests

1. Fork the repo and create a branch from `main`
2. Write tests for new features
3. Run `bundle exec rspec && bundle exec rubocop`
4. Update README/CHANGELOG if needed
5. Use conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`

## Architecture

```
lib/docyard/
  cli.rb              # CLI
  server.rb           # Server lifecycle
  rack_application.rb # HTTP handling
  router.rb           # URL → file mapping
  renderer.rb         # Markdown → HTML
  markdown.rb         # Parsing
  file_watcher.rb     # Live reload
  asset_handler.rb    # Static assets
```

## Code Style

- Maintain >85% test coverage
- Keep methods focused and readable
- Add tests for new features

## Questions?

Open an issue.

---

Thanks for contributing! 🚀
