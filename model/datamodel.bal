
# Model for a follow, a relationship between two users.
# In a follow we state that one user follows another one.
# + follower_id - ID of the user that is following the other 
# + following_id - ID of the user that is being followed.
type Follow record {
    string follower_id;
    string following_id;
};


# Used to store the result of queries that only ask for the follower_id.
# For example, the query for the followers of a given user.
# + follower_id - id of the user that is following
type Follow_FollowerId record {
    string follower_id;
};


# Used to store the result of queries that only ask for the following_id.
# For example, the query for the users that a given user follows.
# + following_id - id of the user being followed
type Follow_FollowingId record {
    string following_id;
};