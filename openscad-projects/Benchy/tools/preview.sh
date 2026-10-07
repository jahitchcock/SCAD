#!/bin/bash
# usage: tools/preview.sh <name> [-D var=value ...]   -> previews/var_<name>.png (iso view)
O="/c/Program Files/OpenSCAD/openscad.exe"
n=$1; shift
"$O" -o "previews/var_$n.png" "$@" --camera=0,0,0,60,0,28,210 --imgsize=800,640 --autocenter --viewall src/main.scad >/dev/null 2>&1
echo "$n done"
