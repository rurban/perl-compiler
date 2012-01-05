#!/bin/sh
# creates log.modules files with date added
perlall -m --nogit make '-Mblib t/modules.t t/top100'
