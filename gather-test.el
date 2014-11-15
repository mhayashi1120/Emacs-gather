(require 'ert)

(ert-deftest gather-format-0001 ()
  :tags '(gather)
  (should (equal (gather--format "{%%%{1}}%2" "A" "B" "C") "{%B}C"))
  (should (equal (gather--format "{%a1}" "A" "B" "C") "{a1}")))

(ert-deftest gather-format-0002 ()
  :tags '(gather)
  (should
   (equal
    (gather--format
     "%0 %1 %{1} %{2:S} %{3:03d} %{4:03x} %{5:03o} %{6:0.3f} %{7:5s}"
     "12030040005000600000"
     "1"
     "20"
     "300"
     (number-to-string ?\xfa0)
     (number-to-string (string-to-number "141520" 8))
     "600000"
     "7")
    "12030040005000600000 1 1 20 300 fa0 141520 600000.000     7")))

(ert-deftest gather-format-0003 ()
  :tags '(gather)
  (should
   (equal
    (gather--format
     "%{1:QS} %{2:QS} %{3:QS}"
     ;;dummy
     0
     "(\"a\nA\" b c)"
     "a b c"
     "a\nb"
     )
    "\"(\\\"a\\nA\\\" b c)\" \"a b c\" \"a\\nb\"")))

(ert-deftest gather-format-0004 ()
  :tags '(gather)
  (should
   (equal
    (gather--format
     "%{1:Qs} %{2:Qs} %{3:Qs}"
     ;;dummy
     0
     "(\"a\nA\" b c)"
     "a b c"
     "a\nb"
     )
    "(\"a\\nA\" b c) a a")))
