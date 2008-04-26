=======================================
  Lim: Reinventing the Square Wheel
=======================================
Pre-packaged & welded-together collection of Vim plugins working together for your Lispy desires!  It defaults to `Steel Bank Common Lisp (SBCL) <http://www.sbcl.org>`_.  It is based on ViLisp and other great Vim plugins, and is an attempt at forming a usable Lisp environment for Vim users.

.. While you can't have lengthy conversations with SWANK (yet...), what you *can* do is send code to your Lisp, ask the HyperSpec for documentation, and on top of that, fairly sane bracket-behaviour.

Table of Contents
==================
.. image:: /static/hacking/lim/square-wheel.jpg
   :class: rightalignplain

.. contents::

Features
=========
* Boot/attach/detach a Lisp directly from Vim, or using a script
* Automatic brackets closing
* Form highlighting
* HyperSpec documentation lookup and name completion

Quickstart
============
First, follow the instructions for installing Lim.

.. figure:: /static/hacking/lim/docs/screenshots/disconnected.png

   Vim started with a simple hello-world program.

.. figure:: /static/hacking/lim/docs/screenshots/connecting.png

   Press ``<F12>`` to start a new Lisp.

.. figure:: /static/hacking/lim/docs/screenshots/listener.png

   Press ``<F12>`` again to go to the listener.

.. figure:: /static/hacking/lim/docs/screenshots/sending-code.png

   Press  ``<F12>`` to return to Vim.

   Move the cursor somewhere inside the form and press ``\et`` *(Evaluate Top
   form)*. The function definition will be sent to the running Lisp.

.. figure:: /static/hacking/lim/docs/screenshots/listener-with-defun.png

   Looking at the listener, you see that the code you just sent has been
   compiled.

.. figure:: /static/hacking/lim/docs/screenshots/highlighting-current-form.png

   Let's add more code inside the function definition.  With the cursor
   in the middle of the newly added form, you can now press ``\ec`` *(Evaluate
   Current form)* to send only what's currently highlighted.

.. figure:: /static/hacking/lim/docs/screenshots/evaluating-current-form.png

   And here you can see the results.

.. figure:: /static/hacking/lim/docs/screenshots/evaluate-prompt.png

   We can also evaluate arbitrary expressions, such as looking at a symbol,
   using ``\ex`` *(Evaluate eXpression)* and typing something at the prompt,
   followed by enter to send it.

.. figure:: /static/hacking/lim/docs/screenshots/expression-sent.png

   Yes, it is indeed a symbol.

.. figure:: /static/hacking/lim/docs/screenshots/defun-with-documentation.png

   Let's remove that extra line of code in the function, and add a docstring
   describing the function. Send the definition to Lisp with ``\et``.

.. figure:: /static/hacking/lim/docs/screenshots/describe-symbol.png

   With the cursor on the word ``say-hello``, we now press ``\hd`` *(Help
   Describe)* to get detailed information from Lisp about the symbol.

.. figure:: /static/hacking/lim/docs/screenshots/describe-results.png

   This is what our Lisp believes ``SAY-HELLO`` to be.

.. figure:: /static/hacking/lim/docs/screenshots/listing-lisps.png

   If we exit Vim, our Lisp is still active. You can attach from it directly from the command line,
   or from another Vim session.

Usage
=======

Documentation Lookup
~~~~~~~~~~~~~~~~~~~~
Example 1::

    (defun fib (n)
    ;   ^ cursor here
      (cond ((or (= n 0)
                 (= n 1)) 1)
            (t (+ (fib (- n 1))
               (fib (- n 2))))))

With the cursor at the indicated spot, "K" (see below) will invoke your
browser with file://localhost/path/to/hyperspec/Body/m_defun.htm#defun. This
may require some configuration of a Perl script, lim-hyperspec.pl.  See
below.

Example 2::

    with-
    ; ^ cursor here

With the cursor at the indicated spot, "\hp" (see below) will invoke your
browser with the address of a freshly built index of links to::

    with-accessors
    with-compilation-unit
    with-condition-restarts
    with-hash-table-iterator
    with-input-from-string
    with-open-file
    with-open-stream
    with-output-to-string
    with-package-iterator
    with-simple-restart
    with-slots
    with-standard-io-syntax


Configuration
--------------
Lim uses a Perl script, ``lim/bin/lim-hyperspec.pl``, for invoking a browser with the documentation.
I use Opera (www.opera.com), so Lim comes comes pre-configured to use
it.  I've done some testing with Lynx and Netscape, so uncomment those lines to
try those browsers.  I haven't gotten Konqueror to work to my satisfaction; if
you do, please drop me
an e-mail.

There are a few configuration parameters you can set in the file to modify the
default browser and such.

$BASE
  Where you keep your copy of the HyperSpec.
  Defaults to /usr/share/doc/hyperspec.

