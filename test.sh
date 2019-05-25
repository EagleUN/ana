pref=http://192.168.99.107:9090/ana

echo "INSERT follow diego->juan"
curl $pref/users/diego/following -d "{\"followingId\": \"juan\"}" -H "Content-Type: application/json"
echo && echo

echo "getFollowing(diego)"
curl $pref/users/diego/following
echo && echo

echo "getFollowers(diego)"
curl $pref/users/victor/followers
echo && echo

echo "DELETE follow diego->juan"
curl -X DELETE $pref/users/diego/following/juan
echo && echo
