/* vi:ts=8:sts=4:sw=4:iskeyword+=-
 *
 * VIM - Vi IMproved	by Bram Moolenaar
 *
 * Do ":help uganda"  in Vim to read copying and usage conditions.
 * Do ":help credits" in Vim to see a list of people who contributed.
 * See README.txt for an overview of the Vim source code.
 */
/*
 * ECL (Embeddable Common-Lisp) extension by Jim Bailey.
 *
 * Provides the "ecl" ex command for evalutating lisp forms,
 * and a "VIM" package for querying/updating vim from lisp.
 *
 * The ecl command can take an argument, e.g. :ecl (print 42)
 * or a range to evalutate forms from a buffer, e.g. :%ecl
 *
 * The "VIM" package is written and documented in lisp, see the
 * very first few static constants defined in this file for details.
 *
 * TODO: Help files need to be written so everything is documented from
 * vim (the documentation is available from CL at least).
 *
 * TODO: ECL has undocumented threading capabilities, if threads are
 * used by someone who knows how, there are threading issues with
 * vim (which is single threaded). This appears to be unresolved in
 * other interfaces as well.
 */

#include "vim.h"
#undef CAR
#include "ecl/ecl.h"
#include "ecl/ecl-inl.h"
#include <signal.h>

static const char *g_vim_package_definition =
"(defpackage :vim                                                           \n"
"  (:use cl)                                                                \n"
"  (:export #:msg                                                           \n"
"           #:execute                                                       \n"
"	    #:expr							    \n"
"           #:add-input-listener                                            \n"
"           #:remove-input-listener                                         \n"
"           ;; a cons of (start-line . end-line) set when :ecl is called    \n"
"           #:range                                                         \n"
"                                                                           \n"
"           #:window                                                        \n"
"           #:windows                                                       \n"
"           #:current-window                                                \n"
"           #:window-width                                                  \n"
"           #:window-height                                                 \n"
"           #:window-column                                                 \n"
"           #:window-cursor                                                 \n"
"           #:window-buffer                                                 \n"
"                                                                           \n"
"           #:buffer                                                        \n"
"           #:buffers                                                       \n"
"           #:current-buffer                                                \n"
"           #:buffer-line-count                                             \n"
"           #:buffer-lines                                                  \n"
"           #:buffer-name                                                   \n"
"           #:append-line-to-buffer                                         \n"
"           #:append-to-buffer                                              \n"
"           #:get-buffer-by-name                                            \n"
"                                                                           \n"
"           #:get-line                                                      \n"
"           #:replace-lines                                                 \n"
"  ))";

/* 
 * This core form must be kept minimal, as it is run without
 * any error output, making debugging very difficult.
 */