$browser_name
  The name of your browser, assumed findable via your $PATH.  Defaults to
  "opera".

$external
  Will your browser open a new window (e.g. set to 0 to use lynx).  Defaults to 1.

@browser_args
  Array of string arguments to your browser.
  Opera's "new-page" argument to openURL gives
  each set of HyperSpec search results a new
  page. Other browsers may have analogous flags, and
  similar behavior. 

  ``lim-hyperspec.pl`` replaces %s in
  @browser_args with the URL to be opened.  See
  the Opera configuration for an example.

$READLINE_ON_BROWSER_START
  Whether to make you press enter when it starts a browser for the first time.
  Defaults to 0 (i.e. no).

The script requires you to have a local copy of the HyperSpec.  It searches
``$BASE/Front/X_Perm_*.htm`` to find the symbols you want it to look for.  You can
find a tarball of the CLHS at http://www.xanalys.com.  If you use Debian or a derivative, such as Ubuntu,
``apt-get install hyperspec`` will put the HyperSpec in
``/usr/share/doc/hyperspec``.  lim-hyperspec.pl looks for it there, by default.

Completion
~~~~~~~~~~~~~~~~~~~
Name Completion
-----------------
Lim can complete the names of symbols. They tend to be rather long, so it's a useful thing.

.. figure:: /static/hacking/lim/docs/screenshots/name-completion.png

   First, type this in Vim...

.. figure:: /static/hacking/lim/docs/screenshots/name-completion-popup.png

   Then, hitting ^N (Ctrl-N) will expand ``least-`` into
   ``least-negative-long-float`` first, then (with another ^N)
   ``least-positive-long-float``, then ``least-negative-short-float``, and so on.


Name Expansion
---------------
There's a convention to talk about dashed names by abbreviating them into the first letter of each word, e.g.:

.. figure:: /static/hacking/lim/docs/screenshots/name-expansion.png
   
   First, type this in Vim...

.. figure:: /static/hacking/lim/docs/screenshots/name-expansion-popup.png

   Then, hitting ^N^N (Ctrl-N twice) will expand the ``p-n``
   to ``package-name``.  ^N again will replace ``package-name`` with ``pathname-name``,
   and ^N yet again will replace that with ``pprint-newline``.  See Vim help for 
   ``complete``, ``compl-generic``, and ``i_CTRL-X_CTRL-T``.  Also, see below for notes on
   this facility.

Notes
-----
* Due to the way the Vim thesaurus works, you have to press ^N (Ctrl-N) twice
  to get the first replacement for abbreviations like w-a => with-accessors,
  but only once after that.  For Vim to know to expand w-a into
  with-accessors, I have to include w-a in the thesaurus file, so w-a expands
  first into just w-a, *then* with-accessors.  See the lisp-thesaurus file and
  "help i_CTRL-X_CTRL-T".
