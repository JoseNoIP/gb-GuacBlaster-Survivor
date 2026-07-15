# Skill: /android-deploy

Configura o repara el pipeline de CI/CD de GitHub Actions para publicar un juego Godot 4.x en Google Play Store como AAB firmado.

Usa este skill cuando:
- Estás configurando el pipeline por primera vez en un nuevo juego
- Un paso del workflow está fallando y quieres el mapa completo de errores conocidos

---

## Arquitectura del pipeline (Godot 4.7+)

```
Checkout → Java 17 → Instalar Godot → Instalar templates
→ Configurar keystore + version_code → Pre-heat cache
→ Export APK (instala template Gradle + popula assets)
→ bundleRelease (produce AAB firmado)
→ Subir artefacto → Upload a Play Store
```

El flujo **dos pasos** es obligatorio en Godot 4.7:
1. `godot --export-release ... game.apk` — Godot exporta APK y popula `android/build/` con los assets del juego.
2. `./gradlew bundleRelease` — Gradle produce el AAB que Play Store requiere.

Godot 4.7 **rechaza** la extensión `.aab` directamente. El AAB solo se puede producir vía Gradle.

---

## Workflow completo probado y funcional

```yaml
name: Deploy → Google Play

on:
  push:
    branches: [main]
    tags: ["v*.*.*"]
  workflow_dispatch:
    inputs:
      skip_upload:
        description: "Solo construir AAB (sin subir a Play Store)"
        type: boolean
        default: false

env:
  GODOT_VERSION: "4.7"          # cambiar según versión del proyecto
  EXPORT_PRESET: "Android"      # debe coincidir exactamente con export_presets.cfg
  PACKAGE_NAME: "com.tuempresa.tujuego"   # ← CAMBIAR

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Determinar track y versión
        id: ctx
        run: |
          if [[ "${{ github.ref }}" == refs/tags/* ]]; then
            echo "track=production" >> $GITHUB_OUTPUT
          else
            echo "track=internal"   >> $GITHUB_OUTPUT
          fi
          echo "version_code=${{ github.run_number }}" >> $GITHUB_OUTPUT

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 17

      - name: Instalar Godot ${{ env.GODOT_VERSION }}
        run: |
          wget -q "https://github.com/godotengine/godot/releases/download/${{ env.GODOT_VERSION }}-stable/Godot_v${{ env.GODOT_VERSION }}-stable_linux.x86_64.zip" -O godot.zip
          unzip -q godot.zip
          mv "Godot_v${{ env.GODOT_VERSION }}-stable_linux.x86_64" /usr/local/bin/godot
          chmod +x /usr/local/bin/godot
          rm godot.zip

      - name: Instalar export templates
        run: |
          wget -q "https://github.com/godotengine/godot/releases/download/${{ env.GODOT_VERSION }}-stable/Godot_v${{ env.GODOT_VERSION }}-stable_export_templates.tpz" -O templates.tpz
          TEMPLATES_DIR="$HOME/.local/share/godot/export_templates/${{ env.GODOT_VERSION }}.stable"
          mkdir -p "$TEMPLATES_DIR"
          unzip -q templates.tpz -d templates_tmp
          mv templates_tmp/templates/* "$TEMPLATES_DIR/"
          rm -rf templates_tmp templates.tpz

      - name: Configurar keystore y version code
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > /tmp/game.keystore
          sed -i "s|version/code=[0-9]*|version/code=${{ steps.ctx.outputs.version_code }}|" export_presets.cfg
          sed -i "s|gradle_build/use_gradle_build=false|gradle_build/use_gradle_build=true|" export_presets.cfg

      # Pre-heat: evita crashes del file-system scanner en modo headless
      - name: Pre-heat Godot cache
        run: godot --headless --editor --quit || true

      - name: Exportar APK (instala template + popula android/build/)
        env:
          GODOT_ANDROID_KEYSTORE_RELEASE_PATH: /tmp/game.keystore
          GODOT_ANDROID_KEYSTORE_RELEASE_USER: ${{ secrets.ANDROID_KEYSTORE_ALIAS }}
          GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD: ${{ secrets.ANDROID_KEYSTORE_PASS }}
        run: |
          mkdir -p builds/
          godot --headless --verbose \
            --install-android-build-template \
            --export-release "${{ env.EXPORT_PRESET }}" \
            "builds/game.apk"

      - name: Construir AAB firmado
        env:
          KEYSTORE_ALIAS: ${{ secrets.ANDROID_KEYSTORE_ALIAS }}
          KEYSTORE_PASS: ${{ secrets.ANDROID_KEYSTORE_PASS }}
        run: |
          # El assetPackInstallTime module necesita existir para bundleRelease
          mkdir -p android/build/assetPackInstallTime/src/main/assets

          cd android/build
          # PROPIEDADES CRÍTICAS de config.gradle (Godot 4.7):
          #   export_package_name  → applicationId (default: com.godot.game)
          #   perform_signing=true → activa signingConfig release (default: FALSE)
          #   release_keystore_*   → datos del keystore de release
          ./gradlew bundleRelease \
            "-Pexport_package_name=${{ env.PACKAGE_NAME }}" \
            "-Pperform_signing=true" \
            "-Prelease_keystore_file=/tmp/game.keystore" \
            "-Prelease_keystore_password=$KEYSTORE_PASS" \
            "-Prelease_keystore_alias=$KEYSTORE_ALIAS"

          # Godot 4.7 genera variantes: standardRelease, monoRelease, instrumentedRelease
          AAB=$(find . -name "*.aab" -path "*/standardRelease/*" | head -1)
          if [ -z "$AAB" ]; then
            AAB=$(find . -name "*.aab" -not -path "*/intermediates/*" | head -1)
          fi
          cp "$AAB" ../../builds/game.aab

      - name: Guardar AAB como artefacto
        uses: actions/upload-artifact@v4
        with:
          name: aab-${{ steps.ctx.outputs.track }}-${{ github.run_number }}
          path: builds/game.aab
          retention-days: 30

      - name: Subir a Google Play — ${{ steps.ctx.outputs.track }}
        if: ${{ github.event_name != 'workflow_dispatch' || inputs.skip_upload == false }}
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_JSON }}
          packageName: ${{ env.PACKAGE_NAME }}
          releaseFiles: builds/game.aab
          track: ${{ steps.ctx.outputs.track }}
          status: completed
```

