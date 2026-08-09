# linux_setup

Opinionated collection of shell scripts to automate initial Linux workstation and server setup.

> NOTE: These scripts are provided as-is. Review them before running and run them in a safe environment first (VM or container).

## What this repo contains

A set of POSIX/Bash shell scripts that help automate common tasks when setting up a Linux machine, such as:

- Installing packages
- Creating and configuring user dotfiles
- Enabling and configuring common services
- Basic system hardening and configuration

Placeholders in this README should be adjusted to match the specific scripts and behaviors in this repository.

## Prerequisites

- A Linux distribution with a Bourne-style shell (bash, dash, sh).
- sudo or root privileges for system-wide operations.
- Internet access for package installation (unless using an offline package cache).

## ⚠️ Warning
These configuration files may overwrite your existing settings in `~/.config` or your `Home` directory. Always back up your important files before proceeding.

## Quickstart

1. Clone the repository:
```bash
   git clone https://github.com/aale01/linux_setup.git
   cd linux_setup
```
2. Inspect scripts before running. For example:
```bash
   ls -1
   sed -n '1,120p' scripts/setup.sh
```
3. Run a script in a dry-run or review mode if available. If a script requires sudo, run it explicitly:

   ### Inspect then run (example)
```bash
   ./scripts/install-packages.sh --dry-run
   sudo ./scripts/install-packages.sh
```
Replace the above script names with the actual script(s) present in the repository.

## Common scripts (examples)

If you add or maintain scripts in this repo, provide a short description for each script. Example template:

- scripts/install-packages.sh — Installs the base set of packages for the target distribution.
- scripts/configure-dotfiles.sh — Symlinks dotfiles from this repo into the user's home directory.
- scripts/setup-ssh.sh — Generates or installs SSH keys and configures sshd/ssh client settings.
- scripts/harden-system.sh — Applies basic system hardening steps (firewall, SSH config, etc.).

Update this list to match the actual contents.

## Safety and best practices

- Always review scripts before running, especially those that use sudo, modify system configuration, or remove files.
- Test in an isolated environment (VM, container, or a disposable machine) before applying to production systems.
- Use version control for dotfiles and track changes.
- Prefer idempotent scripts (safe to re-run) and provide a `--dry-run` or `--check` mode where possible.

## Customization

- Edit the scripts or add a configuration file (e.g., config.sh) to centralize distribution-specific variables (package manager, package list, user/group names).
- Use environment variables for sensitive values rather than hard-coding credentials.

## Contributing

Contributions are welcome. Please:

1. Open an issue describing the change or improvement.
2. Create a branch and open a pull request with a clear description and tests/verification steps.
3. Follow shell script best practices (set -euo pipefail where appropriate, quote variables, check return codes).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

If you have questions, open an issue or reach out to the repository owner.
