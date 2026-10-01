#!/bin/bash
#
# Fails the SPAG Buddy Home build if anything that could reach the network, school sync code, token storage
# or a third-party SDK appears in the sources Home is built from (SPAGCore and SPAG Buddy Home).
#
# Xcode runs this from the "Check Home is on-device" build phase of the SPAG Buddy Home target.
# Run it by hand with: Scripts/check-home-on-device.sh
#
# The only web addresses allowed are in the allow-list file below, and they may only be opened with
# SwiftUI's Link or openURL, which hand them to Safari.

set -uo pipefail

root="${SRCROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$root" || exit 1

scan_dirs=("SPAGCore" "SPAG Buddy Home")
allow_list="SPAG Buddy Home/ExternalLinks.swift"
max_allowed_links=2
info_plist="SPAG Buddy Home/Info.plist"
privacy_manifest="SPAG Buddy Home/PrivacyInfo.xcprivacy"
project="SPAG Buddy.xcodeproj/project.pbxproj"
home_target="SPAG Buddy Home"

# Apple frameworks Home may import. Anything else is treated as a third-party SDK.
allowed_imports=" Foundation SwiftUI SwiftData Observation AVFoundation UIKit Combine CoreGraphics os OSLog "

# label|extended regex. Matched case-sensitively against every line, comments included.
forbidden=(
    "URLSession|URLSession"
    "URLRequest|URLRequest"
    "NWConnection|NWConnection"
    "NWPathMonitor|NWPathMonitor"
    "WKWebView|WKWebView"
    "UIWebView|UIWebView"
    "SFSafariViewController|SFSafariViewController"
    "ASWebAuthenticationSession|ASWebAuthenticationSession"
    "NSURLConnection|NSURLConnection"
    "CFNetwork|CFNetwork"
    "CFStream|CFStream"
    "AsyncImage|AsyncImage"
    "import Network|import[[:space:]]+([a-z]+[[:space:]]+)?Network([[:space:].]|$)"
    "import WebKit|import[[:space:]]+([a-z]+[[:space:]]+)?WebKit([[:space:].]|$)"
    "import FoundationNetworking|import[[:space:]]+([a-z]+[[:space:]]+)?FoundationNetworking([[:space:].]|$)"
    "import SPAGSchoolSync|import[[:space:]]+([a-z]+[[:space:]]+)?SPAGSchoolSync([[:space:].]|$)"
    "token storage (Keychain)|SecItem(Add|CopyMatching|Update|Delete)|kSecClass|import[[:space:]]+Security([[:space:].]|$)"
)

# School sync types that must never be defined or used in Home. Matched as whole words.
school_types="APIClient|SyncService|ContentUpdater|KeychainStore|JoinClassView|TeacherGateView|SchoolServices|JoinDetails"

apple_plist_doctype='<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
allowed_link_line='^[[:space:]]*static let [A-Za-z]+ = URL\(string: "https://[^"[:space:]]+"\)!$'

failures=0
fail() {
    echo "$1: error: $2"
    failures=$((failures + 1))
}

files=()
while IFS= read -r -d '' file; do
    files+=("$file")
done < <(find "${scan_dirs[@]}" -type f \( -name '*.swift' -o -name '*.h' -o -name '*.m' -o -name '*.mm' \
    -o -name '*.c' -o -name '*.cpp' -o -name '*.js' -o -name '*.html' -o -name '*.json' -o -name '*.plist' \
    -o -name '*.xcprivacy' -o -name '*.entitlements' -o -name '*.strings' -o -name '*.xcstrings' \) -print0 | sort -z)

swift_files=()
if [ "${#files[@]}" -gt 0 ]; then
    for file in "${files[@]}"; do
        case "$file" in *.swift) swift_files+=("$file") ;; esac
    done
fi

if [ "${#swift_files[@]}" -eq 0 ]; then
    fail "$root" "No sources found in ${scan_dirs[*]}"
    exit 1
fi

for rule in "${forbidden[@]}"; do
    label="${rule%%|*}"
    pattern="${rule#*|}"
    while IFS= read -r match; do
        [ -n "$match" ] && fail "$root/${match%%:*}:$(echo "$match" | cut -d: -f2)" "$label is not allowed in SPAG Buddy Home"
    done < <(grep -nHE -- "$pattern" "${files[@]}")
done

while IFS= read -r match; do
    [ -n "$match" ] && fail "$root/${match%%:*}:$(echo "$match" | cut -d: -f2)" \
        "School sync code ($(echo "$match" | cut -d: -f3- | grep -owE "$school_types" | head -1)) lives only in SPAGSchoolSync"
done < <(grep -nHwE -- "$school_types" "${files[@]}")

allowed_links=0
while IFS= read -r match; do
    [ -z "$match" ] && continue
    file="${match%%:*}"
    rest="${match#*:}"
    line="${rest%%:*}"
    text="${rest#*:}"
    if [ "$text" = "$apple_plist_doctype" ]; then
        continue
    fi
    if [ "$file" = "$allow_list" ] && echo "$text" | grep -qE "$allowed_link_line"; then
        allowed_links=$((allowed_links + 1))
        continue
    fi
    fail "$root/$file:$line" "Web address outside the allow-list. Add it to $allow_list only if it is opened in Safari with Link or openURL"
done < <(grep -nHiE -- 'https?://' "${files[@]}")

if [ ! -f "$allow_list" ]; then
    fail "$root/$allow_list" "The allow-list file is missing"