static const char *g_vim_package_source_core =
"(progn                                                                     \n"
"  (defun msg (str &optional (start 0) (end (length str)))                  \n"
"    \"writes a message line to the screen, it must not contain newlines\"  \n"
"    (check-type str string)                                                \n"
"    (check-type start fixnum)                                              \n"
"    (check-type end fixnum)                                                \n"
"    (msg-int str start end))                                               \n"
"                                                                           \n"
"  ;; *standard-output* and *error-output* must be redirected to use        \n"
"  ;; vim's msg(). This is done using ECL's gray streams.                   \n"
"  (defclass msg-stream (si::fundamental-character-output-stream)           \n"
"    ((buffer :initform \"\")))                                             \n"
"                                                                           \n"
"  (defmethod si:stream-write-char ((strm msg-stream) char)                 \n"
"    (with-slots (buffer) strm                                              \n"
"      (cond                                                                \n"
"        ((char= char #\\newline)                                           \n"
"         (msg buffer)                                                      \n"
"         (setf buffer \"\"))                                               \n"
"        (t                                                                 \n"
"         (setf buffer (concatenate 'string buffer (string char)))))))      \n"
"                                                                           \n"
"  (cl:setq *standard-output* (make-instance 'msg-stream))                  \n"
"  (cl:setq *error-output* *standard-output*)                               \n"
"                                                                           \n"
"  ;; Using msg() does not work very well unless executing an ex cmd.       \n"
"  ;; At all other times it is best to send output to a special ecl buffer. \n"
"  (defun buffer-append-char (buffer char)                                  \n"
"    (let ((tail (buffer-line-count buffer)))                               \n"
"      (if (char= char #\\newline)                                          \n"
"        (replace-lines (list \"\")                                         \n"
"                       :start tail :end tail                               \n"
"                       :buffer buffer)                                     \n"
"        (replace-lines (list (concatenate 'string                          \n"
"					   (get-line (1- tail) buffer)      \n"
"					   (string char)))                  \n"
"                       :start (1- tail)                                    \n"
"                       :end tail                                           \n"
"                       :buffer buffer))))                                  \n"
"                                                                           \n"
"  (defclass vim-buf-stream (si::fundamental-character-output-stream)       \n"
"    ((buffer :accessor buffer :initform nil)))                             \n"
"                                                                           \n"
"  (defmethod si:stream-line-column ((strm msg-stream))                     \n"
"    (with-slots (buffer) strm                                              \n"
"      (length buffer)))                                                    \n"
"                                                                           \n"
"  (defmethod si:stream-write-char ((strm vim-buf-stream) char)             \n"
"    (unless (and (buffer strm)                                             \n"
"                 (find (buffer strm) (buffers) :test 'equal))              \n"
"      (execute \"new\")                                                    \n"
"      (setf (buffer strm) (current-buffer)))                               \n"
"    (buffer-append-char (buffer strm) char))                               \n"
"                                                                           \n"
"  (defvar *vim-buf-stream* (make-instance 'vim-buf-stream))                \n"
"                                                                           \n"
"  (defun safe-eval (form from-ex)                                          \n"
"    \"evaluates a form, reporting any errors\"                             \n"
"    (handler-case                                                          \n"
"      (if from-ex                                                          \n"
"        (progn                                                             \n"
"          (when (stringp form)                                             \n"
"            (cl:setq form (read-from-string form)))                        \n"
"          (eval form)                                                      \n"
"          (fresh-line *standard-output*))                                  \n"
"        (let ((*standard-output* *vim-buf-stream*)                         \n"
"              (*error-output* *vim-buf-stream*))                           \n"
"          (eval form)))                                                    \n"
"      (error (cnd)                                                         \n"
"        (format t \"ERROR: ~a~%\" cnd))))                                  \n"
"  )";

/*
 * Global packages and symbols.
 */
static cl_object g_vim_package;
static cl_object g_window_symbol;
static cl_object g_buffer_symbol;

static cl_object intern_vim(const char *name)
{
    return cl_intern(2, make_base_string_copy(name), g_vim_package);
}

static char *string_to_line(cl_object string)
{
    return vim_strnsave(string->base_string.self, string->base_string.fillp);
}

/*
 * Copied from if_python.c, thanks.
 */
static void fix_cursor(int lo, int hi, int extra)
{
    if (curwin->w_cursor.lnum >= lo)
    {
	/* Adjust the cursor position if it's in/after the changed
	 * lines. */
	if (curwin->w_cursor.lnum >= hi)
	{
	    curwin->w_cursor.lnum += extra;
	    check_cursor_col();
	}
	else if (extra < 0)
	{
	    curwin->w_cursor.lnum = lo;
	    check_cursor();
	}
	changed_cline_bef_curs();
    }
    invalidate_botline();
}

static char *zero_terminate(cl_object string)
{
    int length = string->base_string.fillp;
    char *buf = alloc(length + 1);
    memcpy(buf, string->base_string.self, length);
    buf[length] = 0;
    return buf;
}

/*
 * vim callbacks
 */

static cl_object cl_vim_msg_int(cl_narg narg, cl_object string, cl_object start, cl_object end)
{
    int start_pos = fix(start);
    int end_pos = fix(end);
    int length = end_pos - start_pos;
    char *buf;
    
    if (length < 0)
        return Cnil;

    buf = alloc(length + 1);
    memcpy(buf, string->base_string.self + start_pos, length);
    buf[length] = 0;
    msg(buf);
    vim_free(buf);

    return Ct;
}

static cl_object cl_vim_execute_int(cl_object cmd)
{
    char *buf = zero_terminate( cmd );
    do_cmdline_cmd(buf);
    vim_free(buf);

    return Ct;
}

