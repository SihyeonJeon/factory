#!/bin/bash
# init_expo_app.sh
# 팩토리의 UI/UX 에이전트가 호출하는 2026 SOTA 환경 자동 구축 서브 에이전트 스크립트

set -e

WORKSPACE_DIR="$1"
if [ -z "$WORKSPACE_DIR" ]; then
    echo "Usage: ./init_expo_app.sh <WORKSPACE_DIR>"
    exit 1
fi

echo "==========================================="
echo "⚙️ [Subagent] Expo + SOTA Plugins 초기화 시작..."
echo "==========================================="

# 기존 더미 파일이 있다면 삭제
if [ -d "$WORKSPACE_DIR" ]; then
    rm -rf "$WORKSPACE_DIR"/*
    rm -rf "$WORKSPACE_DIR"/.* 2>/dev/null || true
fi

mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

# Expo Blank Typescript 템플릿으로 현재 디렉토리에 강제 생성
echo "-> 1. Expo Router & Typescript 스캐폴딩 생성 중..."
npx create-expo-app@latest . -t expo-template-blank-typescript --yes

echo "-> 2. Unfading Core Plugins (Architecture) 설치 중..."
# Web Support (for Playwright QA testing)
npx expo install react-native-web react-dom @expo/metro-runtime
# Navigation
npx expo install expo-router react-native-safe-area-context react-native-screens expo-linking expo-constants expo-status-bar
# UI Thread / Animations
npx expo install react-native-reanimated react-native-gesture-handler
# Bottom Sheet
npm install @gorhom/bottom-sheet@^4
# Map & Clustering
npx expo install react-native-maps react-native-map-clustering
# State Management
npm install zustand
# NativeWind (Tailwind for React Native)
npm install nativewind
npm install --save-dev tailwindcss@3.3.2
npx tailwindcss init

echo "-> 3. 바벨(Babel) 및 설정 파일 자동 조율..."
cat << 'EOF' > babel.config.js
module.exports = function(api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      'nativewind/babel',
      'react-native-reanimated/plugin',
    ],
  };
};
EOF

# Claude Code CLI Agent 권한 매핑 (Harness Configuration)
# 이 파일은 에이전트가 무슨 도구를 호출할 수 있는지 알려줍니다.
cat << 'EOF' > .claude.json
{
  "tools": {
    "expo_start": {
      "command": "npx expo start --clear",
      "description": "Start the Expo React Native local server for preview testing."
    },
    "ios_build": {
      "command": "eas build -p ios --profile development",
      "description": "Trigger an EAS cloud build for iOS Simulator."
    },
    "lint": {
      "command": "npx eslint . --ext js,jsx,ts,tsx",
      "description": "Check syntax and Vibe Coding strictness."
    }
  },
  "roles": ["Senior React Native Lead", "UX Map Specialist"],
  "rules": [
    "Strictly follow Apple HIG rules for touch zones (44x44pt minimum)",
    "Use zustand for state. NO local state unless absolutely strictly isolated.",
    "Use nativewind for all styling. No Magic Numbers.",
    "Map and Bottom sheet must interact seamlessly on the UI thread via reanimated."
  ]
}
EOF

echo "==========================================="
echo "✅ [Subagent] Expo 기반 SOTA 환경 초기화 및 하네스 연결 완료!"
echo "==========================================="
exit 0
