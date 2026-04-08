# Rails Upgrade Plan: 7.2.3 → 8.0.x → 8.1.x

> Created: March 2026
> Current: Rails 7.2.3, Ruby 4.0.0
> Target: Rails 8.1.2 (latest as of Jan 2026)

## Strategy

Upgrade one major version at a time: **7.2 → 8.0 → 8.1**. This isolates breaking changes at each step and allows use of `new_framework_defaults` files to opt into changes gradually.

---

## Phase 1: Preparation (before touching the Gemfile)

1. **Enable deprecation reporting in production** — Temporarily set `config.active_support.report_deprecations = true` in `config/environments/production.rb` and deploy. Monitor logs for any Rails 7.2 deprecation warnings that need fixing before the upgrade.

2. **Review upgrade guides** — Read the [Rails 8.0 release notes](https://rubyonrails.org/2024/11/7/rails-8-no-paas-required) and the [upgrade guide](https://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html) for breaking changes.

3. **Audit gem compatibility** — Key blockers identified:
   - **`rails-i18n`** (v7.0.10) — Hard caps at `railties < 8`. Upgrade to `rails-i18n >= 8.0.0`.
   - **`lookbook`** (pinned to 2.3.11) — Already has known issues (GitHub #712). Verify Rails 8 compatibility or find a compatible version.
   - **`minitest < 6.0`** constraint — Verify Rails 8 doesn't require minitest 6+.
   - **`hotwire_combobox`** (0.4.0) — No upper cap but needs testing.
   - **`rack-attack ~> 6.6`** — Should work with Rack 3, but verify.

4. **Create a dedicated branch** — `git checkout -b rails-8-upgrade`

---

## Phase 2: Upgrade to Rails 8.0

5. **Update Gemfile** — Change `gem "rails", "~> 7.2.3"` to `gem "rails", "~> 8.0"`. Also update `rails-i18n` and any other gems with hard version caps.

6. **Run `bundle update rails`** — Let Bundler resolve dependencies. Fix any gem conflicts that arise.

7. **Run `rails app:update`** — This interactive task updates config files, binstubs, and generates `config/initializers/new_framework_defaults_8_0.rb`. For each file conflict:
   - **Keep your version** of files you've customized (environments, initializers)
   - **Accept the new version** for boilerplate files (binstubs, etc.)
   - Review diff carefully for each prompt

8. **Keep `config.load_defaults 7.2`** initially — Don't change this yet. The generated `new_framework_defaults_8_0.rb` file lets you opt into Rails 8 defaults one-by-one.

9. **Fix breaking changes** — Common Rails 8.0 changes to watch for:
   - New default authentication generator (won't affect custom auth)
   - Solid Queue/Solid Cache/Solid Cable are new defaults (keep Sidekiq/Redis)
   - Kamal deployment defaults (optional, won't break anything)
   - Propshaft is now the only asset pipeline (already on Propshaft)
   - `config.assets.quiet` and `config.assets.version` — verify these still work

10. **Run the test suite** — `bin/rails test` then `bin/rails test:system`

11. **Run linters and security checks** — `bin/rubocop -f github -a`, `bundle exec erb_lint ./app/**/*.erb -a`, `bin/brakeman --no-pager`

---

## Phase 3: Adopt Rails 8.0 Defaults

12. **Gradually enable new defaults** — Open `new_framework_defaults_8_0.rb` and uncomment each setting one at a time, running tests after each change.

13. **Once all defaults are enabled**, change `config.load_defaults` from `7.2` to `8.0` and delete the `new_framework_defaults_8_0.rb` file.

---

## Phase 4: Upgrade to Rails 8.1 (repeat the process)

14. Change Gemfile to `gem "rails", "~> 8.1"`, run `bundle update rails`, then `rails app:update`.

15. Repeat phases 2-3 targeting 8.1 defaults.

---

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| `rails-i18n` blocker | Upgrade to `rails-i18n >= 8.0` before Rails upgrade |
| `lookbook` incompatibility | Test early; may need to pin a newer version or temporarily remove |
| Ruby 4.0.0 + Rails 8 | Bleeding-edge Ruby. If gem compilation issues arise, test gems individually |
| Plaid/Stripe/OpenAI gems | Framework-agnostic, low risk |
| Active Storage changes | Verify S3/Cloudflare R2 storage configs still work |
| Sidekiq vs Solid Queue | Rails 8 defaults to Solid Queue, but Sidekiq works fine. No action needed unless switching |

---

## What's Already Rails 8-Ready

- Propshaft (not Sprockets) — aligned with Rails 8 default
- Importmap — aligned with Rails 8 default
- Modern config patterns (no deprecated `cache_classes`, uses symbol-based `show_exceptions`, etc.)
- `config.autoload_lib` — Rails 7.1+ feature already in use
- No Sprockets references anywhere in the codebase