static cl_object vim_type_to_cl_object(typval_T *tv)
{
    cl_object cl_result = Cnil;
    switch (tv->v_type) {
	case VAR_LIST:
	    {
		/* NOTE: Traverse the list back to front -- don't have to
		 * NREVERSE at the end that way. */
		listitem_T *item = tv->vval.v_list->lv_last;
		while (item) {
		    cl_result = CONS( vim_type_to_cl_object( &item->li_tv ),
					   cl_result );
		    item = item->li_prev;
		}
	    }
	    break;
	case VAR_STRING:
	    if (tv->vval.v_string != NULL)
		cl_result = make_base_string_copy(tv->vval.v_string);
	    break;
	case VAR_NUMBER:
	    {
		long num = (long)tv->vval.v_number;
		if (num < MOST_NEGATIVE_FIXNUM
		    || num > MOST_POSITIVE_FIXNUM)
		{
		    /* Make a BIGNUM */
		    char num_buf[NUMBUFLEN];
		    sprintf((char *)num_buf, "%ld", (long)num);
		    cl_result = c_string_to_object(num_buf);
		} else
		    cl_result = MAKE_FIXNUM(num);
	    }
	    break;
	case VAR_UNKNOWN:
	    EMSG2(_(e_intern2), "vim_type_to_cl_object(VAR_UNKNOWN)");
	    break;
	case VAR_DICT:
	    EMSG2(_(e_intern2), "vim_type_to_cl_object(VAR_DICT)");
	    break;
	case VAR_FUNC:
	    EMSG2(_(e_intern2), "vim_type_to_cl_object(VAR_FUNC)");
	    break;
	default:
	    EMSG2(_(e_intern2), "vim_type_to_cl_object()");
	    break;
    }
    return cl_result;
}

static cl_object cl_vim_expr_int(cl_object cmd)
{
    typval_T	*tv;

    char *buf = zero_terminate(cmd);
    cl_object cl_result = Cnil;

    tv = eval_expr(buf, NULL);
    if (tv != NULL) {
	cl_result = vim_type_to_cl_object(tv);
	clear_tv(tv);
    }

    vim_free(buf);

    return cl_result;
}


/*
 * Async socket reading.
 */
static int listener_callback(int fd, void *data)
{
    cl_funcall(1, (cl_object) data);
#ifdef FEAT_GUI    
    if (gui.in_use)
    {
	gui_update_screen();
    } else
#endif
    {
	setcursor();
	out_flush();
	update_screen(NOT_VALID);
    }
    return 1;
}

static int cl_stream_fd(cl_object stream)
{
#ifdef FEAT_GUI_W32
    int mode = stream->stream.mode;
    if (mode == smm_input_wsock || mode == smm_output_wsock || mode == smm_io_wsock)
	return (int) stream->stream.file;
    else
	return fileno(stream->stream.file);
#else
    return fileno(stream->stream.file);
#endif
}

static cl_object cl_vim_kill_int (cl_object pid, cl_object sig)
{
#ifndef FEAT_GUI_W32
    int fixed_pid = fix(pid);
    int fixed_sig = fix(sig);
    if (kill (fixed_pid, fixed_sig) == 0)
        return Ct;
    else
        return Cnil;
#endif
}

static cl_object cl_vim_add_input_listener_int(cl_object stream, cl_object form)
{
#if 0
    nwio_register_input_handler(cl_stream_fd(stream),
                                listener_callback,
                                (void *)form);
#endif
    return Ct;
}

static cl_object cl_vim_remove_input_listener_int(cl_object stream)
{
#if 0
    nwio_unregister_input_handler(cl_stream_fd(stream));
#endif
    return Ct;
}

/*
 * windows
 */

static cl_object cl_vim_windows_int()
{
    cl_object result = Cnil;
    win_T *vwin = firstwin;

    while (vwin)
    {
        result = CONS(ecl_make_foreign_data(g_window_symbol,
                                                 sizeof(win_T *),
                                                 vwin),
                           result);
        vwin = W_NEXT(vwin);
    }

    return cl_nreverse(result);
}

static cl_object cl_vim_current_window_int()
{
    return ecl_make_foreign_data(g_window_symbol,
                                 sizeof(win_T *),
                                 curwin);
}

static cl_object cl_vim_window_width_int(cl_object win_)
{
    win_T *win = ((win_T *)ecl_foreign_data_pointer_safe(win_));

    return MAKE_FIXNUM(win->w_width);
}

