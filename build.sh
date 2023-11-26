#!/usr/bin/env bash

cd tooling
lua process.lua ../adventurer.adoc --overwrite
lua process.lua ../heros.adoc --overwrite
lua process.lua ../elites.adoc --overwrite
cd ..
