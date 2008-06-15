(require :asdf)
(require :sb-bsd-sockets)

(load "vimff")

(defpackage :foobar
  (:use :cl))
(in-package :foobar)

(defun foobar ()
  'hi)

(format t "[~a]~%" (foobar))


(vimff:start-listen #(127 0 0 1) 9999)

