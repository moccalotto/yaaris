#!/usr/bin/env bash

cd tooling
lua process.lua ../adventurer.adoc --overwrite
lua process.lua ../heros.adoc --overwrite
lua process.lua ../elites.adoc --overwrite
cd ..

asciidoctor-pdf adventurer.adoc -o out/adventurer.pdf
asciidoctor-pdf heros.adoc -o out/heros.pdf
asciidoctor-pdf elites.adoc -o out/elites.pdf
