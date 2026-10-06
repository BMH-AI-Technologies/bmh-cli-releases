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

# The PATH line above only reaches NEW terminals. So that `bmh` works right away in this
# window too, link it into a writable folder that's already on this shell's PATH.
NOW=""
for d in /opt/homebrew/bin /usr/local/bin "$HOME/.local/bin" "$HOME/bin"; do
  case ":$PATH:" in
    *":$d:"*)
      # Only create the link, or replace one that already points at a bmh install;
      # never overwrite some other program that happens to be called bmh.
      if [ -d "$d" ] && [ -w "$d" ]; then
        if [ ! -e "$d/bmh" ] && [ ! -L "$d/bmh" ]; then ok=1
        elif [ -L "$d/bmh" ] && case "$(readlink "$d/bmh")" in */.bmh/bin/bmh) true ;; *) false ;; esac; then ok=1
        else ok=0; fi
        if [ "$ok" = 1 ] && ln -sf "$BIN_DIR/bmh" "$d/bmh" 2>/dev/null; then NOW="$d"; break; fi
      fi ;;
  esac
done
# The pipe from curl occupies stdin; setup's questions need the keyboard. Hand bmh the
# window's own terminal (stderr/stdout are still connected to it). Re-opening /dev/tty
# looks equivalent but bmh's runtime then never receives keystrokes, not even Ctrl+C.
# BMH_INVITE (optional) registers the laptop with the BMH server.
SETUP="$BIN_DIR/bmh setup ${BMH_ORG:+--org $BMH_ORG} ${BMH_INVITE:+--invite $BMH_INVITE}"
if [ -t 2 ]; then
  $SETUP <&2
elif [ -t 1 ]; then
  $SETUP <&1
else
  echo "Chạy tiếp: bmh setup${BMH_ORG:+ --org $BMH_ORG}"
fi
echo
if [ -n "$NOW" ]; then
  echo "Vào thư mục làm việc rồi gõ: bmh"
else
  echo "Mở cửa sổ Terminal mới (hoặc terminal trong Antigravity), vào thư mục làm việc rồi gõ: bmh"
fi
