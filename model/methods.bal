import ballerinax/jdbc;
import ballerina/sql;

jdbc:Client followsDB = new({
    url: "jdbc:postgresql://localhost:25432/feedms",
    username: "feedms",
    password: "yiuPh9eipiu2la9ie8gaifee"
});

type ModelError error<string, map<anydata|error>>;

function buildError(string message) returns ModelError {
    ModelError e = error(message, { });
    return e;
}


public function insertFollow(string followerId, string followingId) returns boolean {
    var retWithKey = followsDB->update("INSERT INTO follows (follower_id, following_id) values (?, ?)", followerId, followingId);
    return (retWithKey is sql:UpdateResult);
}


public function getFollowers(string userId) returns string[]|error {
    var selectRet = followsDB->select("SELECT follower_id, following_id FROM follows WHERE following_id = ?", Follow, userId);
    if ( selectRet is table<Follow> ) {
        string[] userIdList = [];
        foreach var row in selectRet {
            userIdList[userIdList.length()] = row.follower_id;
        }
        return userIdList;
    }
    else {
        return buildError("Error getting followers from DB");
    }
}
