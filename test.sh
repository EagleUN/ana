# pref=http://192.168.99.107:9090/ana
pref=http://127.0.0.1:9090/ana

echo "INSERT follow diego->juan"
curl $pref/users/diego/following -d "{\"followingId\": \"juan\"}" -H "Content-Type: application/json"
echo && echo

echo "getFollowing(diego)"
curl $pref/users/diego/following
echo && echo

echo "getFollowers(juan)"
curl $pref/users/juan/followers
echo && echo

echo "getFollow(diego,juan)"
curl $pref/users/diego/following/juan
echo && echo

echo "DELETE follow diego->juan"
curl -X DELETE $pref/users/diego/following/juan
echo && echo
