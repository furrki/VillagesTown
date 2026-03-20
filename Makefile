include ../common/Makefile.common

APP_NAME         = VillagesTown
SCREENSHOT_SLOTS = 1

.PHONY: help

help:
	@echo "VillagesTown - Quick Commands"
	@echo ""
	@echo "  make screenshots          Capture screenshots"
	@echo "  make screenshots-copy-ios Copy screenshots to fastlane/"
	@echo "  make run                  Run app"
	@echo "  make build-ios            Build iOS release"
	@echo "  make clean                Clean build artifacts"
