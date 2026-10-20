---
kind: build_system
name: 'Build System: Maven + Flutter/Gradle Dual-Toolchain'
category: build_system
scope:
    - '**'
source_files:
    - backend/pom.xml
    - frontend/pubspec.yaml
    - frontend/analysis_options.yaml
    - frontend/android/build.gradle.kts
    - frontend/android/app/build.gradle.kts
---

## Overview

The repository is a two-layer MVP with no shared top-level build script. Each layer builds independently with its native toolchain:

- **Backend** — Java 17 Spring Boot application built with **Maven** (`backend/pom.xml`).
- **Frontend** — Flutter app built via the **Flutter SDK**, which delegates Android packaging to **Gradle** (`frontend/android/build.gradle.kts`, `frontend/android/app/build.gradle.kts`) and uses `pubspec.yaml` for Dart/Flutter dependencies.

There is no top-level `Makefile`, no Dockerfile, no CI pipeline, and no release automation in this branch.

## Backend build (Maven)

- Parent POM: `org.springframework.boot:spring-boot-starter-parent:3.3.4`.
- Artifact: `com.penaareia:pe-na-areia-backend:0.1.0-SNAPSHOT`.
- Java version pinned to `17` via `<java.version>` property.
- Packaging is handled by `spring-boot-maven-plugin`; Lombok is explicitly excluded from the repackaged JAR via `<excludes>`.
- Test scope includes `de.flapdoodle.embed.mongo.spring3x` for an embedded MongoDB used during tests.
- Typical commands are the standard Maven ones (`mvn compile`, `mvn package`, `mvn spring-boot:run`); none are scripted.

## Frontend build (Flutter + Gradle)

- Dependency manifest: `frontend/pubspec.yaml` declares Flutter SDK constraints (`sdk: '>=3.3.0 <4.0.0'`) and all third-party packages (`google_maps_flutter`, `geolocator`, `http`, `provider`, `image_picker`, `firebase_core`, `firebase_messaging`).
- Linting is configured through `frontend/analysis_options.yaml`, which includes `package:flutter_lints/flutter.yaml` and is invoked via `flutter analyze` (documented in the file comments).
- Android packaging is delegated to Gradle Kotlin DSL:
  - `frontend/android/build.gradle.kts` configures repositories (`google()`, `mavenCentral()`), redirects all build output to `frontend/build/<project-name>`, and registers a `clean` task that deletes the root build directory.
  - `frontend/android/app/build.gradle.kts` applies `com.android.application`, `kotlin-android`, and `dev.flutter.flutter-gradle-plugin`. It pins Java/Kotlin JVM target to `11`, reads `compileSdk`/`ndkVersion`/`minSdk`/`targetSdk`/`versionCode`/`versionName` from the Flutter plugin, and currently signs `release` builds with the debug keystore (noted in a TODO comment).
- Desktop/mobile targets (Linux, macOS, Windows) ship with default Flutter-generated CMake/IDE project files; no custom cross-compilation rules exist.

## Conventions observed

- Versioning is per-module: backend uses Maven SNAPSHOT semantics (`0.1.0-SNAPSHOT`); frontend uses a plain semantic version string (`0.1.0`) in `pubspec.yaml`.
- The Android app ID is still the Flutter template value `com.example.pe_na_areia` (TODO in `app/build.gradle.kts`); it has not been customized yet.
- Release signing on Android falls back to debug keys (`signingConfig = signingConfigs.getByName("debug")`) as documented in a TODO comment.
- Build artifacts are produced in platform-native locations: `backend/target/` (Maven) and `frontend/build/` (Flutter/Gradle). No artifact upload, publishing, or containerization step is defined.
- There is no top-level orchestrator: developers must run Maven and Flutter commands separately.

## Constraints / enforced rules

- Backend requires **Java 17** (enforced by `spring-boot-starter-parent` 3.3.4 and the `<java.version>17</java.version>` property in `pom.xml`).
- Frontend requires Dart SDK `>=3.3.0 <4.0.0` (enforced by the `environment.sdk` constraint in `pubspec.yaml`).
- Android code compiles against **JDK 11** (`sourceCompatibility`/`targetCompatibility`/`jvmTarget` set to `VERSION_11` in `app/build.gradle.kts`), independent of the backend's JDK 17.
- Lint rules are inherited from `package:flutter_lints/flutter.yaml` via `analysis_options.yaml`; deviations require explicit rule overrides in that file.
- Lombok is excluded from the Spring Boot fat jar (enforced by the `<exclude>` entry under `spring-boot-maven-plugin` configuration in `pom.xml`).

## Not present

No `Dockerfile`, no `.github/workflows` / CI YAML, no `Makefile`, no `build.sh`, no artifact registry publish step, and no release tagging automation were found in this branch.