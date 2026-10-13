# Contributing

1. Create a branch from `main` (any name, e.g. `fix-ticker-speed`).
2. Make your change. Before pushing, run the same checks as CI:
   ```bash
   dart format .
   flutter analyze
   flutter test
   ```
3. Push the branch and open a pull request into `main`. CI runs automatically;
   a maintainer reviews and merges once it's green.

## Guidelines

- Keep pull requests focused on one change and describe what you tested.
- Add or update tests for behaviour changes ([docs/testing.md](docs/testing.md)).
- Check both light and dark mode, and phone and display (≥ 900 px) layouts for
  UI changes.
- Update the docs in `docs/` and add a line to [CHANGELOG.md](CHANGELOG.md)
  under **Unreleased**.
- **Never commit secrets** – see [docs/security.md](docs/security.md#never-commit).
  `.env` must only ever contain public settings.
- Changes to `firestore.rules` affect live data security: say so in the PR, and
  they're deployed manually after review.
