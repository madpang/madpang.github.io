+++ header
@file: pd-wysheid/README.txt
@author: madpang
@date:
- created on 2025-02-22
- updated on 2025-02-24
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
|- contents/    # @todo: the source files of the posts, symlink -> `zettelkasten`
|- assets/
|  |- fonts/
|  |- images/
|- styles/	    # contains CSS files
|- scripts/
|- utils/       # @todo: utilities for the project, symlink -> `mmd`
