#!/usr/bin/env bash
#
# Continuation character
#

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

# The continuation prompt has its own variables. It used to share GAUDI_CHAR_*
# with the "char" segment; a value set through those names is still used when
# the new one is not set, but the old names are no longer assigned here (that
# made the "char" segment show the continuation glyph).
: "${GAUDI_CONTINUATION_PREFIX=${GAUDI_CHAR_PREFIX-}}"
: "${GAUDI_CONTINUATION_SUFFIX=${GAUDI_CHAR_SUFFIX-\\t}}"
: "${GAUDI_CONTINUATION_SYMBOL=${GAUDI_CHAR_SYMBOL-\\uf6d7}}"
: "${GAUDI_CONTINUATION_COLOR=${GAUDI_CHAR_COLOR_SUCCESS-$GAUDI_YELLOW}}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

# Paint PS2 – Continuation interactive prompt
gaudi_continuation () {

  gaudi::section \
    "$GAUDI_CONTINUATION_COLOR" \
    "$GAUDI_CONTINUATION_PREFIX" \
    "$GAUDI_CONTINUATION_SYMBOL" \
    "" \
    "$GAUDI_CONTINUATION_SUFFIX"
}
