cd $(dirname $0)

if [ -n "$(which tput)" ]; then
  green="`tput sgr0; tput setaf 2`"
  GREEN="`tput setaf 2; tput bold`"
  RED="`tput setaf 1; tput bold`"
  colors_reset="`tput sgr0`"
fi

passed="${GREEN}# OK"

for f in test*.ss ; do
    { echo "$green# $f $colors_reset" && csi -s $f && echo -e "$passed"; } || { echo -e "$RED# FAILED: $f\n"; exit 1; }
    echo -e "$colors_reset"
done

echo -e "$GREEN#\n# ALL TESTS PASSED\n#$colors_reset\n"

