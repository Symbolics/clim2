;; -*- mode: common-lisp; package: xm-silica -*-
;; 
;; copyright (c) 1985, 1986 Franz Inc, Alameda, Ca.  All rights reserved.
;; copyright (c) 1986-1991 Franz Inc, Berkeley, Ca.  All rights reserved.
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
;; 52.227-19 or DOD FAR Suppplement 252.227-7013 (c) (1) (ii), as
;; applicable.
;;
;; $fiHeader: xm-gadgets.lisp,v 1.20 92/04/10 14:27:50 cer Exp Locker: cer $

(in-package :xm-silica)

(defmethod make-pane-class ((framem motif-frame-manager) class &rest options) 
  (declare (ignore options))
  (second (assoc class '(
			 ;; experiment
			 (outlined-pane motif-frame-pane)
			 ;;
			 (scroll-bar motif-scrollbar)
			 (slider motif-slider)
			 (push-button motif-push-button)
			 (label-pane motif-label-pane)
			 (text-field motif-text-field)
			 (text-editor motif-text-editor)
			 (toggle-button motif-toggle-button)
			 (menu-bar motif-menu-bar)
			 (viewport xm-viewport)
			 (radio-box motif-radio-box)
			 (frame-pane motif-frame-pane)
			 (top-level-sheet motif-top-level-sheet)
			 ;; One day
			 (line-editor-pane)
			 (label-button-pane)
			 (radio-button-pane)
			 (horizontal-divider-pane)
			 (vertical-divider-pane)
			 (label-pane)
			 ;;
			 (list-pane)
			 (caption-pane)
			 (cascade-button)
			 ))))

;;; We now need a lot of classes that mirror the xm classes.


;;; Motif widgets that support the :value resource and value-changed callback

(defclass motif-value-pane () ())

(defmethod add-sheet-callbacks :after ((port motif-port) (sheet motif-value-pane) (widget t))
  (tk::add-callback widget
		    :value-changed-callback
		    'queue-value-changed-event
		    sheet))

(defmethod gadget-value ((gadget motif-value-pane))
  (if (sheet-direct-mirror gadget)
      (tk::get-values (sheet-mirror gadget) :value)
    (call-next-method)))

(defmethod (setf gadget-value) (nv (gadget motif-value-pane) &key)
  (when (sheet-mirror gadget)
    (tk::set-values (sheet-mirror gadget) :value nv)))

(defmethod queue-value-changed-event (widget sheet)
  (declare (ignore widget))
  (distribute-event
   (port sheet)
   (make-instance 'value-changed-gadget-event
		  :gadget sheet
		  :value (gadget-value sheet))))

;;; Motif widgets that support the activate callback

(defclass motif-action-pane () ())

(defmethod add-sheet-callbacks :after ((port motif-port) (sheet motif-action-pane) (widget t))
  (tk::add-callback widget
		    :activate-callback
		    'queue-active-event
		    sheet))

(defmethod queue-active-event (widget count sheet)
  (declare (ignore widget count))
  (distribute-event
   (port sheet)
   (make-instance 'activate-gadget-event
		  :gadget sheet)))

;;; Label

(defclass motif-label-pane (xt-leaf-pane label-pane) 
	  ())

(defmethod find-widget-class-and-initargs-for-sheet ((port motif-port)
						     (parent t)
						     (sheet motif-label-pane))
  (with-accessors ((label gadget-label)
		   (alignment gadget-alignment)) sheet
    (values 'tk::xm-label
	    (append
	     (list :alignment 
		   (ecase alignment
		     ((:left nil) :beginning)
		     (:center :center)
		     (:right :end)))
	     (and label (list :label-string label))))))


;;; Push button

(defclass motif-push-button (xt-leaf-pane
			     push-button
			     motif-action-pane) 
	  ())



(defmethod find-widget-class-and-initargs-for-sheet ((port motif-port)
						     (parent t)
						     (sheet motif-push-button))
  (declare (ignore port))
  (with-accessors ((label gadget-label)) sheet
    (values 'tk::xm-push-button 
	    (and label (list :label-string label)))))

