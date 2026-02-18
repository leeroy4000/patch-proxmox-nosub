#!/bin/bash
# =============================================================================
# patch_proxmox_nosub.sh
# Neutralizes the "No valid subscription" nag dialog in the Proxmox web UI
# by patching proxmoxlib.js directly on the host.
#
# Usage:
#   ./patch_proxmox_nosub.sh patch    # Apply the patch
#   ./patch_proxmox_nosub.sh restore  # Restore from backup
#
# Tested on: Proxmox VE 7.x, 8.x, 9.x
# =============================================================================

TARGET="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"
BACKUP="${TARGET}.bak"
PATCH_PATTERN="res.data.status.toLowerCase() !== 'active'"

# --- Colors ------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Helpers -----------------------------------------------------------------
info()    { echo -e "${CYAN}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    echo ""
    echo "  Usage: $0 [patch|restore]"
    echo ""
    echo "  patch    Neutralize the subscription warning dialog"
    echo "  restore  Restore proxmoxlib.js from backup"
    echo ""
    exit 1
}

# --- Preflight checks --------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    error "This script must be run as root."
    exit 1
fi

if [ ! -f "$TARGET" ]; then
    error "Target file not found: $TARGET"
    error "Is proxmox-widget-toolkit installed?"
    exit 1
fi

# --- Patch -------------------------------------------------------------------
do_patch() {
    info "Target: $TARGET"

    # Backup
    if [ ! -f "$BACKUP" ]; then
        cp "$TARGET" "$BACKUP"
        success "Backup created at $BACKUP"
    else
        warn "Backup already exists at $BACKUP — skipping backup step."
    fi

    # Check if already patched
    if ! grep -q "$PATCH_PATTERN" "$TARGET"; then
        warn "Patch pattern not found. File may already be patched or your Proxmox version uses a different pattern."
        exit 0
    fi

    # Apply patch
    sed -i "s/$PATCH_PATTERN/false/" "$TARGET"
    success "Subscription check neutralized."

    # Restart pveproxy
    info "Restarting pveproxy..."
    if systemctl restart pveproxy; then
        success "pveproxy restarted. Changes are live — refresh your browser."
    else
        error "pveproxy restart failed. You may need to restart it manually."
        exit 1
    fi
}

# --- Restore -----------------------------------------------------------------
do_restore() {
    if [ ! -f "$BACKUP" ]; then
        error "No backup found at $BACKUP. Cannot restore."
        exit 1
    fi

    info "Restoring from $BACKUP..."
    cp "$BACKUP" "$TARGET"
    success "Original file restored."

    info "Restarting pveproxy..."
    if systemctl restart pveproxy; then
        success "pveproxy restarted. Subscription warning is active again."
    else
        error "pveproxy restart failed. You may need to restart it manually."
        exit 1
    fi
}

# --- Entry point -------------------------------------------------------------
echo ""
echo "  Proxmox No-Subscription Patch"
echo "  =============================="
echo ""

case "$1" in
    patch)   do_patch ;;
    restore) do_restore ;;
    *)       usage ;;
esac

echo ""
