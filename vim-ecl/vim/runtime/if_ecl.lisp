; vim:ts=8

(in-package :vim)

(shadow '(append funcall setq search map close))

(export
  '(; These functions are implemented in if_ecl.c and probably use "internal"
    ; data structures.
    cmd expr
    windows current-window window-width window-height window-column window-cursor window-buffer
    buffers current-buffer buffer-line-count buffer-lines buffer-name
    replace-lines append-line-to-buffer append-to-buffer
    eval-range

    ; Use or return "internal" data structures.
    find-buffer get-line

    ; Wrapped Vim functions
    append argc argidx argv browse bifexists buflisted bufloaded bufname bufnr
    bufwinnr num-buffers bufinnr byte2line char2nr cindent col confirm
    cursor
    expand
    getcwd
    getline
    getwinposx getwinposy
    input
    line
    lispindent
    maparg
    search
    setline
    virtcol
    winbufnr wincol winheight winline winnr
    winwidth
    tabpagebuflist tabpagenr

    ; Other wrapped Vim functionality.
    execute normal normal!
    map map! unmap unmap!
    wincmd
    close close!

    ; Utility functions
    funcall setq var
    change-to-buffer
    open-buffer
    get-pos goto-pos
    kill
    point bufnr-of line-of col-of virtcol-of winline-of
    scroll-window position-window
    append-text-to-buffer multi-line-map append-multi-line-string
    num-windows

    ; Macros
    get-pos-after with-buffer with-options with-window with-window-of
    ))

(defun build-command (args)
  (apply #'concatenate 'string
	 (mapcar (lambda (arg)
		   (etypecase arg
		     (null "")
		     (character (string arg))
		     (string arg)
		     (number (princ-to-string arg))))
		 args)))

(defun cmd (&rest args)
  "Executes an ex command, e.g. \"w\" or \"help ecl\".
  Accepts strings, characters, and NIL.  All are concatenated into a single
  string to pass to Vim.  Characters are converted to strings, NIL is
  converted to \"\".
  NOTE: This is exactly the same as typing in the command at the Vim colon-prompt.  If
  you want \":exec ...\", use vim:execute.  vim:cmd does NOT allow use of <>
  notation, whereas vim:execute does."
  ; (format t "cmd is ~S~%" (build-command args))
  (execute-int (build-command args)))

(defun execute (&rest args)
  (cmd "exec \"" (build-command args) "\""))

(defun expr (str)
  "Evaluates a Vim expression; returns the result as a string, or NIL"
  (check-type str string)
  (expr-int str))