static cl_object cl_vim_window_height_int(cl_object win_)
{
    win_T *win = ((win_T *)ecl_foreign_data_pointer_safe(win_));

    return MAKE_FIXNUM(win->w_height);
}

static cl_object cl_vim_window_column_int(cl_object win_)
{
    win_T *win = ((win_T *)ecl_foreign_data_pointer_safe(win_));

    return MAKE_FIXNUM(W_WINCOL(win));
}

static cl_object cl_vim_window_cursor_int(cl_object win_)
{
    win_T *win = ((win_T *)ecl_foreign_data_pointer_safe(win_));

    return CONS(MAKE_FIXNUM(win->w_cursor.lnum - 1),
                     MAKE_FIXNUM(win->w_cursor.col));
}

static cl_object cl_vim_window_buffer_int(cl_object win_)
{
    win_T *win = ((win_T *)ecl_foreign_data_pointer_safe(win_));

    return ecl_make_foreign_data(g_buffer_symbol,
                                 sizeof(buf_T *),
                                 win->w_buffer);
}

/*
 * buffers
 */

static cl_object cl_vim_buffers_int()
{
    cl_object result = Cnil;
    buf_T *vbuf = firstbuf;

    while (vbuf)
    {
        result = CONS(ecl_make_foreign_data(g_buffer_symbol,
                                                 sizeof(buf_T *),
                                                 vbuf),
                           result);
        vbuf = vbuf->b_next;
    }

    return cl_nreverse(result);
}

static cl_object cl_vim_current_buffer_int()
{
    return ecl_make_foreign_data(g_buffer_symbol,
                                 sizeof(buf_T *),
                                 curbuf);
}

static cl_object cl_vim_buffer_line_count_int(cl_object buf_)
{
    buf_T *buf = ((buf_T *)ecl_foreign_data_pointer_safe(buf_));

    return MAKE_FIXNUM(buf->b_ml.ml_line_count);
}

/* 
   start_ and end_ and fixnums in the range 0..(num_lines-1)
*/

static cl_object cl_vim_buffer_lines_int(cl_object buf_, cl_object start_, cl_object end_)
{
    buf_T *buf = ((buf_T *)ecl_foreign_data_pointer_safe(buf_));
    int start = fix(start_) + 1;
    int end = fix(end_);
    cl_object result = Cnil;
    
    while (end >= start)
    {
        result = CONS(make_base_string_copy(ml_get_buf(buf, end--, FALSE)),
                           result);
    }
    
    return result;
}

static cl_object cl_vim_buffer_name_int (cl_object buf_)
{
    buf_T *buf = ((buf_T *)ecl_foreign_data_pointer_safe(buf_));
    if (buf->b_fname == NULL)
	return Cnil;
    else
	return make_base_string_copy (buf->b_fname);
}

static cl_object cl_vim_append_string_int (cl_object buf, cl_object string)
{
    buf_T *savebuf = curbuf;
    int start_line;
    curbuf = ((buf_T *)ecl_foreign_data_pointer_safe(buf));
    start_line = curbuf->b_ml.ml_line_count;

    if (string != Cnil)
    {
        char_u *line = string_to_line (string);
        ml_append_string (start_line, line, -1);
        //ml_append_string (curbuf->b_ml.ml_line_count-1, string->base_string.self, string->base_string.fillp);
    }
    changed_lines(start_line, 0, curbuf->b_ml.ml_line_count, 1);

    /* restore and return */
    curbuf = savebuf;
    return Ct;
}

static cl_object cl_vim_append_lines_int (cl_object buf, cl_object lines)
{
    buf_T *savebuf = curbuf;
    int start_line, first_line;
    curbuf = ((buf_T *)ecl_foreign_data_pointer_safe(buf));
    start_line = curbuf->b_ml.ml_line_count;
    first_line = 1;
    if (start_line == 0) start_line = 1;

    while (lines != Cnil) {
        char_u *line = string_to_line (cl_car (lines));
        if (first_line)
        {
            ml_append_string (start_line, line, -1);
            first_line = 0;
        }
        else
            ml_append (start_line, line, 0, FALSE);
        vim_free (line);
        lines = cl_cdr (lines);
    }
    changed_lines(start_line, 0, start_line, (long)(curbuf->b_ml.ml_line_count - start_line));

    /* restore and return */
    curbuf = savebuf;
    return Ct;
}

