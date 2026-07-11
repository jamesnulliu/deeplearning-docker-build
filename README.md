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
rest of your files), and container-side changes never touch your real
`~/.bashrc` etc. Only `~/.bashrc` is seeded into it automatically (the minimum
bash needs to have any hook at all in an otherwise-empty directory) —
everything else is opt-in, one function call away, and prompted by that
seeded `~/.bashrc`'s startup banner: `ADOPT_DEFAULT_CONFIGS` installs the rest
of the container's default dotfiles (including your own persistent copy of
the toolchain script, `~/.env_setup.sh`), and `LINK_HOST_IDENTITY` symlinks in
`~/.ssh`/`~/.gitconfig` from your real host home so git/ssh work. Your host
`/home` is still mounted at `/home` for general file access.

```bash
# Run as yourself (default):
bash ./scripts/run.sh -i <image> -c devbox
bash ./scripts/exec.sh devbox

# Run as root instead (legacy behavior):
bash ./scripts/run.sh -i <image> --root -c devbox
bash ./scripts/exec.sh devbox --root
```

The container toolchain environment (`$ENV_SETUP_FILE`) defaults to your own
persistent `~/.env_setup.sh` once you've run `ADOPT_DEFAULT_CONFIGS`; until
then it falls back live to the read-only shipped default, so the banner and
helper functions are always available with zero setup. It's sourced from your
workspace's `~/.bashrc` — not a root-owned system file — so editing it and
opening a new shell (or re-running `source "$ENV_SETUP_FILE"`) always picks up
your changes. It prints every environment variable it touches so you always
know what is set.

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

`ADOPT_DEFAULT_CONFIGS` installs (or re-syncs) the container default dotfiles
(exposed as `CONTAINER_DEFAULT_BASHRC`, `CONTAINER_DEFAULT_INPUTRC`,
`CONTAINER_DEFAULT_TMUX_CONF`, `CONTAINER_DEFAULT_BASH_PROFILE`,
`CONTAINER_DEFAULT_ENV_SETUP`) into your workspace home, backing up any
existing files to `*.bak`. Only `~/.bashrc` is seeded automatically at
container start; run this for everything else, or whenever you deliberately
want to pull in updated shipped defaults later. `LINK_HOST_IDENTITY` is the
equivalent for `~/.ssh`/`~/.gitconfig` — symlinks in whatever's missing from
your real host home.

