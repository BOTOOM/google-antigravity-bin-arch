# Google Antigravity for Arch Linux

This project allows you to install both **Google Antigravity IDE** and **Google Antigravity 2.0** on Arch Linux (and derivatives like Manjaro).

**Latest Antigravity IDE Version:** `2.5.5`
**Latest Antigravity 2.0 Version:** `2.12.2`

It provides quick install scripts for each product and local maintenance scripts that can fetch the absolute latest version directly from Google.

## Installation Methods

### Option 1: Quick Install - Antigravity IDE
This method uses the `PKGBUILD` hosted in this repository, which is automatically updated by GitHub Actions to track the official Antigravity IDE Linux download.

```bash
curl -sSL https://raw.githubusercontent.com/BOTOOM/google-antigravity-bin-arch/main/install_antigravity | bash
```

**What this does:**
1. Clones this repository to a temporary directory.
2. Checks if you have `google-antigravity-bin` installed.
3. Builds and installs the package using `makepkg`.
4. Cleans up temporary files.

### Option 2: Quick Install - Antigravity 2.0
This installs the standalone Antigravity 2.0 package from the dedicated package definition in this repository.

```bash
curl -sSL https://raw.githubusercontent.com/BOTOOM/google-antigravity-bin-arch/main/install_antigravity_2_0 | bash
```

**What this does:**
1. Clones this repository to a temporary directory.
2. Checks if you have `google-antigravity-2-0-bin` installed.
3. Builds and installs the package using `makepkg`.
4. Cleans up temporary files.

### Option 3: Local Maintenance (Docker Required)
If you want to check for updates directly from Google yourself (e.g., if the repository hasn't updated yet), you can use the local Docker-based scripts for either product.

**Prerequisites:**
- Docker
- `base-devel` package group

**Usage:**
1. Clone the repository:
   ```bash
   git clone https://github.com/BOTOOM/google-antigravity-bin-arch.git
   cd google-antigravity-bin-arch
   ```

2. Run the local check and update script for the product you want:
   ```bash
   ./check_and_update_local.sh
   ./check_and_update_local_2_0.sh
   ```

**What this does:**
1. Builds a minimal Ubuntu Docker image.
2. Fetches the latest version info from Google's release metadata service.
3. Updates the matching local `PKGBUILD` file with this new information.
4. Compares the new version with your installed version.
5. Asks if you want to build and install the update immediately.

## Project Structure

- `install_antigravity`: The standalone installation script used by the curl command.
- `install_antigravity_2_0`: The standalone installation script for Antigravity 2.0.
- `check_and_update_local.sh`: Local maintenance script that orchestrates the Docker check and update process.
- `check_and_update_local_2_0.sh`: Local maintenance script for Antigravity 2.0.
- `_install_local.sh`: Internal script used by `check_and_update_local.sh` to perform the actual installation.
- `update.sh`: The core logic that runs the Docker container to fetch version info.
- `package/PKGBUILD`: The Arch Linux package build description file for Antigravity IDE.
- `package-2.0/PKGBUILD`: The Arch Linux package build description file for Antigravity 2.0.
- `.github/workflows/update.yml`: GitHub Action that runs periodically (every 5 hours) to update both package definitions automatically.

## GitHub Actions Storage Retention

To keep GitHub Actions storage usage low (free tier), configure repository retention to **1 day**:

1. Go to `Settings` → `Actions` → `General`.
2. Set **Artifact and log retention** to `1`.
3. Save changes.

## Disclaimer

This is an unofficial package. Google Antigravity is a trademark of Google.
These packages repackage the official `.tar.gz` archives distributed by Google.
