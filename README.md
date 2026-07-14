# Tradelog iOS Demo

App iOS mínima (SwiftUI) que integra el **Tradelog Support SDK**: una pantalla con un botón que abre el chat de soporte.

El proyecto Xcode se **genera** con [XcodeGen] desde un spec `.yml` (no se versiona el `.xcodeproj`). El SDK se puede validar por **dos mecanismos**: Swift Package Manager y CocoaPods.

## Requisitos
- macOS con **Xcode 15+** (target iOS 15.0+)
- **Homebrew** (el `Makefile` instala `xcodegen` / `cocoapods` si faltan)

## Uso

### Swift Package Manager
```bash
make spm         # genera project-spm.yml + resuelve el SDK (SPM)
make open-spm    # ...y abre el .xcodeproj
make build-spm   # compila en el simulador
```

### CocoaPods
```bash
make pods        # genera project-pods.yml + pod install
make open-pods   # ...y abre el .xcworkspace
make build-pods  # compila en el simulador
```

`make clean` borra todo lo generado. Simulador configurable: `make build-spm SIMULATOR="iPhone 16"`.

> Cambiar de mecanismo regenera el `.xcodeproj`; corre `make clean` entre uno y otro si quieres partir limpio. Con CocoaPods abre siempre el **`.xcworkspace`**, no el `.xcodeproj`.

## Configuración del SDK (vía `.env`)
Las credenciales/config salen de un `.env` (no se versiona), no del código:

```bash
cp .env.example .env          # (make env lo copia solo si no existe)
# edita .env con tus valores reales
```

Variables:
| Var | Descripción |
|-----|-------------|
| `TRADELOG_API_KEY` | API key del tenant |
| `TRADELOG_TENANT_ID` | ID del tenant |
| `TRADELOG_ENVIRONMENT` | `staging` \| `production` |
| `TRADELOG_ENABLE_LOGS` | `true` \| `false` |
| `TRADELOG_CUSTOMER_NAME` / `TRADELOG_CUSTOMER_DATA` | datos iniciales del cliente |

`make env` genera `Sources/Generated/AppConfig.generated.swift` desde el `.env` (se ejecuta solo en `make spm` / `make pods`). El código lee `AppConfig.*`.

## Estructura
```
tradelog-ios-demo/
├── project-spm.yml     # spec XcodeGen CON el package SPM del SDK
├── project-pods.yml    # spec XcodeGen SIN el SDK (lo agrega el Podfile)
├── Podfile             # dependencia del SDK vía CocoaPods
├── Makefile            # env / spm / pods / build / open / clean
├── .env.example        # plantilla de variables (versionada)
├── scripts/
│   └── gen-config.sh   # .env → AppConfig.generated.swift
└── Sources/
    ├── TradelogDemoApp.swift   # @main — inicializa el SDK con AppConfig
    ├── ContentView.swift       # pantalla + botón "Abrir soporte" (sheet con el SDK)
    └── Generated/              # AppConfig.generated.swift (gitignored)
```

El código Swift (`import TradelogSupport`) es idéntico para ambos mecanismos.

## SDK
- Módulo: **`TradelogSupport`** (`import TradelogSupport`) — SPM y CocoaPods
- SPM: `https://github.com/Tradelog-sas/tradelog-support-sdk.git` (exact `2026.508.82`)
- CocoaPods: `pod 'TradelogSupport'` (:git + :tag `2026.508.82`)
- Docs: https://tradelog.mintlify.app/i-os-integration

> ⚠️ Ajusta la versión/tag en `project-spm.yml` y en el `Podfile` al tag real publicado tras el fix del SDK.
> El SDK expone `TradelogSupport.podspec` en la raíz del repo, así `pod 'TradelogSupport'` (:git) resuelve correctamente. Requiere `git-lfs` para bajar los xcframeworks.

[XcodeGen]: https://github.com/yonaskolb/XcodeGen
