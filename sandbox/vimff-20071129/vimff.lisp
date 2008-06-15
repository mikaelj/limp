(require :asdf)
(require :sb-bsd-sockets)
(defpackage :vimff
  (:use :cl :sb-bsd-sockets)
  (:export :start-listen))

(in-package :vimff)

(defun eval-form (form)
  (format t "VIMFF: [~a]~%" form)
  (restart-case (print (eval form))
    (skip-eval-form (&optional c)
      (format t "skipping error ~a~%" c))))

(defun start-listen (ip port)
  (let ((socket (make-instance 'inet-socket :type :stream
                               :protocol :tcp)))
    (setf (sockopt-reuse-address socket) t)
    (socket-bind socket ip port)
    (socket-listen socket 1)
    (loop
      (let ((conn (socket-accept socket)))
        (let ((s (socket-make-stream conn :element-type 'character
                                          :input t :output t
                                          :buffering :none)))
          (loop for form = (handler-case (read s nil nil)
                             (t () (format t "VIMFF: bad form received!~%")))
                while form do
          (eval-form form)))
        (socket-close conn)))))

