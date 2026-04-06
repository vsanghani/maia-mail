# Changelog

All notable changes to **Maia Mail** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html) where version bumps apply.

## [Unreleased]

### Added

- **Changelog** — this file, for release notes and notable changes.
- **Simulated inbox messages** (Settings → Demos → *Add simulated inbox message…*): on-device-only messages with full control over From, To, Cc, Bcc, subject, body, date, and read state. Entries appear in Inbox alongside real mail, are stored per signed-in account, and are not sent or synced via SMTP/IMAP.
- **Email detail**: Bcc line shown in the header when present (including for simulated messages).
- **Model**: `EmailMessage.isSimulated` and `SimulatedInboxStore` for persistence; IMAP messages continue to use `isSimulated: false`.

### Changed

- **Inbox**: fetch results are merged with simulated messages for the Inbox folder; star, read/unread, and delete bypass the server for simulated rows.

---

*Earlier versions were not listed here; treat **1.0.0** (app Settings) as the baseline before changelog tracking.*
