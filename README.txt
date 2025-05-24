+++ header
@file: pd-wysheid/README.txt
@author: madpang
@date:
- created on 2025-02-22
- updated on 2025-05-24
+++

=== Overview

This is a personal knowledge system, in the form of a blog website, codename "Wysheid" (pronounced "vay-sayd"), which means "wisdom" in Afrikaans.

It is a collection of notes, articles, and essays on various topics.

The website is built in a bare-bones, minimalistic style, using HTML, CSS, and JavaScript, without any static site generators.

The content is written in markdown-like style plain text, and converted to HTML using a custom-built converter (see [mmd](@todo) project).

=== Organization

The folder structure of the project is as follows:
+++ tree
.
|- README.txt   # THIS file
|- tickets.txt  # issue tracker, progress log
|- index.html   # the entry point of the website
|- artifacts/   # the generated HTML files of the posts
|  |- <post_id>
|  |  |- <post_id>.html
|  |  |- media/
|- contents/    # manuscripts of the posts
|  |- <post_id>
|  |  |- <post_id>.txt
|  |  |- media/
|- commons/     # top level assets
|  |- fonts/
|  |- images/
|  |- styles/
|  |- scripts/
|- tools/       # tools for generating the website
|  |- mmd2html  # [submodule], for custom plain text markup to HTML converter
|- build.ps1    # @todo: executable script to build the website
+++

=== License info.

The CSS and JavaScript files are free to use, modify, and distribute.

But the content of those articles are the intellectual creation of the author, and are thus copyrighted.

Also note that, the font used in this site---called **Dinkie Bitmap**---is a product of [3type](https://3type.cn/fonts/dinkie_bitmap/index.html), if you want to use it, please purchase a license from their website.
