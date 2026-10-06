#!/bin/sh
# bmh installer for macOS / Linux.
#   curl -fsSL https://raw.githubusercontent.com/BMH-AI-Technologies/bmh-cli-releases/main/install.sh | BMH_ORG=family sh
# Downloading with curl (not a browser) means Gatekeeper doesn't quarantine
# the binary, so no notarization is needed yet.
set -eu

RELEASES="${BMH_RELEASES:-https://github.com/BMH-AI-Technologies/bmh-cli-releases/releases/latest/download}"
BMH_HOME="${BMH_HOME:-$HOME/.bmh}"
BIN_DIR="$BMH_HOME/bin"

case "$(uname -s)" in
  Darwin) os=darwin ;;
  Linux) os=linux ;;
  *) echo "Hệ điều hành chưa hỗ trợ: $(uname -s)"; exit 1 ;;
esac
case "$(uname -m)" in
  arm64|aarch64) arch=arm64 ;;
  x86_64|amd64) arch=x64 ;;
  *) echo "Chip chưa hỗ trợ: $(uname -m)"; exit 1 ;;
esac
# Rosetta: an Apple-silicon Mac running this shell as x86_64 should still get arm64.
if [ "$os" = darwin ] && [ "$arch" = x64 ] && [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" = 1 ]; then
  arch=arm64
fi

asset="bmh-$os-$arch"
echo "✦ Đang tải bmh ($asset)…"
mkdir -p "$BIN_DIR"
curl -fL --progress-bar "$RELEASES/$asset" -o "$BIN_DIR/bmh.tmp"
chmod +x "$BIN_DIR/bmh.tmp"
mv "$BIN_DIR/bmh.tmp" "$BIN_DIR/bmh"

# Put ~/.bmh/bin on PATH for future terminals (zsh is the macOS default).
line="export PATH=\"$BIN_DIR:\$PATH\""
for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
  if [ -f "$rc" ] || [ "$rc" = "$HOME/.zshrc" ]; then
    grep -qs "$BIN_DIR" "$rc" || printf '\n# bmh\n%s\n' "$line" >> "$rc"
  fi
done

echo "✓ Đã cài bmh vào $BIN_DIR"
# The pipe from curl occupies stdin; setup's questions need the keyboard.
if (exec </dev/tty) 2>/dev/null; then
  # BMH_INVITE (optional) registers the laptop with the BMH server.
  "$BIN_DIR/bmh" setup ${BMH_ORG:+--org "$BMH_ORG"} ${BMH_INVITE:+--invite "$BMH_INVITE"} </dev/tty
else
  echo "Chạy tiếp: bmh setup${BMH_ORG:+ --org $BMH_ORG}"
fi
echo
echo "Mở cửa sổ Terminal mới (hoặc terminal trong Antigravity), vào thư mục làm việc rồi gõ: bmh"
