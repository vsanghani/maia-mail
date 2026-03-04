# Maia Mail

A native iOS email client built with **SwiftUI** — supporting real IMAP/SMTP email accounts with zero third-party dependencies.

## Purpose

Maia Mail is a fully functional email application for iOS that lets you connect to any IMAP/SMTP email provider (Gmail, Outlook, Yahoo, iCloud, or custom servers) to **view, receive, and send emails** directly from your iPhone or iPad.

Built entirely with Apple's frameworks — `SwiftUI` for the UI, `Network` framework for TLS socket connections, and `Security` framework for Keychain credential storage.

---

## Features

- **Account Setup** — Provider presets for Gmail, Outlook, Yahoo, iCloud with auto-filled server config
- **Inbox** — Pull-to-refresh, search, swipe-to-delete/star/mark-read, unread badges
- **Read Emails** — Full email detail view with headers, body, and text selection
- **Compose & Send** — To / CC / BCC fields, reply, forward, discard confirmation
- **Folder Navigation** — Inbox, Sent, Drafts, Trash, Spam, Archive, Starred
- **Secure Storage** — Credentials stored in iOS Keychain
- **Premium UI** — Gradient accents, animated onboarding, avatar colors, SF Symbols

---

## File Structure

```
maia-mail/
├── README.md
├── .gitignore
├── MaiaMail.xcodeproj/                 # Xcode project (open this to build)
│   ├── project.pbxproj
│   ├── project.xcworkspace/
│   └── xcshareddata/xcschemes/
│       └── MaiaMail.xcscheme
│
└── MaiaMail/                           # Source code
    ├── MaiaMailApp.swift               # App entry point (@main)
    │
    ├── Models/
    │   ├── EmailMessage.swift          # Email data model (Identifiable, Codable, Hashable)
    │   ├── EmailFolder.swift           # Folder model with default folder presets
    │   └── EmailAccount.swift          # Account config with provider presets (Gmail, Outlook, etc.)
    │
    ├── Services/
    │   ├── IMAPService.swift           # IMAP client (Network framework + TLS)
    │   │                               #   LOGIN, LIST, SELECT, FETCH, STORE, EXPUNGE
    │   ├── SMTPService.swift           # SMTP client (Network framework + TLS)
    │   │                               #   EHLO, AUTH LOGIN, MAIL FROM, RCPT TO, DATA
    │   ├── EmailService.swift          # High-level orchestrator combining IMAP + SMTP
    │   └── KeychainHelper.swift        # iOS Keychain wrapper for secure credential storage
    │
    ├── ViewModels/
    │   ├── InboxViewModel.swift        # Inbox state: fetch, search, filter, flag ops
    │   ├── ComposeViewModel.swift      # Compose state: send, reply, forward
    │   └── AccountViewModel.swift      # Account setup: save, test connection, sign out
    │
    ├── Views/
    │   ├── MainTabView.swift           # Tab bar (Inbox, Folders, Settings) + FAB compose
    │   ├── Inbox/
    │   │   ├── InboxView.swift         # Email list with search & swipe actions
    │   │   └── EmailRowView.swift      # Single email row (avatar, sender, subject, snippet)
    │   ├── Detail/
    │   │   └── EmailDetailView.swift   # Full email view with reply/forward/delete
    │   ├── Compose/
    │   │   └── ComposeView.swift       # Email compose modal (To, CC, BCC, Subject, Body)
    │   ├── Folders/
    │   │   └── FoldersView.swift       # Folder list + per-folder email view
    │   ├── Settings/
    │   │   ├── AccountSetupView.swift  # Onboarding / account config screen
    │   │   └── SettingsView.swift      # Account info, server details, sign out
    │   └── Components/
    │       └── Components.swift        # Reusable: AvatarView, SearchBarView, EmptyState, Loading
    │
    ├── Theme/
    │   └── Theme.swift                 # Design system: colors, typography, spacing, modifiers
    │
    └── Assets.xcassets/                # App icon & accent color
```

---

## How to Use

### Prerequisites

- **Xcode 15+** (with iOS 17+ SDK)
- **macOS Sonoma** or later
- An email account with IMAP/SMTP access enabled

### Build & Run

1. Clone this repository
2. Open **`MaiaMail.xcodeproj`** in Xcode
3. Select an iPhone simulator (e.g. iPhone 16 Pro)
4. Press **⌘R** to build and run

### First Launch

1. The app opens to the **Account Setup** screen
2. Select your email provider (Gmail, Outlook, Yahoo, iCloud, or Custom)
3. Enter your display name, email address, and password
4. *(Optional)* Tap "Test Connection" to verify before signing in
5. Tap **Sign In** — you'll be taken to your inbox

### Gmail Setup

> **Important:** Gmail requires an **App Password** instead of your regular password.
>
> 1. Go to [Google Account → App Passwords](https://myaccount.google.com/apppasswords)
> 2. Generate a new app password for "Mail"
> 3. Use that 16-character password in Maia Mail

### Outlook / Yahoo / iCloud

These providers work with your regular account password as long as IMAP access is enabled in your account settings.

### Custom Server

Select "Custom" as the provider and manually enter your IMAP and SMTP host, port, and SSL settings.

---

## Architecture

| Layer | Role |
|---|---|
| **Models** | Plain data structs — `EmailMessage`, `EmailFolder`, `EmailAccount` |
| **Services** | Protocol clients (IMAP/SMTP) using Apple's `Network` framework with TLS |
| **ViewModels** | `@ObservableObject` classes bridging services ↔ views with async/await |
| **Views** | SwiftUI views with `@EnvironmentObject` dependency injection |
| **Theme** | Centralized design tokens (colors, fonts, spacing, modifiers) |

---

## Tech Stack

| Component | Technology |
|---|---|
| UI Framework | SwiftUI (iOS 17+) |
| Email Receive | IMAP over TLS (Apple `Network` framework) |
| Email Send | SMTP with AUTH LOGIN (Apple `Network` framework) |
| Credential Storage | iOS Keychain (`Security` framework) |
| Concurrency | Swift async/await + actors |
| Dependencies | **None** — pure Apple frameworks |

---

## License

This project is for personal / educational use.
