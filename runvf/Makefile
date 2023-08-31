PREFIX?=${out}

.PHONY: install

.build/release/runvf: Sources/runvf/Runvf.swift Package.swift
	swift build -c release --disable-sandbox
	chmod +x .build/release/runvf
	codesign -s - -f --entitlements runvf.entitlements .build/release/runvf

install:
	mkdir -p $(PREFIX)/bin
	install -m 755 .build/release/runvf $(PREFIX)/bin/runvf
