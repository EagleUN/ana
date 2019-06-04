import ballerina/io;
import ballerinax/jdbc;
import ballerina/sql;
import ballerina/config;
import ballerina/utils;
import ballerina/system;


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
    password: DB_PASSWORD,
    poolOptions: {
        maximumPoolSize: 5,
        idleTimeout: 100000
    }
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
            "SELECT follower_id, following_id FROM follows WHERE follower_id = CAST(? AS uuid) AND following_id = CAST(? AS uuid)",
            Follow, followerId, followingId);

    if ( selectRet is table<Follow> ) {
        return selectRet.hasNext();
    }
    else {
        io:println("ERROR: " + <string>selectRet.detail().message);
    }
    return buildError("Error getting followers from DB");
}

public function insertFollow(string followerId, string followingId) returns boolean|error
{

    var x = system:uuid();
    var y = system:uuid();
    io:println("On insertFollow(" + followerId + "," + followingId + ")");
    var retWithKey = followsDB->update(
            "INSERT INTO follows (follower_id, following_id) values (CAST(? AS uuid), CAST(? AS uuid))",
            followerId, followingId);

    if (retWithKey is sql:UpdateResult) {
        io:println ("Insertion successful!!!");
        return true;
    }
    else {
        io:println("ERROR: " + <string>retWithKey.detail().message);
        return buildError("Error inserting follow to DB");
    }
}


public function getFollowers(string userId) returns string[]|error
{
    var selectRet = followsDB->select(
        "SELECT CAST(follower_id AS varchar) FROM follows WHERE following_id = CAST(? AS uuid)",
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
    var selectRet = followsDB->select("SELECT CAST(following_id AS varchar) FROM Follows WHERE follower_id = CAST(? AS uuid)", Follow_FollowingId, userId );
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
            "DELETE FROM follows WHERE follower_id = CAST(? AS uuid) AND following_id = CAST(? AS uuid)",
            followerId, followingId );
    if (ret is sql:UpdateResult) {
        return ( ret.updatedRowCount > 0 );
    }
    else  {
        io:println("ERROR: " + <string>ret.detail().message);
    }
    return buildError("Error deleting follower from DB");

}