#!/bin/bash
# https://github.com/jirutka/luasrcdiet
for i in *.lua; do 
  luasrcdiet "$i" -o "dist/Deathpool/$i" --none --opt-comments --opt-emptylines --opt-srcequiv --opt-binequiv
done
