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

(defvar pk-total-recall-directory 
  (concat (getenv "HOME") "/.total-recall")
  "Directory where web pages will be kept.")

(defvar pk-checksum-programs '("shasum" "gsha1sum" "sha1sum" 
			       "md5sum" "cksum")
  "List of possible checksum programs, in order of preference.  
Feel free to add more!")




;; Zeroconf way of selecting a binary.
;; FIXME: bad notation to call it binary?
(defun pk-util-select-binary (l)
  "Given a list of programs, select the first one found using 'which'."
  (if (null l)
      (error "No binary in list available!")
    (let ((binary (shell-command-to-string
		   (concat "which " (car l)))))
      (if (not (string= "" binary))
	  (car (split-string binary))
	(pk-util-select-binary (cdr l))))))

(defvar pk-checksum-program
  ;; FIXME: Maybe better if the binary is fixed after a first inital
  ;; selection - what if the user shares/syncs his ~/.total-recall
  ;; between several computers, and they have different checksum
  ;; programs installed!?  (Not a massive problem, the user can later
  ;; run a program which renames files according to their (new)
  ;; checksum.
  (pk-util-select-binary pk-checksum-programs)
  "Which binary to use for checksums.")

;; Create directory for saving history if it does not already exist.
(unless (file-exists-p pk-total-recall-directory)
  (make-directory pk-total-recall-directory))

;; FIXME: bad style to use defvar here?
(defvar pk-tmp-file-name (concat pk-total-recall-directory "/tc-test"))

(defun pk-get-cksum ()
  "Compute cksum of file corresponding to temporarily saved buffer."
  ; Note: use as strong checksum algorithm as possible; say SHA or
  ; md5.  Likelyhood of adversary making html pages with intentional
  ; collisions is probably extremely small, but...
  (car (split-string
	(shell-command-to-string 
	 (concat pk-checksum-program " " pk-tmp-file-name)))))
;;JAVE TODO do a process here... async and works with tramp.
;; FIXME: hack away! :-)
;; Actually, is this worth doing?  The text is saved *after* async
;; downloading, and the actual saving and computing of the checksum
;; ought to be "instant".

(defun pk-save-page (url)
  ; Dump web page text to file, compute its checksum, and rename file
  ; to checksum.  

  ; Note: functions in w3m-display-hook are called with the url in
  ; question as an argument, but we don't use it.
  (let ((coding-system-for-write 'utf-8))
    (write-region nil nil pk-tmp-file-name t)
    ;(message (pk-get-cksum))
    (rename-file pk-tmp-file-name 
		 (concat pk-total-recall-directory "/" (pk-get-cksum))
		 t)))

(add-hook 'w3m-display-hook 'pk-save-page)

;; Remark: Advising w3m-goto-url does not work; pages are retrived
;; asyncronously, and the adviced code is sometimes run *before* the
;; text has been fetched.  Switching to a hook instead: stuff in
;; w3m-display-hook is run *after* the web page has been fetched.

(provide 'pk-total-recall)