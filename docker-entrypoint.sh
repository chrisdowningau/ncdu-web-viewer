#!/bin/sh

# default container parameter
export NCDU_WEB_VIEWER_SCAN_FROM=${NCDU_WEB_VIEWER_SCAN_FROM:='folder'}
export NCDU_WEB_VIEWER_READONLY=${NCDU_WEB_VIEWER_READONLY:='yes'}
export NCDU_WEB_VIEWER_EXTRA_ARGS=${NCDU_WEB_VIEWER_EXTRA_ARGS:=''}

# EXTRA_ARGS is appended into wetty's shell command. Rules:
# - paths with spaces: use single quotes, e.g. --exclude '/path/with spaces'
# - no double quotes; no unmatched single quotes
# - outside single quotes: only safe flag/path characters (no ; $ | & etc.)
if [ -n "$NCDU_WEB_VIEWER_EXTRA_ARGS" ]; then
    case $NCDU_WEB_VIEWER_EXTRA_ARGS in
        *\"*)
            echo "NCDU_WEB_VIEWER_EXTRA_ARGS: double quotes are not allowed; use single quotes for spaces" >&2
            exit 1
            ;;
    esac
    if [ "$(printf '%s' "$NCDU_WEB_VIEWER_EXTRA_ARGS" | wc -l)" -ne 0 ]; then
        echo "NCDU_WEB_VIEWER_EXTRA_ARGS: newlines are not allowed" >&2
        exit 1
    fi
    # Drop paired '...' segments; remainder must be safe unquoted text only
    stripped=$(printf '%s' "$NCDU_WEB_VIEWER_EXTRA_ARGS" | sed "s/'[^']*'//g")
    case $stripped in
        *\'*)
            echo "NCDU_WEB_VIEWER_EXTRA_ARGS: unmatched single quote" >&2
            exit 1
            ;;
        *[!A-Za-z0-9_./=*?+\[\]\ -]*)
            echo "NCDU_WEB_VIEWER_EXTRA_ARGS: unsupported characters outside single quotes" >&2
            exit 1
            ;;
    esac
fi

# Charge la crontab depuis le template
if [ "$NCDU_WEB_VIEWER_SCAN_FROM" = "dump" ]; then
    # execute ncdu and inject the dump file
    echo "Feature activated: NCDU_WEB_VIEWER_SCAN_FROM=dump"
    exec node . --port 3000 --base / --command "ncdu -f /ncdu-dump.json ${NCDU_WEB_VIEWER_EXTRA_ARGS}"
else
    # execute ncdu on the folder
    if [ "$NCDU_WEB_VIEWER_READONLY" = "no" ]; then
        echo "Feature activated: NCDU_WEB_VIEWER_SCAN_FROM=folder"
        exec node . --port 3000 --base / --command "ncdu ${NCDU_WEB_VIEWER_EXTRA_ARGS} /folder-to-scan/"
    else
        echo "Feature activated: NCDU_WEB_VIEWER_SCAN_FROM=folder (with NCDU_WEB_VIEWER_READONLY=yes)"
        exec node . --port 3000 --base / --command "ncdu -r ${NCDU_WEB_VIEWER_EXTRA_ARGS} /folder-to-scan/"
    fi
fi
