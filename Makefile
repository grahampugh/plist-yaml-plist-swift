SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# Extract version from Swift source
VERSION := $(shell grep 'version:' Sources/plistyamlplist/plistyamlplist.swift | sed -E 's/.*"([0-9.]+)".*/\1/')
BINARY_NAME := plistyamlplist
PKG_DIR := .build/pkg
PKG_NAME := $(BINARY_NAME)-$(VERSION).pkg
PKG_PATH := $(PKG_DIR)/$(PKG_NAME)
INSTALL_PREFIX := /usr/local/bin

# Build configuration
SWIFT_BUILD_FLAGS := -c release --arch arm64 --arch x86_64

.PHONY: all clean package release help

# Default target
all: package

# Display help
help:
	@echo "plist-yaml-plist Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  package    - Build release binary and create installer package (default)"
	@echo "  clean      - Remove build artifacts and packages"
	@echo "  release    - Create GitHub pre-release with package"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Version: $(VERSION)"

# Clean build artifacts and packages
clean:
	@echo "Cleaning build artifacts..."
	rm -rf .build/release .build/debug
	rm -rf $(PKG_DIR)
	@echo "Clean complete"

# Build the binary and create installer package
package: clean
	@echo "Building plistyamlplist version $(VERSION)..."
	@echo "Building universal binary (arm64 + x86_64)..."
	swift build $(SWIFT_BUILD_FLAGS)
	
	@echo "Creating package directory..."
	mkdir -p $(PKG_DIR)/payload$(INSTALL_PREFIX)
	mkdir -p $(PKG_DIR)/scripts
	
	@echo "Copying binary..."
	cp .build/apple/Products/Release/$(BINARY_NAME) $(PKG_DIR)/payload$(INSTALL_PREFIX)/
	chmod 755 $(PKG_DIR)/payload$(INSTALL_PREFIX)/$(BINARY_NAME)
	
	@echo "Verifying binary architecture..."
	@lipo -info $(PKG_DIR)/payload$(INSTALL_PREFIX)/$(BINARY_NAME)
	
	@echo "Creating postinstall script..."
	@echo '#!/bin/bash' > $(PKG_DIR)/scripts/postinstall
	@echo 'echo "plistyamlplist $(VERSION) installed to $(INSTALL_PREFIX)"' >> $(PKG_DIR)/scripts/postinstall
	@echo 'echo "Run: plistyamlplist --help"' >> $(PKG_DIR)/scripts/postinstall
	@echo 'exit 0' >> $(PKG_DIR)/scripts/postinstall
	chmod +x $(PKG_DIR)/scripts/postinstall
	
	@echo "Building package..."
	pkgbuild \
		--root $(PKG_DIR)/payload \
		--scripts $(PKG_DIR)/scripts \
		--identifier com.github.grahampugh.plistyamlplist \
		--version $(VERSION) \
		--install-location / \
		$(PKG_PATH)
	
	@echo "Package created: $(PKG_PATH)"
	@echo "Package size: $$(du -h $(PKG_PATH) | cut -f1)"
	@echo ""
	@echo "Opening package directory in Finder..."
	open $(PKG_DIR)
	@echo ""
	@echo "✅ Package build complete!"

# Create GitHub pre-release
release: package
	@echo "Creating GitHub pre-release..."
	@if ! command -v gh &> /dev/null; then \
		echo "❌ Error: GitHub CLI (gh) is not installed"; \
		echo "Install with: brew install gh"; \
		exit 1; \
	fi
	
	@if ! gh auth status &> /dev/null; then \
		echo "❌ Error: Not authenticated with GitHub"; \
		echo "Run: gh auth login"; \
		exit 1; \
	fi
	
	@echo "Creating release v$(VERSION)..."
	gh release create "v$(VERSION)" \
		--title "plistyamlplist v$(VERSION)" \
		--notes "Swift implementation of plist-yaml-plist converter.$${'\n\n'}### Installation$${'\n\n'}Download and run the .pkg installer.$${'\n\n'}### Features$${'\n'}- Plist ↔ YAML conversion$${'\n'}- JSON → Plist conversion$${'\n'}- AutoPkg recipe optimization$${'\n'}- Batch processing with glob patterns$${'\n'}- Native macOS 15+ support$${'\n\n'}See CHANGELOG.md for details." \
		--prerelease \
		$(PKG_PATH)
	
	@echo ""
	@echo "✅ Pre-release created successfully!"
	@echo "View at: $$(gh repo view --json url -q .url)/releases"
	@echo ""
	@echo "To publish the release, visit GitHub and change from pre-release to full release."

# Development: build debug version
dev:
	swift build
	.build/debug/$(BINARY_NAME) --version

# Run tests (if any exist)
test:
	swift test

# Install locally (without package)
install: package
	@echo "Installing to $(INSTALL_PREFIX)..."
	sudo installer -pkg $(PKG_PATH) -target /
	@echo "Installed successfully!"
	@echo ""
	plistyamlplist --version
