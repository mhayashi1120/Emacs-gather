(require 'ert)

(ert-deftest gather-format-0001 ()
  :tags '(gather)
  (should (equal (gather-format "{%%%{1}}%2" "A" "B" "C") "{%B}C"))
  (should (equal (gather-format "{%a1}" "A" "B" "C") "{a1}")))
