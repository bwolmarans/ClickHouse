#!/bin/bash -eu

# Fuzzer runner. Appends .options arguments and seed corpus to users args.
# Usage: $0 <fuzzer_name> <fuzzer_args>

# export PATH=$OUT:$PATH
# cd $OUT

DEBUGGER=${DEBUGGER:-}

function run_fuzzer() {
    FUZZER=$1
    CORPUS_DIR=""
    if [ -d "${FUZZER}.in" ]; then
        CORPUS_DIR="${FUZZER}.in"
    fi

    OPTIONS_FILE="${FUZZER}.options"
    CUSTOM_LIBFUZZER_OPTIONS=""

    if [ -f $OPTIONS_FILE ]; then
        custom_asan_options=$(parse_options.py $OPTIONS_FILE asan)
        if [ ! -z $custom_asan_options ]; then
            export ASAN_OPTIONS="$ASAN_OPTIONS:$custom_asan_options"
        fi

        custom_msan_options=$(parse_options.py $OPTIONS_FILE msan)
        if [ ! -z $custom_msan_options ]; then
            export MSAN_OPTIONS="$MSAN_OPTIONS:$custom_msan_options"
        fi

        custom_ubsan_options=$(parse_options.py $OPTIONS_FILE ubsan)
        if [ ! -z $custom_ubsan_options ]; then
            export UBSAN_OPTIONS="$UBSAN_OPTIONS:$custom_ubsan_options"
        fi

        CUSTOM_LIBFUZZER_OPTIONS=$(parse_options.py $OPTIONS_FILE libfuzzer)
    fi

    CMD_LINE="$FUZZER $FUZZER_ARGS"
    CMD_LINE="$CMD_LINE $CORPUS_DIR"

    if [[ ! -z ${CUSTOM_LIBFUZZER_OPTIONS} ]]; then
        CMD_LINE="$CMD_LINE $CUSTOM_LIBFUZZER_OPTIONS"
    fi

    if [[ ! "$CMD_LINE" =~ "-dict=" ]]; then
        if [ -f "$FUZZER.dict" ]; then
            CMD_LINE="$CMD_LINE -dict=$FUZZER.dict"
        fi
    fi

    CMD_LINE="$CMD_LINE < /dev/null"

    echo $CMD_LINE

    # Unset OUT so the fuzz target can't rely on it.
    # unset OUT

    if [ ! -z "$DEBUGGER" ]; then
        CMD_LINE="$DEBUGGER $CMD_LINE"
    fi

    # bash -c "$CMD_LINE"
}

for fuzzer in *_fuzzer; do
    if [ -f $fuzzer ] && [ -x $fuzzer ]; then
        run_fuzzer $fuzzer
    fi
done
