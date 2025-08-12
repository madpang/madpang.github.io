``` header
@file: pd-wysheid/README.txt
@author: madpang
@date: [created: 2025-02-22, updated: 2025-08-12]
```

# pd-wysheid

This is a personal knowledge system, in the form of a blog website, codename "Wysheid" (pronounced "vay-sayd"), which means "wisdom" in Afrikaans.

It is a collection of notes, articles, and essays on various topics.

The website is built in a bare-bones, minimalistic style, using HTML, CSS, and JavaScript, without any static site generation frameworks.

The content is written in plain text, with markdown-style custom markup.
It is converted to HTML using a custom-built converter (see [mmd2html](https://github.com/madpang/mmd2html)).

## Organization

The folder structure of the project is as follows:
``` tree
.
|- README.txt
|- README.md      # symlink to README.txt
|- tickets.txt    # issue tracker, progress log
|- index.html     # entry point of the website
|- artifacts/     # generated HTML files of the posts
|  |- <post_id>
|  |  |- <post_id>.html
|  |  |- media/
|- commons/       # common assets
|  |- fonts/
|  |- images/
|  |- styles/
|  |- scripts/
|- zettelkasten/  # [submodule] manuscripts of the posts
|  |- <post_id>
|  |  |- <post_id>.txt
|  |  |- media/
|- contents       # symlink to zettelkasten
|- mmd2html/      # [submodule] custom plain text markup to HTML converter
|- tools          # symlink to mmd2html
|- build-post.ps1 # script to build a single blog post
|- build.ps1      # script to build blogs for the website
|- scripts/       # utility scripts
```

## License info.

The CSS and JavaScript files are free to use, modify, and distribute.

The content of those articles are the intellectual creation of the author, and are thus copyrighted.

Note that, the font used in this site---called **Dinkie Bitmap**---is a product of [3type](https://3type.cn/fonts/dinkie_bitmap/index.html), if you want to use it, please purchase a license from their website.

JetBrains Mono is used as the monospace font.
It is an open-source font, and can be obtained from [GitHub](https://github.com/JetBrains/JetBrainsMono).
