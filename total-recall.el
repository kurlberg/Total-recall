;;; Commentary:
;; 
; My attempt of dressing up w3m so that (the text of) every web page
; I read is saved.
;
; Possible improvements: add list of URL's to be ignored.  E.g.,
; "frontpages" such as www.slashdot.org; we almost never want to save
; anything but the articles clicked on.
;
; Note: we assume that the checksum program will give its result as a
; space delimited string, with the checksum as the first word.  (This
; works with md5sum, gsha1sum, and cksum.)


;;; History:
;; 
;; PK started hacking on this in August 2009. 

;;; Code:

;;;; Things for the user to configure.  However, we try to set things
;;;; up to be "zero config", with reasonable defaults etc.

(defvar total-recall-directory 
  (concat (getenv "HOME") "/.total-recall")
  "Directory where web pages will be kept.")

(defvar total-recall-checksum-programs 
  '("shasum" "gsha1sum" "sha1sum" "md5sum" "cksum")
  "List of possible checksum programs, in order of preference.  
Feel free to add more!")



;; Zeroconf way of selecting an executable.

(defun total-recall-select-executable (l)
  (if (null l)
      (error "No binary in list available!")
    (let ((executable (executable-find (car l))))
      (if executable
	  executable
	(total-recall-select-executable (cdr l))))))

(defvar total-recall-checksum-program
  ;; MAYBE FIXME: Maybe better if the binary is fixed after a first
  ;; inital selection - what if the user shares/syncs his
  ;; ~/.total-recall between several computers, and they have
  ;; different checksum programs installed!?  (Not a massive problem,
  ;; the user can later run a program which renames files according to
  ;; their (new) checksum.
  (total-recall-select-executable total-recall-checksum-programs)
  "Which binary to use for checksums.")

;; Create directory for saving history if it does not already exist.
(unless (file-exists-p total-recall-directory)
  (make-directory total-recall-directory))

;; FIXME: bad style to use defvar here?
(setq total-recall-tmp-file-name (concat total-recall-directory "/tc-test"))

(defun total-recall-get-cksum ()
  "Compute cksum of file corresponding to temporarily saved buffer."
  ; Note: use as strong checksum algorithm as possible; say SHA or
  ; md5.  Likelyhood of adversary making html pages with intentional
  ; collisions is probably extremely small, but...
  (car (split-string
	(shell-command-to-string 
	 (concat total-recall-checksum-program " " total-recall-tmp-file-name)))))
;;JAVE TODO do a process here... async and works with tramp.
;; FIXME: hack away! :-)
;; Actually, is this worth doing?  The text is saved *after* async
;; downloading, and the actual saving and computing of the checksum
;; ought to be "instant".

(defun total-recall-save-page (url)
  ; Dump web page text to file, compute its checksum, and rename file
  ; to checksum.  

  ; Note: functions in w3m-display-hook are called with the url in
  ; question as an argument, but we don't use it.
  (let ((coding-system-for-write 'utf-8))
    (write-region nil nil total-recall-tmp-file-name t)
    (rename-file total-recall-tmp-file-name 
		 (concat total-recall-directory "/" 
			 (total-recall-get-cksum))
		 t)))

(add-hook 'w3m-display-hook 'total-recall-save-page)

;; Remark: Advising w3m-goto-url does not work; pages are retrived
;; asyncronously, and the adviced code is sometimes run *before* the
;; text has been fetched.  Switching to a hook instead: stuff in
;; w3m-display-hook is run *after* the web page has been fetched.

(provide 'total-recall)
