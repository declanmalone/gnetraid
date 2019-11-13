#!/bin/bash

DIR=$1
FILE=$2

# I can't be bothered with passing all parameters on the command line,
# so I'll set them up as environment variables.
#
# IDA_SCRIPT=worker_validate.pl
#
# This needs to be in the PATH, or else set the following:
#
# IDA_SCRIPT_PATH=/full/path/to/validate/script
#
# IDA_REPORT_PATH=/path/to/store/reports
#
# This script will create suitable names for the reports, one for each
# worker.
#
# When checking shares, it will append to the report files to allow
# for dealing with restarting a failed run later with a new $IDA_SKIP
# value set. (see below)
#
# IDA_WORKERS=4
#
# Number of workers, passed to script as "-n $WORKERS"
#
# IDA_OFFSETS="0 1 2 3"  # (note: needs to be quoted)
#
# Individual offsets for each worker
#
# for $offset in $IDA_OFFSETS; do
#    $IDA_SCRIPT -n $IDA_WORKERS -m $offset ...
# done
#
# IDA_SKIP=0
#
# In the event that validation scripts fail (eg, disk problems), I
# don't want to have to do the whole scan again. This value
# (defaulting to 0) can be used to skip entries that have already been
# scanned.
#
# Called as:
#
# for $offset in $IDA_OFFSETS; do
#    $IDA_SCRIPT ... -s $(($offset + $IDA_SKIP)) ...
# done
#
# We interpret the variable as the number of entries that the *0'th*
# worker will skip (to), hence, by the above, each worker will be told
# to restart at a different offset, as required by worker-validate.pl.
#

BASE=`basename "$0"`

USAGE="
$BASE - Launch a group of workers validating IDA shares

Usage (assuming Bash-style exports):

 \$ export IDA_SCRIPT=worker-validate.pl      # default
 \$ export IDA_SCRIPT_PATH=/path/to/script
 \$ export IDA_SKIP=0                         # default
 \$ export IDA_REPORT_PATH=/path/for/reports
 \$ export IDA_WORKERS=4                      # default
 \$ export IDA_OFFSETS='0 1 2 3'              # default
 \$ $BASE replica_dir report.yaml

See comments at the top of this script for the meanings of these
environment variables.
"

# Set up default values if not supplied
[ "x$IDA_SCRIPT"  == "x" ] && IDA_SCRIPT="worker-validate.pl"
[ "x$IDA_SKIP"    == "x" ] && IDA_SKIP="0"
[ "x$IDA_WORKERS" == "x" ] && IDA_WORKERS="4"
[ "x$IDA_OFFSETS" == "x" ] && IDA_OFFSETS="0 1 2 3"

# Check values of environment variables
offsets=0
for o in $IDA_OFFSETS; do
    offsets=$(( $offsets + 1 ))
done
if [ "x$offsets" != "x$IDA_WORKERS" ]; then
    echo "IDA_OFFSETS ('$IDA_OFFSETS') should be a string" \
	 "with $IDA_WORKERS elements"
    echo "Got $offsets elements"
    exit 1;
fi

if [ "x$IDA_SCRIPT_PATH"  != "x" ]; then
    # prepend path if supplied (else rely on PATH to find it)
    IDA_SCRIPT="$IDA_SCRIPT_PATH/$IDA_SCRIPT";
fi

if [ ! -d "$IDA_REPORT_PATH" ]; then
    echo "IDA_REPORT_PATH is not a directory"
    exit 1;
fi

# Check command-line arguments
ARGS_OK=1
if [ "x$DIR"  == "x" ]; then ARGS_OK=0; fi
if [ "x$FILE" == "x" ]; then ARGS_OK=0; fi

if [ $ARGS_OK != 1 ]; then
    echo -e "$USAGE"
    exit 1
fi

if [ ! -d "$DIR" ]; then
    echo "$DIR is not a directory";
    exit 1
fi
if [ ! -f "$FILE" ]; then
    echo "$FILE is not a regular file";
    exit 1
fi

# Filenames in report are relative to root of replica store, so we
# need to chdir there.
cd "$DIR" || exit 1;

# Launch sub processes
pids=""
for offset in $IDA_OFFSETS; do
    "$IDA_SCRIPT" -n $IDA_WORKERS -m $offset \
		  -s $(($offset + $IDA_SKIP)) \
		  "$FILE" \
		  2>> "$IDA_REPORT_PATH/validate-errors-${offset}.log" \
		  >> "$IDA_REPORT_PATH/validate-report-${offset}.log" &
    thispid=$!
    pids="$pids $thispid"
    echo "Launched worker $offset [pid]"
done

echo "Waiting for pids $pids"
wait $pids

echo All workers exited.
