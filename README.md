Common Lisp Interface Manager
=============================

Description
-----------

Common Lisp Interface Manager 2.0 based on the open source release by
Franz, Inc. The original release runs on Allegro Common Lisp; this
fork adds compatibility with other implementations, focusing mostly on
CCL and to a lesser extent on SBCL due to SBCLs poor MS Windows
support.

See the file LICENSE for information on the license for this source
code.

The Franz release was relatively recent by Lisp standards. It decends
from the original CLIM put out by the lisp vendors like Symbolics and
Franz. Because there were no freely available versions,
[McCLIM](https://github.com/McCLIM/McCLIM) was created as a community
project.

Which one to use depends on your goals. If you need a version of CLIM
with an unencumbered license, then Franz CLIM is your only
choice. It's also good if you want to understand the original intent
of the lisp vendors when implementing CLIM. If you are able to use
encumbered licenses (i.e. GPL) in your project, you'll find McCLIM to
have a more active community, and better cross platform support.

Issues
------

Please report issues on github. The [old issue
tracker](https://gitlab.common-lisp.net/mcclim/gramps-clim2/-/issues)
has a few issues that were not carried over in the move to github;
look there first, as some have descriptions of the problem.

Running the software
--------------------

To manage dependencies `clim` uses ASDF system definitions and
Quicklisp. To use the software clone its source code to
`~/quicklisp/local-projects` and call:

    (ql:quickload 'clim/all)
    (clim-demo:start-demo)

Development status
------------------

Currently software has a few problems which may result in application
crashes. It is not completely stable, and runs on SBCL and CCL with an
X11 server backend. Some of the issues seem related to CLX. The
original Franz implementation is designed to work with Franz CLX,
whereas this fork uses the [cross platform
CLX](https://github.com/sharplispers/clx).

Project goals are to make it work reliably on conforming Common Lisp
implementations which feature Gray Streams and MOP extensions.
