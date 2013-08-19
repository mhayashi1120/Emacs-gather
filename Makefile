check:
	emacs -q -batch -eval "(byte-compile-file \"gather.el\")"; \
	emacs -q -batch -l gather.el -l gather-test.el \
		-eval "(ert-run-tests-batch-and-exit '(tag gather))"
