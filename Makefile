# Tradelog iOS Demo — descarga el SDK con el CLI de Tradelog y genera la app.
#
# Requisito:  brew install tradelog-sas/tap/tradelog   +   .env con tus credenciales.
#
# SPM:
#   make spm         → tradelog install + genera proyecto (SPM) + abre Xcode
#   make build-spm   → compila la variante SPM en el simulador
# CocoaPods:
#   make pods        → tradelog install --pods + pod install + abre workspace
#   make build-pods  → compila la variante Pods en el simulador
#
#   make clean       → borra generados (proj, workspace, Pods, DerivedData)
#   make clean-sdk   → borra también el SDK descargado (Tradelog/)

PROJECT       := TradelogDemo
SCHEME        := TradelogDemo
XCODEPROJ     := $(PROJECT).xcodeproj
XCWORKSPACE   := $(PROJECT).xcworkspace
SPM_SPEC      := project-spm-local.yml       # SPM (paquete local descargado por el CLI)
PODS_SPEC     := project-pods.yml            # CocoaPods
SIMULATOR     ?=
# Sin SIMULATOR → simulador genérico. Con SIMULATOR='iPhone 17' → ese device.
ifeq ($(strip $(SIMULATOR)),)
DESTINATION   := generic/platform=iOS Simulator
else
DESTINATION   := platform=iOS Simulator,name=$(SIMULATOR)
endif
DERIVED_DATA  := build/DerivedData

ENV_FILE      := .env
CONFIG_SWIFT  := Sources/Generated/AppConfig.generated.swift
SDK_DIR       := Tradelog/TradelogSupport
SDK_MANIFEST  := $(SDK_DIR)/Package.swift

.PHONY: help setup pod-check env sdk \
        spm build-spm open-spm pods build-pods open-pods clean clean-sdk

help:
	@echo "Tradelog iOS Demo — valida el SDK vía el CLI de Tradelog."
	@echo ""
	@echo "Requisito:  brew install tradelog-sas/tap/tradelog   +   .env con credenciales."
	@echo ""
	@echo "  make spm           SPM  · descarga SDK + genera + abre Xcode"
	@echo "  make build-spm     SPM  · compila en el simulador"
	@echo "  make pods          Pods · descarga SDK + pod install + abre workspace"
	@echo "  make build-pods    Pods · compila en el simulador"
	@echo "  make clean         borra generados (proj, workspace, Pods, DerivedData)"
	@echo "  make clean-sdk     borra también el SDK descargado (Tradelog/)"
	@echo ""
	@echo "Config: copia .env.example -> .env y edita tus credenciales."

## Genera Sources/Generated/AppConfig.generated.swift desde .env.
env: $(ENV_FILE)
	@sh scripts/gen-config.sh $(ENV_FILE) $(CONFIG_SWIFT)

$(ENV_FILE):
	@echo "→ No hay .env; copiando desde .env.example..."
	@cp .env.example $(ENV_FILE)
	@echo "⚠️  Edita $(ENV_FILE) con tus credenciales."

## Instala xcodegen si falta (requiere Homebrew).
setup:
	@command -v xcodegen >/dev/null 2>&1 || { echo "→ Instalando xcodegen..."; brew install xcodegen; }

## Instala CocoaPods si falta (requiere Homebrew).
pod-check:
	@command -v pod >/dev/null 2>&1 || { echo "→ Instalando cocoapods..."; brew install cocoapods; }

## Descarga el SDK con el CLI de Tradelog (solo si falta). Lee las creds del .env.
## Para re-descargar: `make clean-sdk` y vuelve a correr.
sdk: $(SDK_MANIFEST)
$(SDK_MANIFEST): | $(ENV_FILE)
	@command -v tradelog >/dev/null 2>&1 || { \
		echo "✖ Falta el CLI. Instala:  brew install tradelog-sas/tap/tradelog"; exit 1; }
	@echo "→ [SDK] Descargando con 'tradelog install'…"
	@set -a; . ./$(ENV_FILE); set +a; tradelog install --pods

# ── SPM ───────────────────────────────────────────────────────────────────────
spm: clean setup env sdk
	@echo "→ [SPM] Generando desde $(SPM_SPEC)…"
	xcodegen generate --spec $(SPM_SPEC)
	xcodebuild -resolvePackageDependencies -project $(XCODEPROJ) -scheme $(SCHEME)
	@echo "✅ [SPM] Listo → abre $(XCODEPROJ)"
	open $(XCODEPROJ)

build-spm: clean setup env sdk
	xcodegen generate --spec $(SPM_SPEC)
	xcodebuild build -project $(XCODEPROJ) -scheme $(SCHEME) \
		-destination '$(DESTINATION)' -derivedDataPath $(DERIVED_DATA)

open-spm: spm

# ── CocoaPods ──────────────────────────────────────────────────────────────────
pods: clean setup pod-check env sdk
	@echo "→ [Pods] Generando desde $(PODS_SPEC)…"
	xcodegen generate --spec $(PODS_SPEC)
	pod install
	@echo "✅ [Pods] Listo → $(XCWORKSPACE)"
	open $(XCWORKSPACE)

build-pods: clean setup pod-check env sdk
	xcodegen generate --spec $(PODS_SPEC)
	pod install
	xcodebuild build -workspace $(XCWORKSPACE) -scheme $(SCHEME) \
		-destination '$(DESTINATION)' -derivedDataPath $(DERIVED_DATA)

open-pods: pods

# ── Limpieza ─────────────────────────────────────────────────────────────────
clean:
	rm -rf $(XCODEPROJ) $(XCWORKSPACE) Pods Podfile.lock build .build DerivedData Sources/Generated
	@# También el DerivedData GLOBAL de Xcode: si no, al abrir el proyecto usa una
	@# resolución de paquetes stale y da "Missing package product 'TradelogSupport'".
	rm -rf ~/Library/Developer/Xcode/DerivedData/$(PROJECT)-*
	@echo "✅ Limpio (incluye DerivedData global de Xcode)."

clean-sdk: clean
	rm -rf Tradelog
	@echo "✅ SDK descargado eliminado (Tradelog/)."