(defmethod add-sheet-callbacks ((port motif-port) (sheet t) (widget tk::xm-drawing-area))
  (tk::add-callback widget 
		    :expose-callback 
		    'sheet-mirror-exposed-callback
		    sheet)
  (tk::add-callback widget 
		    :input-callback 
		    'sheet-mirror-input-callback
		    sheet)
  (tk::add-event-handler widget
			 '(:enter-window 
			   :leave-window
			   :pointer-motion-hint
			   :pointer-motion
			   :button1-motion
			   :button2-motion
			   :button3-motion
			   :button4-motion
			   :button5-motion
			   :button-motion
			   )
			 0
			 'sheet-mirror-event-handler
			 sheet))

;; Drawing area
;; Who uses this anyway??????????????

(defclass motif-drawing-area (xt-leaf-pane 
			      standard-sheet-input-mixin
			      permanent-medium-sheet-output-mixin
			      mute-repainting-mixin) 
	  ())

(defmethod find-widget-class-and-initargs-for-sheet ((port motif-port)
						     (parent t)
						     (sheet motif-drawing-area))
  (values 'tk::xm-drawing-area (list :margin-width 0 
				     :resize-policy :none
				     :margin-height 0)))

(defmethod add-sheet-callbacks :after ((port motif-port) (sheet motif-drawing-area) widget)
  ;; Now does nothing
  )

(defmethod gadget-value ((gadget motif-value-pane))
  ;;--- We should use the scale functions to get the value
  (let ((mirror (sheet-direct-mirror gadget)))
    (if mirror 
	(tk::get-values mirror :value)
      (call-next-method))))

(defmethod (setf gadget-value) (nv (gadget motif-value-pane) &key)
  (let ((gadget (sheet-mirror gadget)))
    (when gadget
      (tk::set-values gadget
		      :value nv))))

;;; range pane mixin

(defclass motif-range-pane (motif-value-pane) ())


(defmethod gadget-value ((gadget motif-range-pane))
  ;;--- We should use the scale functions to get the value
  (let ((mirror (sheet-direct-mirror gadget)))
    (if mirror 
	(multiple-value-bind
	    (smin smax) (silica::gadget-range* gadget)
	  (multiple-value-bind
	      (value mmin mmax)
	      (tk::get-values mirror :value :minimum :maximum)
	    (silica::compute-symmetric-value
	     mmin mmax value smin smax)))
      (call-next-method))))


(defmethod (setf gadget-value) (nv (gadget motif-range-pane) &key)
  (let ((gadget (sheet-mirror gadget)))
    (when gadget
      (multiple-value-bind
	  (smin smax) (silica::gadget-range* gadget)
	(multiple-value-bind
	    (mmin mmax)
	    (tk::get-values gadget :minimum :maximum)
	  (tk::set-values gadget
			  :value (silica::compute-symmetric-value
				  smin smax nv mmin mmax)))))))

;;; Slider

(defclass motif-slider (xt-leaf-pane
			motif-range-pane
			slider)
	  ())

(defmethod find-widget-class-and-initargs-for-sheet ((port motif-port)
						     (parent t)
						     (sheet motif-slider))
  (with-accessors ((orientation gadget-orientation)
		   (label gadget-label)
		   (show-value-p silica::gadget-show-value-p)
		   (value gadget-value)) sheet
    (values 'tk::xm-scale 
	    (append
	     (and show-value-p (list :show-value show-value-p ))
	     (and label (list :title-string label))
	     (list :orientation orientation)
	     (and value (list :value value))))))


(defmethod compose-space ((m motif-slider) &key width height)
  (declare (ignore width height))
  (destructuring-bind
      (label scrollbar) (tk::widget-children (sheet-direct-mirror m))
    (declare (ignore scrollbar))
    (multiple-value-bind
	(label-x label-y label-width label-height)
	(and (gadget-label m)
	     (tk::widget-best-geometry label))
      (declare (ignore label-x label-y))
      ;;-- We need to estimate the space requirements for the value if
      ;;-- that is shown
      (let ((fudge 16))
	(ecase (gadget-orientation m)
	  (:vertical
	   (make-space-requirement :width (if (gadget-label m) ;
					      (+ fudge label-width)
					    fudge)
				   :min-height fudge
				   :height (max (* 2 fudge) label-height)
				   :max-height +fill+))
	  (:horizontal
	   (make-space-requirement :height (if (gadget-label m) ;
					       (+ fudge label-height)
					     fudge)
				   :min-width fudge
				   :width (max (* 2 fudge) label-width)
				   :max-width +fill+)))))))

