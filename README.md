# gather.el

gather.el provides search regexp and kill text.  This is not replacing
nor modifying Emacs `kill-ring' mechanism.  You MUST know about elisp
regular-expression.
Have similar concept of `occur'.  If I think `occur' have line oriented
feature, gather.el have list oriented feature.  You can handle the list,
as long as you can handle Emacs-Lisp list object.

## Install:

    (require 'gather)
    (define-key ctl-x-r-map "\M-w" 'gather-matching-kill-save)
    (define-key ctl-x-r-map "\C-w" 'gather-matching-kill)
    (define-key ctl-x-r-map "\M-y" 'gather-matched-insert)
    (define-key ctl-x-r-map "\M-Y" 'gather-matched-insert-with-format)
    (define-key ctl-x-r-map "v" 'gather-matched-show)

## Usage:

* C-x r M-w : Kill the regexp in current-buffer.
* C-x r C-w : Kill and delete regexp in current-buffer.
* C-x r M-y : Insert killed text to point.
* C-x r M-Y : Insert killed text as formatted text to point.
* C-x r v   : View killed text status.
