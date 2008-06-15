(require :sb-bsd-sockets)
(defpackage :swankemu
  (:use :cl :sb-bsd-sockets)
  (:export :slime-connect))

(in-package :swankemu)

(defun slime-connect (ip port)
  (let ((socket (make-instance 'inet-socket :type :stream
                               :protocol :tcp)))
    (socket-connect socket ip port)
    (if (not (socket-open-p socket))
      (return-from slime-connect))
    socket))

(defun slime-disconnect (socket)
  (socket-close socket))

(defun make-msg (msg)
  (let ((len (+ (length msg) 1)) len2 l)
  (setf len2 (string-downcase (format nil "~x" len)))
  (setf l (- 6 (length len2)))
  (loop repeat l do
    (setf len2 (format nil "0~a" len2)))
  (format nil "~a~a~%" len2 msg)))

(defun msg-hexdump (msg)
  (let ((seq (sb-ext:string-to-octets msg)))
  (format t "msg:")
  (loop for c across seq do
    (format t " ~x" c))
  (format t "~%")))

(defun get-slime-msg (sock)
  (let (buf len len2)
  (multiple-value-setq (buf len) (socket-receive sock nil 6))
  ;(format t "readed ~a: ~a~%" len buf)
  (setf len2 (parse-integer buf :radix 16))
  (multiple-value-setq (buf len) (socket-receive sock nil len2))
  ;(format t "readed ~a: ~a~%" len buf)
  buf))

(defun getall-slime-msg (sock)
  (let (msg)
  (loop
    (setf msg (get-slime-msg sock))
    (setf msg (read-from-string msg))
    (if (string= (format nil "~a" (car msg)) "RETURN") (return)))))

(defun set-slime-msg (sock msg)
  (setf msg (make-msg msg))
  ;(format t "msg: [~a]~%" msg)
  ;(msg-hexdump msg)
  (socket-send sock msg (length msg)))


(defun test-run (sock)
  (let (msg)

  ; send slime-event
  (set-slime-msg sock "(:emacs-rex (swank:connection-info) nil t 1)")
  (getall-slime-msg sock)

  (set-slime-msg sock "(:emacs-rex (swank:listener-eval \"(format t \\\"hej~%\\\")\") \"COMMON-LISP-USER\" :repl-thread 9)")
  (getall-slime-msg sock)

  (set-slime-msg sock "(:emacs-rex (swank:interactive-eval \"(foopac::foobar)\") \":foopac\" t 10)")
  (getall-slime-msg sock)

  (set-slime-msg sock (format nil "(:emacs-rex (swank:interactive-eval \"(defun foobar () 'foobar~a)\") \":foopac\" t 10)" (get-universal-time)))
  (getall-slime-msg sock)

  ))

(let (sock)
  (setf sock (slime-connect #(127 0 0 1) 4005))
  (when (not sock)
    (error "cant open slime connection")
    (sb-ext:quit))

  (format t "connected to slime~%")
  (test-run sock)
  (slime-disconnect sock)

  )

