# Hybrid Dev Environment — Architecture \& Operations

> \\\\\\\*\\\\\\\*Layers:\\\\\\\*\\\\\\\* Windows Host · WSL2 (Ubuntu) · Obsidian Vault · Git Repository
> \\\\\\\*\\\\\\\*Paradigm:\\\\\\\*\\\\\\\* Secrets in Vault, code in Repo, execution in WSL, UI in Windows.

\---

## Table of Contents

- [Hybrid Dev Environment — Architecture \& Operations](#hybrid-dev-environment--architecture--operations)
  - [Table of Contents](#table-of-contents)
  - [Architecture Overview](#architecture-overview)
  - [Layer Responsibilities](#layer-responsibilities)
    - [🪟 Windows Host](#-windows-host)
    - [🐧 WSL2 (Ubuntu)](#-wsl2-ubuntu)
    - [🔐 Obsidian Vault](#-obsidian-vault)
    - [📦 Git Repository](#-git-repository)
  - [File Placement Philosophy](#file-placement-philosophy)
    - [The Three Questions](#the-three-questions)
    - [Placement Decision Tree](#placement-decision-tree)
  - [Vault Design](#vault-design)
    - [Secrets Reference Pattern](#secrets-reference-pattern)
    - [Vault–Repo Graduation Workflow](#vaultrepo-graduation-workflow)
  - [Migration Workflow](#migration-workflow)
    - [Phase 1 — Audit](#phase-1--audit)
    - [Phase 2 — Classify](#phase-2--classify)
    - [Phase 3 — Migrate](#phase-3--migrate)
    - [Phase 4 — Verify](#phase-4--verify)
  - [Environment Bootstrap](#environment-bootstrap)
  - [Security Model](#security-model)
  - [Conventions \& Rules](#conventions--rules)
  - [Quick Reference](#quick-reference)

\---

## Architecture Overview

```text
┌─────────────────────────────────────────────────────────┐
│                    WINDOWS HOST                         │
│   GUI apps · Browser · VSCode UI · Docker Desktop       │
│   System fonts · Local backups · Media assets           │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │              WSL2 (Ubuntu)                       │   │
│  │  All dev toolchains (Python, Node, Rust, Go)    │   │
│  │  Docker daemon · SSH agent · Git operations     │   │
│  │  .env files (local) · Compiled artifacts        │   │
│  │                                                  │   │
│  │  ┌────────────────┐   ┌────────────────────┐    │   │
│  │  │  OBSIDIAN VAULT│   │   GIT REPOSITORY   │    │   │
│  │  │  (via Win mount│   │   (GitHub / remote)│    │   │
│  │  │  Personal notes│   │   Source of truth  │    │   │
│  │  │  Secrets ref   │   │   for all code \\\\\\\&   │    │   │
│  │  │  Draft docs    │   │   config templates │    │   │
│  │  └────────────────┘   └────────────────────┘    │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

**Core principle:** Each file lives in exactly one canonical layer. The matrix in `docs/file-placement-matrix.md` encodes that mapping.

\---

## Layer Responsibilities

### 🪟 Windows Host

The substrate layer. Manages hardware, GUI, and heavy binary assets.

|Owns|Never Owns|
|-|-|
|System fonts \& display config|Source code|
|Local backup archives (.tar.gz)|Secrets (plaintext)|
|Browser profiles \& GUI apps|Dev toolchains|
|Docker Desktop (frontend)|.gitconfig identity|
|Video / audio / wallpaper media|Any file in .gitignore scope|

### 🐧 WSL2 (Ubuntu)

The execution layer. All build, run, and test operations happen here.

|Owns|Never Owns|
|-|-|
|All dev toolchains \& runtimes|Windows system files|
|SSH keys (\~/.ssh/)|Vault-designated secrets|
|Local .env files (gitignored)|Committed binary blobs|
|Docker daemon \& containers|Raw database files (commit .sql migrations instead)|
|Compiled artifacts \& logs|Large ML model weights|

**WSL mount convention:**

```bash
# Windows drives mounted at:
/mnt/c/          # C: drive (Windows home)
/mnt/c/Vault/    # Obsidian Vault (cross-accessible)

# Working directory convention:
\\\\\\\~/projects/      # All repos cloned here inside WSL fs
```

### 🔐 Obsidian Vault

The knowledge \& secrets reference layer. Lives on Windows filesystem, accessible from both sides.

|Owns|Never Owns|
|-|-|
|Personal \& team notes (.md)|Executable code|
|API token references (named, not raw)|Files that need Git version history|
|Architecture diagrams (reference copies)|.env files|
|Certificate metadata \& expiry tracking|Compiled/binary assets|
|Draft docs before they graduate to Repo|Secrets in plaintext (use a secrets manager)|

### 📦 Git Repository

The collaboration and truth layer. If it needs to be shared or versioned, it lives here.

|Owns|Never Owns|
|-|-|
|All source code|Real secrets or credentials|
|Config templates (.env.example)|Compiled binaries or large artifacts|
|Infrastructure-as-code (Terraform, Ansible, K8s)|Raw database files|
|CI/CD pipeline definitions|Personal notes|
|Committed documentation (README, ADRs, CHANGELOG)|Log files|

\---

## File Placement Philosophy

### The Three Questions

Before placing any file, ask:

1. **Does it contain a secret?** → Vault reference + WSL local copy. Never Repo.
2. **Does it need version history or collaboration?** → Repo. Always.
3. **Is it environment-specific or generated?** → WSL local or Windows local. Gitignore it.

### Placement Decision Tree

```text
New file created
     │
     ├─ Contains credentials / tokens / keys?
     │       YES → WSL local (.gitignore'd) + reference note in Vault
     │       NO  ↓
     │
     ├─ Needs to be shared or version-tracked?
     │       YES → Repo (commit it)
     │       NO  ↓
     │
     ├─ Is it a personal note or knowledge artifact?
     │       YES → Vault
     │       NO  ↓
     │
     └─ Is it a build artifact, log, or large binary?
             YES → WSL local only (gitignore'd)
             NO  → Re-evaluate; most things fit above categories
```

\---

## Vault Design

```md
📁 Vault/
├── 00-Inbox/              # Unprocessed notes land here first
├── 01-Projects/           # One folder per active project
│   └── <project-name>/
│       ├── Overview.md
│       ├── Architecture.md
│       ├── Decisions/     # ADR drafts before Repo graduation
│       └── Secrets-Ref.md # Named references ONLY (no raw values)
├── 02-Areas/              # Ongoing responsibilities
│   ├── DevEnv/            # This architecture doc's source
│   ├── Security/          # Cert expiry, SSH key inventory
│   └── Infrastructure/
├── 03-Resources/          # Reference material \\\\\\\& research
├── 04-Archive/            # Completed projects, frozen
├── 09-Templates/          # Note templates (PARA, ADR, Runbook)
└── 99-Meta/               # Vault config, plugin settings
```python
```md
```

### Secrets Reference Pattern

The Vault stores **named references**, not raw secrets:

```markdown
<!-- Vault: 01-Projects/my-api/Secrets-Ref.md -->
## API Credentials

- \\\\\\\*\\\\\\\*OpenAI API Key\\\\\\\*\\\\\\\*: Stored in WSL `\\\\\\\~/.env.openai` | Loaded via `direnv`
- \\\\\\\*\\\\\\\*AWS Access Key\\\\\\\*\\\\\\\*: In `\\\\\\\~/.aws/credentials` (WSL) | Profile: `dev`
- \\\\\\\*\\\\\\\*DB Password\\\\\\\*\\\\\\\*: 1Password vault item "prod-db-postgres"

\\\\\\\_Never paste raw values here. This file is NOT gitignored in Vault.\\\\\\\_
```

### Vault–Repo Graduation Workflow

Drafts begin in Vault and graduate to Repo when they're ready to be shared:

```md
Vault/01-Projects/foo/Decisions/ADR-001-draft.md
        ↓  (reviewed, finalized)
Repo/docs/decisions/ADR-001-use-postgres.md
        ↓  (committed, PR merged)
Vault/04-Archive/foo/ADR-001-archived.md  (optional reference copy)
```

\---

## Migration Workflow

Use this workflow when migrating files from an existing monolithic layout into the hybrid architecture.

### Phase 1 — Audit

```bash
# From WSL, list all files not in .gitignore scope
git ls-files --others --exclude-standard > /tmp/untracked.txt

# Find potential secrets (broad scan)
grep -rE '(api\\\\\\\_key|secret|password|token)\\\\\\\\s\\\\\\\*=' . \\\\\\\\
  --include="\\\\\\\*.py" --include="\\\\\\\*.env" --include="\\\\\\\*.json" \\\\\\\\
  -l > /tmp/secret-candidates.txt
```

### Phase 2 — Classify

For each file in the audit:

```bash
# Run interactive classifier (adapt to your setup)
while IFS= read -r file; do
  echo "FILE: $file"
  echo "  \\\\\\\[1] Repo  \\\\\\\[2] WSL local  \\\\\\\[3] Vault  \\\\\\\[4] Windows  \\\\\\\[5] Delete"
  read -rp "  Choice: " choice
  echo "$file -> $choice" >> /tmp/classification.log
done < /tmp/untracked.txt
```

### Phase 3 — Migrate

```bash
# 1. Move secrets out of Repo history (if any were committed)
git filter-repo --path secrets/ --invert-paths

# 2. Add comprehensive .gitignore
cat >> .gitignore << 'EOF'
# Secrets \\\\\\\& local config
.env
.env.\\\\\\\*
!.env.example
!.env.template
\\\\\\\*.pem
\\\\\\\*.key
\\\\\\\*.p12
id\\\\\\\_rsa
id\\\\\\\_ed25519

# Build artifacts
dist/
build/
\\\\\\\*.egg-info/
\\\\\\\_\\\\\\\_pycache\\\\\\\_\\\\\\\_/
\\\\\\\*.pyc
node\\\\\\\_modules/

# Local data
\\\\\\\*.db
\\\\\\\*.sqlite
\\\\\\\*.log
\\\\\\\*.tfstate
\\\\\\\*.tfstate.backup

# OS / Editor
.DS\\\\\\\_Store
Thumbs.db
.vscode/settings.json
EOF

# 3. Commit the .gitignore first
git add .gitignore \\\\\\\&\\\\\\\& git commit -m "chore: establish hybrid architecture gitignore"

# 4. Move Vault-destined files
VAULT="/mnt/c/Vault/01-Projects/$(basename $(pwd))"
mkdir -p "$VAULT/Decisions" "$VAULT/Notes"
mv docs/personal-notes/\\\\\\\* "$VAULT/Notes/"

# 5. Commit remaining tracked files
git add -A \\\\\\\&\\\\\\\& git commit -m "chore: migrate to hybrid architecture file placement"
```

### Phase 4 — Verify

```bash
# Confirm no secrets in Repo
git log --all --full-history -- "\\\\\\\*\\\\\\\*/\\\\\\\*.pem" "\\\\\\\*\\\\\\\*/\\\\\\\*.key" "\\\\\\\*\\\\\\\*/.env"

# Confirm .gitignore working
git status --short | grep -v "^?? "

# Diff between desired placement matrix and actual
# (run your preferred diff tool against docs/file-placement-matrix.md)
```

\---

## Environment Bootstrap

Fresh machine setup order:

```bash
# 1. Install WSL2 (PowerShell, admin)
wsl --install -d Ubuntu

# 2. Clone dotfiles repo (establishes shell, git config, toolchain)
git clone https://github.com/<you>/dotfiles \\\\\\\~/dotfiles
cd \\\\\\\~/dotfiles \\\\\\\&\\\\\\\& ./install.sh

# 3. Set up SSH keys (WSL-native)
ssh-keygen -t ed25519 -C "$(hostname)-wsl-$(date +%Y)"
cat \\\\\\\~/.ssh/id\\\\\\\_ed25519.pub  # Add to GitHub

# 4. Clone this repo
git clone git@github.com:<org>/<repo>.git \\\\\\\~/projects/<repo>

# 5. Restore Vault (from backup or sync)
# Mount from Windows: /mnt/c/Vault already accessible

# 6. Restore .env files from Vault references
# See Vault/01-Projects/<repo>/Secrets-Ref.md
```

\---

## Security Model

|Threat|Mitigation|
|-|-|
|Secret committed to Repo|Pre-commit hook (detect-secrets / gitleaks)|
|Secret in Vault plaintext|Vault notes contain names/references only; raw values in password manager|
|WSL .env leaked via backup|Backup excludes WSL home; Windows backup excludes /mnt/c/… WSL paths|
|SSH key compromise|Ed25519 keys; WSL key ≠ Windows key; rotate annually|
|Supply chain (deps)|Lockfiles committed; Dependabot/Renovate enabled|
|Stale secrets|Vault/02-Areas/Security/ tracks expiry dates; quarterly review|

\---

## Conventions \& Rules

1. **One canonical home.** Every file has exactly one primary layer. The placement matrix is the authority.
2. **Secrets never touch the Repo.** Not even in history. Use `git filter-repo` if they do.
3. **Templates live in Repo; values live in WSL.** `.env.example` is committed; `.env` is not.
4. **Vault drafts graduate to Repo; they don't duplicate.** Once a doc is in Repo, the Vault copy is archived or deleted.
5. **WSL is ephemeral for artifacts.** Anything not in Repo or Vault can be regenerated. Build with that assumption.
6. **No Windows-path strings in code.** Use `/mnt/c/...` in WSL scripts, never `C:\\\\\\\\...`.
7. **Commit messages follow Conventional Commits.** `feat:`, `fix:`, `chore:`, `docs:`, `ci:`.
8. **The matrix is a living document.** When a new file type appears, update `docs/file-placement-matrix.md` in the same PR.

\---

## Quick Reference

```md
LAYER      PRIMARY FOR                        NEVER CONTAINS
─────────  ─────────────────────────────────  ──────────────────────────
Windows    GUI, media, system, Win backups    Source code, secrets
WSL        Toolchains, .env, SSH, execution  Vault docs, committed blobs
Vault      Notes, secret refs, draft docs    Raw secrets, runnable code
Repo       Code, IaC, config templates       Real secrets, binaries, logs
```

\---

*Last updated: 2026-07-09 | Maintained in: `docs/ARCHITECTURE.md`*
