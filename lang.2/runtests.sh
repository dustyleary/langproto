
green="`tput sgr0; tput setaf 2`"
GREEN="`tput setaf 2; tput bold`"
RED="`tput setaf 1; tput bold`"
colors_reset="`tput sgr0`"

testCaseName="$green"
passed="${GREEN}# OK"

for f in sexpr_test.rb test*.rb ; do
    { echo "$testCaseName# ./$f$colors_reset" && ./$f && echo -e "$passed"; } || { echo -e "$RED# FAILED: ./$f\n"; exit 1; }
    echo -e "$colors_reset\n"
done

echo -e "$GREEN#\n# ALL TESTS PASSED\n#$colors_reset\n"

