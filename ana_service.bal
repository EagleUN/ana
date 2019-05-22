import ballerina/http;
import ballerina/io;
import ballerinax/docker;
import ballerina/grpc;

const string ERROR_NO_FOLLOWING_ID_IN_JSON = "Payload should contain a JSON with a string followingId";

#API names for url parameters
const string USER_ID = "userId";
const string OTHER_USER_ID = "otherUserId";

#API names for JSON responses
const string FOLLOWER_ID = "followerId";
const string FOLLOWING_ID = "followingId";

function buildErrorJson ( int code, string message ) returns json {
    json errorJson = { "message" : message, "code": code };
    return errorJson;
}

function sendResponse(http:Caller caller, json res) {
    http:Response response = new;
    response.setJsonPayload(untaint res);
    error? result = caller -> respond(response);
    if ( result is error) {
        io:println("Error in responding", result);
    }
}

@docker:Config {}
@docker:Expose {}
listener http:Listener cmdListener = new(9090);

@http:ServiceConfig {
    basePath: "/ana"
}
service ana on cmdListener {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "users/{"+USER_ID+"}/following"
    }
    resource function postFollow(http:Caller caller, http:Request request, string userId) {
        json res = {};

        json|error payload = request.getJsonPayload();

        if ( payload is error )
        {
            res = buildErrorJson(400, ERROR_NO_FOLLOWING_ID_IN_JSON);
        }
        else
        {
            json followingId = payload[FOLLOWING_ID];
            if ( followingId is string )
            {
                //TODO: insert it to database and check if it's ok
                res = { };
                res[FOLLOWER_ID] = userId;
                res[FOLLOWING_ID] = followingId;
            }
            else
            {
                res = buildErrorJson(400, ERROR_NO_FOLLOWING_ID_IN_JSON);
            }
        }

        sendResponse(caller, res);
    }
    
    @http:ResourceConfig {
        methods: ["GET"],
        path: "users/{" + USER_ID + "}/followers"
    }
    resource function getFollowers(http:Caller caller, http:Request request, string userId) {
        json res = {};
        res["calledMethod"] = "getFollowers(" + userId + ")";
        //TODO
        sendResponse(caller, res);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "users/{"+USER_ID+"}/following"
    }
    resource function getFollowing(http:Caller caller, http:Request request, string userId) {
        json res = {};
        res["calledMethod"] = "getFollowing(" + userId + ")";
        //TODO
        sendResponse(caller, res);
    }

    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "users/{" + USER_ID + "}/following/{" + OTHER_USER_ID + "}"
    }
    resource function deleteFollow(http:Caller caller, http:Request request, string userId, string otherUserId ) {
        json res = {};
        res["calledMethod"] = "deleteFollow(" + userId + "," + otherUserId + ")";
        //TODO
        sendResponse(caller, res);
    }
}
