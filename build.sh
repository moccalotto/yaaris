#!/usr/bin/env bash

cd tooling
lua process.lua ../adventurer.adoc --overwrite
lua process.lua ../hero.adoc --overwrite
lua process.lua ../elite.adoc --overwrite
cd ..

asciidoctor-pdf adventurer.adoc -o out/adventurer.pdf
asciidoctor-pdf hero.adoc -o out/hero.pdf
asciidoctor-pdf elite.adoc -o out/elite.pdf
