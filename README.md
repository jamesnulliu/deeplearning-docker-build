# deeplearning-docker-build
Dockerfiles, data and build scripts for creating and maintaining the jamesnulliu/deeplearning container image.

## Running as your host user

By default `scripts/run.sh` and `scripts/exec.sh` run the container as the
**invoking host user** — same UID/GID and full group list as on the host —
rather than root. The host user and group databases (`/etc/passwd`,
`/etc/group`) are mounted read-only so your username and groups resolve, and
files you create keep your host ownership. Passwordless `sudo` is available if
you need root for a one-off command.

`$HOME` inside the container is an **isolated workspace directory**, not your
real host home — default `~/.dl-workspace`, override with `--workspace-home`.
It's a plain host directory (so it survives `docker rm`/recreate just like the
rest of your files), seeded once on first use with the container's default
dotfiles, and never re-seeded or clobbered afterward — container-side changes
never touch your real `~/.bashrc` etc. `~/.ssh` and `~/.gitconfig` are
symlinked in automatically from your real host home so git/ssh keep working.
Your host `/home` is still mounted at `/home` for general file access.

```bash
# Run as yourself (default):
bash ./scripts/run.sh -i <image> -c devbox
bash ./scripts/exec.sh devbox

# Run as root instead (legacy behavior):
bash ./scripts/run.sh -i <image> --root -c devbox
bash ./scripts/exec.sh devbox --root
```

The container toolchain environment is sourced from your workspace's own
`~/.bashrc` (seeded on first use, so it's a file you own and can edit or
remove) — not from a root-owned system file. It prints every environment
variable it touches so you always know what is set.

State/cache/root directories are **intentionally not defaulted** — you set them
yourself so nothing points at a stale, guessed location across container
versions. In particular, set these (in your shell or `~/.bashrc`) before using
the matching helper:

- `VCPKG_ROOT` — a writable directory for vcpkg, then run `INSTALL_VCPKG` to clone
  and bootstrap it there.
- `NPM_CONFIG_PREFIX` — a writable npm global prefix, then run `INSTALL_AI_CLI` to
  install the Codex and Claude CLIs into it.
- `CARGO_HOME` (optional) — `cargo`/`rustc`/`rustup` are already on `PATH` (the
  shared toolchain lives under `RUSTUP_HOME`); `cargo` falls back to `~/.cargo`
  unless you set `CARGO_HOME` to relocate its state and add its bin dir to `PATH`.
- `UV_CACHE_DIR` / `UV_PYTHON_INSTALL_DIR` (optional) — override uv's own defaults.

`ADOPT_DEFAULT_CONFIGS` re-syncs the container default dotfiles (exposed as
`CONTAINER_DEFAULT_BASHRC`, `CONTAINER_DEFAULT_INPUTRC`,
`CONTAINER_DEFAULT_TMUX_CONF`, `CONTAINER_DEFAULT_BASH_PROFILE`) into your
workspace home, backing up any existing files to `*.bak`. Your workspace is
already seeded once automatically on first use; run this only when you
deliberately want to pull in updated shipped defaults later.