;;; Scrollbar


(defclass motif-scrollbar (xt-leaf-pane
			   scrollbar)
	  ())

(defmethod find-widget-class-and-initargs-for-sheet ((port motif-port)
						     (parent t)
						     (sheet motif-scrollbar))
  (with-accessors ((orientation gadget-orientation)) sheet
    ;;-- we should really decide what the min and max resources should be
    (values 'tk::xm-scroll-bar 
	    (list :orientation orientation))))

(defmethod (setf silica::scrollbar-size) (nv (sb motif-scrollbar))
  (tk::set-values (sheet-direct-mirror sb) :slider-size (floor nv))
  nv)

(defmethod (setf silica::scrollbar-value) (nv (sb motif-scrollbar))
  (tk::set-values (sheet-direct-mirror sb) :value nv)
  nv)

;;;--- We should use the motif functions for getting and changing the
;;;--- values

(defmethod change-scrollbar-values ((sb motif-scrollbar) &key slider-size value)
  (let ((mirror (sheet-direct-mirror sb)))
    (multiple-value-bind
	(smin smax) (silica::gadget-range* sb)
      (multiple-value-bind
	  (mmin mmax) (tk::get-values mirror :minimum :maximum)
	(tk::set-values
	 mirror
	 :slider-size 
	 (integerize-coordinate
	  (silica::compute-symmetric-value
		       smin smax slider-size mmin mmax))
	 :value (integerize-coordinate
		 (silica::compute-symmetric-value
		  smin smax value mmin mmax)))))))


(defmethod add-sheet-callbacks ((port motif-port) (sheet motif-scrollbar) (widget t))
  (tk::add-callback widget
		    :value-changed-callback
		    'scrollbar-changed-callback-1
		    sheet))


(defun scrollbar-changed-callback-1 (widget sheet)
  (multiple-value-bind
      (smin smax) (silica::gadget-range* sheet)
    (multiple-value-bind
	(value size mmin mmax)
	(tk::get-values widget :value :slider-size :minimum :maximum)
      (scrollbar-value-changed-callback
       sheet
       (gadget-client sheet)
       (gadget-id sheet)
       (silica::compute-symmetric-value
	mmin mmax value smin smax)
       (silica::compute-symmetric-value
	mmin mmax size smin smax)))))


(defmethod compose-space ((m motif-scrollbar) &key width height)
  (let ((x 16))
    (ecase (gadget-orientation m)
      (:vertical
       (make-space-requirement :width x
			       :min-height x
			       :height (* 2 x)
			       :max-height +fill+))
      (:horizontal
       (make-space-requirement :height x
			       :min-width x
			       :width (* 2 x)
			       :max-width +fill+)))))

;; Should we stick in our preferred scrollbar geometry here?

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defclass motif-top-level-sheet (top-level-sheet) ())


(defmethod add-sheet-callbacks :after ((port motif-port) 
				       (sheet motif-top-level-sheet)
				       (widget tk::xm-drawing-area))
  (tk::add-callback widget 
		    :resize-callback 'sheet-mirror-resized-callback
		    sheet))

(defmethod find-widget-class-and-initargs-for-sheet ((port motif-port)
						     (parent t)
						     (sheet motif-top-level-sheet))
  (cond 
   ;;--- hack alert
   ;; Seems that we need to use a bulletin board so that everything
   ;; comes up in the right place.
   ((popup-frame-p sheet)
    (values 'tk::xm-bulletin-board
	    (list :margin-width 0 :margin-height 0
		  ;; We specify NIL for accelerators otherwise the
		  ;; bulletin board messes with the event handling of
		  ;; its drawing area children
		  :accelerators nil
		  :resize-policy :none
		  :name (string (frame-name (pane-frame sheet))))))
   (t
    (values 'tk::xm-drawing-area 
	    (list :resize-policy :none
		  :name (string (frame-name (pane-frame sheet)))
		  :margin-width 0 :margin-height 0)))))

