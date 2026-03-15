#!/usr/bin/env bash

set -e

TEST_CVM_DIR="/tmp/cvm-test-$$"
export CVM_DIR="$TEST_CVM_DIR"

echo "=== cvm Integration Test ==="
echo "Test directory: $TEST_CVM_DIR"
echo

cleanup() {
  echo
  echo "Cleaning up test directory..."
  rm -rf "$TEST_CVM_DIR"
}

trap cleanup EXIT

mkdir -p "$TEST_CVM_DIR"
export PATH="$TEST_CVM_DIR/bin:$PATH"

CVM_CMD="$(pwd)/cvm.sh"

echo "1. Testing help command..."
$CVM_CMD help > /dev/null
echo "   ✓ Help command works"

echo "2. Testing version command..."
version_output=$($CVM_CMD version)
if [[ "$version_output" == *"1.0.0"* ]]; then
  echo "   ✓ Version command works"
else
  echo "   ✗ Version command failed"
  exit 1
fi

echo "3. Testing install command..."
$CVM_CMD install 2.1.63
if [ -d "$TEST_CVM_DIR/versions/2.1.63" ]; then
  echo "   ✓ Version 2.1.63 installed"
else
  echo "   ✗ Version 2.1.63 not found"
  exit 1
fi

echo "4. Testing use command..."
$CVM_CMD use 2.1.63
if [ -L "$TEST_CVM_DIR/bin/claude" ]; then
  echo "   ✓ Symlink created"
else
  echo "   ✗ Symlink not created"
  exit 1
fi

echo "5. Verify claude executable works..."
if $TEST_CVM_DIR/bin/claude --version > /dev/null 2>&1; then
  echo "   ✓ Claude executable works"
else
  echo "   ✗ Claude executable failed"
  exit 1
fi

echo "6. Testing current command..."
output=$($CVM_CMD current)
if [[ "$output" == *"2.1.63"* ]]; then
  echo "   ✓ Current version detected"
else
  echo "   ✗ Current version not detected"
  exit 1
fi

echo "7. Testing list command..."
output=$($CVM_CMD list)
if [[ "$output" == *"2.1.63"* ]] && [[ "$output" == *"currently active"* ]]; then
  echo "   ✓ List shows installed version correctly"
else
  echo "   ✗ List doesn't show version correctly"
  exit 1
fi

echo "8. Testing alias command..."
$CVM_CMD alias test-provider 2.1.63
if [ -f "$TEST_CVM_DIR/alias/test-provider" ]; then
  echo "   ✓ Alias created"
else
  echo "   ✗ Alias not created"
  exit 1
fi

echo "9. Testing use with alias..."
$CVM_CMD use test-provider > /dev/null
echo "   ✓ Can switch using alias"

echo "10. Testing list with aliases..."
output=$($CVM_CMD list)
if [[ "$output" == *"test-provider -> 2.1.63"* ]]; then
  echo "   ✓ List shows aliases"
else
  echo "   ✗ List doesn't show aliases"
  exit 1
fi

echo "11. Testing unalias command..."
$CVM_CMD unalias test-provider
if [ ! -f "$TEST_CVM_DIR/alias/test-provider" ]; then
  echo "   ✓ Alias removed"
else
  echo "   ✗ Alias still exists"
  exit 1
fi

echo "12. Install second version for switching test..."
$CVM_CMD install 2.1.62
if [ -d "$TEST_CVM_DIR/versions/2.1.62" ]; then
  echo "   ✓ Second version installed"
else
  echo "   ✗ Second version not installed"
  exit 1
fi

echo "13. Testing version switching..."
$CVM_CMD use 2.1.62
output=$($CVM_CMD current)
if [[ "$output" == *"2.1.62"* ]]; then
  echo "   ✓ Successfully switched versions"
else
  echo "   ✗ Version switch failed"
  exit 1
fi

echo "14. Testing uninstall of non-active version..."
$CVM_CMD uninstall 2.1.63 <<< "y"
if [ ! -d "$TEST_CVM_DIR/versions/2.1.63" ]; then
  echo "   ✓ Non-active version uninstalled"
else
  echo "   ✗ Version still exists"
  exit 1
fi

echo "15. Testing uninstall of active version..."
$CVM_CMD uninstall 2.1.62 <<< "y"
if [ ! -d "$TEST_CVM_DIR/versions/2.1.62" ] && [ ! -L "$TEST_CVM_DIR/bin/claude" ]; then
  echo "   ✓ Active version uninstalled and symlink removed"
else
  echo "   ✗ Active version uninstall failed"
  exit 1
fi

echo "16. Testing error: invalid version format..."
if ! $CVM_CMD install invalid-version 2>&1 | grep -q "Invalid version format"; then
  echo "   ✗ Should reject invalid version format"
  exit 1
fi
echo "   ✓ Invalid version format rejected"

echo "17. Testing error: use non-existent version..."
if ! $CVM_CMD use 9.9.9 2>&1 | grep -q "not installed"; then
  echo "   ✗ Should error on non-existent version"
  exit 1
fi
echo "   ✓ Non-existent version error handled"

echo "18. Testing error: unalias non-existent alias..."
if ! $CVM_CMD unalias nonexistent 2>&1 | grep -q "does not exist"; then
  echo "   ✗ Should error on non-existent alias"
  exit 1
fi
echo "   ✓ Non-existent alias error handled"

echo
echo "=== All 18 tests passed! ==="
