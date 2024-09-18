# Facts
GIT_REPO_TOPLEVEL := $(shell git rev-parse --show-toplevel)

# Apple Platform Destinations
DESTINATION_PLATFORM_IOS_SIMULATOR = "platform=iOS Simulator,name=iPhone 16 Pro Max"
DESTINATION_PLATFORM_WATCHOS_SIMULATOR = "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)"

# Run Results
IOS_RUN_RESULT_BUNDLE_PATH="$(GIT_REPO_TOPLEVEL)/xcresults/ios_result.xcresult"
WATCHOS_RUN_RESULT_BUNDLE_PATH="$(GIT_REPO_TOPLEVEL)/xcresults/watchos_result.xcresult"

# Formatting
SWIFT_FORMAT_BIN := swift format
SWIFT_FORMAT_CONFIG_FILE := $(GIT_REPO_TOPLEVEL)/.swift-format.json
FORMAT_PATHS := "$(GIT_REPO_TOPLEVEL)"

# Tasks

.PHONY: default
default: test-all-clean

.PHONY: test-all-clean
test-all-clean: clean-all test-xcode

.PHONY: clean-all
clean-all: xcode-result-clean xcode-clean

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
		-destination $(DESTINATION_PLATFORM_IOS_SIMULATOR) \
		-resultBundlePath $(IOS_RUN_RESULT_BUNDLE_PATH) \
		-quiet

.PHONY: test-xcode-watchos
test-xcode-watchos:
	xcodebuild \
		-project Kasa.xcodeproj \
		-scheme 'Kasa WatchKit App' \
		-destination $(DESTINATION_PLATFORM_WATCHOS_SIMULATOR) \
		-resultBundlePath $(WATCHOS_RUN_RESULT_BUNDLE_PATH) \
		-quiet

.PHONY: format
format:
	$(SWIFT_FORMAT_BIN) \
		--configuration $(SWIFT_FORMAT_CONFIG_FILE) \
		--ignore-unparsable-files \
		--in-place \
		--parallel \
		--recursive \
		$(FORMAT_PATHS)

.PHONY: lint
lint:
	$(SWIFT_FORMAT_BIN) lint \
		--configuration $(SWIFT_FORMAT_CONFIG_FILE) \
		--ignore-unparsable-files \
		--parallel \
		--recursive \
		$(FORMAT_PATHS)