---

## GitHub Secrets requeridos

| Secret | Cómo obtenerlo |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -i mi.keystore` |
| `ANDROID_KEYSTORE_ALIAS` | El alias que usaste al crear el keystore |
| `ANDROID_KEYSTORE_PASS` | La contraseña del keystore (y del key) |
| `GOOGLE_PLAY_JSON` | Play Console → Configuración → Cuentas de servicio → JSON |

---

## export_presets.cfg — requisitos mínimos

```ini
[preset.0]
name="Android"           # debe coincidir con EXPORT_PRESET

[preset.0.options]
package/unique_name="com.tuempresa.tujuego"
gradle_build/use_gradle_build=false   # el CI lo activa via sed
gradle_build/gradle_build_directory=""
```

---

## Errores conocidos y sus soluciones exactas

### `Trying to build from a gradle built template, but no version info for it exists`
**Causa:** `.build_version` en `android/build/` está ausente o con contenido incorrecto.  
**Solución:** Usar `--install-android-build-template` en el comando de Godot. Este flag extrae `android_source.zip` y escribe `.build_version` con el string exacto que Godot espera. **Nunca** escribir `.build_version` manualmente.

### `Android APK requires the *.apk extension`
**Causa:** Godot 4.7 no soporta exportar directamente a `.aab`.  
**Solución:** Exportar siempre a `.apk`. El AAB se produce en un paso separado con `./gradlew bundleRelease`.

### `APKs are not allowed for this application`
**Causa:** Play Store requiere AAB para apps nuevas.  
**Solución:** Subir el AAB generado por Gradle, no el APK de Godot.

### `APK has the wrong package name` / `com.godot.game.fileprovider`
**Causa:** El `config.gradle` de Godot usa `com.godot.game` como default si no se le pasa `-Pexport_package_name`.  
**Solución:** Pasar `-Pexport_package_name=com.tuempresa.tujuego` a `bundleRelease`.

### `All uploaded bundles must be signed`
**Causa:** `shouldSign()` en `config.gradle` devuelve `false` por defecto (solo es `true` dentro de Android Studio).  
**Solución:** Pasar `-Pperform_signing=true` a `bundleRelease`. Las propiedades de keystore correctas son `release_keystore_file`, `release_keystore_password`, `release_keystore_alias`. **No** usar `android.injected.signing.*` — esas no aplican al template de Godot.

### `assetPackInstrumentedReleasePreBundleTask FAILED`
**Causa:** El directorio `android/build/assetPackInstallTime/src/main/assets` no existe. `bundleRelease` necesita este directorio para el módulo de Play Asset Delivery.  
**Solución:** `mkdir -p android/build/assetPackInstallTime/src/main/assets` antes de correr Gradle.

### `Error: APK has the wrong package name` (en el upload a Play Store)
**Causa primaria:** Primera vez que se sube, sin carga manual previa.  
**Requisito Play Store:** Antes de que la API de Google Play funcione, se debe subir manualmente al menos una versión desde la web de Play Console. Descargar el artefacto AAB del CI y subirlo manualmente una vez.

---

## Propiedades de config.gradle (Godot 4.7) — referencia completa

Estas propiedades se pasan a Gradle con el prefijo `-P`:

| Propiedad | Default | Descripción |
|---|---|---|
| `export_package_name` | `com.godot.game` | applicationId del APK/AAB |
| `export_version_code` | `1` | versionCode |
| `export_version_name` | `1.0` | versionName |
| `perform_signing` | `false` | Activa signingConfig release |
| `release_keystore_file` | `.` | Ruta absoluta al .keystore |
| `release_keystore_password` | `""` | Store password (también usado como key password) |
| `release_keystore_alias` | `""` | Key alias |
| `export_enabled_abis` | todas | ABIs separadas por `\|` |
| `export_build_type` | `debug` | `debug` o `release` |
| `export_format` | `apk` | `apk` o `aab` |

---

## Variantes de build en Godot 4.7

`bundleRelease` genera tres variantes. Usar siempre `standardRelease`:
- `standardRelease` — build de producción normal ✓
- `monoRelease` — build con .NET/C#
- `instrumentedRelease` — build para tests de instrumentación

El AAB queda en: `android/build/app/build/outputs/bundle/standardRelease/*.aab`

---

## Notas de Play Console

- **Primera subida:** obligatoriamente manual desde la web. La API falla sin ella.
- **Track interno:** push a `main` → Internal Testing (sin revisión de Google).
- **Producción:** tag `v*.*.*` → Production (pasa por revisión de Google).
- **Play Games Sidekick:** advertencia que aparece porque el template de Godot incluye el módulo `assetPackInstallTime`. Es ignorable para juegos pequeños (< 150 MB de assets).