static cl_object cl_vim_append_char_int (cl_object buf, cl_object ecl_char)
{
    static char string[2] = {0};
    buf_T *savebuf = curbuf;
    int start_line, lines_changed;
    curbuf = ((buf_T *)ecl_foreign_data_pointer_safe(buf));
    start_line = curbuf->b_ml.ml_line_count;
    lines_changed = 0;

    if (ecl_char != Cnil)
    {
        string[0] = CHAR_CODE (ecl_char);
        if (string[0] == '\n')
        {
            ml_append (start_line, "", 0, FALSE);
            lines_changed = 1;
        }
        else
            ml_append_string (start_line, string, -1);
        //ml_append_string (curbuf->b_ml.ml_line_count-1, string->base_string.self, string->base_string.fillp);
    }
    changed_lines (start_line, 0, start_line, lines_changed);

    /* restore and return */
    curbuf = savebuf;
    return Ct;
}
/* 
   start1_ and end1_ are fixnums in the range 0..(num_lines-1)
*/

static cl_object cl_vim_replace_lines_int(cl_object buf, cl_object lines, cl_object start1_, cl_object end1_, cl_object start2_, cl_object end2_)
{
    linenr_T start1 = (linenr_T)fix(start1_) + 1;
    linenr_T end1 = (linenr_T)fix(end1_) + 1;
    int start2 = fix(start2_);
    int new_len = fix(end2_);
    int old_len = end1 - start1;
    int max_len;
    int i;
    buf_T *savebuf = curbuf;

    curbuf = ((buf_T *)ecl_foreign_data_pointer_safe(buf));

    if (start2 > 0)
    {
        /* take off the head of the list */
        lines = cl_nthcdr(start2_, lines);
        new_len -= start2;
    }

    max_len = new_len > old_len ? new_len : old_len;

    /* save undo information 
     * Need to restrict the length to the buffer size or
     * the u_save fails
     */
    if (start1 + max_len > curbuf->b_ml.ml_line_count + 1)
        u_save(start1 - 1, curbuf->b_ml.ml_line_count + 1);
    else
        u_save(start1 - 1, start1 + max_len);
    
    /* delete excess lines */
    for (i = 0; i < old_len - new_len; ++i)
    {
        ml_delete(start1, FALSE);
    }

    /* replace existing lines */
    for (i = 0; i < old_len && i < new_len; ++i)
    {
        ml_replace(start1 + i, string_to_line(cl_car(lines)), FALSE);
        lines = cl_cdr(lines);
    }

    /* add new lines (must be freed) */
    while (i < new_len)
    {
        char_u *line = string_to_line(cl_car(lines));
        ml_append(start1 + i - 1, line, 0, FALSE);
        vim_free(line);
        lines = cl_cdr(lines);
        ++i;
    }

    /* adjust marks */
    mark_adjust(start1, end1 - 1,
                (long)MAXLNUM, (long)(new_len - old_len));
    changed_lines(start1, 0, end1, (long)(new_len - old_len));

    /* fix cursor */
    if (curbuf == savebuf)
        fix_cursor(start1, end1, (new_len - old_len));
    
    /* restore and return */
    curbuf = savebuf;
    return Ct;
}

/*
 * helpers
 */

static cl_object eval_string(const char *form)
{
    return cl_eval(c_string_to_object(form));
}

static cl_object safe_eval_form(cl_object form, int from_ex)
{
    /* uses vim::safe-eval to trap errors */
    static cl_object safe_eval = 0;

    if (safe_eval == 0)
    {
        /* get the safe eval and quote symbols */
        safe_eval = intern_vim("SAFE-EVAL");
    }
    
    /* this is (vim::safe-eval form from_ex) */
    return si_eval_with_env(1, cl_list(3,
				       safe_eval,
                                       form,
                                       from_ex == TRUE ? Ct : Cnil));
}

static cl_object safe_eval_string(const char *string, int from_ex)
{
    return safe_eval_form(make_base_string_copy(string), from_ex);
}

