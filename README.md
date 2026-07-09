# deeplearning-docker-build
Dockerfiles, data and build scripts for creating and maintaining the jamesnulliu/deeplearning container image.

## Running as your host user

By default `scripts/run.sh` and `scripts/exec.sh` run the container as the
**invoking host user** — same UID/GID and primary group as on the host — rather
than root. The host user and group databases (`/etc/passwd`, `/etc/group`) are
mounted read-only and the host `/home` is mounted in, so your username, home,
groups, dotfiles, and `~/.ssh` all resolve inside the container, and files you
create keep your host ownership.

```bash
# Run as yourself (default):
bash ./scripts/run.sh -i <image> -c devbox
bash ./scripts/exec.sh devbox

# Run as root instead (legacy behavior):
bash ./scripts/run.sh -i <image> --root -c devbox
bash ./scripts/exec.sh devbox --root
```

The container toolchain environment is auto-sourced for every interactive shell
(you can also `source "$ENV_SETUP_FILE"` manually). It prints every environment
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

`ADOPT_DEFAULT_CONFIGS` copies the container default dotfiles (exposed as
`CONTAINER_DEFAULT_BASHRC`, `CONTAINER_DEFAULT_INPUTRC`,
`CONTAINER_DEFAULT_TMUX_CONF`, `CONTAINER_DEFAULT_BASH_PROFILE`) into your home,
backing up any existing files to `*.bak`. Your own configs are left untouched
unless you run this.

