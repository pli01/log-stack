test_name="$(basename $0)"
timeout=3;
test_result=1
[ "$#" -eq 0 ] && exit 1
echo $# $@
until [ "$timeout" -le 0 -o "$test_result" -eq "0" ] ; do
  test_output=$( $@ )
  test_result=$?
 if [ "$test_result" -gt 0 ] ;then
  echo "Retry $timeout seconds: $test_result";
  (( timeout-- ))
  sleep 1
 fi
done
if [ "$test_result" -gt 0 ] ;then
        echo "ERROR: $test_name $test_result"
        ret=$test_result
        test_status=FAILED
        exit $ret
fi
echo $test_output
