# Skill: Conventional Commit & Changelog Management

## Purpose
Automate structured Git commits, branch formatting, and continuous maintenance of `CHANGELOG.md` across project iterations.

---

## 1. Conventional Commits Standard
Always format commit messages using: `<type>(<optional scope>): <short description in lowercase>`

### Allowed Commit Types:
- `feat`: A new feature added to the application.
- `fix`: A bug fix.
- `docs`: Documentation updates only (README, inline docs, comments).
- `style`: Formatting, missing semi-colons, or whitespace changes (no code logic change).
- `refactor`: Code restructuring without fixing bugs or adding features.
- `test`: Adding missing unit/integration tests or updating existing ones.
- `chore`: Maintenance tasks, dependency updates, build/tooling configuration.

**Examples:**
- `feat(auth): add OAuth2 Google login flow`
- `fix(api): handle timeout exception on user fetch`
- `docs(readme): add local environment setup instructions`

---

## 2. Structured Branch Naming Conventions
Follow standardized branch prefixes:
- `feature/feature-name` (e.g., `feature/user-profiles`)
- `bugfix/issue-description` (e.g., `bugfix/cart-item-deletion`)
- `hotfix/urgent-fix` (e.g., `hotfix/stripe-webhook-crash`)
- `docs/doc-update-description` (e.g., `docs/api-endpoints`)

---

## 3. CHANGELOG.md Standard Format
Maintain `CHANGELOG.md` at the root of the repository following the Keep a Changelog standard.
If the file does not exist, create it with this initial structure:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - YYYY-MM-DD

### Added
- Feature details...

### Fixed
- Bug fix details...

### Changed
- Refactored logic or functional adjustments...