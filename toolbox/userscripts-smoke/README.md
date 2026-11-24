# Kiwi Tampermonkey compatibility: baseline tests

The fork's kiwi branch identifies Chromium 105.0.5195.24. The final public APK is labelled 137.0.7337.0; its version label does not establish its actual engine/API level. This repository is a partial source tree (root DEPS, .gn and build/config are absent). Do not assume it can compile directly. The original APK workflow delegates to Kiwi infrastructure and is not a self-contained build.

Chromium introduced chrome.userScripts in 120. Versions before 138 use the developer-mode gate; 138+ uses an explicit per-extension Allow User Scripts control. See https://developer.chrome.com/docs/extensions/reference/api/userScripts/ and https://developer.chrome.com/blog/chrome-userscript.

## Build preflight

On a supported Linux build host with depot_tools on PATH, run:
```sh
python3 toolbox/check_android_build.py /path/to/full/chromium/src --require-userscripts
```
This is read-only; it does not download, merge, or build anything. Reconstruct a matching full source checkout before overlaying Kiwi changes. A clean baseline build must succeed before any API backport. Do not send secrets to the legacy build service.

## Manual smoke test (unpacked MV3 extension)

1. Load this directory as an unpacked extension on the test browser, if supported. If the userScripts permission is rejected or reported as unknown, record that separately.
2. With the relevant user permission disabled, open the extension popup and select Register and verify. Expect failure.
3. For Chromium 120–137, enable Developer mode; for 138+, enable Allow User Scripts on the extension details page. Select Register and verify again. Expect registration PASS.
4. Reload https://example.com/. Expect the green banner. Verify other origins do not receive it.
5. Select Unregister and reload example.com. Expect no banner.
6. Register again, restart the browser and confirm the registration and injection persist; revoke the permission and verify injection stops on a fresh navigation. Test a second extension without permission to ensure isolation.
7. Test current Tampermonkey with an equivalent harmless @match https://example.com/* script, plus existing MV2/MV3 extensions.

No network access other than visiting example.com is needed for the test extension. It does not modify browser permissions, bypass checks, or collect data. These are acceptance tests, not a compatibility patch.
