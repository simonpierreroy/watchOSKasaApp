# Facts
GIT_REPO_TOPLEVEL := $(shell git rev-parse --show-toplevel)

# Apple Platform Destinations
DESTINATION_PLATFORM_IOS_SIMULATOR = platform=iOS Simulator,name=iPhone 14 Pro Max
DESTINATION_PLATFORM_WATCHOS_SIMULATOR = platform=watchOS Simulator,name=Apple Watch Series 8 (45mm)

# Run Results
IOS_RUN_RESULT_BUNDLE_PATH="$(GIT_REPO_TOPLEVEL)/xcresults/latest_ios_result.xcresult"
WATCHOS_RUN_RESULT_BUNDLE_PATH="$(GIT_REPO_TOPLEVEL)/xcresults/latest_watchos_result.xcresult"

# Formatting
SWIFT_FORMAT_VERSION=0.50700.1
SWIFT_FORMAT_FOLDER="$(GIT_REPO_TOPLEVEL)/swift-format"
SWIFT_FORMAT_BIN := "$(shell swift build -c release --show-bin-path --package-path $(SWIFT_FORMAT_FOLDER))/swift-format"
SWIFT_FORMAT_CONFIG_FILE := "$(GIT_REPO_TOPLEVEL)/.swift-format.json"
FORMAT_PATHS := "$(GIT_REPO_TOPLEVEL)/Kasa WatchKit App" "$(GIT_REPO_TOPLEVEL)/KasaApp" \
"$(GIT_REPO_TOPLEVEL)/KasaAppWidget" "$(GIT_REPO_TOPLEVEL)/KasaIntentsExtension" \
"$(GIT_REPO_TOPLEVEL)/AppPackage/Sources" "$(GIT_REPO_TOPLEVEL)/AppPackage/Package.swift" \
"$(GIT_REPO_TOPLEVEL)/WidgetFeature/Sources" "$(GIT_REPO_TOPLEVEL)/WidgetFeature/Package.swift" \
"$(GIT_REPO_TOPLEVEL)/Routing/Sources" "$(GIT_REPO_TOPLEVEL)/Routing/Package.swift" \
"$(GIT_REPO_TOPLEVEL)/DeviceFeature/Sources" "$(GIT_REPO_TOPLEVEL)/DeviceFeature/Package.swift" \
"$(GIT_REPO_TOPLEVEL)/UserFeature/Sources" "$(GIT_REPO_TOPLEVEL)/UserFeature/Package.swift" \
"$(GIT_REPO_TOPLEVEL)/KasaCore/Sources" "$(GIT_REPO_TOPLEVEL)/KasaCore/Package.swift" \

# Tasks

.PHONY: default
default: test-all-clean

.PHONY: test-all-clean
test-all-clean: xcode-result-clean xcode-clean test-xcode

.PHONY: xcode-result-clean
xcode-result-clean: 
	rm -rf "$(GIT_REPO_TOPLEVEL)/xcresults"

.PHONY: xcode-clean
xcode-clean: 
	xcodebuild \
		clean \
		-project Kasa.xcodeproj \
		-scheme 'KasaApp' \
		-destination "generic/platform=iOS" \
		-destination "generic/platform=iOS Simulator"

.PHONY: test-xcode
test-xcode: test-xcode-ios test-xcode-watchos

.PHONY: test-xcode-ios
test-xcode-ios:
	xcodebuild \
		-project Kasa.xcodeproj \
		-scheme 'KasaApp' \
		-destination "$(DESTINATION_PLATFORM_IOS_SIMULATOR)" \
		-resultBundlePath "$(IOS_RUN_RESULT_BUNDLE_PATH)" \
		-quiet

.PHONY: test-xcode-watchos
test-xcode-watchos:
	xcodebuild \
		-project Kasa.xcodeproj \
		-scheme 'Kasa WatchKit App' \
		-destination "$(DESTINATION_PLATFORM_WATCHOS_SIMULATOR)" \
		-resultBundlePath "$(WATCHOS_RUN_RESULT_BUNDLE_PATH)" \
		-quiet

.PHONY: install-swift-format
install-swift-format:
	git clone -b "$(SWIFT_FORMAT_VERSION)" https://github.com/apple/swift-format.git "$(SWIFT_FORMAT_FOLDER)"
	swift build -c release --package-path "$(SWIFT_FORMAT_FOLDER)"

.PHONY: format
format:
	$(SWIFT_FORMAT_BIN) \
		--configuration $(SWIFT_FORMAT_CONFIG_FILE) \
		--ignore-unparsable-files \
		--in-place \
		--recursive \
		$(FORMAT_PATHS)

.PHONY: lint
lint:
	$(SWIFT_FORMAT_BIN) lint \
		--configuration $(SWIFT_FORMAT_CONFIG_FILE) \
		--ignore-unparsable-files \
		--recursive \
		$(FORMAT_PATHS)
