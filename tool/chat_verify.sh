#!/usr/bin/env bash
# One-shot local verification for the chat redesign (run from ado_dad_mobile in Git Bash).
#   bash tool/chat_verify.sh            # analyze + chat tests
#   bash tool/chat_verify.sh --clean    # also deletes the old chat files first (git rm)
set -e
cd "$(dirname "$0")/.."
if [[ "$1" == "--clean" ]]; then
  git rm -r --quiet --ignore-unmatch \
    lib/features/chat/bloc lib/features/chat/ui \
    lib/services/chat_socket_service.dart lib/services/chat_api_service.dart \
    lib/repositories/chat_repository.dart lib/models/chat_item.dart \
    lib/single-user-chat.html lib/single-user-chat-test.html
  echo "old chat files removed"
fi
flutter pub get
flutter analyze
flutter test test/features/chat
echo
echo "OK — now: flutter run   (Chat tab, long-press a row, ad → Chat, ad → Make an offer, logout/login)"
echo "Design QA: flutter run -t lib/main_chat_preview.dart  on 360x800 + 412x915, light/dark, text 1.3"