static void
RunEclCommand(exarg_T *eap, const char *cmd)
{
    static int have_inited = 0;
    static cl_object range;

    if (!have_inited)
    {
        static char *argv[] = {"ecl", 0};
        have_inited = 1;
        cl_boot(1, argv);

        /* create the vim package */
        g_vim_package = eval_string(g_vim_package_definition);

        /* add the lisp->c functions */
        cl_def_c_function_va(intern_vim("MSG-INT"), cl_vim_msg_int);
        cl_def_c_function(intern_vim("EXECUTE-INT"), cl_vim_execute_int, 1);
        cl_def_c_function(intern_vim("EXPR-INT"), cl_vim_expr_int, 1);
        cl_def_c_function(intern_vim("ADD-INPUT-LISTENER-INT"), 
                          cl_vim_add_input_listener_int, 2);
        cl_def_c_function(intern_vim("KILL-INT"), cl_vim_kill_int, 2);
        cl_def_c_function(intern_vim("REMOVE-INPUT-LISTENER-INT"), 
                          cl_vim_remove_input_listener_int, 1);

        g_window_symbol = intern_vim("WINDOW");

        cl_def_c_function(intern_vim("WINDOWS-INT"),
                          cl_vim_windows_int, 0);
        cl_def_c_function(intern_vim("CURRENT-WINDOW-INT"),
                          cl_vim_current_window_int, 0);
        cl_def_c_function(intern_vim("WINDOW-WIDTH-INT"),
                          cl_vim_window_width_int, 1);
        cl_def_c_function(intern_vim("WINDOW-HEIGHT-INT"),
                          cl_vim_window_height_int, 1);
        cl_def_c_function(intern_vim("WINDOW-COLUMN-INT"),
                          cl_vim_window_column_int, 1);
        cl_def_c_function(intern_vim("WINDOW-CURSOR-INT"),
                          cl_vim_window_cursor_int, 1);
        cl_def_c_function(intern_vim("WINDOW-BUFFER-INT"),
                          cl_vim_window_buffer_int, 1);


        g_buffer_symbol = intern_vim("BUFFER");

        cl_def_c_function(intern_vim("BUFFERS-INT"),
                          cl_vim_buffers_int, 0);
        cl_def_c_function(intern_vim("CURRENT-BUFFER-INT"),
                          cl_vim_current_buffer_int, 0);
        cl_def_c_function(intern_vim("BUFFER-LINE-COUNT-INT"),
                          cl_vim_buffer_line_count_int, 1);
        cl_def_c_function(intern_vim("BUFFER-LINES-INT"),
                          cl_vim_buffer_lines_int, 3);
        cl_def_c_function(intern_vim("BUFFER-NAME-INT"),
                          cl_vim_buffer_name_int, 1);


        cl_def_c_function(intern_vim("REPLACE-LINES-INT"),
                          cl_vim_replace_lines_int, 6);
        cl_def_c_function(intern_vim("APPEND-LINES-INT"),
                          cl_vim_append_lines_int, 2);
        cl_def_c_function(intern_vim("APPEND-STRING-INT"),
                          cl_vim_append_string_int, 2);
        cl_def_c_function(intern_vim("APPEND-CHAR-INT"),
                          cl_vim_append_char_int, 2);

        /* Eval the vim package source,
         * the minimal core sets up the "safe" version. */
        eval_string("(in-package :vim)");
        eval_string(g_vim_package_source_core);

        /* return to cl-user */
        eval_string("(in-package :cl-user)");

        /*
         * Load the lisp source that is provided with the runtime,
         * this is responsible for defining the public :vim interface.
         */
        safe_eval_string("(cl:load (cl:format nil \"~a/if_ecl\" (vim::expr-int \"$VIMRUNTIME\")))", TRUE);

        /* get needed symbols */
        range = intern_vim("RANGE");
    }

    /* Store the range. */
    cl_set(range, cl_cons(MAKE_FIXNUM(eap->line1),
                          MAKE_FIXNUM(eap->line2)));

    /* Run the string, this isn't a REPL loop so the result is discarded. */
    if (cmd[0] == '\0')
        safe_eval_string("(vim:eval-range)", TRUE);
    else
        safe_eval_string(cmd, TRUE);
}

/*
 * ":ecl" command
 */
void
ex_ecl(exarg_T *eap)
{
    char_u *script;

    script = script_get(eap, eap->arg);
    if (!eap->skip)
    {
        if (script == NULL)
            RunEclCommand(eap, (char *)eap->arg);
        else
            RunEclCommand(eap, (char *)script);
    }

    vim_free(script);
}

    void
ecl_end()
{
}

