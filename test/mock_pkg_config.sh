#!/bin/bash
if [[ "$*" == *"--cflags"* ]]; then
  echo "-I/usr/include"
  exit 0
fi
if [[ "$*" == *"--libs"* ]]; then
  echo "-L/usr/lib"
  exit 0
fi
exit 0
