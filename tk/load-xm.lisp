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
;; $fiHeader: load-xm.lisp,v 1.12 92/05/13 17:10:19 cer Exp Locker: cer $

(in-package :tk)



;;;; 

(defvar sys::*libxt-pathname* "/x11/R4/src/mit/lib/Xt/libXt_d.a")
(defvar sys::*libxm-pathname* "/x11/motif-1.1/lib/Xm/libXm.a")

(defun load-from-xm ()
  (unless (ff:get-entry-point (ff:convert-to-lang "XmCreateMyDrawingArea"))
    (load "MyDrawingA.o"
	  :system-libraries (list sys::*libxm-pathname* 
				  sys::*libxt-pathname*
				  sys::*libx11-pathname*)
	  :print t))
  (x11::load-undefined-symbols-from-library
   "stub-motif.o"
   (x11::symbols-from-file 
    "misc/undefinedsymbols.xt"
    "misc/undefinedsymbols.motif")
    '("__unpack_quadruple" 
      "__prod_b10000" 
      "__carry_out_b10000" 
      "__prod_65536_b10000"
      ;; got these when compiling on ox
      "__pack_integer"
      "_class_double"
      "_class_single"
      "_class_extended"
      "__unpack_integer"
      )
    (list sys::*libxm-pathname*
	  sys::*libxt-pathname*
	  sys::*libx11-pathname*)))

(load-from-xm)

