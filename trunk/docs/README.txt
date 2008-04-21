=======================================
  Lim: Reinventing the Square Wheel
=======================================

.. image:: /static/hacking/lim/square-wheel.jpg

Pre-packaged & welded-together collection of Vim plugins working together for your Lispy desires!

Download
========
The latest version of Lim is `Lim v0.1 (lim-0.1.tar.gz) </static/hacking/lim/lim-0.1.tar.gz>`_ (2008-04-21).

Installation
============
#. Unpack ``lim-0.1.tar.gz`` where you want to have it; suggested location is ``~/.vim``.
#. Symlink or copy lim-0.1/vim to ``~/.vim/lim``
#. Symlink or copy ``lim-0.1/bin/lisp.sh`` and ``.../vim-to-lisp-funnel.pl`` to a directory of your liking, and change the path to ``vim-to-lisp-funnel.pl`` in ``lisp.sh``.

Usage
=====
After installation, run ``lisp.sh`` in a terminal::

  $ lisp.sh test
  *** Lisp listener at /home/mikael/.lim_bridge_channel-test

  This is SBCL 1.0, an implementation of ANSI Common Lisp.
  More information about SBCL is available at <http://www.sbcl.org/>.

  SBCL is free software, provided as is, with absolutely no warranty.
  It is mostly in the public domain; some portions are provided under
  BSD-style licenses.  See the CREDITS and COPYING files in the
  distribution for more information.
  CL-USER(1): 

Then, open a .lisp file in Vim and hit ``<F10>``. You'll be asked about the name
of the Lisp you want to connect to. Press ``<Tab>`` to have Vim fill in the one
you just started, then press ``<Enter>``.

You are now communicating with Lisp, through Vim.

Key Mappings
~~~~~~~~~~~~
In order to do anything useful, i.e. talk to your Lisp, you need to know how.
Here's a list of mappings for doing that.

* ``<F10>``

  To do anything useful at all you have to connect to your Lisp.  You'll be
  asked to enter the full name of the running Lisp.  This is where your Lisp code
  is sent.

* ``<Leader>lms``:   99[(V%
* ``<Leader>lfc``:   [(=%`'
* ``<Leader>lft``:   99<Leader>fc
* ``<Leader>llw``:   :call Cursor_push()<CR>[(%a)<ESC>h%i(<ESC>:call Cursor_pop()<CR>
* ``<Leader>llp``:   :call :call Cursor_push()<CR>[(:call Cursor_push()<CR>%x:call Cursor_pop()<CR>x:call Cursor_pop()<CR>
* ``<Leader>lcc``:   :call Cursor_push()<CR>[(%a\|#<ESC>hh%i#\|<ESC>:call Cursor_pop()<CR>
* ``<Leader>let``:   :call LimBridge_eval_top_form()<CR>
* ``<Leader>lec``:   :call LimBridge_eval_current_form()<CR>
* ``<Leader>lex``:   :call LimBridge_prompt_eval_expression()<CR>
* ``<Leader>leb``:  :call LimBridge_eval_block()<cr>
* ``<Leader>let``:  <Leader>leb
* ``<Leader>lec``:  <Leader>leb
* ``<Leader>lar``:   :call LimBridge_send_to_lisp( "ABORT\n" )<CR>
* ``<Leader>laq``:   :call LimBridge_send_to_lisp( "(sb-ext:quit)\n" )<CR>
* ``<Leader>lai``:  :call LimBridge_send_to_lisp( "

AutoClose
~~~~~~~~~
When typing an opening bracket or paren, it automatically adds the closing
bracket. You can now either type the closing bracket yourself or skip it
altogether.  Also works for quote and double-quote. For more information, `see
the AutoClose documentation
<http://www.vim.org/scripts/script.php?script_id=1849>`_.


Credits
=======
Larry Clapp
  Without his hard work on VIlisp, this would never have happened. Now that he
  has stopped working on VIlisp and SLIM-Vim, I've done some minor polishing on it

Karl Guertin
  For `AutoClose <http://www.vim.org/scripts/script.php?script_id=1849>`_.
  Small patch applied to enable/disable instead of toggling.

Charles E. Campbell, Jr.
  For `HiMtchBrkt <http://www.vim.org/scripts/script.php?script_id=1435>`_.
  Modified to highlight the contents inside the brackets, removed Vim
  backward-compatibility (<7.00) code.

Changelog
=========
Version 0.1
~~~~~~~~~~~
* 2008-04-21 -- Mikael Jansson <mail@mikael.jansson.be>
 
  Initial version 
  

