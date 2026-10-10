# Agent–GitHub Integration Plan (DRAFT for review)

Status: draft, partly decided, not yet implemented.
Goal: drive agent work on the gdd repo through GitHub issues and PRs, from anywhere.

## 0. Decisions log

- Event intake: polling (Option A) for phase 1. No inbound ports. (decided)
- Polling interval: every 3 minutes. (decided)
- Chat platform: none in phase 1. User avoids Telegram. GitHub is the only interface. (decided)
- Host: Hermes runs on alow-aws (NixOS). (decided)
- Trigger rule: no keyword or command. The only human is the user, so any new comment from the user's account starts a run. (decided)
- Who can trigger: only the user's account. The agent has its own clearly identified account. (decided)
- Agent identity: GitHub App named tessera, owned by mmport80, installed on gdd only. Acts as tessera[bot]. Replaces the tessera-bot user account. (decided)
- Model: anthropic/claude-haiku-5.5 to start. (decided)
- Phase 2 (opening issues, merging, CI edits): deferred. (decided)
- Hermes profile: dedicated profile named tessera, so its config, memory, skills, and sessions stay separate from the default profile. (decided; created on alow-aws, model anthropic/claude-haiku-5.5 via openrouter)
- Starting permissions (phase 1, deliberately narrow):
  - Allowed: comment on issues and PRs; push to agent/* branches; open PRs; run the gdd Nix dev shell to build and test.
  - Not allowed: opening issues, merging, pushing to main, editing .github/workflows, changing branch protection or repo settings.
  - Widen later only after a few runs have gone well. (decided)
- Dev environment: the agent uses the gdd flake devShell (ghc, cabal, stack) via `nix develop`. Requires Nix with flakes on alow-aws (already enabled in aws-configuration.nix) and a gdd checkout there. (decided)
- Agent write access: the agent writes code, tests, and tooling, and may push branches and open PRs. Book prose stays with the user. (decided)
- gh CLI: install via Nix in environment.systemPackages on alow-aws. (user doing)
- Port 8644 (webhooks): not opened. Security implications still under review by user. (deferred, Option B)
- Agent GitHub App: not yet created. (pending, user)
- Branch protection on main: not yet enabled. (pending, user)

## 1. Summary

- A long-running Hermes instance (profile tessera) on alow-aws watches the gdd repo on GitHub.
- The user comments on an issue or PR. The agent picks that up, does the work, and replies on the same thread.
- Code changes go out as PRs from agent-owned branches. The user reviews and merges.

## 2. Actors and permissions

| Actor | Who | Can do |
|---|---|---|
| User (john) | Repo owner | Comment, review, merge, write prose |
| Agent (GitHub App tessera, acts as tessera[bot]) | Installed on gdd only; shown as a bot in GitHub's UI | Comment, push to agent/* branches, open PRs (phase 1 limits in section 0) |
| Hermes profile tessera on alow-aws | Runs as a non-root user (name TBD) | Acts through the agent account's token; runs the gdd dev shell |

Rules:
- Only comments from the user's GitHub account trigger work. Everything else is ignored.
- The agent ignores its own comments, to prevent loops.
- The agent never pushes to main. Branch protection on main requires a PR and at least one approval from the user.
- The agent never writes book prose (see gdd/AGENTS.md). Feedback on prose is offered as comments, not edits.

## 3. Event intake

Polling (DECIDED for phase 1, every 3 minutes)
- A cron job on alow-aws runs every 3 minutes.
- It uses gh to list issue and PR comments created since the last run, filters to the user's login, and starts an agent run for each new one.
- Last-seen cursor stored in ~/.hermes/state (exact location TBD).
- Pros: no inbound ports, no public endpoint, no webhook secret.
- Cons: up to 3 minutes of latency.

Webhooks (deferred)
- GitHub webhook to a Hermes webhook subscription on port 8644.
- Needs port 8644 opened on alow-aws (NixOS firewall change) and either an IP allowlist for GitHub's hook ranges plus a strong HMAC secret, or a TLS reverse proxy / tunnel.
- Revisit only if polling latency is a problem. Security review first.

## 4. Run flow

1. Intake finds a new comment from the user on issue or PR #X.
2. The comment and the thread context are passed to a tessera run.
3. The run works on a branch agent/<short-topic>, runs tests inside the gdd dev shell, commits, and pushes.
4. It opens or updates a PR and replies on the thread with a summary and the PR link.
5. Any follow-up comment from the user continues the same thread and branch.

Kanban (multi-profile orchestration) is out of scope for phase 1. Add it once a single agent works end to end.

## 5. Security notes

- Agent auth: GitHub App installation tokens (1-hour lifetime), scoped to gdd by the installation. Permissions: contents, pull requests, issues read and write; metadata read. Nothing else.
- The App private key lives in a mode 600 file outside the repo. The tessera .env holds its path and the App/installation IDs, not the key. Never in config.yaml.
- Prompt injection: issue and PR text is untrusted input. The agent should not run arbitrary commands taken from comment text without the user's own instruction in the same thread.
- Running the dev shell executes project code. That's acceptable for gdd, but changes to flake.nix or build scripts should be reviewed in the PR before the next run.
- Run the agent as a non-root user on alow-aws.
- Audit: GitHub history is the record. Keep the agent's actions traceable to its own account.

## 6. Setup steps

1. [User] Install gh on alow-aws (add `gh` to environment.systemPackages and rebuild).
2. [User] Create the GitHub App "tessera" under mmport80: permissions Contents, Pull requests, Issues (read and write), Metadata (read); webhook disabled. Install it on the gdd repo only. Generate a private key and save it on alow-aws with mode 600, outside the repo.
3. [User] Enable branch protection on main: require PR, require approval, no bypass for tessera.
4. [Done] tessera profile created on alow-aws, model anthropic/claude-haiku-5.5.
5. [Agent] Write a token helper: sign a JWT with the App key, exchange it for a short-lived installation token, and export it as GH_TOKEN per run. The tessera .env holds only the App ID, installation ID, and key path, never the key contents.
6. [Agent] Clone gdd on alow-aws and verify `nix develop` builds the dev shell there.
7. [Agent] Verify gh auth as the agent account on alow-aws.
8. [Agent] Write the polling script and cron entry; test on a throwaway issue.
9. [Agent] Write a skill documenting the run flow, so future sessions follow it.
10. [Both] End-to-end test: comment on a test issue, watch the agent reply and open a PR.

## 7. Open questions

- Tessera profile has no API key yet. It inherits from the shell environment, which won't reach cron jobs. Add the OpenRouter key to the tessera .env before setting up polling.
