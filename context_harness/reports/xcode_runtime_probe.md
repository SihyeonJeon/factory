# Xcode Runtime Probe

- xcodeproj: /Users/jeonsihyeon/factory/.worktrees/_integration/workspace/ios/Unfading.xcodeproj
- scheme: Unfading
- build_output: BUILD SUCCEEDED
- build_log: /Users/jeonsihyeon/factory/context_harness/reports/xcode_build.log
- simulator_status: booted
- booted_device: iPhone 17
- app_binary: /Users/jeonsihyeon/factory/.worktrees/_integration/.deriveddata/evaluation/Build/Products/Debug-iphonesimulator/Unfading.app
- bundle_id: com.jeonsihyeon.unfading
- install_ok: True
- launch_ok: True
- screenshot: /Users/jeonsihyeon/factory/context_harness/reports/xcode_runtime_screenshot.png

## Evidence

n/factory/.worktrees/_integration/workspace/ios
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/jeonsihyeon/factory/.worktrees/_integration/.deriveddata/evaluation/Build/Products/Debug-iphonesimulator/Unfading.app/__preview.dylib
/Users/jeonsihyeon/factory/.worktrees/_integration/.deriveddata/evaluation/Build/Products/Debug-iphonesimulator/Unfading.app/__preview.dylib: replacing existing signature

CodeSign /Users/jeonsihyeon/factory/.worktrees/_integration/.deriveddata/evaluation/Build/Products/Debug-iphonesimulator/Unfading.app (in target 'Unfading' from project 'Unfading')
    cd /Users/jeonsihyeon/factory/.worktrees/_integration/workspace/ios
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/jeonsihyeon/factory/.worktrees/_integration/.deriveddata/evaluation/Build/Products/Debug-iphonesimulator/Unfading.app

Validate /Users/jeonsihyeon/factory/.worktrees/_integration/.deriveddata/evaluation/Build/Products/Debug-iphonesimulator/Unfading.app (in target 'Unfading' from project 'Unfading')
    cd /Users/jeonsihyeon/factory/.worktrees/_integration/workspace/ios
    builtin-validationUtility /Users/jeonsihyeon/factory/.worktrees/_integration/.deriveddata/evaluation/Build/Products/Debug-iphonesimulator/Unfading.app -shallow-bundle -infoplist-subpath Info.plist

** BUILD SUCCEEDED **
