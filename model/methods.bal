import ballerina/io;
import ballerinax/jdbc;
import ballerina/sql;
import ballerina/config;

function get(string config) returns string {
    return config:getAsString(config);
}

string DB_IP       = get("DB_IP");
string DB_PORT     = get("DB_PORT"); 
string DB_NAME     = get("DB_NAME"); 
string DB_USERNAME = get("DB_USERNAME"); 
string DB_PASSWORD = get("DB_PASSOWRD"); 
string DB_URL = "jdbc:postgresql://" + DB_IP + ":" + DB_PORT + "/" + DB_NAME;

jdbc:Client followsDB = new({
    url: DB_URL,
    username: DB_USERNAME,
    password: DB_PASSWORD
});

type ModelError error<string, map<anydata|error>>;

function buildError(string message) returns ModelError
{
    ModelError e = error(message, { });
    return e;
}

# Checks if a user follows another one.
# + followerId - the ID of the user that follows
# + followingId - the ID of the user being followed
# + return - true if the the first user follows the second one, false if not. 
#            returns an error in case something goes wrong doing the update operation.
public function follows(string followerId, string followingId) returns boolean|error
{
    var selectRet = followsDB->select(
            "SELECT follower_id, following_id FROM follows WHERE follower_id = ? AND following_id = ?",
            Follow, followerId, followingId);

    if ( selectRet is table<Follow> ) {
        return selectRet.hasNext();
    }
    else {
        io:println("ERROR: " + <string>selectRet.detail().message);
    }
    return buildError("Error getting followers from DB");
}

public function insertFollow(string followerId, string followingId) returns boolean
{
    io:println("On insertFollow(" + followerId + "," + followingId + ")");
    var retWithKey = followsDB->update(
            "INSERT INTO follows (follower_id, following_id) values (?, ?)",
            followerId, followingId);

    if (retWithKey is sql:UpdateResult) {
        io:println ("Insertion successful!!!");
        return true;
    }
    else {
        io:println("ERROR: " + <string>retWithKey.detail().message);
        //TODO Return error
    }
    return false;
}


public function getFollowers(string userId) returns string[]|error
{
    var selectRet = followsDB->select(
        "SELECT follower_id FROM follows WHERE following_id = ?",
        Follow_FollowerId, userId);

    if ( selectRet is table<Follow_FollowerId> ) {
        string[] userIdList = [];
        foreach var row in selectRet {
            userIdList[userIdList.length()] = row.follower_id;
        }
        return userIdList;
    }
    else {
        io:println("ERROR: " + <string>selectRet.detail().message);
        return buildError("Error getting followers from DB");
    }
}

public function getFollowing(string userId) returns string[]|error
{
    var selectRet = followsDB->select("SELECT following_id FROM Follows WHERE follower_id = ?", Follow_FollowingId, userId );
    if ( selectRet is table<Follow_FollowingId> ) {
        string[] userIdList = [];
        foreach var row in selectRet {
            userIdList[userIdList.length()] = row.following_id;
        }
        return userIdList;
    }
    else {
        io:println("ERROR: " + <string>selectRet.detail().message);
        return buildError("Error getting followers from DB");
    }
}

# Deletes a follow
# + followerId - ID of user following the other
# + followingId - ID of user being followed
# + return - true if the follow is succesfully deleted.
#            false if the follow doesn't exists.
#            error in case something goes wrong.
public function deleteFollow(string followerId, string followingId) returns boolean|error
{
    var ret = followsDB->update(
            "DELETE FROM follows WHERE follower_id = ? AND following_id = ?",
            followerId, followingId );
    if (ret is sql:UpdateResult) {
        return ( ret.updatedRowCount > 0 );
    }
    else  {
        io:println("ERROR: " + <string>ret.detail().message);
    }
    return buildError("Error deleting follower from DB");

}