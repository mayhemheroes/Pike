#!/usr/bin/env bash
set -euo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH

# DWARF < 4 debug info on every target binary — Mayhem's triage cannot read DWARF >= 4 and clang-19's
# plain -g emits DWARF-5, so thread $DEBUG_FLAGS explicitly (§6.2 item 10). The base leaves it empty;
# default it to -gdwarf-3 so the installed pike carries a readable (< 4) .debug_info.
: "${DEBUG_FLAGS:=-gdwarf-3}"

# Pike is self-hosting: `make` builds tpike (a fresh Pike) and runs it as the module precompiler for
# every module. Halting UBSan aborts tpike on benign unaligned reads (get_unaligned* in pike_memory.h)
# for every module, and ASan's leak checker aborts tpike at exit — either way the self-hosting build
# never finishes. ASan on the installed binary also makes Mayhem's sanitizer-compat treat every clean
# interpreter error-exit as a crash (0-edge run). So the fuzz build is unsanitized by default;
# $SANITIZER_FLAGS stays threaded as an opt-in knob (build with PIKE_SANITIZE=1 to apply it).
# SanitizerCoverage edge feedback for Mayhem WITHOUT the libFuzzer main and WITHOUT ASan/UBSan.
# A plain file-input pike carries no coverage otherwise, so Mayhem sees 0 edges. -fsanitize=fuzzer-no-link
# links a self-contained SanCov runtime (defines __sanitizer_cov_* itself, no undefined refs, no abort-
# on-error), so the self-hosting tpike precompiler still runs cleanly during make while the installed
# pike/libpike.so export the counters Mayhem reads. Threaded into CFLAGS/CXXFLAGS/LDFLAGS below.
FUZZ_COV="-fsanitize=fuzzer-no-link"
FUZZ_SAN="${PIKE_SANITIZE:+$SANITIZER_FLAGS}"
FUZZ_FLAGS="-O2 $DEBUG_FLAGS $FUZZ_COV $FUZZ_SAN"

: "${CC:=clang}" ; : "${CXX:=clang++}"
: "${MAYHEM_JOBS:=$(nproc)}"
export CC CXX MAYHEM_JOBS
export PATH="/usr/bin:$PATH"

cd "$SRC"
PIKE_VER="9.1.3"
FUZZ_PREFIX="$SRC/mayhem/fuzz-prefix"
TEST_PREFIX="$SRC/mayhem/test-prefix"

pike_build() {
  local prefix="$1" cflags="$2" cxxflags="$3" label="$4"
  echo "=== Pike $label build (prefix=$prefix) ==="
  if [ -f Makefile ]; then make distclean >/dev/null 2>&1 || true; fi
  make -j"$MAYHEM_JOBS" \
    CONFIGUREARGS="--prefix=$prefix CC=$CC CXX=$CXX CFLAGS='$cflags' CXXFLAGS='$cxxflags' LDFLAGS='$cflags'"
  make CONFIGUREARGS="--prefix=$prefix CC=$CC CXX=$CXX CFLAGS='$cflags' CXXFLAGS='$cxxflags' LDFLAGS='$cflags'" \
    install
}

pike_build "$FUZZ_PREFIX" "$FUZZ_FLAGS" "$FUZZ_FLAGS" "fuzz"
FUZZ_PIKE="$FUZZ_PREFIX/pike/${PIKE_VER}/bin/pike"
[ -x "$FUZZ_PIKE" ] || { echo "ERROR: fuzz pike not at $FUZZ_PIKE" >&2; exit 1; }
cp "$FUZZ_PIKE" /mayhem/pike
chmod +x /mayhem/pike
echo "built /mayhem/pike"

pike_build "$TEST_PREFIX" "-O2 -g" "-O2 -g" "oracle"
echo "oracle build ready for test.sh"
