PREFIX?=/usr/local

.PHONY: install

.build/release/runvf: Sources/runvf/main.swift Package.swift
	swift build -c release --disable-sandbox
	codesign -s - --entitlements runvf.entitlements .build/release/runvf
	chmod +x .build/release/runvf

install:
	install -m 755 .build/release/runvf $(PREFIX)/bin/runvf