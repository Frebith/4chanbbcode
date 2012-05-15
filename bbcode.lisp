(defpackage :4bbcode
  (:use :common-lisp :parenscript)
  (:nicknames :4bbc)
  (:export #:compile-4bbc))

(in-package :4bbcode)

(defparameter *name*
  "//@name            4chan bbcode")
(defparameter *description*
  "//@description     Adds bbcode to 4chan imageboards and enables passive non-breaking spaces when posting
//                   Following bbcode is supported:
//                   b => bold, u => underline, o => overline
//                   i => italic, s => strikethrough, m => courier text
//                   spoiler => spoiler
//                   sup => makes text smaller and higher on the line
//                   sub => makes text smaller and lower on the line
//                   aa => for SJIS art
//                   sp => &nbsp [Note: you never need to use these explicitly]")
(defparameter *includes*
  "//@include         http:*//boards.4chan.org/*")
(defparameter *author*
  "//@author          Frebith")
(defparameter *version*
  "//@version         0.8")
(defparameter *update*
  "//@updateURL       https://raw.github.com/Frebith/4chanbbcode/master/4chan-bbcode.js")
(defparameter *license*
  "//@license         MIT; http://www.opensource.org/licenses/mit-license.php")
(defparameter *MIT*
 "
/*
*Copyright (c) 2012 Frebith
*Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
*and associated documentation files (the 'Software'), to deal in the Software without restriction, 
*including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
*and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do 
*so, subject to the following conditions: 
*
*The above copyright notice and this permission notice shall be included in all copies or substantial 
*portions of the Software. 
*
*THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
*LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN 
*NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
*WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
*SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/")
(defparameter *header*
  (format nil "~A~%~A~%~A~%~A~%~A~%~A~%~A~%~A~%~A~%~%"
               "// ==UserScript=="
               *name*
               *version*
               *author*
               *description*
               *license*
               *includes*
               *update*
               "// ==/UserScript=="))

;v0.8
(defun compile-4bbc (file)
  (with-open-file (out file :direction :output
                       :if-exists :supersede)
    (princ *header* out)
    (princ *MIT* out)
    (format out "~A~%" 
            (ps 
              ;;old posts already checked
              (var old-posts (make-array))
              ;;time between updates [ms]
              (var +update-time+ 5000) 
              ;;css
              (var css (chain document (create-element "style")))
              (setf (@ css 'type) "text/css")
              (setf (@ css 'inner-h-t-m-l) 
                    ".spoiler{background:#000;color:#000;}
.spoiler:hover{color:#FFF;}
.aa{text-align:left;font-family:IPAMonaPGothic,Mona,'MS PGothic',YOzFontAA97 !important}
.o{text-decoration:overline}
tt{font-size:smaller}")
              (chain document body (append-child css))


              
              ;;updates thread every +update-time+ time
              (var update-s (chain (set-timeout update-submit +update-time+)))
              ;;initially call check-thread to do first scan
              (update-submit)

              ;;;&nbsp edit
              (defun update-submit ()
                ;;get all inputs
                (var inputs (chain document (get-elements-by-tag-name "input")))
                (dotimes (i (@ inputs 'length))
                  ;;loop through to find submit button
                  (when (= (chain (getprop inputs i) (get-attribute "type")) "submit")
                    (chain (getprop inputs i) (add-event-listener "mouseup"
                                                                  (lambda (e)
                                                                    (spacify))
                                                                  false))))
                (setf update-s (chain (set-timeout update-submit +update-time+))))
              (defun spacify ()
                ;;get the textareas
                (let ((text-areas (chain document (get-elements-by-tag-name "textarea"))))
                  (dotimes (i (@ text-areas 'length))
                    (update-text (getprop text-areas i)))))

              (defun update-text (text)
                ;;replace all spaces with &nbsp which will later be parsed by the bbcode into proper &nbsp
                (let ((new-text "")
                      (ch "")
                      (spec false)
                      (spc 0)
                      (lc ""))
                  (dotimes (i (@ text 'value 'length))
                    ;;store last char
                    (setf lc (chain ch (char-at (1- (@ ch 'length)))))
                    ;;get next char
                    (setf ch (chain text value (char-at i)))
                    (cond
                      ((= ch " ") 
                       (if spec ;only do (sp ...) on >= consecutive spaces
                           (progn
                             (incf spc) ;keep count of special spaces
                             (setf ch "(sp "))
                           (setf ch " "))
                       ;;consecutive go
                       (setf spec true))
                      ((= ch #\NewLine)
                       (dotimes (j spc)
                         (setf ch (+ ")" ch)))
                       (setf spec false)
                       (setf spc 0))
                      (t (setf spec false)))
                    (setf new-text (+ new-text ch)))
                  (dotimes (i spc)
                    (setf new-text (+ new-text ")")))
                  (setf (@ text 'value) new-text))
                t)

              ;;;BBCODE portion

              ;;updates thread every +update-time+ time
              (var update (chain (set-timeout check-thread +update-time+)))
              ;;initially call check-thread to do first scan
              (check-thread)
              
              (defun check-thread ()
                ;;get all <blockquotes.../> posts
                (var posts (chain document (get-elements-by-class-name "postMessage")))
                (dotimes (i (@ posts 'length))
                  ;;update post as long as it's new
                  (when (= (chain old-posts (index-of (chain (getprop posts i)  (get-attribute "id")))) -1) 
                    (update-posts (getprop posts i))
                    ;;remember old
                    (chain old-posts (push (chain (getprop posts i) (get-attribute "id"))))))
                ;;reset timer to go off in +update-time+ time again
                (setf update (chain (set-timeout check-thread +update-time+)))
                t)
              
              (defun update-posts (post)
                (let ((new-post "")
                      (m-tag "")
                      (c-tag "")
                      (tags (make-array))
                      (matching false)
                      (ch ""))
                  (dotimes (i (@ post 'inner-h-t-m-l 'length))
                    (setf ch (chain post inner-h-t-m-l (char-at i)))
                    (if matching
                        (cond
                          ;;end of tag
                          ((or (= ch " ")
                               (= ch "<")) ;brbrbrbrbr
                           ;;stop matching only
                           (setf matching false)
                           ;;store last tag on space
                           (chain tags (push c-tag))
                           ;;update to new tag
                           (setf c-tag m-tag)
                           (setf m-tag "")
                           ;;insert new html
                           (case c-tag
                             (("b") (setf new-post (+ new-post "<b>")))
                             (("u") (setf new-post (+ new-post "<u>")))
                             (("i") (setf new-post (+ new-post "<i>")))
                             (("s") (setf new-post (+ new-post "<s>")))
                             (("o") (setf new-post (+ new-post "<span class=\"o\">")))
                             (("m") (setf new-post (+ new-post "<tt>")))
                             (("spoiler") (setf new-post (+ new-post "<span class=\"spoiler\" onmouseout=\"this.style.color=this.style.backgroundColor='#000'\" onmouseover=\"this.style.color='#FFF';\">")))
                             (("sup") (setf new-post (+ new-post "<sup>")))
                             (("sub") (setf new-post (+ new-post "<sub>")))
                             (("aa") (setf new-post (+ new-post "<span class=\"aa\">")))
                             (("sp")
                              (if (= (chain new-post (char-at (1- (@ new-post 'length)))) " ")
                                  (setf new-post (+ (chain new-post (substring 0 (1- (@ new-post 'length))))
                                                    "&nbsp;"))
                                  (setf new-post (+ new-post "&nbsp;"))))
                             ;;not a tag
                             (t 
                              (setf new-post (+ new-post "(" c-tag " "))
                              (setf c-tag "")))
                           ;brbrbr
                           (when (= ch "<")
                             (setf new-post (+ new-post "<"))))
                          ((= ch ")") ; no tags support (...) only (... ) for now...
                           ;;turn matchign off
                           (setf matching false)
                           ;;save text
                           (setf new-post (+ new-post "(" m-tag ")"))
                           (setf m-tag ""))
                          ;; update m-tag
                          (t
                           (setf m-tag (+ m-tag ch))))
                        (cond
                          ;; turn on matching
                          ((= ch "(")
                           (setf matching true))
                          ;; finish current tag
                          ((and (= ch ")")
                                c-tag)
                           ;;insert html
                           (setf new-post (+ new-post (finish-tag c-tag)))
                           ;;load last tag found
                           (setf c-tag (chain tags (pop))))
                          ;;echo character
                          (t 
                           (setf new-post (+ new-post  ch))))))
                  ;;update post with new content
                  (setf (@ post 'inner-h-t-m-l) new-post)
                  t))
              
              (defun finish-tag (tag)
                (case tag
                  (("b") "</b>")
                  (("u") "</u>")
                  (("i") "</i>")
                  (("s") "</s>")
                  (("m") "</tt>")
                  (("sup") "</sup>")
                  (("sub") "</sub>")
                  (("spoiler" "o" "aa") "</span>")
                  (t "")))))))
