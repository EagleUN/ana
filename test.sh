# pref=http://192.168.99.107:9090/ana
pref=http://127.0.0.1:9090/ana

echo "INSERT follow dfcb2566-1a8d-4cb3-9f46-773adee5bfb4->35f3e5b9-be19-4533-95ae-5d1f02302de6"
curl $pref/users/dfcb2566-1a8d-4cb3-9f46-773adee5bfb4/following -d "{\"followingId\": \"35f3e5b9-be19-4533-95ae-5d1f02302de6\"}" -H "Content-Type: application/json"
echo && echo

echo "getFollowing(dfcb2566-1a8d-4cb3-9f46-773adee5bfb4)"
curl $pref/users/dfcb2566-1a8d-4cb3-9f46-773adee5bfb4/following
echo && echo

echo "getFollowers(35f3e5b9-be19-4533-95ae-5d1f02302de6)"
curl $pref/users/35f3e5b9-be19-4533-95ae-5d1f02302de6/followers
echo && echo

echo "getFollow(dfcb2566-1a8d-4cb3-9f46-773adee5bfb4,35f3e5b9-be19-4533-95ae-5d1f02302de6)"
curl $pref/users/dfcb2566-1a8d-4cb3-9f46-773adee5bfb4/following/35f3e5b9-be19-4533-95ae-5d1f02302de6
echo && echo

echo "DELETE follow dfcb2566-1a8d-4cb3-9f46-773adee5bfb4->35f3e5b9-be19-4533-95ae-5d1f02302de6"
curl -X DELETE $pref/users/dfcb2566-1a8d-4cb3-9f46-773adee5bfb4/following/35f3e5b9-be19-4533-95ae-5d1f02302de6
echo && echo

echo "TEST invalid user ids"

echo "INSERT follow diego->victor"
curl $pref/users/diego/following -d "{\"followingId\": \"victor\"}" -H "Content-Type: application/json"
echo && echo

echo "getFollowing(diego)"
curl $pref/users/diego/following
echo && echo

echo "getFollowers(victor)"
curl $pref/users/victor/followers
echo && echo

echo "getFollow(diego,victor)"
curl $pref/users/diego/following/victor
echo && echo

echo "DELETE follow diego->victor"
curl -X DELETE $pref/users/diego/following/victor
echo && echo

