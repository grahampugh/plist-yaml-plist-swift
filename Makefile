SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# Extract version from Swift source
VERSION := $(shell grep 'version:' Sources/plistyamlplist/plistyamlplist.swift | sed -E 's/.*"([0-9.]+)".*/\1/')
BINARY_NAME := plistyamlplist
PKG_DIR := .build/pkg
PKG_NAME := $(BINARY_NAME)-$(VERSION).pkg
PKG_PATH := $(PKG_DIR)/$(PKG_NAME)
INSTALL_PREFIX := /usr/local/bin

SIGN_ID_APP    ?= Developer ID Application: Graham Pugh
SIGN_ID_PKG    ?= Developer ID Installer: Graham Pugh
NOTARY_PROFILE ?= graham-notary-profile-plistyamlplist
TEAM_ID        ?= C96ALZKYH6

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
	@echo "  sign       - Code sign the built binary with SIGN_ID_APP"
	@echo "  notarize   - Notarize the signed binary using NOTARY_PROFILE and staple the ticket"
	@echo "  notarize-pkg - Notarize and staple the built installer package (.pkg)"
	@echo "  staple     - Staple the notarization ticket to the binary"
	@echo "  staple-pkg - Staple the notarization ticket to the existing .pkg (after a successful notarization)"
	@echo "  clean      - Remove build artifacts and packages"
	@echo "  release    - Create GitHub pre-release with package"
	@echo "  staple-and-release - Staple existing .pkg and create GitHub pre-release (no re-notarization)"
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
package: verify-sign
	@echo "Building plistyamlplist version $(VERSION)..."
	
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
		--identifier com.grahamrpugh.plistyamlplist \
		--version $(VERSION) \
		--sign "$(SIGN_ID_PKG)" \
		--install-location / \
		$(PKG_PATH)
	
	@echo "Package created: $(PKG_PATH)"
	@echo "Package size: $$(du -h $(PKG_PATH) | cut -f1)"
	@echo ""
	@echo "Opening package directory in Finder..."
	open $(PKG_DIR)
	@echo ""
	@echo "Package build complete!"

# Create GitHub pre-release
release: notarize-pkg
	@echo "Removing any existing release/tag v$(VERSION) (if present)..."
	@gh release delete "v$(VERSION)" -y >/dev/null 2>&1 || true
	@git tag -d "v$(VERSION)" >/dev/null 2>&1 || true
	@git push origin :refs/tags/v$(VERSION) >/dev/null 2>&1 || true
	@echo "Creating release v$(VERSION)..."
	@if ! command -v gh &> /dev/null; then \
		echo "Error: GitHub CLI (gh) is not installed"; \
		echo "Install with: brew install gh"; \
		exit 1; \
	fi
	
	@if ! gh auth status &> /dev/null; then \
		echo "Error: Not authenticated with GitHub"; \
		echo "Run: gh auth login"; \
		exit 1; \
	fi
	
	@echo "Creating release v$(VERSION)..."
	@NOTES=$$(printf "Swift implementation of plist-yaml-plist converter.\n\n### Installation\n\nDownload and run the .pkg installer.\n\n### Features\n- Plist ↔ YAML conversion\n- JSON → Plist conversion\n- AutoPkg recipe optimization\n- Batch processing with glob patterns\n- Native macOS 15+ support\n\nSee CHANGELOG.md for details."); \
	gh release create "v$(VERSION)" \
		--title "plistyamlplist v$(VERSION)" \
		--notes "$$NOTES" \
		--prerelease \
		$(PKG_PATH) \
		$(ZIP_BIN)
	
	@echo ""
	@echo "Pre-release created successfully!"
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

# Path to the built release binary
BUILD_BIN := .build/apple/Products/Release/$(BINARY_NAME)
ZIP_BIN := .build/apple/Products/Release/$(BINARY_NAME).zip

# Ensure the binary exists before signing/notarizing
$(BUILD_BIN):
	@echo "Building release binary..."
	swift build $(SWIFT_BUILD_FLAGS)

# Verify the signed binary before packaging
.PHONY: verify-sign
verify-sign: notarize
	@echo "Verifying signed binary before packaging..."
	codesign --verify --strict --deep --verbose=2 $(BUILD_BIN)
	@echo "Signature details:" 
	codesign -dv --verbose=4 $(BUILD_BIN) 2>&1 | sed -n '1,40p'
	@echo "Binary architectures:"
	lipo -info $(BUILD_BIN)

.PHONY: sign notarize staple

