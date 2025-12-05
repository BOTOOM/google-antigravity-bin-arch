# Google Antigravity for Arch Linux

![Version](https://img.shields.io/badge/version-1.11.14-blue.svg)

This project allows you to install **Google Antigravity**, Google's new AI-powered IDE, on Arch Linux (and derivatives like Manjaro).

**Latest Version Available:** `1.11.14`

It provides two methods for installation: a quick automated install using the repository's latest info, or a local maintenance mode using Docker to fetch the absolute latest version directly from Google.

## Installation Methods

### Option 1: Quick Install (Recommended)
This method uses the `PKGBUILD` hosted in this repository, which is automatically updated by GitHub Actions.

```bash
curl -sSL https://raw.githubusercontent.com/BOTOOM/google-antigravity-bin-arch/main/install_antigravity | bash
```

**What this does:**
1. Clones this repository to a temporary directory.
2. Checks if you have `google-antigravity-bin` installed.
3. Builds and installs the package using `makepkg`.
4. Cleans up temporary files.

### Option 2: Local Maintenance (Docker Required)
If you want to check for updates directly from Google yourself (e.g., if the repository hasn't updated yet), you can use the local Docker-based scripts.

**Prerequisites:**
- Docker
- `base-devel` package group

**Usage:**
1. Clone the repository:
   ```bash
   git clone https://github.com/BOTOOM/google-antigravity-bin-arch.git
   cd google-antigravity-bin-arch
   ```

2. Run the local check and update script:
   ```bash
   ./check_and_update_local.sh
   ```

**What this does:**
1. Builds a minimal Ubuntu Docker image.
2. Queries Google's APT repository inside the container to get the latest version, SHA256 hash, and download URL.
3. Updates the local `package/PKGBUILD` file with this new information.
4. Compares the new version with your installed version.
5. Asks if you want to build and install the update immediately.

## Project Structure

- `install_antigravity`: The standalone installation script used by the curl command.
- `check_and_update_local.sh`: Local maintenance script that orchestrates the Docker check and update process.
- `_install_local.sh`: Internal script used by `check_and_update_local.sh` to perform the actual installation.
- `update.sh`: The core logic that runs the Docker container to fetch version info.
- `package/PKGBUILD`: The Arch Linux package build description file.
- `.github/workflows/update.yml`: GitHub Action that runs periodically to update the `PKGBUILD` in this repository automatically.

## Disclaimer

This is an unofficial package. Google Antigravity is a trademark of Google.
This package repackages the official `.deb` file distributed by Google.
