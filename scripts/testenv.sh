#!/bin/bash

if [ -n "${APPLY_WAIT+x}" ] && [ -n "$APPLY_WAIT" ]; then
    echo "Apply wait"
else
    echo "Non Apply wait"
fi
