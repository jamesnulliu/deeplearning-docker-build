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
real host home — default `~/.jnl-dl-container-home`, override with `--workspace-home`.
It's a plain host directory (so it survives `docker rm`/recreate just like the
rest of your files), and container-side changes never touch your real
`~/.bashrc` etc.

The workspace is seeded **automatically**, like `/etc/skel` does for
`useradd -m`: every default dotfile (`.bashrc`, `.bash_profile`, `.inputrc`,
`.tmux.conf`, `.vimrc`, `.env_setup.sh`) lives in one directory, `/etc/jnl-dl/skel`, and
gets copied into `$HOME` on your very first shell — copy-if-missing, so
nothing you edit is ever overwritten. `~/.ssh`/`~/.gitconfig` are symlinked in
the same way from your real host home. Every shell tells you exactly what
state your workspace is in:
```
[jnl-dl] Workspace /home/you/.jnl-dl-container-home: new -- seeding default configs from /etc/jnl-dl/skel.
```
or, once it exists:
```
[jnl-dl] Workspace /home/you/.jnl-dl-container-home: already set up (left untouched; any files you don't have yet are still added below).
```
This is driven entirely by `/etc/bash.bashrc`/`/etc/profile.d` (bash's own
startup files, see `/etc/jnl-dl/bootstrap.sh`), not Docker's `ENTRYPOINT` —
so it works the same way under any runtime that runs a plain bash shell
(Docker exec, Apptainer `shell`/`exec`, a bare `docker run --entrypoint
bash`, ...). Your host `/home` is still mounted at `/home` for general file
access.

```bash
# Run as yourself (default):
bash ./scripts/run.sh -i <image> -c devbox
bash ./scripts/exec.sh devbox

# Run as root instead (legacy behavior):
bash ./scripts/run.sh -i <image> --root -c devbox
bash ./scripts/exec.sh devbox --root
```

The container toolchain environment (`$ENV_SETUP_FILE`) always points at your
own persistent `~/.env_setup.sh` — guaranteed to exist from your first shell
onward, so there's no fallback path and no staleness to worry about. Editing
it and opening a new shell (or re-running `source "$ENV_SETUP_FILE"` in the
same shell) always picks up your changes. It prints every environment
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

`ADOPT_DEFAULT_CONFIGS` force re-syncs the shipped default dotfiles from
`/etc/jnl-dl/skel` into your workspace home, backing up any existing files to
`*.bak` first. Your workspace is already seeded automatically on your first
shell (see above) — use this only when you deliberately want to overwrite
your own edits with the latest shipped defaults, e.g. after pulling a newer
image.

