# Tradelog iOS Demo — genera la app con XcodeGen y valida el SDK por SPM y CocoaPods.
#
# SPM:
#   make spm        → genera con project-spm.yml + resuelve el SDK (SPM) → abre .xcodeproj
#   make build-spm  → compila la variante SPM en el simulador
#
# CocoaPods:
#   make pods       → genera con project-pods.yml + `pod install` → abre .xcworkspace
#   make build-pods → compila la variante CocoaPods en el simulador
#
#   make clean      → borra todo lo generado (proj, workspace, Pods, DerivedData)

PROJECT       := TradelogDemo
SCHEME        := TradelogDemo
XCODEPROJ     := $(PROJECT).xcodeproj
XCWORKSPACE   := $(PROJECT).xcworkspace
SPM_SPEC        := project-spm.yml           # SPM distribución (CodeArtifact)
SPM_LOCAL_SPEC  := project-spm-local.yml     # SPM local (Debug/simulador)
PODS_SPEC       := project-pods.yml          # Pods distribución
PODS_LOCAL_SPEC := project-pods.yml          # Pods local (mismo spec; el pod cambia por env)
SIMULATOR     ?=
# Sin SIMULATOR → simulador genérico (compila sin necesitar un device concreto).
# Con SIMULATOR='iPhone 17' → ese device.
ifeq ($(strip $(SIMULATOR)),)
DESTINATION   := generic/platform=iOS Simulator
else
DESTINATION   := platform=iOS Simulator,name=$(SIMULATOR)
endif
DERIVED_DATA  := build/DerivedData

ENV_FILE      := .env
CONFIG_SWIFT  := Sources/Generated/AppConfig.generated.swift

# CodeArtifact (registry SwiftPM del SDK iOS)
CA_DOMAIN     ?= trade-log-sdk-ios
CA_OWNER      ?= 498628473923
CA_REPO       ?= tradelog-sdk-ios
CA_REGION     ?= us-east-1
CA_URL        := https://$(CA_DOMAIN)-$(CA_OWNER).d.codeartifact.$(CA_REGION).amazonaws.com/swift/$(CA_REPO)/

.PHONY: help setup pod-check env ca-login \
        spm spm-local build-spm build-spm-local open-spm open-spm-local \
        pods pods-local build-pods build-pods-local open-pods open-pods-local clean

help:
	@echo "TradeLog iOS Demo — valida el SDK por SPM y CocoaPods."
	@echo ""
	@echo "LOCAL (Debug/simulador · iterar y debuggear · sin AWS):"
	@echo "  make build-spm-local        SPM  · set Debug local (binario)"
	@echo "  make build-pods-local       Pods · pod local (frameworks Debug, binario)"
	@echo "  make open-spm-local         abre el .xcodeproj (SPM local)"
	@echo "  make open-pods-local        abre el .xcworkspace (Pods local)"
	@echo ""
	@echo "DISTRIBUCION (release · requiere AWS):"
	@echo "  make spm                    SPM  · CodeArtifact: genera + login + abre Xcode"
	@echo "                                     (agregas tradelog.TradelogSupport en Xcode)"
	@echo "  make build-pods             Pods · canal de distribucion"
	@echo ""
	@echo "UTILIDADES:"
	@echo "  make ca-login               login a CodeArtifact (token 12h)"
	@echo "  make env                    genera AppConfig desde .env"
	@echo "  make clean                  borra generados (proj, workspace, Pods, DerivedData)"
	@echo ""
	@echo "EJEMPLOS:"
	@echo "  make build-spm-local"
	@echo "  make build-pods-local SIMULATOR='iPhone 16'"
	@echo "  make open-spm-local"
	@echo ""
	@echo "Config: copia .env.example -> .env y edita tus credenciales."

## Genera Sources/Generated/AppConfig.generated.swift desde .env.
env: $(ENV_FILE)
	@sh scripts/gen-config.sh $(ENV_FILE) $(CONFIG_SWIFT)

$(ENV_FILE):
	@echo "→ No hay .env; copiando desde .env.example..."
	@cp .env.example $(ENV_FILE)
	@echo "⚠️  Edita $(ENV_FILE) con tus credenciales reales."

## Instala xcodegen si falta (requiere Homebrew).
setup:
	@command -v xcodegen >/dev/null 2>&1 || { \
		echo "→ Instalando xcodegen..."; brew install xcodegen; }

