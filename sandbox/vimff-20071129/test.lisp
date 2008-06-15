
(load "vimff")

;(setf sb-ext:*invoke-debugger-hook*
;      (lambda (a b)
;        (format t "hello!~%")
;        (format t "arg-1: ~a~%" a)
;        (format t "arg-1: ~a~%" b)
;        ))

(sb-thread:make-thread (lambda ()
                         (format t "io: ~s~%" *debug-io*)
                         (vimff:start-listen #(127 0 0 1) 9999)))
;(loop
;  (eval (read)))
