EMACS = emacs

check:
	$(EMACS) -q -batch -l gather.el -l gather-test.el \
		-f ert-run-tests-batch-and-exit
	$(EMACS) -q -batch -l gather.elc -l gather-test.el \
		-f ert-run-tests-batch-and-exit

compile:
	$(EMACS) -q -batch -f batch-byte-compile gather.el
