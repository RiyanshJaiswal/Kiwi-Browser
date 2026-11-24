#!/usr/bin/env python3
"""Read-only preflight for a complete Kiwi/Chromium Android build checkout."""
import argparse
import pathlib
import platform
import shutil
import sys

REQUIRED = (".gn", "DEPS", "BUILD.gn", "build/config/BUILDCONFIG.gn",
            "chrome/VERSION", "chrome/android/BUILD.gn",
            "third_party/blink/renderer/core/BUILD.gn")
API = ("extensions/browser/api/user_scripts/user_scripts_api.cc",
       "extensions/browser/api/user_scripts/user_scripts_api.h")

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("src", type=pathlib.Path)
    parser.add_argument("--require-userscripts", action="store_true",
                        help="Fail if the modern API implementation is missing.")
    args = parser.parse_args()
    root = args.src.resolve()
    if not root.is_dir():
        parser.error("Source directory does not exist.")
    failed = False
    for path in REQUIRED:
        if not (root / path).is_file():
            print("MISSING SOURCE:", path)
            failed = True
    version = root / "chrome/VERSION"
    if version.is_file():
        print("Source version:", version.read_text().strip().replace("\n", " "))
    for path in API:
        if not (root / path).is_file():
            print("MISSING USER SCRIPTS API:", path)
            failed |= args.require_userscripts
    for tool in ("git", "gclient", "gn", "autoninja"):
        if shutil.which(tool) is None:
            print("MISSING TOOL:", tool)
            failed = True
    if platform.system() != "Linux":
        print("Android Chromium build requires a supported Linux host.")
        failed = True
    free_gib = shutil.disk_usage(root).free / (1024 ** 3)
    print(f"Free disk: {free_gib:.1f} GiB (100+ GiB recommended)")
    if free_gib < 100:
        print("WARNING: disk may be insufficient for a full Android build.")
    print("PREFLIGHT FAILED" if failed else "PREFLIGHT PASSED (not a build test)")
    return int(failed)

if __name__ == "__main__":
    sys.exit(main())
