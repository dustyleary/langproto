ROOTDIR=$(cd $(dirname $0) ; pwd -P)

chsum1=""
MD5=`which md5`
if [ "$MD5" == "" ]; then MD5=`which md5sum`; fi

while [[ true ]]
do
  chsum2=`find $ROOTDIR -type f -print0 | xargs -0 $MD5`
  if [[ "$chsum1" != "$chsum2" ]]; then
    clear
    $ROOTDIR/runtests.sh
    chsum1="$chsum2"
  fi
  sleep 0.05
done

