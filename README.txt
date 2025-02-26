+++ header
@file: pd-wysheid/README.txt
@author: madpang
@date:
- created on 2025-02-22
- updated on 2025-02-25
+++

=== Overview

This is a personal knowledge system, in the form of a blog website, codename "Wysheid" (pronounced "vay-sayd"), which means "wisdom" in Afrikaans.

It is a collection of notes, articles, and essays on various topics.

THe website is built in a bare-bones, minimalistic style, using HTML, CSS, and JavaScript, without any static site generators.

The content is written in markdown-like style plain text, and converted to HTML using a custom-built converter (see [mmd](@todo) project).

=== Organization

The folder structure of the project is as follows:
.
|- README.txt
|- tickets.txt  # issue tracker, progress log
|- index.html   # the entry point of the website
|- artifacts/   # the generated HTML files of the posts
|- contents/    # @todo: the source files of the posts, symlink -> `zettelkasten` project
|- common/      # top level assets
|  |- fonts/
|  |- images/
|  |- styles/
|  |- scripts/
|- utils/       # @todo: utilities for the project, symlink -> `mmd` project

=== License info.

The CSS and JavaScript files are free to use, modify, and distribute.

But the content of those articles are the intellectual creation of the author, and are thus copyrighted.

Also note that, the font used in this site---called **Dinkie Bitmap**---is a product of [3type](https://3type.cn/fonts/dinkie_bitmap/index.html), if you want to use it, please purchase a license from their website.