## Instala CocoaPods si falta (requiere Homebrew).
pod-check:
	@command -v pod >/dev/null 2>&1 || { \
		echo "→ Instalando cocoapods..."; brew install cocoapods; }

# ── SPM ───────────────────────────────────────────────────────────────────────
# spm-local → paquete LOCAL Debug (simulador, source-based). Para iterar/debug.
# spm       → CodeArtifact (registry SwiftPM). Consumo real. Requiere ca-login.

## Login CodeArtifact (token 12h) — necesario para `spm`.
ca-login:
	@echo "→ [CodeArtifact] login SwiftPM (token 12h)..."
	@cd LocalPackages/TradelogSDK && aws codeartifact login --tool swift \
		--domain $(CA_DOMAIN) --domain-owner $(CA_OWNER) --repository $(CA_REPO) --region $(CA_REGION)
	@swift package-registry set --global $(CA_URL) >/dev/null 2>&1 || true

spm-local: clean setup env
	@echo "→ [SPM·local] Generando desde $(SPM_LOCAL_SPEC) (Debug)..."
	xcodegen generate --spec $(SPM_LOCAL_SPEC)
	xcodebuild -resolvePackageDependencies -project $(XCODEPROJ) -scheme $(SCHEME)
	@echo "✅ [SPM·local] Listo"

build-spm-local: spm-local
	xcodebuild build -project $(XCODEPROJ) -scheme $(SCHEME) \
		-destination '$(DESTINATION)' -derivedDataPath $(DERIVED_DATA)

open-spm-local: spm-local
	open $(XCODEPROJ)

## SPM CodeArtifact: genera el proyecto + loguea el registry. El paquete se
## agrega en Xcode (XcodeGen no soporta registry) — como un cliente real.
spm: clean setup env ca-login
	@echo "→ [SPM] Generando desde $(SPM_SPEC) (CodeArtifact)..."
	xcodegen generate --spec $(SPM_SPEC)
	@echo ""
	@echo "✅ Proyecto generado + registry logueado (token 12h)."
	@echo "   En Xcode:  File ▸ Add Package Dependencies…  ▸  tradelog.TradelogSupport  ▸ Add"
	@echo "   Luego Run. El código ya usa 'import TradelogSupport'."
	open $(XCODEPROJ)

# build-spm: no aplica por CLI — el paquete de registry se agrega en Xcode.
# Para validar SPM por CLI/simulador usa `make build-spm-local`.
build-spm: spm

open-spm: spm

# ── CocoaPods ──────────────────────────────────────────────────────────────────
# pods-local → SDK como pod LOCAL (fuente + frameworks Debug). Para iterar/debug.
# pods       → distribución (mecanismo por definir).
# El Podfile elige local vs distribución según TRADELOG_PODS_LOCAL.

pods-local: clean setup pod-check env
	@echo "→ [Pods·local] Generando desde $(PODS_LOCAL_SPEC) (Debug)..."
	xcodegen generate --spec $(PODS_LOCAL_SPEC)
	TRADELOG_PODS_LOCAL=1 pod install
	@echo "✅ [Pods·local] Listo → $(XCWORKSPACE)"

build-pods-local: pods-local
	xcodebuild build -workspace $(XCWORKSPACE) -scheme $(SCHEME) \
		-destination '$(DESTINATION)' -derivedDataPath $(DERIVED_DATA)

open-pods-local: pods-local
	open $(XCWORKSPACE)

pods: clean setup pod-check env
	@echo "→ [Pods] Generando desde $(PODS_SPEC)..."
	xcodegen generate --spec $(PODS_SPEC)
	pod install
	@echo "✅ [Pods] Listo → $(XCWORKSPACE)"

build-pods: pods
	xcodebuild build -workspace $(XCWORKSPACE) -scheme $(SCHEME) \
		-destination '$(DESTINATION)' -derivedDataPath $(DERIVED_DATA)

open-pods: pods
	open $(XCWORKSPACE)

# ── Limpieza ─────────────────────────────────────────────────────────────────

clean:
	rm -rf $(XCODEPROJ) $(XCWORKSPACE) Pods Podfile.lock build .build DerivedData Sources/Generated
	@# También el DerivedData GLOBAL de Xcode: si no, al abrir el proyecto usa una
	@# resolución de paquetes stale y da "Missing package product 'TradelogSupport'".
	rm -rf ~/Library/Developer/Xcode/DerivedData/$(PROJECT)-*
	@echo "✅ Limpio (incluye DerivedData global de Xcode)."