elif [ "$allowed_links" -gt "$max_allowed_links" ]; then
    fail "$root/$allow_list" "$allowed_links links allowed, but only $max_allowed_links (App Store review and privacy policy) may be"
fi

while IFS= read -r match; do
    [ -z "$match" ] && continue
    text="$(echo "$match" | cut -d: -f3-)"
    if ! echo "$text" | grep -qE 'Link\(destination: ExternalLinks\.|openURL\(ExternalLinks\.'; then
        fail "$root/$(echo "$match" | cut -d: -f1):$(echo "$match" | cut -d: -f2)" "ExternalLinks may only be opened with Link(destination:) or openURL"
    fi
done < <(grep -nHE -- 'ExternalLinks\.' "${files[@]}")

while IFS= read -r match; do
    [ -z "$match" ] && continue
    module="$(echo "$match" | cut -d: -f3- | sed -E 's/^[[:space:]]*(@[A-Za-z_]+[[:space:]]+)*import[[:space:]]+((typealias|struct|class|enum|protocol|let|var|func)[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*).*/\4/')"
    case "$allowed_imports" in
        *" $module "*) ;;
        *) fail "$root/$(echo "$match" | cut -d: -f1):$(echo "$match" | cut -d: -f2)" "import $module is not on Home's import allow-list (on-device Apple frameworks only, no third-party SDKs)" ;;
    esac
done < <(grep -nHE -- '^[[:space:]]*(@[A-Za-z_]+[[:space:]]+)*import[[:space:]]+' "${swift_files[@]}")

while IFS= read -r -d '' binary; do
    fail "$root/$binary" "Binary frameworks and libraries are not allowed in SPAG Buddy Home"
done < <(find "${scan_dirs[@]}" \( -name '*.framework' -o -name '*.xcframework' -o -name '*.a' -o -name '*.dylib' -o -name '*.bundle' \) -print0)

if [ -f "$project" ]; then
    # The Home target's PBXNativeTarget block, from its opening line to its closing brace.
    target_block="$(awk -v target="$home_target" '
        index($0, "/* " target " */ = {") { start = 1; buffer = $0; next }
        start && /isa = / && !/isa = PBXNativeTarget;/ { start = 0; buffer = "" }
        start { buffer = buffer "\n" $0 }
        start && /^\t\t};$/ { print buffer; exit }
    ' "$project")"
    if [ -z "$target_block" ]; then
        fail "$root/$project" "The $home_target target was not found"
    fi
    packages="$(echo "$target_block" | awk '/packageProductDependencies = \(/ { on = 1; next } on && /\);/ { on = 0 } on { print }')"
    if [ -n "$packages" ]; then
        fail "$root/$project" "The $home_target target depends on Swift packages:$(echo "$packages" | tr -s '\t\n' ' ')"
    fi
    groups="$(echo "$target_block" | awk '/fileSystemSynchronizedGroups = \(/ { on = 1; next } on && /\);/ { on = 0 } on { print }')"
    for dir in "${scan_dirs[@]}"; do
        echo "$groups" | grep -qF "/* $dir */" || fail "$root/$project" "The $home_target target must be built from $dir"
    done
    extra="$(echo "$groups" | grep -vF "$(printf '/* %s */\n' "${scan_dirs[@]}")" | tr -s '\t\n' ' ')"
    if [ -n "${extra// /}" ]; then
        fail "$root/$project" "The $home_target target may only compile ${scan_dirs[*]}, but also has:$extra"
    fi
    if echo "$target_block" | grep -q "SPAGSchoolSync"; then
        fail "$root/$project" "The $home_target target must not build or link SPAGSchoolSync"
    fi
else
    fail "$root/$project" "Project file not found"
fi

if [ ! -f "$info_plist" ]; then
    fail "$root/$info_plist" "Home's Info.plist is missing"
else
    for key in CFBundleURLTypes SPAGBuddyAPIBaseURL NSAppTransportSecurity LSApplicationQueriesSchemes; do
        if grep -q "<key>$key</key>" "$info_plist"; then
            fail "$root/$info_plist:$(grep -n "<key>$key</key>" "$info_plist" | cut -d: -f1 | head -1)" "$key is not allowed: Home handles no links and talks to no server"
        fi
    done
fi

if [ ! -f "$privacy_manifest" ]; then
    fail "$root/$privacy_manifest" "PrivacyInfo.xcprivacy is missing"
else
    flat="$(tr -d ' \t\r\n' < "$privacy_manifest")"
    case "$flat" in *"<key>NSPrivacyTracking</key><false/>"*) ;; *) fail "$root/$privacy_manifest" "NSPrivacyTracking must be false" ;; esac
    case "$flat" in *"<key>NSPrivacyCollectedDataTypes</key><array/>"*) ;; *) fail "$root/$privacy_manifest" "NSPrivacyCollectedDataTypes must be an empty array" ;; esac
    case "$flat" in *"<key>NSPrivacyTrackingDomains</key><array/>"*) ;; *) fail "$root/$privacy_manifest" "NSPrivacyTrackingDomains must be an empty array" ;; esac
fi

if [ "$failures" -gt 0 ]; then
    echo "error: SPAG Buddy Home must stay on-device. $failures problem(s) found."
    exit 1
fi

echo "SPAG Buddy Home is on-device: ${#files[@]} files checked in ${scan_dirs[*]}, $allowed_links allow-listed link(s) in $allow_list."
