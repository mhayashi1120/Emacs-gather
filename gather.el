;;; gather.el --- Gather string in buffer.

;; Author: Masahiro Hayashi <mhayashi1120@gmail.com>
;; Keywords: matching, convenience, tools
;; URL: https://github.com/mhayashi1120/Emacs-gather/raw/master/gather.el
;; Emacs: GNU Emacs 21 or later
;; Version: 1.0.4

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; gather.el provides search regexp and kill text.  This is not replacing
;; nor modifying Emacs `kill-ring' mechanism.  You MUST know about elisp
;; regular-expression.
;; Have similar concept of `occur'.  If I think `occur' have line oriented
;; feature, gather.el have list oriented feature.  You can handle the list,
;; as long as you can handle Emacs-Lisp list object.

;;; Install:

;; Put this file into load-path'ed directory, and byte compile it if
;; desired. And put the following expression into your ~/.emacs.
;;
;;     (require 'gather)
;;     (define-key ctl-x-r-map "\M-w" 'gather-matching-kill-save)
;;     (define-key ctl-x-r-map "\C-w" 'gather-matching-kill)
;;     (define-key ctl-x-r-map "\M-y" 'gather-matched-insert)
;;     (define-key ctl-x-r-map "\M-Y" 'gather-matched-insert-with-format)
;;     (define-key ctl-x-r-map "v" 'gather-matched-show)

;; ********** Emacs 22 or earlier **********
;;     (require 'gather)
;;     (global-set-key "\C-xr\M-w" 'gather-matching-kill-save)
;;     (global-set-key "\C-xr\C-w" 'gather-matching-kill)
;;     (global-set-key "\C-xr\M-y" 'gather-matched-insert)
;;     (global-set-key "\C-xr\M-Y" 'gather-matched-insert-with-format)
;;     (global-set-key "\C-xrv" 'gather-matched-show)

;;; Usage:

;; C-x r M-w : Kill the regexp in current-buffer.
;; C-x r C-w : Kill and delete regexp in current-buffer.
;; C-x r M-y : Insert killed text to point.
;; C-x r M-Y : Insert killed text as formatted text to point.
;; C-x r v   : View killed text status.

;; Why gather.el?

;; 1. Hope to get list of function names in elisp file buffer.
;; 2. C-x r M-w with regexp like "(defun \\(.+?\\_>\\)"
;; 3. Now, you can paste function names by C-x r M-y with 1
;; 4. Write a external document of functions has been gathered.

;;; Code:

(defvar transient-mark-mode)
(defvar current-prefix-arg)

(defvar gather-killed nil)
(defvar gather-matching-regexp-ring nil)

;;;###autoload
(defun gather-matching-kill-save (regexp)
  "Gather matching REGEXP save to `gather-killed'.
Use \\[gather-matched-insert] or \\[gather-matched-insert-with-format] after capture."
  (interactive (gather-matching-read-args "Regexp: " nil))
  (gather-matching-do-command regexp nil))

;;;###autoload
(defun gather-matching-kill (regexp)
  "Gather matching REGEXP kill to `gather-killed'.
Same as `gather-matching-kill-save' but with deleting the matched text."
  (interactive (gather-matching-read-args "Regexp: " t))
  (gather-matching-do-command regexp 'erase))

;;;###autoload
(defun gather-matched-insert (subexp &optional separator)
  "Insert SUBEXP from `gather-killed'.
That was set by \\[gather-matching-kill-save] \\[gather-matching-kill]."
  (interactive (gather-matched-insert-read-args))
  (barf-if-buffer-read-only)
  (push-mark (point))
  (let ((sep (or separator "\n"))
        (inhibit-read-only t))
    (mapcar
     (lambda (x)
       (let ((str (nth subexp x)))
         (when str
           (insert str))
         (insert sep)
         str))
     gather-killed)))

;;;###autoload
(defun gather-matched-insert-with-format (format &optional separator)
  "Insert gathered list with format.

Example:

Gathered list: ((\"defun A\" \"defun\" \"A\") (\"defun B\" \"defun\" \"B\"))
Format: \"(%1 %2 (arg) \"%2\")\"

Then insert following text.

\(defun A (arg) \"A\")
\(defun B (arg) \"B\")

FORMAT accept `format' function or C printf like `%' prefixed sequence.
But succeeding char can be `digit' or `{digit}'
 (e.g. %1, %{1}, %{10} but cannot be %10)
digit is replacing to gathered items that is captured by
`gather-matching-kill-save', `gather-matching-kill'."
  (interactive (gather-matched-insert-format-read-args))
  (barf-if-buffer-read-only)
  (push-mark (point))
  (let ((sep (or separator "\n"))
	(inhibit-read-only t))
    (mapcar
     (lambda (x)
       (let ((str (apply 'gather-format format x)))
         (insert str)
	 (insert sep)
	 str))
     gather-killed)))

;;;###autoload
(defun gather-matched-show ()
  "Show gathered information."
  (interactive)
  (let ((num (length gather-killed)))
    (cond
     ((= num 0)
      (message "Nothing is gathered."))
     ((= num 1)
      (message "Gathered a element."))
     (t
      (message "Gathered %d elements." num)))))

(defun gather-matching-do-command (regexp erasep)
  (gather-matching-regexp-ring-add regexp)
  (let (start end)
    (if (and transient-mark-mode mark-active)
	(setq start (region-beginning)
	      end (region-end))
      (setq start (point-min)
	    end (point-max)))
    (save-restriction
      (narrow-to-region start end)
      (setq gather-killed (gather-matching regexp erasep))
      (gather-matched-show))))

;;;###autoload
(defun gather-matching (regexp &optional erasep no-property)
  "Gather REGEXP from current buffer.
Optional arg ERASEP no-nil means delete gathered text.
Optional arg NO-PROPERTY means remove any of text property."
  (let ((depth (regexp-opt-depth regexp))
	subexp ret getfunc)
    (when (string-match regexp "")
      (signal 'invalid-regexp '("Regexp match to nothing.")))
    (when erasep
      (cond
       ((integerp erasep)
	(when (or (> erasep depth)
		  (< erasep 0))
	  (signal 'args-out-of-range '("erasep args out of ranges")))
	(setq subexp erasep))
       (t
	(setq subexp 0))))
    (setq getfunc
	  (if no-property
	      'match-string-no-properties
	    'match-string))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward regexp nil t)
	(let ((i 0)
	      (datum nil))
	  (while (<= i depth)
	    (setq datum
		  (cons (funcall getfunc i) datum))
	    (setq i (1+ i)))
	  (setq datum (nreverse datum))
	  (when subexp
	    (replace-match "" subexp))
	  (setq ret
		(cons datum ret))))
      (nreverse ret))))

(defun gather-matching-regexp-ring-add (regexp)
  (let* ((ring gather-matching-regexp-ring)
         (ring (delete regexp ring))
         (ring (cons regexp ring)))
    (setq gather-matching-regexp-ring ring)))

(defun gather-matching-read-args (prompt erasep)
  (when erasep
    (barf-if-buffer-read-only))
  (let ((regexp (read-from-minibuffer
                 prompt nil nil nil
                 'regexp-history
                 nil t)))
    (list regexp)))

(defun gather-matched-insert-read-args ()
  (barf-if-buffer-read-only)
  (gather-matching--check-regexp-ring)
  (let* ((universal-arg current-prefix-arg)
         (subexp-max (regexp-opt-depth (car gather-matching-regexp-ring)))
         (prompt-last (gather-matching-previous-as-prompt))
         (num (gather-read-number
               (format "%s Subexp(<= %d): "
                       prompt-last subexp-max)
               0 subexp-max))
         (sep (and universal-arg
                   (read-from-minibuffer "Separator: "))))
    (list num sep)))

(defun gather-matched-insert-format-read-args ()
  (barf-if-buffer-read-only)
  (gather-matching--check-regexp-ring)
  (let* ((universal-arg current-prefix-arg)
         (prompt-last (gather-matching-previous-as-prompt))
         (format (read-from-minibuffer
                  (format "%s Insert format (like this): " prompt-last)
                  "%{0}"))
         (sep (and universal-arg (read-from-minibuffer "Separator: "))))
    (list format sep)))

(defun gather-matching-previous-as-prompt ()
  (format "Last gatherd: %s "
	  (car gather-matching-regexp-ring)))

(defun gather-matching--check-regexp-ring ()
  (unless gather-matching-regexp-ring
    (error "Matched ring is empty")))

(defun gather-read-number (prompt min max)
  (let ((num nil)
	(val ""))
    (while (or (not (numberp num))
	       (not (and (<= min num) (<= num max))))
      (condition-case err
	  (progn
	    (setq num (read-minibuffer prompt val))
	    (setq val (prin1-to-string num)))
	(end-of-file nil)))
    num))

;; format special FORMAT-STRING
(defun gather-format (format-string &rest args)
  (let ((start 0)
	(ret '())
	(escape-char "%")
        (case-fold-search nil)
	index next-start prev-end)
    (while (string-match escape-char format-string start)
      (setq prev-end (match-beginning 0))
      (setq next-start (match-end 0))
      (setq ret (cons (substring format-string start prev-end) ret))
      (setq start next-start)
      (cond
       ((eq (string-match "\\(?:\\([0-9]\\)\\|{\\([0-9]+\\)}\\)"
                          format-string start) start)
        ;; indicate index of `args'
	(setq next-start (match-end 0))
	(setq index (string-to-number
                     (or (match-string 1 format-string)
                         (match-string 2 format-string))))
	(setq ret (cons (or (nth index args) "") ret))
        (setq start next-start))
       ((eq (string-match escape-char format-string start) start)
        ;; escaped escape char
        (setq ret (cons escape-char ret))
        (setq start (1+ start)))
       ;; unknown escaped char is ignored
       (t)))
    (setq ret (cons (substring format-string start) ret))
    (apply 'concat (nreverse ret))))

(provide 'gather)

;;; gather.el ends here
