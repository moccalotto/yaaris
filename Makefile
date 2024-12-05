pdf: out/adventurer.pdf
	cd tooling && lua process.lua ../adventurer.adoc --overwrite
	asciidoctor-pdf adventurer.adoc -o out/adventurer.pdf
