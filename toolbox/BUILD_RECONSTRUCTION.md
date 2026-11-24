# Independent build reconstruction (experimental)

This is a baseline reconstruction step, NOT the Tampermonkey fix. The Kiwi source overlay identifies Chromium 105.0.5195.24, and Chromium 105 predates the modern userScripts API. Do not use this old engine for regular browsing.

Use a disposable x86-64 Linux build machine with at least 100 GB free disk and 8 GB RAM (16 GB or more recommended); allow additional room for build output. Follow the Android build documentation at https://chromium.googlesource.com/chromium/src/+/main/docs/android_build_instructions.md. Historical Chromium 105 dependencies may require a compatible historical Linux/depot_tools environment. They have not been resolved or validated.

1. Obtain a full Chromium checkout at the exact official tag 105.0.5195.24 and sync its Android dependencies according to that revision's documentation.
2. Clone this fork and check out fix/tampermonkey-userscripts.
3. Run the read-only preflight and overlay dry-run:

    python3 toolbox/check_android_build.py /path/to/chromium/src
    bash toolbox/prepare_kiwi_source.sh "$PWD" /path/to/chromium/src

4. On the disposable checkout only, repeat the overlay command with --apply. It replaces overlapping source files but intentionally leaves root metadata and untracked source outside the overlay untouched. Inspect diffs and dependency compatibility. The script does not recreate private/missing Kiwi modifications, detect every dependency conflict, or build an APK.

5. Establish a baseline build before porting to a maintained Chromium engine. Never copy an entire 105 overlay onto 138+; port individual Kiwi changes with conflict review. Use Chromium's native per-extension userScripts permission and its tests, rather than bypassing permission checks or spoofing the version. The official Chromium per-extension permission migration commit is https://chromium.googlesource.com/chromium/src.git/+/ba6541dbdc79af70937fb39800321af98de6297b (requires a compatible modern base).
6. Test with toolbox/userscripts-smoke and current Tampermonkey, including permission revocation and existing extensions. Only publish a signed test APK after a real build and device checks.

Validation performed on temporary synthetic Git repositories: shell syntax, read-only dry-run, mismatched version rejection, successful overlay, and preservation of root .gn. No Chromium or Android compilation has been performed. The original Kiwi build workflow is not used.
