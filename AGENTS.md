# Repository Guidelines

## Project Structure & Module Organization
This repository is a small Docker image build system. The root contains `Dockerfile.cpu` and `Dockerfile.cuda`, which define the CPU and CUDA variants. Shared shell entrypoints, environment setup, and container dotfiles live in `data/`. Operational wrappers live in `scripts/`: `build.sh`, `run.sh`, `exec.sh`, `image-configs.sh`, and `next-version.sh`. Release automation is in `.github/workflows/cd-docker-build-push.yml`.

## Build, Test, and Development Commands
Use the scripts rather than calling long `docker` commands by hand.

- `bash ./scripts/build.sh Dockerfile.cpu`: build the CPU image and print its tag.
- `bash ./scripts/build.sh Dockerfile.cuda`: build the CUDA image using the version values from `scripts/image-configs.sh`.
- `bash ./scripts/next-version.sh --patch --push`: bump `IMAGE_VERSION`, commit current changes, tag the release, and push the branch plus tag to start the GitHub workflow.
- `bash ./scripts/next-version.sh --minor --push` or `--major --push`: same release flow for larger version bumps.
- `bash ./scripts/run.sh -i jamesnulliu/deeplearning:v2.4.7-cuda12.8.0 --tmp`: start an interactive temporary container.
- `bash ./scripts/run.sh -i <image> -c devbox`: start a named long-lived container.
- `bash ./scripts/run.sh -i <image> --root -c devbox`: start it as root (legacy) instead of the host user.
- `bash ./scripts/exec.sh devbox`: open a shell as the host user; add `--root` for a root shell.

By default `run.sh`/`exec.sh` run the container as the invoking host user (same UID/GID and full group list via `--group-add`, computed from `id -G`), mounting `/etc/passwd` and `/etc/group` read-only and the host `/home`, so identities and groups resolve. `$HOME` is an isolated per-user workspace directory (default `~/.dl-workspace`, override with `--workspace-home`), not the real host home, so container-side changes never touch real host dotfiles. `entrypoint.sh` seeds exactly one file there, `~/.bashrc` (copy-if-missing) — the minimum bash needs to have any hook at all; root gets the same single-file treatment baked at build time. Everything else is opt-in via functions defined in `$ENV_SETUP_FILE` and prompted by that seeded `~/.bashrc`'s banner: `ADOPT_DEFAULT_CONFIGS` installs the rest of the `CONTAINER_DEFAULT_*` dotfiles plus your own persistent `~/.env_setup.sh` copy, and `LINK_HOST_IDENTITY` symlinks in `~/.ssh`/`~/.gitconfig` from the real host home. `$ENV_SETUP_FILE` itself defaults to `~/.env_setup.sh`, falling back live to the read-only shipped default until you adopt it — sourced from `~/.bashrc`, not a system-wide hook, and re-sourceable after edits (no double-source guard). Passwordless `sudo` is available. Other per-user helpers: `INSTALL_VCPKG`, `INSTALL_AI_CLI` (codex + claude into a personal npm prefix).

## Coding Style & Naming Conventions
Keep Dockerfiles and shell scripts POSIX/Bash-friendly, with one logical step per block and consistent four-space indentation for wrapped commands. Prefer uppercase variable names for exported build configuration (`IMAGE_VERSION`, `CUDA_VERSION`) and lowercase filenames for scripts and data assets. When you change a version, update `scripts/image-configs.sh` first so tags stay consistent. For releases, prefer `scripts/next-version.sh` so the version bump, commit, tag, and push happen in one place.

## Testing Guidelines
There is no automated unit test suite in this repository today. Validation is build-and-smoke-test based: rebuild the affected Dockerfile, start a container, and verify entrypoint behavior plus any installed toolchain changes. For example, after editing `data/env_setup.sh`, run the image and confirm the shell starts cleanly.

## Commit & Pull Request Guidelines
Recent history uses short bracketed prefixes such as `[update]`, `[fix]`, and version-scoped subjects like `[UPDATE][v2.4.5] ...`. Follow that pattern and keep the subject imperative. The release helper stages all current repo changes, allows an empty commit when needed, creates the new `v*` tag, and only pushes to `origin` when `--push` is passed. PRs should state which image variant changed, summarize package/toolchain impact, include the exact build command used for verification, and note any release-tag implications. Do not commit credentials; Docker Hub publishing is handled by GitHub Actions secrets on tagged pushes (`v*`).
