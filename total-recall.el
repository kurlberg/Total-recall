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

;;; Code:
(defvar pk-checksum-programs '("shasum" "gsha1sum" "sha1sum" 
			       "md5sum" "cksum")
  "List of checksum programs, in order of preference.")

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
  (pk-util-select-binary pk-checksum-programs)
  "Which binary to use for checksums.")

(defvar pk-total-recall-directory 
  (concat (getenv "HOME") "/.total-recall"))


(unless (file-exists-p pk-total-recall-directory)
  (make-directory pk-total-recall-directory))

(defvar pk-tmp-file-name (concat pk-total-recall-directory "/tc-test"))

(defun pk-get-cksum ()
  "Compute cksum of file corresponding to temporarily saved buffer."
  ; Note: probably a good idea to replace cksum with some SHA or md5
  ; variant.  Likelyhood of adversary making html pages with
  ; intentional collisions is probably extremely small, but...
  (car (split-string
	(shell-command-to-string 
	 (concat pk-checksum-program " " pk-tmp-file-name)))))

(defun pk-save-page (url)
  ; Dump web page text to file, compute its checksum, and rename file
  ; to checksum.  

  ; Note: functions in w3m-display-hook are called with the url in
  ; question as an argument.
  (let ((coding-system-for-write 'utf-8))
    (write-region nil nil pk-tmp-file-name t)
    ;(message (pk-get-cksum))
    (rename-file pk-tmp-file-name 
		 (concat pk-total-recall-directory "/" (pk-get-cksum))
		 t)))

(add-hook 'w3m-display-hook 'pk-save-page)

;; Advising w3m-goto-url does not work; pages are retrived
;; asyncronously, and the adviced code is sometimes run *before* the
;; text has been fetched.  Switching to a hook instead: stuff in
;; w3m-display-hook is run *after* the web page has been fetched.

;(defadvice w3m-goto-url (after pk-total-recall)
;  "Save the text of visited web page to local copy."
;  ; Note: w3m-goto-url supposedly is primitive for visiting web pages,
;  ; so it should be ok to only advice this function.  However, is this
;  ; really the case?
;
;  (message "before advice")
;  (pk-save-page)
;  (message "after advice")
;  )
;
;(ad-activate 'w3m-goto-url)





(provide 'pk-total-recall)