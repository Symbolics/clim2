;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; Package: CLX-CLIM; Base: 10; Lowercase: Yes -*-

;; $fiHeader: clx-frames.lisp,v 1.5 92/04/15 11:45:49 cer Exp $

(in-package :clx-clim)

"Copyright (c) 1992 Symbolics, Inc.  All rights reserved."


(defclass clx-frame-manager (standard-frame-manager)
    ())

(defmethod make-frame-manager ((port clx-port))
  (make-instance 'clx-frame-manager :port port))

(defmethod frame-wrapper ((framem clx-frame-manager) 
			  (frame standard-application-frame) pane)
  (let ((menu-bar (slot-value frame 'menu-bar)))
    (if menu-bar
	(with-look-and-feel-realization (framem frame)
	  (vertically ()
	    (outlining ()
	      (make-pane 'command-menu-pane
			 :display-function 
			   `(display-command-menu :command-table ,menu-bar)
			 :default-text-style clim-internals::*command-table-menu-text-style*
			 :width :compute :height :compute))
	    pane))
	pane)))

(defmethod frame-manager-dialog-view ((framem clx-frame-manager))
  +textual-dialog-view+)
  
;;--- Should "ungray" the command button, if there is one
(defmethod note-command-enabled ((framem clx-frame-manager) frame command)
  (declare (ignore frame command)))

;;--- Should "gray" the command button, if there is one
(defmethod note-command-disabled ((framem clx-frame-manager) frame command)
  (declare (ignore frame command)))

(defmethod frame-manager-notify-user
	   ((framem clx-frame-manager) message-string 
	    &key (style :inform)
		 (frame nil frame-p)
		 (associated-window
		   (if frame-p
		       (frame-top-level-sheet frame)
		       (graft framem)))
		 (title "Notify user")
		 documentation
		 (exit-boxes '(:exit :abort :help))
		 (name title))
  )

(defmethod frame-manager-select-file 
	   ((framem clx-frame-manager) &rest options 
	    &key (frame nil frame-p)
		 (associated-window
		   (if frame-p
		       (frame-top-level-sheet frame)
		       (graft framem)))
		 (title "Select a file")
		 documentation
		 file-search-proc
		 directory-list-label
		 file-list-label
		 (exit-boxes '(:exit :abort :help))
		 (name title))
  )