;;; 

(defmethod add-sheet-callbacks :after ((port motif-port) (sheet t) 
				       (widget tk::xm-bulletin-board))
  (tk::add-event-handler widget
			 '(:enter-window 
			   :leave-window
			   :pointer-motion-hint
			   :pointer-motion
			   :button1-motion
			   :button2-motion
			   :button3-motion
			   :button4-motion
			   :button5-motion
			   :button-motion
			   :exposure
			   :structure-notify
			   :key-press
			   :key-release
			   :button-press
			   :button-release
      			   )
			 0
			 'sheet-mirror-event-handler
			 sheet))


;;;; text field

(defclass motif-text-field (xt-leaf-pane
			    motif-value-pane 
			    motif-action-pane
			    text-field)
	  ())

(defmethod find-widget-class-and-initargs-for-sheet ((port motif-port)
						     (parent t)
						     (sheet motif-text-field))
  (with-accessors ((value gadget-value)) sheet
    (values 'tk::xm-text-field 
	    (append
	     (and value `(:value ,value))))))

;;; 

(defclass motif-text-editor (xt-leaf-pane
			     motif-value-pane 
			     motif-action-pane
			     silica::text-editor)
	  ())

(defmethod find-widget-class-and-initargs-for-sheet ((port motif-port)
						     (parent t)
						     (sheet
						      motif-text-editor))
  (with-accessors ((value gadget-value)
		   (ncolumns silica::gadget-columns)
		   (nlines silica::gadget-lines)) sheet
    (values 'tk::xm-text
	    (append
	     (list :edit-mode :multi-line)
	     (and ncolumns (list :columns ncolumns))
	     (and nlines (list :rows nlines))
	     (and value `(:value ,value))))))

(defmethod set-mirror-geometry (parent (sheet motif-text-editor) initargs)
  (multiple-value-bind (left top right bottom)
      (sheet-actual-native-edges* sheet)
      (setf (getf initargs :x) (floor left)
	    (getf initargs :y) (floor top))
    initargs))


(defmethod compose-space ((te motif-text-editor) &key width height)
  (declare (ignore width height))
  (let ((sr (call-next-method)))
    (setq sr (silica::copy-space-requirement sr))
    (setf (space-requirement-max-width sr) +fill+
	  (space-requirement-max-height sr) +fill+)
    sr))

;;; Toggle button

(defclass motif-toggle-button (xt-leaf-pane 
			       motif-value-pane
			       toggle-button)
	  ())

(defmethod find-widget-class-and-initargs-for-sheet ((port motif-port)
						     (parent t)
						     (sheet motif-toggle-button))
  (with-accessors ((set gadget-value)
		   (label gadget-label)
		   (indicator-type gadget-indicator-type)) sheet
    (values 'tk::xm-toggle-button 
	    (append (list :set set)
		    (and label (list :label-string label))
		    (list :indicator-type 
			  (ecase indicator-type
			    (:one-of :one-of-many)
			    (:some-of :n-of-many)))))))

(defmethod gadget-value ((gadget motif-toggle-button))
  (if (sheet-direct-mirror gadget)
      (tk::get-values (sheet-mirror gadget) :set)
    (call-next-method)))

(defmethod (setf gadget-value) (nv (gadget motif-toggle-button) &key)
  (when (sheet-direct-mirror gadget)
    (tk::set-values (sheet-mirror gadget) :set nv)))

(defmethod add-sheet-callbacks :after ((port motif-port) 
				       (sheet clim-stream-sheet)
				       (widget tk::xm-drawing-area))
  ;;---- It would suprise me if we needed this.
  (tk::add-callback widget 
		    :resize-callback 
		    'sheet-mirror-resized-callback
		    sheet))


