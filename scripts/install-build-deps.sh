#!/bin/bash
# OpenFang Build Dependencies Installer
# Run this script before: cargo build --release
#
# Supported: Ubuntu 22.04+, Debian 12+
# For other distros, adapt the package names accordingly

set -e

echo "=============================================="
echo "OpenFang Build Dependencies Installer"
echo "=============================================="

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo: sudo bash $0"
    exit 1
fi

# Detect package manager
if command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
else
    echo "Unsupported package manager. Please install dependencies manually."
    exit 1
fi

echo "Detected package manager: $PKG_MANAGER"
echo ""

# ============================================
# Core build tools
# ============================================
CORE_BUILD_TOOLS=(
    build-essential
    pkg-config
    curl
    git
    cmake
    autoconf
    libtool
)

# ============================================
# GTK3 and GLib ecosystem (for webkit2gtk)
# ============================================
GTK_DEPS=(
    libgtk-3-dev
    libglib2.0-dev
    libpango1.0-dev
    libcairo2-dev
    libgdk-pixbuf-2.0-dev
    libatk1.0-dev
    libgio2.0-cil-dev
)

# ============================================
# WebKitGTK (for Tauri webview)
# ============================================
WEBKIT_DEPS=(
    libwebkit2gtk-4.1-dev
    libjavascriptcoregtk-4.1-dev
)

# ============================================
# libsoup (HTTP client/server)
# ============================================
SOUP_DEPS=(
    libsoup-3.0-dev
    libjson-glib-dev
)

# ============================================
# OpenSSL (TLS/SSL)
# ============================================
OPENSSL_DEPS=(
    libssl-dev
)

# ============================================
# SQLite (database)
# ============================================
SQLITE_DEPS=(
    libsqlite3-dev
)

# ============================================
# AppIndicator (system tray)
# ============================================
APPINDICATOR_DEPS=(
    libayatana-appindicator3-dev
)

# ============================================
# Audio/Video (optional, for media features)
# ============================================
AV_DEPS=(
    libasound2-dev
    libpulse-dev
)

# ============================================
# Install based on package manager
# ============================================

install_apt() {
    echo "Updating package lists..."
    apt-get update -qq

    echo ""
    echo "Installing core build tools..."
    apt-get install -y "${CORE_BUILD_TOOLS[@]}"

    echo ""
    echo "Installing GTK3 and GLib dependencies..."
    apt-get install -y "${GTK_DEPS[@]}"

    echo ""
    echo "Installing WebKitGTK dependencies..."
    apt-get install -y "${WEBKIT_DEPS[@]}" || {
        echo ""
        echo "WARNING: libwebkit2gtk-4.1-dev not found."
        echo "Trying alternative package name (Ubuntu 22.04)..."
        apt-get install -y libwebkit2gtk-4.0-dev libjavascriptcoregtk-4.0-dev || {
            echo "ERROR: Could not install WebKitGTK. Please install manually."
            exit 1
        }
    }

    echo ""
    echo "Installing libsoup dependencies..."
    apt-get install -y "${SOUP_DEPS[@]}" || {
        echo ""
        echo "WARNING: libsoup-3.0-dev not found."
        echo "Trying alternative package name (libsoup2.4)..."
        apt-get install -y libsoup2.4-dev libjson-glib-dev || {
            echo "ERROR: Could not install libsoup. Please install manually."
            exit 1
        }
    }

    echo ""
    echo "Installing OpenSSL dependencies..."
    apt-get install -y "${OPENSSL_DEPS[@]}"

    echo ""
    echo "Installing SQLite dependencies..."
    apt-get install -y "${SQLITE_DEPS[@]}"

    echo ""
    echo "Installing AppIndicator dependencies..."
    apt-get install -y "${APPINDICATOR_DEPS[@]}"

    echo ""
    echo "Installing Audio/Video dependencies..."
    apt-get install -y "${AV_DEPS[@]}"
}

install_dnf() {
    echo "Updating package lists..."
    dnf makecache

    echo ""
    echo "Installing dependencies (Fedora/RHEL)..."
    dnf groupinstall -y "Development Tools" "C Development Tools and Libraries"
    dnf install -y \
        pkgconfig \
        gtk3-devel \
        glib2-devel \
        pango-devel \
        cairo-devel \
        gdk-pixbuf2-devel \
        atk-devel \
        webkit2gtk4.1-devel \
        libsoup3-devel \
        openssl-devel \
        sqlite-devel \
        libappindicator-gtk3-devel \
        alsa-lib-devel \
        pulseaudio-libs-devel
}

install_pacman() {
    echo "Updating package lists..."
    pacman -Sy

    echo ""
    echo "Installing dependencies (Arch Linux)..."
    pacman -S --noconfirm --needed \
        base-devel \
        pkgconfig \
        gtk3 \
        glib2 \
        pango \
        cairo \
        gdk-pixbuf2 \
        atk \
        webkit2gtk-4.1 \
        libsoup3 \
        openssl \
        sqlite \
        libappindicator-gtk3 \
        alsa-lib \
        libpulse
}

# ============================================
# Run installation
# ============================================

case "$PKG_MANAGER" in
    apt)
        install_apt
        ;;
    dnf)
        install_dnf
        ;;
    pacman)
        install_pacman
        ;;
esac

echo ""
echo "=============================================="
echo "✓ All build dependencies installed successfully!"
echo "=============================================="
echo ""
echo "You can now build OpenFang:"
echo ""
echo "    cd /home/enrico/openfang"
echo "    cargo build --release"
echo ""
