 ;; -*- mode: common-lisp; package: tk -*-
;;
;;				-[]-
;; 
;; copyright (c) 1985, 1986 Franz Inc, Alameda, CA  All rights reserved.
;; copyright (c) 1986-1991 Franz Inc, Berkeley, CA  All rights reserved.
;;
;; The software, data and information contained herein are proprietary
;; to, and comprise valuable trade secrets of, Franz, Inc.  They are
;; given in confidence by Franz, Inc. pursuant to a written license
;; agreement, and may be stored and used only in accordance with the terms
;; of such license.
;;
;; Restricted Rights Legend
;; ------------------------
;; Use, duplication, and disclosure of the software, data and information
;; contained herein by any agency, department or entity of the U.S.
;; Government are subject to restrictions of Restricted Rights for
;; Commercial Software developed at private expense as specified in FAR
;; 52.227-19 or DOD FAR Supplement 252.227-7013 (c) (1) (ii), as
;; applicable.
;;
;; $fiHeader: event.lisp,v 1.9 92/04/21 20:27:28 cer Exp $

(in-package :tk)

(defun simple-event-loop (context)
  (loop
    (multiple-value-bind (mask reason)
	(wait-for-event context)
      (process-one-event context mask reason))))

(defconstant *xt-im-xevent*		1)
(defconstant *xt-im-timer*		2)
(defconstant *xt-im-alternate-input*	4)
(defconstant *xt-im-all* (logior *xt-im-xevent*  *xt-im-timer*  *xt-im-alternate-input*))

(defun wait-for-event (context &key timeout wait-function)
  (let ((mask 0)
	(fds (mapcar #'(lambda (display)
			 (x11::display-fd display))
		     (application-context-displays context)))
	(reason nil))
    (declare (fixnum mask))
    
    (flet ((wait-function (fd)
	     (declare (ignore fd))
	     (or (plusp (setq mask (xt_app_pending context)))
		 (and wait-function
		      (funcall wait-function)
		      (setq reason :wait)))))
      (mp:wait-for-input-available fds :wait-function #'wait-function
				   :timeout timeout))
    (values mask reason)))

(defun process-one-event (context mask reason)
  (cond ((plusp mask)
	 (xt_app_process_event
	  context
	  ;; Because of a feature in the OLIT toolkit we need to
	  ;; give preference to events rather than timer events
	  (if (logtest mask *xt-im-xevent*) *xt-im-xevent* mask))
	 t)
	(reason :wait-function)
	(t :timeout)))

(defun-c-callable match-event-sequence-and-types ((display :unsigned-long)
						  (event :unsigned-long)
						  (arg :unsigned-long))
  ;; Arg points to a n element (unsigned-byte 32) vector, where the first
  ;; element is the display, the second is the sequence number, and
  ;; the other elements are the event types to be matched (null terminated).
  (let ((desired-display (sys:memref-int arg 0 0 :unsigned-long))
	(desired-sequence (sys:memref-int arg 4 0 :unsigned-long))
	(event-type (x11:xevent-type event)))
    (if (and (eql desired-display display)
	     (eql desired-sequence (x11:xanyevent-serial event))
	     (do* ((i 8 (+ i 4))
		   (desired-type (sys:memref-int arg i 0 :unsigned-long)
				 (sys:memref-int arg i 0 :unsigned-long)))
		 ((zerop desired-type) nil)
	       (if (eql desired-type event-type)
		   (return t))))
	1
      0)))

(defparameter *match-event-sequence-and-types-address*
    (register-function 'match-event-sequence-and-types))

(defun get-event-matching-sequence-and-types (display-object seq-no types
					      &key (block t))
  (unless (consp types)
    (setq types (list types)))
  (let ((display (object-display display-object))
	(data (make-array (+ 3 (length types))
			  :element-type '(unsigned-byte 32)))
	(i 2)
	(resulting-event (x11:make-xevent)))
    (declare (type (simple-array (unsigned-byte 32) (*)) data)
	     (fixnum i)) 
    (setf (aref data 0) (ff:foreign-pointer-address display))
    (setf (aref data 1) seq-no)
    (dolist (type types)
      (setf (aref data i) (position type tk::*event-types*))
      (incf i))
    (setf (aref data i) 0)
    (cond (block
	   (x11:xifevent display resulting-event
			 *match-event-sequence-and-types-address* data)
	   resulting-event)
	  ((zerop (x11:xcheckifevent display resulting-event
				     *match-event-sequence-and-types-address*
				     data))
	   nil)
	  (t
	   resulting-event))))


(defvar *event* nil)

(defun-c-callable event-handler ((widget :unsigned-long)
				 (client-data :unsigned-long)
				 (event :unsigned-long)
				 (continue-to-dispatch
				  :unsigned-long))
  (let* ((widget (find-object-from-address widget))
	 (eh-info (or (assoc client-data (widget-event-handler-data widget))
		      (error "Cannot find event-handler info ~S,~S"
			     widget client-data))))
    (destructuring-bind (ignore (fn &rest args))
	eh-info
      (declare (ignore ignore))
      (apply fn widget event args)
      0)))

(defvar *event-handler-address* (register-function 'event-handler))

(defun add-event-handler (widget events maskable function &rest args)
  (xt_add_event_handler
   widget
   (encode-event-mask events)
   maskable
   *event-handler-address*
   (caar (push
	  (list (new-callback-id) (cons function args))
	  (widget-event-handler-data widget)))))

(defun build-event-mask (widget)
  (xt_build_event_mask widget))


