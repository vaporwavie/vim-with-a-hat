BIN := vim-with-a-hat
RELEASE := .build/release/$(BIN)
PREFIX ?= $(HOME)/.local
DEST := $(PREFIX)/bin/vh

.PHONY: build release run install uninstall clean

build:
	swift build

release:
	swift build -c release

run: build
	.build/debug/$(BIN) $(ARGS)

install: release
	@mkdir -p $(PREFIX)/bin
	@install -m 0755 $(RELEASE) $(DEST)
	@strip $(DEST) 2>/dev/null || true
	@echo "installed: $(DEST)  ($$(ls -lh $(DEST) | awk '{print $$5}'))"
	@echo "ensure $(PREFIX)/bin is on your PATH, then run: vh <file>"

uninstall:
	@rm -f $(DEST) && echo "removed: $(DEST)"

clean:
	swift package clean
	rm -rf .build