(defun scrollbar-changed-callback (widget which scroller)
  (let* ((vp (sheet-child scroller))
	 (viewport (viewport-viewport-region vp))
	 (extent (stream-output-history (sheet-child vp))))
    (multiple-value-bind
      (value size)
	(tk::get-values widget :value :slider-size)
      (case which
	(:vertical
	  (scroll-extent
	    (sheet-child vp)
	    :x (bounding-rectangle-min-x viewport)
	    :y (truncate
		 (* (max 0 (- (bounding-rectangle-height extent)
			      (bounding-rectangle-height viewport)))
		    (if (= size 100)
			0
			(/ value (- 100 size)))))))
	(:horizontal
	  (scroll-extent
	    (sheet-child vp)
	    :x (truncate
		 (* (max 0 (- (bounding-rectangle-width extent)
			      (bounding-rectangle-width viewport)))
		    (if (= size 100)
			0
			(/ value (- 100 size)))))
	    :y (bounding-rectangle-min-y viewport)))))))
	
;;;;;;;;;;;;;;;

(defclass xm-viewport
	  (viewport
	   mirrored-sheet-mixin)
    ())

(defmethod find-widget-class-and-initargs-for-sheet ((port motif-port)
						     (parent t)
						     (sheet xm-viewport))
  (values 'tk::xm-drawing-area
	  '(:scrolling-policy :application-defined
	    :margin-width 0 :margin-height 0
	    :resize-policy :none
	    :scroll-bar-display-policy :static)))

(defmethod add-sheet-callbacks :after ((port motif-port) 
				       (sheet xm-viewport)
				       (widget tk::xm-drawing-area))
  ;;--- I wonder whether this is needed since it should not be resized by
  ;; the toolkit and only as part of the goe management code that will
  ;; recurse to children anyway
  (tk::add-callback widget 
		    :resize-callback 
		    'sheet-mirror-resized-callback
		    sheet))

(defclass motif-radio-box (motif-geometry-manager
			   mirrored-sheet-mixin
			   sheet-multiple-child-mixin
			   sheet-permanently-enabled-mixin
			   radio-box
			   pane
			   ask-widget-for-size-mixin)
    ())

(defmethod sheet-adopt-child :after ((gadget motif-radio-box) child)
  (setf (gadget-client child) gadget))

(defmethod find-widget-class-and-initargs-for-sheet ((port motif-port)
						     (parent t)
						     (sheet motif-radio-box))
  
  (with-accessors ((orientation gadget-orientation)) sheet
    (values 'tk::xm-radio-box
	    (list :orientation orientation))))

(defmethod value-changed-callback :after ((v gadget)
					  (client motif-radio-box)
					  (id t)
					  (value t))
  (when (eq value t)
    (setf (radio-box-current-selection client) id)
    (value-changed-callback client 
			    (gadget-client client)
			    (gadget-id client) 
			    id)))

;;; Lets have a frame so that it can be nice and pretty


(defclass xm-frame-viewport
	  (sheet-single-child-mixin
	   sheet-permanently-enabled-mixin
	   silica::wrapping-space-mixin
	   pane
	   mirrored-sheet-mixin)
    ())




(defclass motif-frame-pane (motif-geometry-manager
			    mirrored-sheet-mixin
			    sheet-single-child-mixin
			    sheet-permanently-enabled-mixin
			    pane
			    silica::layout-mixin)
	  ())

(defmethod initialize-instance :after ((pane motif-frame-pane) &key
							       frame-manager frame
							       contents)
  (let ((viewport (with-look-and-feel-realization (frame-manager frame)
		    (make-pane 'xm-frame-viewport))))
    (sheet-adopt-child pane viewport)
    (sheet-adopt-child viewport contents)))


(defmethod find-widget-class-and-initargs-for-sheet ((port motif-port)
						     (parent t)
						     (sheet motif-frame-pane))
  (values 'tk::xm-frame nil))

(defmethod compose-space ((fr motif-frame-pane) &key width height)
  (declare (ignore width height))
  (silica::space-requirement+*
   (compose-space (sheet-child fr))
   :width 4 :height 4))

(defmethod allocate-space ((fr motif-frame-pane) width height)
  ;;-- We do not need to do anything here because
  ;;-- the pane should resize its child
  )
