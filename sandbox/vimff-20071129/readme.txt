20070810 larry
vimff -- vim form feeder

quick usage:

  optional install:
  0) mkdir ~/.vimff  && cp vimff/*.pl ~/.vimff

  1) start two terminals a, b.
  2) on terminal-a run $ sbcl < example.lisp
  3) on terminal-b run $ vim -u vimrc example.lisp
  4) place the cursor on the format line, press 'e'
     this should execute an one-liner.
     An one-liner is if the cursor line has equal number of parens.

  5) place the cursor on the empty line below the defun
     or the last line of the defun. Press 'e'
     This should replace the curent defun in place.

  Before executing an defun or one-liner the script will
  search upwards after an IN-PACKAGE form, and execute
  that first of all.
  This has the side-effect of replacing the CURRENT-PACKAGE.

vim rc modifications:

  These are my vimrc mappings (for now :)

  e     in normal-mode will send form or oneliner to lisp
  <F12> will start lisp in a new tab. Too bad ":shell" doesn't
        behave like vim so you can't tab back. Useless for now.
  gf    in normal-mode will open the file where the lisp
        function is defined (DEFUN)
  gh    Calls ~/.vimff/vimff-help.pl for symbol help, for now
        that script is a stub.
  t     Next tab
  <C-t> Previous tab
  <tab> Calls ~/.vimff/vimff-comp.pl for symbol completion.

When it doesn't work:
  If nothing happens when pressing 'e', try placing the cursor
  under an form and press : in vi, this enters command mode
  and there type ":call Perly()".
  If this works, then the mapping of 'e' isn't working.
  Make sure the line "map e :call Perly()" in vimrc
  ends with an ^M. This character is produced in vi by pressing
  ctrl-v followed by ctrl-m.
  It can also end with '<CR>'.


