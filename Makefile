EMACS = emacs

check:
	$(EMACS) -q -batch -L . -l gather.el -l gather-test.el \
		-f ert-run-tests-batch-and-exit
	$(EMACS) -q -batch -L . -l gather.elc -l gather-test.el \
		-f ert-run-tests-batch-and-exit

compile:
	$(EMACS) -q -batch -f batch-byte-compile gather.el
