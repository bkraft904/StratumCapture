# Stratum Capture

Native iOS companion app for the Stratum X-ray Passport project. Where the
web app's Scan Lab works from ordinary photos (no real spatial data —
findings are pinned to an illustrative layout), this app uses **RoomPlan**
(LiDAR) to capture a room's *real* geometry, lets you tag close-up photos of
open stud bays to specific walls, and sends those photos to the **same
`/analyze` Lambda** the web app already uses. The result: AI findings placed
on real, measured wall positions instead of an approximate outline.

No new backend work was needed for this — `Upload/AnalyzeAPI.swift` calls
the identical endpoint and JSON contract as `stratum-xray-passport`'s
`src/lib/analyzeApi.ts`.

## Requirements

- A Mac with Xcode 15 or later
- An iPhone 12 Pro/Pro Max or later **Pro** model, or an iPad Pro (2020+) —
  RoomPlan requires a LiDAR sensor and does not work in the Simulator
- iOS 16+ deployment target (RoomPlan's minimum)

## Setting up the Xcode project

This repo ships only Swift source files plus a `project.yml` — a
hand-written `.xcodeproj` isn't reliable, so the real project file is
**generated** by [XcodeGen](https://github.com/yonaskolb/XcodeGen) from that
spec instead of committed. CI does this automatically (see below); to open
it yourself on a Mac:

```bash
brew install xcodegen
cd StratumCapture   # this repo's root, where project.yml lives
xcodegen generate
open StratumCapture.xcodeproj
```

That single command reproduces everything a manual "File → New Project"
walkthrough would set up: a SwiftUI iOS app target, iOS 16.0 minimum
deployment, the `RoomPlan.framework` link, and the `Info.plist` keys
(`NSCameraUsageDescription`, `UIRequiredDeviceCapabilities: [arkit]`) that
RoomPlan and the App Store both require. Change `project.yml` instead of
editing project settings by hand — regenerate after any edit.

To run on a device: Xcode → target `StratumCapture` → **Signing &
Capabilities** → pick your team, then build onto a physical LiDAR-capable
iPhone/iPad (the Simulator has no LiDAR, so RoomPlan reports unsupported
there).

## Continuous integration

`.github/workflows/build-ios.yml` runs on GitHub's `macos-14` runners on
every push: it installs XcodeGen, generates the project from `project.yml`,
and compiles the app for the iOS Simulator SDK (no code signing needed for
a compile-only check). This catches build breaks without needing a Mac at
all — but it only proves the code compiles. Actually *running* a scan still
needs a real LiDAR device, which means eventually getting the app onto one
via Xcode on a Mac (borrowed, cloud-rented, or your own) or, later, signed
TestFlight builds out of CI.

## How it works

1. **Capture** (`Capture/`) — `RoomCaptureView` runs a live RoomPlan scan.
   `RoomScanManager` relays coaching instructions ("move closer to the
   wall", etc.) to the UI and hands back a `CapturedRoom` with real wall
   positions, dimensions, and transforms once you tap "Done scanning".
2. **Review** (`Review/`) — Lists every detected wall. For each one you can:
   - Tag one or more close-up photos to it (`CameraPicker`)
   - Run AI analysis on just that wall's photos (`AnalyzeAPI.analyze`) —
     findings, image-type classification, and a scope note come back exactly
     like they do on the website
   - Export a `CaptureManifest` JSON (wall geometry + findings, one entry per
     wall) or the raw RoomPlan USDZ model, both via the system share sheet
3. **Upload** (`Upload/AnalyzeAPI.swift`) — Talks to the deployed Lambda at
   the URL in `Support/AppConfig.swift`. If you redeploy the backend to a
   new stack/region, update that URL (get the current one with
   `aws cloudformation describe-stacks --stack-name stratum-scan-lab
   --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text`).

## What's intentionally not built yet

- **No backend endpoint consumes the exported manifest.** Exporting is a
  manual stand-in — a future `/capture` Lambda could accept this same JSON
  shape and store it server-side instead of relying on the share sheet.
- **No persistence.** Sessions live in memory (`CaptureStore`) for the
  current app run only; closing the app loses unexported scans.
- **No auth/rate limiting** on the shared `/analyze` endpoint — same
  open item as the web app.

## Project layout

```
StratumCapture/
  StratumCaptureApp.swift      entry point
  ContentView.swift            start screen, RoomPlan support check, nav
  Capture/
    CaptureScreen.swift        live scan UI
    RoomCaptureRepresentable.swift   UIKit bridge for RoomCaptureView
    RoomScanManager.swift      RoomPlan delegate, coaching text, finish handling
  Photos/
    CameraPicker.swift         UIImagePickerController wrapper
    TaggedPhoto.swift          photo <-> wall association
  Review/
    ReviewScreen.swift         wall list, tagging, analyze, export
    ReviewViewModel.swift      per-wall analysis state
    WallRowView.swift          one wall's row UI
  Support/
    AppConfig.swift            deployed /analyze URL
    CaptureSession.swift       in-memory scan + CaptureStore
    CaptureManifest.swift      exportable JSON shape
    IdentifiableURL.swift      sheet(item:) helper
    ShareSheet.swift           UIActivityViewController wrapper
  Upload/
    AnalyzeAPI.swift           calls the shared /analyze Lambda
```
