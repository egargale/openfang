# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

# OpenFang — Agent Instructions

## Project Overview
OpenFang is an open-source Agent Operating System written in Rust (14 crates, 137K+ LOC).
- Config: `~/.openfang/config.toml`
- Default API: `http://127.0.0.1:4200`
- CLI binary: `target/release/openfang.exe` (or `target/debug/openfang.exe`)

## Build & Verify Workflow
After every feature implementation, run ALL THREE checks:
```bash
cargo build --workspace --lib          # Must compile (use --lib if exe is locked)
cargo test --workspace                 # All tests must pass (1,800+ tests)
cargo clippy --workspace --all-targets -- -D warnings  # Zero warnings
```

### Running Specific Tests
```bash
# Run tests in a specific crate
cargo test -p openfang-kernel

# Run a specific test by name
cargo test -p openfang-kernel --test integration_test

# Run tests matching a pattern
cargo test -p openfang-runtime agent_loop

# Run a single test function
cargo test -p openfang-memory test_session_repair -- --exact
```

## MANDATORY: Live Integration Testing
**After implementing any new endpoint, feature, or wiring change, you MUST run live integration tests.** Unit tests alone are not enough — they can pass while the feature is actually dead code. Live tests catch:
- Missing route registrations in server.rs
- Config fields not being deserialized from TOML
- Type mismatches between kernel and API layers
- Endpoints that compile but return wrong/empty data

### How to Run Live Integration Tests

#### Step 1: Stop any running daemon
```bash
tasklist | grep -i openfang
taskkill //PID <pid> //F
# Wait 2-3 seconds for port to release
sleep 3
```

#### Step 2: Build fresh release binary
```bash
cargo build --release -p openfang-cli
```

#### Step 3: Start daemon with required API keys
```bash
GROQ_API_KEY=<key> target/release/openfang.exe start &
sleep 6  # Wait for full boot
curl -s http://127.0.0.1:4200/api/health  # Verify it's up
```
The daemon command is `start` (not `daemon`).

#### Step 4: Test every new endpoint
```bash
# GET endpoints — verify they return real data, not empty/null
curl -s http://127.0.0.1:4200/api/<new-endpoint>

# POST/PUT endpoints — send real payloads
curl -s -X POST http://127.0.0.1:4200/api/<endpoint> \
  -H "Content-Type: application/json" \
  -d '{"field": "value"}'

# Verify write endpoints persist — read back after writing
curl -s -X PUT http://127.0.0.1:4200/api/<endpoint> -d '...'
curl -s http://127.0.0.1:4200/api/<endpoint>  # Should reflect the update
```

#### Step 5: Test real LLM integration
```bash
# Get an agent ID
curl -s http://127.0.0.1:4200/api/agents | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])"

# Send a real message (triggers actual LLM call to Groq/OpenAI)
curl -s -X POST "http://127.0.0.1:4200/api/agents/<id>/message" \
  -H "Content-Type: application/json" \
  -d '{"message": "Say hello in 5 words."}'
```

#### Step 6: Verify side effects
After an LLM call, verify that any metering/cost/usage tracking updated:
```bash
curl -s http://127.0.0.1:4200/api/budget       # Cost should have increased
curl -s http://127.0.0.1:4200/api/budget/agents  # Per-agent spend should show
```

#### Step 7: Verify dashboard HTML
```bash
# Check that new UI components exist in the served HTML
curl -s http://127.0.0.1:4200/ | grep -c "newComponentName"
# Should return > 0
```

#### Step 8: Cleanup
```bash
tasklist | grep -i openfang
taskkill //PID <pid> //F
```

### Key API Endpoints for Testing
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/health` | GET | Basic health check |
| `/api/agents` | GET | List all agents |
| `/api/agents/{id}/message` | POST | Send message (triggers LLM) |
| `/api/budget` | GET/PUT | Global budget status/update |
| `/api/budget/agents` | GET | Per-agent cost ranking |
| `/api/budget/agents/{id}` | GET | Single agent budget detail |
| `/api/network/status` | GET | OFP network status |
| `/api/peers` | GET | Connected OFP peers |
| `/api/a2a/agents` | GET | External A2A agents |
| `/api/a2a/discover` | POST | Discover A2A agent at URL |
| `/api/a2a/send` | POST | Send task to external A2A agent |
| `/api/a2a/tasks/{id}/status` | GET | Check external A2A task status |

## Crate Architecture

14 Rust crates organized as a Cargo workspace. Dependencies flow downward:

```
openfang-cli            CLI interface, daemon auto-detect, MCP server mode
    |
openfang-desktop        Tauri 2.0 desktop app (WebView + system tray)
    |
openfang-api            REST/WS/SSE API server (Axum 0.8), 140+ endpoints
    |
openfang-kernel         Central coordinator: assembles all subsystems, RBAC, metering
    |
    +-- openfang-runtime    Agent loop, 3 LLM drivers, 53 tools, WASM sandbox, MCP/A2A
    +-- openfang-channels   40 channel adapters (Telegram, Discord, Slack, etc.)
    +-- openfang-wire       OFP P2P networking with HMAC-SHA256 auth
    +-- openfang-migrate    Migration engine (OpenClaw YAML→TOML)
    +-- openfang-skills     60 bundled skills, FangHub/ClawHub marketplace
    +-- openfang-hands      7 autonomous Hands (researcher, lead, browser, etc.)
    +-- openfang-extensions MCP templates, credential vault, OAuth2 PKCE
    |
openfang-memory         SQLite memory substrate, sessions, embeddings, usage tracking
    |
openfang-types          Core types: Agent, Capability, Event, Tool, Config, Taint, etc.
```

### Key Files to Know
- `crates/openfang-api/src/server.rs` — Route registration, `AppState` struct, CORS, middleware
- `crates/openfang-api/src/routes.rs` — Route handlers, `AppState` definition
- `crates/openfang-kernel/src/kernel.rs` — `OpenFangKernel` struct, subsystem assembly
- `crates/openfang-kernel/src/config.rs` — Config loading from `~/.openfang/config.toml`
- `crates/openfang-runtime/src/agent_loop.rs` — Agent loop, LLM interaction, tool execution
- `crates/openfang-types/src/config.rs` — `KernelConfig` struct with all config fields
- `static/index_body.html` — Dashboard Alpine.js SPA

## Architecture Notes
- **Don't touch `openfang-cli`** — user is actively building the interactive CLI
- `KernelHandle` trait avoids circular deps between runtime and kernel
- `AppState` in `server.rs` bridges kernel to API routes
- New routes must be registered in `server.rs` router AND implemented in `routes.rs`
- Dashboard is Alpine.js SPA in `static/index_body.html` — new tabs need both HTML and JS data/methods
- Config fields need: struct field + `#[serde(default)]` + Default impl entry + Serialize/Deserialize derives

## Common Gotchas
- `openfang.exe` may be locked if daemon is running — use `--lib` flag or kill daemon first
- `PeerRegistry` is `Option<PeerRegistry>` on kernel but `Option<Arc<PeerRegistry>>` on `AppState` — wrap with `.as_ref().map(|r| Arc::new(r.clone()))`
- Config fields added to `KernelConfig` struct MUST also be added to the `Default` impl or build fails
- `AgentLoopResult` field is `.response` not `.response_text`
- CLI command to start daemon is `start` not `daemon`
- On Windows: use `taskkill //PID <pid> //F` (double slashes in MSYS2/Git Bash)
- When adding new API endpoints, check both `server.rs` route registration AND `routes.rs` handler
- All config structs use `#[serde(default)]` — new fields need sensible defaults
