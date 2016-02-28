#!/bin/bash
TAGS=$(grep -hr categor _posts | cut -d ":" -f2 | tr -d '[],' | tr ' ' '\n' | grep -e "^." | sort | uniq)
for tag in $TAGS; do

	mkdir -p ./tags/$tag/
	cat > ./tags/$tag/index.md <<EOFX
---
layout: tagpage
tag: $tag
title: posts under $tag
---

EOFX
done
