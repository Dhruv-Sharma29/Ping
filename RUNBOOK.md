# Runbook

Everything needed to build, test and install Ping, and to check the parts that can't be unit tested.

| What | Value | Where it's set |
| --- | --- | --- |
| Bundle ID | `com.dhruvsharma.Ping` | `project.yml` → `PRODUCT_BUNDLE_IDENTIFIER` |
| Background task ID | `com.dhruvsharma.Ping.refresh` | `project.yml` → `BGTaskSchedulerPermittedIdentifiers`, and `Checker.taskID`. **Both must match** |
| Signing team | `6N4NH3RW4K` (free Personal Team) | `project.yml` → `DEVELOPMENT_TEAM` |
| Deployment target | iOS 18.0 | `project.yml` → `deploymentTarget` |
| Toolchain used | Xcode 27.1, iOS 27.1 SDK, XcodeGen 2.46.0 | — |
| Swift settings | Swift 6 mode, main-actor default isolation, approachable concurrency | `project.yml` → `settings.base` |
| Database file | `Library/Application Support/default.store` in the app's container | SwiftData default |

## 1. Requirements

- macOS with Xcode 27.1 (any Xcode that can build for iOS 18 with Swift 6 should work **[verify]**).
- XcodeGen: `brew install xcodegen`.
- Only to rebuild the app icons: Python 3 with Pillow.

## 2. Generate the Xcode project

`Ping.xcodeproj` is generated, never edited by hand. Run this after cloning, after adding or
removing a source file, and after changing `project.yml`:

```bash
xcodegen
```

## 3. Run the unit tests

```bash
xcodebuild test -project Ping.xcodeproj -scheme Ping \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -derivedDataPath build
```

Expected: `Test run with 30 tests ... passed` and `** TEST SUCCEEDED **`. Use any simulator you have
(`xcrun simctl list devices available`).

## 4. Run in the Simulator

Easiest: open `Ping.xcodeproj` and press ⌘R. From the command line:

```bash
xcodebuild build -project Ping.xcodeproj -scheme Ping \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -derivedDataPath build
xcrun simctl boot "iPhone 18 Pro"
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/Ping.app
xcrun simctl launch booted com.dhruvsharma.Ping
```

### See a notification without waiting for a real issue

The Simulator can't run background refresh, but it can show notifications from a check made while
the app is open. To make the next check find "new" issues, lower the saved number:

```bash
STORE="$(xcrun simctl get_app_container booted com.dhruvsharma.Ping data)/Library/Application Support/default.store"
sqlite3 "$STORE" "select ZNAME, ZLASTSEEN from ZREPO;"           # e.g. swiftlang/swift|94089
sqlite3 "$STORE" "update ZREPO set ZLASTSEEN = ZLASTSEEN - 30;"  # pretend we missed recent issues
xcrun simctl terminate booted com.dhruvsharma.Ping
xcrun simctl launch booted com.dhruvsharma.Ping                    # one banner per issue above the new value
```

`ZREPO` and `ZLASTSEEN` are SwiftData's generated table and column names. They are an
implementation detail and may change between iOS versions **[verify]**. This is a test trick, not
an interface.

## 5. Install on an iPhone

1. Connect the iPhone by cable (or the same network after pairing) and unlock it.
2. Find its identifier:

   ```bash
   xcrun devicectl list devices      # look for your phone, State "available (paired)"
   ```

3. Build, sign and install. `-allowProvisioningUpdates` lets Xcode create the free provisioning
   profile:

   ```bash
   xcodebuild build -project Ping.xcodeproj -scheme Ping \
     -destination 'id=<DEVICE-ID>' -derivedDataPath build -allowProvisioningUpdates
   xcrun devicectl device install app --device <DEVICE-ID> build/Build/Products/Debug-iphoneos/Ping.app
   ```

4. **First time only, on the phone:** Settings → General → VPN & Device Management → *Apple
   Development: …* → **Trust**. If iOS asks for Developer Mode: Settings → Privacy & Security →
   Developer Mode → On (the phone restarts).
5. Open Ping and tap **Allow** for notifications.

Someone else building Ping must change the bundle ID (both places in § table, plus `Checker.swift`)
and `DEVELOPMENT_TEAM` to their own, then run `xcodegen`.

### The 7-day limit

Apps signed with a free Personal Team stop launching after 7 days **[verify]**. Repeat § 5 step 3
(no need to trust again). Your repos and settings are kept. The paid Apple Developer Program
removes the limit.

## 6. Test the background check (real device only)

`BGAppRefreshTask` never fires in the Simulator. On a phone:

1. Run Ping from Xcode on the device, add a repo you own, then press the home button. Don't
   swipe Ping away: a force-quit stops background refresh until you open it again.
2. In Xcode, pause the debugger and run in the lldb console:

   ```text
   e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.dhruvsharma.Ping.refresh"]
   ```

3. Resume. The background handler runs `Checker.run()`. Open an issue on your repo first to see a
   notification. Test the expiry path too:
   `_simulateExpirationForTaskWithIdentifier:@"com.dhruvsharma.Ping.refresh"`.

These are private debugging selectors: use them only from lldb, never in code.

The processing task can be simulated the same way with `@"com.dhruvsharma.Ping.process"`.
Without a debugger: open Account → **Background Checks**, which shows the last background run and
its result, recorded by `BackgroundLog`.

For a real-world test without the debugger: open an issue, wait, and watch the repo row's
"Checked … ago" line. iOS chooses when to run the check, so expect anything from about 15 minutes
to several hours.

## 7. Rebuild the app icons

Edit `Design/logo-light.webp` / `Design/logo-dark.webp` if you like, then:

```bash
python3 Design/make-icons.py
```

It writes `AppIcon.png` (light) and `AppIcon-Dark.png` (dark) into the asset catalog. The crop
values in the script fit the current originals; a differently framed logo needs new values.

## 8. Clean up

```bash
rm -rf build                                   # ~170 MB of build output
xcrun simctl uninstall booted com.dhruvsharma.Ping
```

## Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| "Unable to launch … profile has not been explicitly trusted" | First install with a free team | § 5 step 4 |
| App stops opening after a week | Free provisioning expired | Reinstall (§ 5 step 3) |
| A new source file isn't compiled | Project not regenerated | `xcodegen` |
| Red row: "GitHub rate limit hit" | 60 unauthenticated requests/hour per IP address, shared with everyone on the same network (e.g. campus Wi-Fi) | Wait for the hourly reset; see [docs/05](docs/05-risks.md) § R3 |
| Red row: "Repo not found, or it's private" | Typo, private repo, or deleted repo | Check the name on github.com; private repos aren't supported |
| No notifications at all | Notifications denied | Ping shows a card with **Open Settings**; turn them on |
| Background checks never happen | App force-quit, Background App Refresh off, or Low Power Mode | Open Ping once; Settings → General → Background App Refresh |
| `BGTaskScheduler` submit fails in the Simulator | Expected: not supported there | Use a device (§ 6) |