# Code sign the release binary
sign: $(BUILD_BIN)
	@if [ -z "$(SIGN_ID_APP)" ]; then \
		echo "Error: SIGN_ID_APP is not set"; \
		exit 1; \
	fi
	@echo "Code signing $(BUILD_BIN) with '$(SIGN_ID_APP)'..."
	codesign \
		--force \
		--options runtime \
		--timestamp \
		--sign "$(SIGN_ID_APP)" \
		$(BUILD_BIN)
	@echo "Verifying signature..."
	codesign --verify --strict --deep --verbose=2 $(BUILD_BIN)
	spctl --assess --type execute --verbose $(BUILD_BIN) || true

# Submit the signed binary for notarization and staple the ticket
notarize: sign
	@if [ -z "$(NOTARY_PROFILE)" ]; then \
		echo "Error: NOTARY_PROFILE is not set"; \
		exit 1; \
	fi
	@echo "Preparing ZIP for notarization..."
	@rm -f $(ZIP_BIN)
	@cd $(dir $(BUILD_BIN)) && zip -q -9 $(notdir $(ZIP_BIN)) $(notdir $(BUILD_BIN))
	@echo "Submitting $(ZIP_BIN) for notarization using profile '$(NOTARY_PROFILE)'..."
	xcrun notarytool submit $(ZIP_BIN) \
		--keychain-profile "$(NOTARY_PROFILE)" \
		--wait

# Staple notarization ticket to the binary
staple: $(BUILD_BIN)
	@echo "Stapling notarization ticket to $(BUILD_BIN)..."
	xcrun stapler staple -v $(BUILD_BIN)
	@echo "Staple complete. Gatekeeper assessment:"
	spctl --assess --type execute --verbose $(BUILD_BIN) || true

# Notarize and staple the installer package
.PHONY: notarize-pkg
notarize-pkg: package
	@if [ -z "$(NOTARY_PROFILE)" ]; then \
		echo "Error: NOTARY_PROFILE is not set"; \
		exit 1; \
	fi
	@echo "Submitting $(PKG_PATH) for notarization using profile '$(NOTARY_PROFILE)'..."
	xcrun notarytool submit "$(PKG_PATH)" \
		--keychain-profile "$(NOTARY_PROFILE)" \
		--wait
	@echo "Stapling notarization ticket to $(PKG_PATH)..."
	xcrun stapler staple -v "$(PKG_PATH)"
	@echo "Staple complete for package."

# Staple an already-notarized installer package without re-submitting
.PHONY: staple-pkg
staple-pkg:
	@if [ ! -f "$(PKG_PATH)" ]; then \
		echo "Error: Package not found at $(PKG_PATH). Build it with 'make package' or notarize with 'make notarize-pkg' first."; \
		exit 1; \
	fi
	@echo "Stapling notarization ticket to $(PKG_PATH)..."
	xcrun stapler staple -v "$(PKG_PATH)"
	@echo "Staple complete for package."

# Staple existing package and create a GitHub pre-release without re-notarizing
.PHONY: staple-and-release
staple-and-release: staple-pkg
	@echo "Removing any existing release/tag v$(VERSION) (if present)..."
	@gh release delete "v$(VERSION)" -y >/dev/null 2>&1 || true
	@git tag -d "v$(VERSION)" >/dev/null 2>&1 || true
	@git push origin :refs/tags/v$(VERSION) >/dev/null 2>&1 || true
	@echo "Creating GitHub pre-release..."
	@if ! command -v gh &> /dev/null; then \
		echo "Error: GitHub CLI (gh) is not installed"; \
		echo "Install with: brew install gh"; \
		exit 1; \
	fi
	@if ! gh auth status &> /dev/null; then \
		echo "Error: Not authenticated with GitHub"; \
		echo "Run: gh auth login"; \
		exit 1; \
	fi
	@echo "Creating release v$(VERSION)..."
	@NOTES=$$(printf "Swift implementation of plist-yaml-plist converter.\n\n### Installation\n\nDownload and run the .pkg installer.\n\n### Features\n- Plist ↔ YAML conversion\n- JSON → Plist conversion\n- AutoPkg recipe optimization\n- Batch processing with glob patterns\n- Native macOS 15+ support\n\nSee CHANGELOG.md for details."); \
	gh release create "v$(VERSION)" \
		--title "plistyamlplist v$(VERSION)" \
		--notes "$$NOTES" \
		--prerelease \
		$(PKG_PATH) \
		$(ZIP_BIN)
	@echo ""
	@echo "Pre-release created successfully!"
	@echo "View at: $$(gh repo view --json url -q .url)/releases"
	@echo ""
	@echo "To publish the release, visit GitHub and change from pre-release to full release."