; Really need to change this to a "deftype" or something and use "check-type".
(defun validate-window (w)
  (unless (and w (eq (si:foreign-data-tag w) 'vim::window))
    (error "~S is not a valid Vim window" w)))

(defun windows ()
  "Returns a list of Vim's windows in the current tab."
  (windows-int))

(defun current-window ()
  "Returns the current window"
  (current-window-int))

(defun window-width (&optional (window (current-window)))
  "returns the width of a window (defaults to (current-window))"
  (validate-window window)
  (window-width-int window))

(defun window-height (&optional (window (current-window)))
  "returns the height of a window (defaults to (current-window))"
  (validate-window window)
  (window-height-int window))

(defun window-column (&optional (window (current-window)))
  "returns the leftmost column of the window on the screen"
  (validate-window window)
  (window-column-int window))

(defun window-cursor (&optional (window (current-window)))
  "returns the cursor of a window (defaults to (current-window)) cursors
  are (lnum . col) cons cells"
  (validate-window window)
  (window-cursor-int window))

(defun window-buffer (&optional (window (current-window)))
  "returns the buffer of a window (defaults to (current-window))"
  (validate-window window)
  (window-buffer-int window))

(defun buffers ()
  "returns a list of vim's buffers"
  (buffers-int))

(defun current-buffer ()
  "returns the current buffer"
  (current-buffer-int))

; Really need to change this to a "deftype" or something and use "check-type".
(defun validate-buffer (buffer)
  (unless (and buffer
	       (eq (si:foreign-data-tag buffer) 'vim::buffer))
    (error "~S is not a valid Vim buffer" buffer)))

(defun buffer-line-count (&optional (buffer (current-buffer)))
  "returns the line count of a buffer (defaults to (current-buffer))"
  (validate-buffer buffer)
  (buffer-line-count-int buffer))

(defun validate-line-num (line-num buffer &optional (num-lines (vim:buffer-line-count buffer)))
  "Valide that line-num < # lines in buffer.
  Assumes that buffer is a valid Vim buffer.
  If you supply num-lines it must equal (vim:buffer-line-count buffer)."
  (unless (and line-num
	       (typep line-num 'fixnum)
	       (<= 0 line-num num-lines))
    (error "~D is out of range; there are only ~D lines in ~S" line-num num-lines buffer)))

(defmacro validate-buffer-start-end (buffer start end)
  `(progn
     (validate-buffer ,buffer)
     (validate-line-num ,start ,buffer)
     (let ((num-lines (vim:buffer-line-count ,buffer)))
       (if ,end
	 (validate-line-num ,end ,buffer num-lines)
	 (setf ,end num-lines)))))

(defun buffer-lines (&key (buffer (vim:current-buffer))
			  (start 0) end)
  "returns the lines from :start to :end in :buffer
  (defaults to (current-buffer))
  :start and :end are in the range 0..(buffer-line-count)
  :start is inclusive, :end is excluded
  If (= start end), the return will be NIL
  To print a single line :start n :end n+1"
  (validate-buffer-start-end buffer start end)
  (buffer-lines-int buffer start end))

(defun buffer-name (&key (buffer (vim:current-buffer)))
  (validate-buffer buffer)
  (buffer-name-int buffer))

(defun find-buffer (name)
  (find-if
    (lambda (b)
      (let ((b-name (vim:buffer-name :buffer b)))
	(if b-name
	  (string= name b-name)
	  (eql name nil))))
    (vim:buffers)))

(defun replace-lines (lines &key (start 0) end (buffer (vim:current-buffer)))
  "replaces the lines from :start to :end in :buffer with the given list of strings
  :start and :end are in the range 0..(buffer-line-count)
  :start is inclusive, :end is excluded
  If :start == :end, then you insert a new line before :start
  To insert a new line at the very beginning of a buffer, :start = :end = 0"
  (validate-buffer-start-end buffer start end)
  (replace-lines-int buffer lines start end
                     0 (length lines)))

(defun get-line (&optional (line (car (window-cursor)))
			       (buffer (vim:current-buffer)))
  "gets a line from a buffer"
  (first (vim:buffer-lines :buffer buffer :start line :end (1+ line))))

(defun append-line-to-buffer (string &key (buffer (vim:current-buffer)))
  (validate-buffer buffer)
  (let ((end-line (vim:buffer-line-count buffer)))
    (replace-lines (list string) :buffer buffer :start end-line :end end-line)))

(defun append-to-buffer (string &key (buffer (vim:current-buffer)))
  (validate-buffer buffer)
  (let* ((end-line (1- (vim:buffer-line-count buffer)))
         (existing (get-line end-line buffer)))
    (replace-lines (list (concatenate 'string existing string)) :buffer buffer :start end-line :end (1+ end-line))))

(defun eval-range ()
  "called when the :ecl command is issued without an argument"
  (with-input-from-string (s (format nil
                                     "~{~a~%~}"
                                     (vim:buffer-lines :buffer (vim:current-buffer)
						       :start (car vim:range)
						       :end (1+ (cdr vim:range)))))
    (loop for form = (read s nil nil)
          while form
          do (eval form))))

(defparameter *returns-integer* (make-hash-table :test #'equal)
  "Stores the Vim functions that return integers, so vim:funcall can parse the
string returned from Vim, if appropriate.")

(defun returns-integer (f)
  (setf (gethash f *returns-integer*) t))

(defun returns-integer-p (f)
  (gethash f *returns-integer*))

(mapcar #'returns-integer
  '("append" "argc" "argidx" "bufexists" "buflisted" "bufloaded" "bufnr"
    "bufwinnr" "byte2line" "char2nr" "cindent" "col" "confirm"
    "cscope_connection" "cursor" "delete" "did_filetype" "eventhandler"
    "executable" "exists" "filereadable" "filewritable" "foldclosed"
    "foldclosedend" "foldlevel" "foreground" "getchar" "getcharmod"
    "getcmdpos" "getfsize" "getftime" "getwinposx" "getwinposy" "has"
    "hasmapto" "histnr" "hlexists" "hlID" "indent" "inputrestore" "inputsave"
    "isdirectory" "libcallnr" "line" "line2byte" "lispindent" "localtime"
    "match" "matchend" "nextnonblank" "prevnonblank" "remote_foreground"
    "remote_peek" "rename" "search" "searchpair" "server2client" "setcmdpos"
    "setline" "setreg" "stridx" "strlen" "strridx" "synID" "synIDtrans" "type"
    "virtcol" "winbufnr" "wincol" "winheight" "winline" "winnr" "winwidth"))

(defun build-vim-funcall (function-name args)
  (with-output-to-string (s)
    (princ function-name s)
    (princ "(" s)
    (loop for (arg . rest) on (remove nil args)
	  if arg do (prin1 arg s)
	  if rest do (princ "," s))
    (princ ")" s)))

(defun vim:funcall (function-name &rest args)
  (assert (typep function-name 'string)
	  (function-name)
	  "vim:funcall expects a string, not ~S"
	  function-name)
  (let ((result (vim:expr (build-vim-funcall function-name args))))
    (if (and (typep result 'string)
	     (gethash function-name *returns-integer*))
      (parse-integer result)
      result)))

;;; ######################################################################
;;; Vim FFI
;;; ######################################################################

(defmacro def-vim-function (name args arg-xlate-functions result-xlat-function
				 &optional documentation)
  (unless (and (typep args 'list)
	       (typep arg-xlate-functions 'list))
    (error
      "In def-vim-function of ~S, args and arg-xlate-functions must both be lists, not ~S and ~S."
      name args arg-xlate-functions))
  (flet ((lambda-list-keyword-p (x) (and (atom x)
					 (eql #\& (char (string x) 0))))
	 (apply-xlat-function (f arg)
	   (when (listp arg) (setf arg (car arg)))
	   (if (eq f 't)
	     arg
	     (if (atom f)
	       (list f arg)
	       f))))
    (let* ((parsed-args
	     (loop for item in args
		   if (listp item) collect (car item)
		   else unless (lambda-list-keyword-p item) collect item))
	   (xlated-args (loop for f in arg-xlate-functions
			      for arg in parsed-args
			      if f collect (apply-xlat-function f arg)))
	   (funcall-expression `(vim:funcall ,name ,@xlated-args)))
      `(defun ,(intern (string-upcase name) :vim) ,args
	 ,documentation
	 ,(if (eq 't result-xlat-function)
	    funcall-expression
	    (if (atom result-xlat-function)
	      `(,result-xlat-function ,funcall-expression)
	      `(let ((result ,funcall-expression))
		 ,result-xlat-function)))))))

(defun string-or-number (lnum)
  (etypecase lnum
    (string lnum)
    (number (1+ lnum))))

(defun t-or-number (expr)
  (if (eql expr t)
    0
    (1+ expr)))

(defun t-string-or-number (expr)
  (if (eql expr t)
    0
    (string-or-number expr)))

(defun nil-or-number (expr)
  (if expr (1+ expr) 0))

(defun result-number-or-nil (result)
  (if (plusp result) (1- result) nil))

(defun result-nil-or-string (result)
  (if (string= result "") nil result))

(defun join-with-newlines (list)
  (apply #'concatenate 'string
	 (loop for (item . rest) on list
	       collect item
	       if rest collect (string #\Newline))))

(def-vim-function "append" (lnum string) (nil-or-number t) t)
(def-vim-function "argc" () () t)
(def-vim-function "argidx" () () t)
(def-vim-function "argv" (n) (t) t)
(def-vim-function "browse" (save title initdir default) ((if save 1 0) t t t) t)
(def-vim-function "bufexists" (expr) (t-string-or-number) plusp
  "Use T to find out about the alternate file name.")
(def-vim-function "buflisted" (expr) (t-string-or-number) plusp
  "Use T to find out about the alternate file name.")
(def-vim-function "bufloaded" (expr) (t-string-or-number) plusp
  "Use T to find out about the alternate file name.")
(def-vim-function "bufname" (expr) (t-string-or-number) t
  "Use T to find out about the alternate file name.")

(def-vim-function "bufnr" (&optional (expr ".")) (t-string-or-number) result-number-or-nil)
(defun num-buffers () (1+ (vim:bufnr "$")))

(def-vim-function "bufwinnr" (expr) (t-string-or-number) result-number-or-nil)

(def-vim-function "byte2line" (byte-count) (1+) 1-)
(def-vim-function "char2nr" (expr) (t) t)
(def-vim-function "cindent" (lnum) (string-or-number) 1-)
(def-vim-function "col" (expr) (t) 1-)

(def-vim-function "confirm" (msg &optional (choices "&Ok") (default 0) (type "Generic"))
  (join-with-newlines
   join-with-newlines
   (if default (1+ default) 0)
   nil)
  result-number-or-nil
  "For MSG and CHOICES, give lists of strings instead of single strings.")

(def-vim-function "cursor" (lnum col) (nil-or-number nil-or-number) 't
  "position cursor at {lnum}, {col}; returns T")

; delete( {fname})		Number	delete file {fname}
; did_filetype()		Number	TRUE if FileType autocommand event used
; escape( {string}, {chars})	String	escape {chars} in {string} with '\'
; eventhandler( )		Number  TRUE if inside an event handler
; executable( {expr})		Number	1 if executable {expr} exists
; exists( {expr})		Number	TRUE if {expr} exists

(def-vim-function "expand" (expr &optional flag) (t (if flag 1 0)) t
  "Use t/nil for the flag.")

; filereadable( {file})		Number	TRUE if {file} is a readable file
; filewritable( {file})		Number	TRUE if {file} is a writable file
; fnamemodify( {fname}, {mods})	String	modify file name
; foldclosed( {lnum})		Number  first line of fold at {lnum} if closed
; foldclosedend( {lnum})	Number  last line of fold at {lnum} if closed
; foldlevel( {lnum})		Number	fold level at {lnum}
; foldtext( )			String  line displayed for closed fold
; foreground( )			Number	bring the Vim window to the foreground
; getchar( [expr])		Number  get one character from the user
; getcharmod( )			Number  modifiers for the last typed character
; getbufvar( {expr}, {varname})		variable {varname} in buffer {expr}
; getcmdline()			String	return the current command-line
; getcmdpos()			Number	return cursor position in command-line

(def-vim-function "getcwd" () () t)

; getfsize( {fname})		Number	size in bytes of file
; getftime( {fname})		Number	last modification time of file

(def-vim-function "getline" (lnum) (string-or-number) t
  "line {lnum} from current buffer")

; getreg( [{regname}])		String  contents of register
; getregtype( [{regname}])	String  type of register

(def-vim-function "getwinposx" () () result-number-or-nil
  "X coord in pixels of GUI Vim window")
(def-vim-function "getwinposy" () () result-number-or-nil
  "Y coord in pixels of GUI Vim window")

; getwinvar( {nr}, {varname})		variable {varname} in window {nr}
; glob( {expr})			String	expand file wildcards in {expr}
; globpath( {path}, {expr})	String	do glob({expr}) for all dirs in {path}
; has( {feature})			Number	TRUE if feature {feature} supported
; hasmapto( {what} [, {mode}])	Number	TRUE if mapping to {what} exists
; histadd( {history},{item})	String	add an item to a history
; histdel( {history} [, {item}])	String	remove an item from a history
; histget( {history} [, {index}])	String	get the item {index} from a history
; histnr( {history})		Number	highest index of a history
; hlexists( {name})		Number	TRUE if highlight group {name} exists
; hlID( {name})			Number	syntax ID of highlight group {name}
; hostname()			String	name of the machine Vim is running on
; iconv( {expr}, {from}, {to})	String  convert encoding of {expr}
; indent( {lnum})		Number  indent of line {lnum}

(def-vim-function "input" (prompt &optional text completion) (t t t) t
  "Get input from the user.")

; inputdialog( {p} [, {t} [, {c}]]) String  		like input() but in a GUI dialog

; inputrestore()		Number  restore typeahead
; inputsave()			Number  save and clear typeahead
; inputsecret( {prompt} [, {text}]) String  like input() but hiding the text
; isdirectory( {directory})	Number	TRUE if {directory} is a directory
; libcall( {lib}, {func}, {arg})	String  call {func} in library {lib} with {arg}
; libcallnr( {lib}, {func}, {arg})  Number  idem, but return a Number

(def-vim-function "line" (expr) (t) result-number-or-nil
  "line nr of cursor, last line, or mark")
(defun num-lines () (1+ (vim:line "$")))

; line2byte( {lnum})		Number	byte count of line {lnum}

(def-vim-function "lispindent" (lnum) (string-or-number) 1-
  "Lisp indent for line {lnum}")

; localtime()			Number	current time

(defparameter *map-modes*
  (let ((h (make-hash-table))
	(modes '((:normal "n")
		 (:visual-select "v")
		 (:visual "x")
		 (:select "s")
		 (:operator-pending "o")
		 (:insert "i")
		 (:command "c")
		 (:lang-arg "l"))))
    (loop for (key val) in modes
	  do (setf (gethash key h) val))
    h)
  "Map keywords to strings for map modes.")

; TODO: maybe a "map-map-modes" function / macro, to make processing map modes easier?

(defun check-map-mode (mode)
  (let ((mode-string (gethash mode *map-modes*)))
    (assert mode-string (mode) "Unknown vim:map mode: ~S; allowed values are ~S"
	    mode (sort (loop for key being the hash-keys of *map-modes*
			     collect key)
		       #'string<))
    mode-string))

(defun vim:maparg (name &key mode abbr)
  (result-nil-or-string
    (vim:funcall "maparg"
		 name
		 (etypecase mode
		   (null "")
		   (string mode)
		   (symbol (check-map-mode mode)))
		 (if abbr 1 0))))

; mapcheck( {name}[, {mode}])	String	check for mappings matching {name}
; match( {expr}, {pat}[, {start}])
; 				Number	position where {pat} matches in {expr}
; matchend( {expr}, {pat}[, {start}])
; 				Number	position where {pat} ends in {expr}
; matchstr( {expr}, {pat}[, {start}])
; 				String	match of {pat} in {expr}
; mode()			String  current editing mode
; nextnonblank( {lnum})		Number	line nr of non-blank line >= {lnum}
; nr2char( {expr})		String	single char with ASCII value {expr}
; prevnonblank( {lnum})		Number	line nr of non-blank line <= {lnum}
; remote_expr( {server}, {string} [, {idvar}])
; 				String	send expression
; remote_foreground( {server})	Number	bring Vim server to the foreground
; remote_peek( {serverid} [, {retvar}])
; 				Number	check for reply string
; remote_read( {serverid})	String	read reply string
; remote_send( {server}, {string} [, {idvar}])
; 				String	send key sequence
; rename( {from}, {to})		Number  rename (move) file from {from} to {to}
; resolve( {filename})		String  get filename a shortcut points to

(defun keywords-to-string (flags meanings)
  (apply #'concatenate 'string
	 (loop for flag in flags
	       collect (cdr (assoc flag meanings)))))

(let* ((aliases '(("b" :backward :b)
		  ("c" :match-at-cursor :c)
		  ("e" :move-to-end :e)
		  (""  :move)
		  ("n" :do-not-move :n)
		  ("p" :count-submatches :p)
		  ("s" :set-tic :s)
		  ("w" :wrap :wl)
		  ("W" :no-wrap :wu)))
       (meanings (loop for record in aliases
		       nconc (loop with string = (car record)
				   for keyword in (cdr record)
				   collect (cons keyword string)))))
  (defun search (pattern &key flags (stopline nil stopline-p))
    (let ((string-flags (keywords-to-string flags meanings)))
      (result-number-or-nil
	(vim:funcall "search" pattern string-flags (when stopline-p 
						     (1+ stopline)))))))

; searchpair( {start}, {middle}, {end} [, {flags} [, {skip}]])
; 				Number  search for other end of start/end pair
; server2client( {clientid}, {string})
; 				Number	send reply string
; serverlist()			String	get a list of available servers
; setbufvar( {expr}, {varname}, {val})	set {varname} in buffer {expr} to {val}
; setcmdpos( {pos})		Number	set cursor position in command-line

(def-vim-function "setline" (lnum line) (string-or-number t) zerop
  "set line {lnum} to {line}")

; setreg( {n}, {v}[, {opt}])	Number  set register to value and type
; setwinvar( {nr}, {varname}, {val})	set {varname} in window {nr} to {val}
; simplify( {filename})		String  simplify filename as much as possible
; strftime( {format}[, {time}])	String	time in specified format
; stridx( {haystack}, {needle})	Number	first index of {needle} in {haystack}
; strlen( {expr})		Number	length of the String {expr}
; strpart( {src}, {start}[, {len}])
; 				String	{len} characters of {src} at {start}
; strridx( {haystack}, {needle})	Number	last index of {needle} in {haystack}
; strtrans( {expr})		String	translate string to make it printable
; submatch( {nr})		String  specific match in ":substitute"
; substitute( {expr}, {pat}, {sub}, {flags})
; 				String	all {pat} in {expr} replaced with {sub}
; synID( {line}, {col}, {trans})	Number	syntax ID at {line} and {col}
; synIDattr( {synID}, {what} [, {mode}])
; 				String	attribute {what} of syntax ID {synID}
; synIDtrans( {synID})		Number	translated syntax ID of {synID}
; system( {expr})		String	output of shell command {expr}

(defun tabpagenr (&optional arg)
  "If no arg given, or NIL given, return the tab page number of the current tab.
  If arg is given, it must string= \"$\", and we return the tab page number of
  the last tab.  (If it doesn't string= \"$\", it's silently ignored.)"
  (1- (vim:funcall "tabpagenr" 
		   (when (and arg (string= arg "$")) 
		     "$"))))

(def-vim-function "tabpagebuflist" (&optional (arg (vim:tabpagenr)))
  (nil-or-number)
  (if (eql result 0)
    (error "~S is not a valid tab page number" arg)
    (mapcar #'1- result)))

; tempname()			String	name for a temporary file
; tolower( {expr})		String	the String {expr} switched to lowercase
; toupper( {expr})		String	the String {expr} switched to uppercase
; type( {name})			Number	type of variable {name}

(def-vim-function "virtcol" (expr) (t) result-number-or-nil
  "screen column of cursor or mark")

; visualmode( [expr])		String	last visual mode used

(def-vim-function "winbufnr" (nr) (nil-or-number) result-number-or-nil
  "buffer number of window {nr}")
(def-vim-function "wincol" () () 1-
  "window column of the cursor")
(def-vim-function "winheight" (nr) (nil-or-number) result-number-or-nil
  "height of window {nr}")
(def-vim-function "winline" () () 1-
  "window line of the cursor")

(def-vim-function "winnr" (&optional arg) (t) 1-
  "number of current window, or (optionally) \"$\" or \"#\".")
(defun num-windows () 
  "Returns the number of open windows in the current tab."
  (1+ (vim:winnr "$")))

; winrestcmd()			String  returns command to restore window sizes

(def-vim-function "winwidth" (nr) (nil-or-number) result-number-or-nil
  "width of window {nr}")

;;; ######################################################################
;;; Various utility functions
;;; ######################################################################
(defmacro with-options (bindings &body body)
  "Set new values to existing Vim options; restores old values at exit.  Works
  with Vim variables, too, as long as they already exist.  If you only list a
  Vim-var, instead of a (var val) pair, the var is set to \"\"."
  (loop with var and val
	for binding in bindings
	for old-var = (gensym "old-var-")
	do (multiple-value-setq (var val)
	     (if (typep binding 'list)
	       (values-list binding)
	       (values binding "")))
	collect `(,old-var (vim:var ,var)) into let-bindings
	collect `(vim:setq ,var ,val) into setup
	collect `(vim:setq ,var ,old-var) into teardown
	finally (return `(let ,let-bindings
			   ,@setup
			   (unwind-protect
			     (progn ,@body)
			     ,@teardown)))))

(defgeneric change-to-buffer (n)
  (:documentation "Changes to the given buffer.  Hides the current buffer."))
(defmethod change-to-buffer ((name string))
  (change-to-buffer (vim:bufnr name)))
(defmethod change-to-buffer ((number number))
  (vim:cmd "silent hide buffer " (1+ number)))

(defgeneric open-buffer (buffer)
  (:documentation "Opens a window on the given buffer."))
(defmethod open-buffer ((number number))
  (vim:cmd "silent vert sb " (1+ number)))
(defmethod open-buffer ((name string))
  (open-buffer (vim:bufnr name)))

(defun vsplit-p ()
  "True of the current tab is vertically split."
  (find-if (lambda (w) (plusp (vim:window-column w)))
	   (vim:windows)))

(defmacro with-buffer (expr &body body)
  `(vim:with-options (("&guioptions"
		       (if (vim::vsplit-p)
			 (vim:var "&guioptions")
			 (remove-if (lambda (o) (find o "LR"))
				    (vim:var "&guioptions")))))
     (unwind-protect
       (progn
	 (vim:open-buffer ,expr)
	 ,@body)
       (vim:close))))

(defun setq (var val)
  (check-type var string)
  (unless (typep val '(or number string))
    (setf val (prin1-to-string val)))
  (vim:cmd (format nil "let ~A = ~S" var val))
  val)

(defun var (var)
  "Get the value of a Vim variable.  If it's a string but looks like a number,
  returned as a number."
  (let ((val (vim:expr var)))
    (if (typep val 'string)
      (let ((length (length val)))
	(multiple-value-bind (n-val pos) (parse-integer val :junk-allowed t)
	  (if (and n-val (= length pos))
	    n-val
	    val)))
      val)))

(defclass point ()
  ((bufnr :initarg :bufnr :accessor bufnr-of)
   (line :initarg :line :accessor line-of)
   (col :initarg :col :accessor col-of)
   (virtcol :initarg :virtcol :accessor virtcol-of)
   (winline :initarg :winline :accessor winline-of)))

(defun get-pos (&optional (where "."))
  "Get the buffer & position of the cursor; returns a POINT class."
  (if (vim:line where)
    (make-instance 'point
      :bufnr (vim:bufnr "%")
      :line (vim:line where)
      :col (vim:col where)
      :virtcol (vim:virtcol where)
      :winline (if (string= where ".") (vim:winline) nil))
    nil))

(defmacro get-pos-after (&body body)
  "Run some code; return the cursor position afterwards."
  `(progn ,@body (get-pos)))

(defun scroll-window (n)
  "Negative means scroll the window down, i.e. scroll the text up, using <c-e>.
  Positive means scroll the window up, i.e. scroll the text down, using <c-y>."
  ;; NOTE: use vim:execute, not vim:cmd, to get interpretation of the <c-e>, etc.
  (cond ((< n 0) (vim:execute (format nil "normal ~D\\<c-e>" (- n))))
	((> n 0) (vim:execute (format nil "normal ~D\\<c-y>" n)))))

(defun position-window (want)
  "Scroll the window such that the current line of text is at the given window line.
  The top line is line 0.  If WANT is NIL, positions the current line in the
  middle of the screen."
  (if want
    (scroll-window (- want (vim:winline)))
    (position-window (truncate vim:winline 2))))

(defgeneric goto-pos (where))
(defmethod goto-pos (where) nil)
(defmethod goto-pos ((where point))
  (with-slots (bufnr line col virtcol winline) where
    (when (/= bufnr (vim:bufnr "%"))
      (change-to-buffer bufnr))
    (vim:cursor line virtcol)
    (position-window winline)))

(defun append-text-to-buffer (line)
  (vim:setline "$" (concatenate 'string (vim:getline "$") line)))

(defun multi-line-map (f text)
  (loop for start = 0 then (1+ end)
	for end = (position #\Newline text :start start)
	for line = (subseq text start end)
	do (cl:funcall f start end line)
	while end))

(defun append-multi-line-string (text)
  (vim:multi-line-map
    (lambda (start end line)
      (if (= start 0)
	(vim:append-text-to-buffer line)
	(vim:append (vim:line "$") line)))
    text))

(defun normal (str &rest rest)
  "Execute a normal-mode Vim command."
  (apply #'vim:cmd "normal " str rest))

(defun normal! (str &rest rest)
  "Execute a normal-mode Vim command w/out remapping."
  (apply #'vim:cmd "normal! " str rest))

(defun resolve-mapleader (lhs)
  "Find any mentions of <leader> in the lhs string and replace it with the
  current value of g:mapleader.  Searches case-insensitively."
  (let* ((mapleader (vim:var "g:mapleader"))
	 (mapleader-string (if (stringp mapleader)
			     mapleader
			     (princ-to-string mapleader))))
    (loop for p = (cl:search "<leader>" lhs :test #'char-equal)
	  while p
	  do (setf lhs (concatenate 'string
				    (subseq lhs 0 p)
				    mapleader-string
				    (subseq lhs (+ p 8))))
	  finally (return lhs))))

(defvar *map-functions* (make-hash-table :test #'equal)
  "Store references to Lisp functions to which we have Vim mappings.")

(defparameter *vim-map-special-flags*
  (let ((h (make-hash-table))
	(flags '((:buffer "<buffer>")
		 (:silent "<silent>")
		 (:special "<special>")
		 (:script "<script>")
		 (:unique "<unique>")
		 (:expr "<expr>"))))
    (loop for (key val) in flags
	  do (setf (gethash key h) val))
    h))

(defun xlat-map-flags (flags)
  "Translate a _list designator_ for Vim mapping flags (e.g. :buffer,
  etc.) into a string with the flags in it (e.g. \"<buffer> \")."
  (labels ((normalize-flags (flags)
	     (etypecase flags
	       (string (list flags))
	       (symbol (list (gethash flags *vim-map-special-flags*)))
	       (list (mapcan #'normalize-flags flags)))))
    (apply #'concatenate 'string
	   (loop for (flag . rest) on (normalize-flags flags)
		 collect flag
		 if rest collect " "))))

(defun normalize-map-modes (modes)
  (labels ((normalize-mode (mode)
	     (etypecase mode
	       (null (list ""))
	       (character (list (string mode)))
	       (string (if (> (length mode) 1)
			 (cl:map 'list #'string mode)
			 (list mode)))
	       (symbol (list (check-map-mode mode)))
	       (list (mapcan #'normalize-mode mode)))))
    (loop for mode in (normalize-mode modes)
	  if (listp mode) nconc mode
	  else collect mode)))

(defun %call-map-function (lhs mode)
  "Call the mapped Lisp function for the given lhs."
  (cl:funcall (gethash (cons lhs mode) *map-functions*)))

(flet ((set-equals (s1 s2)
	 (loop with max-length = (length s2)
	       for item in s1
	       for item-num upfrom 0
	       always (and (< item-num max-length)
			   (member item s2 :test #'string=))
	       finally (return (= item-num (1- max-length))))))

  (defun can-bang (modes)
    (set-equals modes '("i" "c")))

  (defun no-bang (modes)
    (set-equals modes '("n" "v" "o"))))

(defun vim:map (lhs rhs &key mode noremap flags)
  "Make a Vim mapping: lhs must be a string.  rhs can be a string or a
  function.  Mode can be a string, a keyword, or a list of keywords.  A string
  stands for itself, a keyword is translated to strings using
  vim::*map-modes*, and a list of keywords or strings is translated into a
  mapping for each mode.  No mode => "" => normal+visual-select+operator-
  pending modes. For map!, use :mode '(:insert :command)."
  (check-type lhs string)
  (labels ((map-string (bang rhs mode flags)
	     (vim:cmd mode (when noremap "nore") "map" bang " " flags " " lhs " " rhs))
	   (map-function (bang mode flags)
	     (map-string
	       bang
	       (format nil ":ecl (vim::%call-map-function ~S ~S)<CR>" lhs mode)
	       mode flags)
	     (setf (gethash (cons lhs mode) *map-functions*) rhs)))
    (let ((normalized-mode (normalize-map-modes mode))
	  bang)
      (cond
	((can-bang normalized-mode) (setf bang "!"
					  normalized-mode '("")))
	((no-bang normalized-mode) (setf normalized-mode '(""))))
      (loop with flags = (xlat-map-flags flags)
	    for mode in normalized-mode
	    if (functionp rhs)
	    do (map-function bang mode flags)
	    else do (map-string bang rhs mode flags)))))

(defun vim:map! (lhs rhs &key noremap flags)
  "Convenience function: calls vim:map with modes :insert & :command."
  (vim:map lhs rhs :mode '("i" "c") :noremap noremap :flags flags))

(defun vim:unmap (lhs &key mode flags)
  "Unmap a string.  For unmap!, use :mode '(:insert :command)."
  (values-list
    (let ((normalized-mode (normalize-map-modes mode)))
      (when (equal normalized-mode '(""))
	(setf normalized-mode '("n" "v" "o")))
      (loop with flags = (xlat-map-flags flags)
	    for mode in normalized-mode
	    collect (let ((previous-mapping (vim:maparg lhs :mode mode)))
		      (when previous-mapping
			(if (string= mode "")
			  (loop for mode in '("n" "v" "o" "")
				do (remhash (cons lhs mode) *map-functions*))
			  (remhash (cons lhs mode) *map-functions*))
			(vim:cmd mode "unmap " (xlat-map-flags flags) lhs)
			previous-mapping))))))

(defun vim:unmap! (lhs &key flags)
  "Convenience function: calls vim:unmap with modes :insert & :command."
  (vim:unmap lhs :mode '("i" "c") :flags flags))

(let ((signals '((:SIGHUP    . 1)
                 (:SIGINT    . 2)
                 (:SIGQUIT   . 3)
                 (:SIGILL    . 4)
                 (:SIGTRAP   . 5)
                 (:SIGABRT   . 6)
                 (:SIGFPE    . 8)
                 (:SIGKILL   . 9)
                 (:SIGBUS    . 10)
                 (:SIGSEGV   . 11)
                 (:SIGSYS    . 12)
                 (:SIGPIPE   . 13)
                 (:SIGALRM   . 14)
                 (:SIGTERM   . 15)
                 (:SIGURG    . 16)
                 (:SIGSTOP   . 17)
                 (:SIGTSTP   . 18)
                 (:SIGCONT   . 19)
                 (:SIGCHLD   . 20)
                 (:SIGTTIN   . 21)
                 (:SIGTTOU   . 22)
                 (:SIGIO     . 23)
                 (:SIGXCPU   . 24)
                 (:SIGXFSZ   . 25)
                 (:SIGVTALRM . 26)
                 (:SIGPROF   . 27)
                 (:SIGWINCH  . 28)
                 (:SIGINFO   . 29)
                 (:SIGUSR1   . 30)
                 (:SIGUSR2   . 31))))
(defun vim:kill (pid sig)
 (assert (typep pid 'number))
 (assert (typep sig 'symbol))
 (let ((sig-num (cdr (assoc sig signals))))
  (when sig-num
   (kill-int pid sig-num)))))

(defun vim:wincmd (the-cmd &optional (n 0))
  (vim:cmd (1+ n) "wincmd " the-cmd))

(defun vim:close (&key bang)
  (if (cdr (vim:tabpagebuflist))
    (vim:cmd "close" (when bang "!"))
    (error "Can't vim:close: only one open window.")))

(defun vim:close! ()
  (vim:close :bang t))

(defmacro with-window (winnr &body body)
  "Run BODY in the context of the given window number.
  Signals an error if the given value is NIL or the number is out of range."
  (let ((winnr-once (gensym "winnr"))
	(cur-win (gensym "cur-win-")))
    `(let ((,winnr-once ,winnr))
       (if (and (numberp ,winnr-once)
		(<= 0 ,winnr-once (vim:winnr "$")))
	 (let ((,cur-win (vim:winnr)))
	   (vim:with-options (("&winwidth" 1))
	     (vim:wincmd "w" ,winnr-once)
	     (unwind-protect
	       (progn ,@body)
	       (vim:wincmd "w" ,cur-win))))
	 (error "Invalid window number ~A in with-window" ,winnr-once)))))

(defmacro with-window-of (buffer &body body)
  (let ((buffer-once (gensym "buffer-once-"))
	(body-func (gensym "body-func-"))
	(winnr (gensym "winnr")))
    `(flet ((,body-func () ,@body))
       (let* ((,buffer-once ,buffer)
	      (,winnr (vim:bufwinnr ,buffer-once)))
	 (if ,winnr
	   (with-window ,winnr (,body-func))
	   (with-buffer ,buffer-once (,body-func)))))))