* For the multi-word symbols beginning with * and & (e.g. &allow-other-keys),
  you can expand on an abbreviation with or without the leading special
  character (e.g. a-o-k and &a-o-k both expand into &allow-other-keys (if
  you've set iskeyword correctly -- see above)).
* lisp-thesaurus sorts keywords by length, and then alphabetically.  This
  mostly matters when expanding ambiguous abbreviations for multi-word
  symbols.  E.g., c-i expands into char-int, then count-if (which both have
  eight characters), then clear-input (which comes before count-if
  alphabetically, but has eleven characters).
* I generated lisp-thesaurus from the HyperSpec with make-lisp-thes.pl.
  Figuring it out is left as an exercise to the reader.

Finally, you should install `SuperTab <http://www.vim.org/scripts/script.php?script_id=1643>`_ and and use
that instead of the default keys used for completion!

Keyboard Reference
~~~~~~~~~~~~~~~~~~~~~
The default settings in Lim.

``<F12>``
  Start a new Lisp or connect to an existing instance. When connected, the key
  will toggle displaying the Lisp or Vim.
``<Control-F12>``
  Disconnect from the current Lisp, which will be active in the background.
  You can re-attach to it using ``<F12>``.

The rest of the bindings assumes ``<Leader>`` == "\\", which is the default.
Some people prefer ``set mapleader = ","``.

Lisp Interaction
-----------------

For sending code to a Lisp.

* ``\ec``: *(Evaluate Current)*: Evaluate the current form
* ``\et``: *(Evaluate current Top level form)*: Evaluate the currrent form to the top level
* ``\ex``: *(Evaluate eXpression)*: Prompt for arbitrary expression to evaluate
* ``\eb/ec/et``: *(Evaluate currently selected Block)*: Evaluate the currently visual block
* ``\lf``: *(Load File)*: Load the current file in Lisp
* ``\la``: *(Load Any file)*: Load any version (.lisp, .fasl, ...) of this file
* ``\cf``: *(Compile File)*: Compile the current file
* ``\cl``: *(Compile and Load)*: Compile current file and load
* ``\ar``: *(Abort Reset)*: Send ``ABORT`` to Lisp
* ``\aq``: *(Abort Quit)*: Tell Lisp (SBCL, really) to quit 
* ``\ai`` :*(Abort Interrupt)*: Send C-c to Lisp

S-Exp Manipulation
------------------
Source transformation.

* ``\mt``: *(Mark Top)*: Mark the current form to the top level
* ``\fc``: *(Format Current)*: Reindent/format current form
* ``\ft``: *(Format current Top level form)*: Reindent/format current form to the top level 
* ``\sw``: *(S-exp Wrap)*: Wrap the current form inside another list
* ``\sp``: *(S-exp Peel)*: Peel off a list around the current s-exp
* ``\cc`` :*(S-exp Comment)*: Comment current form

Lim
----
Vim interaction.

* ``\gt``: *(Goto Test)*: Goto the test buffer
* ``\gs``: *(Goto Scratch)*: Goto the scratch buffer (where the latest evaluated form is)
* ``\gl``: *(Goto Last)*: Goto the last buffer
* ``\tc``: *(Test Current)*: Send current form to test buffer
* ``\tt``: *(Test Top)*: Send top-level form to test buffer

Documentation
--------------
Looks things up in the HyperSpec, by opening a browser pointing to a local copy of the HyperSpec.

* ``\hd``: *(Help Describe)*: Describe the current symbol in the Lisp listener
* ``\he``: *(Help Exact)*: Lookup exact symbol
* ``\hp``: *(Help Prefix)*: Lookup symbol as prefix
* ``\hs``: *(Help Prefix)*: Lookup symbol as suffix
* ``\hg``: *(Help Grep)*: Lookup symbol by greping through all symbols
* ``\hi``: *(Help Index)*: Go the the index page of the first letter of the current word.  E.g., if you have the cursor on "member" and type \hi, takes you to the Permuted Symbol Index (M) page.
* ``\hI``: *(Help Index page)*: Takes you to the Alphabetical Symbol Index & Permuted Symbol Index page.

Moreover, ``K`` works as expected, doing an exact matching.

Brackets
----------
When typing an opening bracket, paren or double-quote, it automatically adds the closing
bracket. You can now either type the closing symbol yourself or skip it
altogether.  Backspacing over it removes the pair.

Installation
============
I'm going to assume Lim will be installed /usr/local/lim-x.y, but you can place it wherever you want to. 
The name of the directory isn't important either, as long as ``$LIMRUNTIME`` is properly set.

Step-by-step instructions::

  cd /usr/local
  tar /path/to/lim-x.y.tar.gz
  ln -sf /usr/local/lim-x.y/vim $HOME/.vim/lim
  ln -sf ../lim/lim.vim $HOME/.vim/plugin/lim.vim
  ln -sf ../lim/desert256.vim $HOME/.vim/colors/desert256.vim

Lim relies on the variable ``$LIMRUNTIME`` pointing to the base directory, so add this to your ``~/.bashrc``::

  export LIMRUNTIME=/usr/local/lim-x.y

The following step is not required for using Lim with Vim, but if you're planning on using the command line tool, make a symlink like this::

  ln -sf $LIMRUNTIME/bin/lisp.sh /usr/local/bin


Changelog
=========
Version 0.2.2
~~~~~~~~~~~~~
* 2008-04-26 by Mikael Jansson <mail@mikael.jansson.be>

  + Typo in HyperSpec lookup code
  + Updated documentation

Version 0.2.1
~~~~~~~~~~~~~
* 2008-04-26 by Mikael Jansson <mail@mikael.jansson.be>

  + Fixed copy-paste typo for 'Goto Last'
  + Better connection status information


Version 0.2
~~~~~~~~~~~
* 2008-04-25 by Mikael Jansson <mail@mikael.jansson.be>

  Replaced the Perl funnel betwen Vim and Lisp with screen.

Version 0.1
~~~~~~~~~~~
* 2008-04-21 by Mikael Jansson <mail@mikael.jansson.be> 

  Internal release

Known Issues
============
* When the Lisp disappears, no warning is given when trying to send code to it. When that happens,
  disconnect (``<Control-F12>``) and reconnect.

Includes Work By...
====================
Larry Clapp
  Without his hard work on `VIlisp <http://www.vim.org/scripts/script.php?script_id=221>`_, this would never have happened.

Karl Guertin
  For `AutoClose <http://www.vim.org/scripts/script.php?script_id=1849>`_.
  Small patch applied to enable/disable instead of toggling.

Charles E. Campbell, Jr.
  For `HiMtchBrkt <http://www.vim.org/scripts/script.php?script_id=1435>`_.
  Modified to highlight the contents inside the brackets, removed Vim (<7.x)
  backward compatibility.

