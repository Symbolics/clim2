;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; Package: CLIM-DEMO; Base: 10; Lowercase: Yes -*-

;; $fiHeader: aaai-demo-driver.lisp,v 1.4 91/03/26 12:37:26 cer Exp $

(in-package :clim-demo)

"Copyright (c) 1990, 1991 Symbolics, Inc.  All rights reserved."

#-Silica
(defvar *demo-root* nil)

(defvar *demos* nil)

(defmacro define-demo (name start-form)
  `(clim-utils:push-unique (cons ,name #'(lambda () ,start-form)) *demos*
			   :test #'string-equal :key #'car))

(define-demo "Exit" (exit-demo))

(defun exit-demo () (throw 'exit-demo nil))

(define-presentation-type demo-menu-item ())

#-Silica
(defun size-demo-frame (root desired-left desired-top desired-width desired-height)
  (declare (values left top right bottom))
  (multiple-value-bind (left top right bottom)
      (window-inside-edges root)
    (let ((desired-right (+ desired-left desired-width))
	  (desired-bottom (+ desired-top desired-height)))
      (when (> desired-right right)
	(setf desired-right right
	      desired-left (max left (- desired-right desired-width))))
      (when (> desired-bottom bottom)
	(setf desired-bottom bottom
	      desired-top (max top (- desired-bottom desired-height))))
      (values desired-left desired-top desired-right desired-bottom))))

(defun start-demo (&optional (root #-Silica *demo-root*))
  #-Silica
  (unless root
    (lisp:format t "~&No current value for *DEMO-ROOT*.  Use what value? ")
    (setq root (eval (lisp:read)))
    (setq *demo-root* root))
  (labels ((demo-menu-drawer (stream type &rest args)
	     (declare (dynamic-extent args))
	     (with-text-style (stream '(:serif :roman :very-large))
	       (apply #'draw-standard-menu stream type args)))
	   (demo-menu-choose (list associated-window)
	     (with-menu (menu associated-window)
	       (setf (window-label menu)
		     '("Clim Demonstrations" :text-style (:fix :bold :normal)))
	       (menu-choose-from-drawer
		 menu 'demo-menu-item
		 #'(lambda (stream type)
		     (demo-menu-drawer stream type list nil))
		 :cache t
		 :unique-id 'demo-menu :id-test #'eql
		 :cache-value *demos* :cache-test #'equal))))
    (catch 'exit-demo
      (loop
	(let* ((demo-name (demo-menu-choose (nreverse (map 'list #'car *demos*)) root))
	       (demo-fcn (cdr (assoc demo-name *demos* :test #'string-equal))))
	  (when demo-fcn
	    (funcall demo-fcn)))))))

(defparameter *color-stream-p* t)
(defun color-stream-p (stream)
  #-Genera *color-stream-p*		;--- kludge
  #+Genera (if (typep stream 'clim-internals::sheet-window-stream)
	       (slot-value stream 'clim-internals::color-p)
	       *color-stream-p*))