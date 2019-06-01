import ballerina/http;
import ballerina/io;
import ballerinax/docker;

import controller;
import notifications;

const string ERROR_NO_FOLLOWING_ID_IN_JSON = "Payload should contain a JSON with a string followingId";
const string ERROR_FAILED_TO_INSERT_RECORD = "Failed to insert the follow in the database";
const string INTERNAL_DATABASE_ERROR = "Internal error related to DB";
const string NO_JSON_PAYLOAD = "There should be a json payload with the request";

#API names for url parameters
const string USER_ID = "userId";
const string OTHER_USER_ID = "otherUserId";

#API names for JSON responses
const string FOLLOWER_ID = "followerId";
const string FOLLOWING_ID = "followingId";

function buildErrorJson ( string message ) returns json {
    json errorJson = { "message" : message};
    return errorJson;
}

function sendResponse(http:Caller caller, http:Response response) {
    error? result = caller -> respond(response);
    if ( result is error) {
        io:println("Error in responding", result);
    }
}

function sendErrorResponse(http:Caller caller, int code, json errorJson) {
    http:Response response = new;
    response.statusCode = code;
    response.setPayload(untaint errorJson);
    sendResponse(caller, response);
    
}

function sendOKResponse(http:Caller caller, json res) {
    http:Response response = new;
    response.setJsonPayload(untaint res);
    sendResponse(caller, response);
}

@docker:Config {
    name: "ana_service"
}
@docker:Expose { }
@docker:CopyFiles{
    files: [{
            source: "postgresql-42.2.5.jar",
            target: "/ballerina/runtime/bre/lib"
        },
        {
            source: "ballerina.conf",
            target: "/home/ballerina"
        }
    ]
}
listener http:Listener cmdListener = new(9090);

@http:ServiceConfig {
    basePath: "/ana"
}
service ana on cmdListener {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "users/{"+USER_ID+"}/following"
    }
    resource function postFollow(http:Caller caller, http:Request request, string userId)
    {
        io:println("postFollow(" + userId + ")");
        json|error payload = request.getJsonPayload();

        if ( payload is error ) {
            io:println("payload is error");
            sendErrorResponse(caller, 400, buildErrorJson(NO_JSON_PAYLOAD));
        }
        else
        {
            io:println("payload: " + payload.toString());
            json followingId = payload[FOLLOWING_ID];
            if ( followingId is string )
            {
                controller:ApiFollow|error r = controller:insertFollow(userId, followingId);
                if (r is error)
                {
                    io:println("insert follow returned error");
                    sendErrorResponse(caller, 400, buildErrorJson(ERROR_FAILED_TO_INSERT_RECORD));
                }
                else
                {
                    // TODO make sure both IDs are UUIDs
                    notifications:notifyFollow(untaint r.followerId,untaint  r.followingId);

                    json res = { };
                    res[FOLLOWER_ID] = r.followerId;
                    res[FOLLOWING_ID] = r.followingId;
                    sendOKResponse(caller, res);
                }
            }
            else
            {
                io:println("followingId is not a string");
                sendErrorResponse(caller, 400, buildErrorJson(ERROR_NO_FOLLOWING_ID_IN_JSON));
            }
        }
    }
    
    @http:ResourceConfig {
        methods: ["GET"],
        path: "users/{" + USER_ID + "}/followers"
    }
    resource function getFollowers(http:Caller caller, http:Request request, string userId)
    {
        io:println("getFollower(" + userId + ")");
        controller:ApiUserIdList|error r = controller:getFollowers(userId);
        if ( r is error )
        {
            sendErrorResponse(caller, 500, INTERNAL_DATABASE_ERROR);
        }
        else {    
            json res = {
                "count": r.count,
                "userIds": r.userIds
            };      
            sendOKResponse(caller, res);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "users/{"+USER_ID+"}/following"
    }
    resource function getFollowing(http:Caller caller, http:Request request, string userId)
    {
        io:println("getFollowing(" + userId + ")");
        controller:ApiUserIdList|error r = controller:getFollowing(userId);
        if ( r is error )
        {
            sendErrorResponse(caller, 500, INTERNAL_DATABASE_ERROR);
        }
        else
        {
            json res = {
                "count": r.count,
                "userIds": r.userIds
            };
            sendOKResponse(caller, res);
        }
    }

    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "users/{" + USER_ID + "}/following/{" + OTHER_USER_ID + "}"
    }
    resource function deleteFollow(http:Caller caller, http:Request request, string userId, string otherUserId )
    {
        io:println("deleteFollow(" + userId + "," + otherUserId + ")");
        boolean|error r = controller:deleteFollow(userId, otherUserId);
        if ( r is error )
        {
            sendErrorResponse(caller, 500, INTERNAL_DATABASE_ERROR);
        }
        else
        {
            json res = { };
            res[FOLLOWER_ID] = userId;
            res[FOLLOWING_ID] = otherUserId;
            sendOKResponse(caller, res);
        }
    }

    # Checks if a given user follows another one. Returns:
    #    - 200 (OK) if the first user follows the second one. 
    #    - 204 (No content) if the first user does not follow the second one.
    #    - 500 (Internal error) in case something goes wrong.
    # + caller - The caller
    # + request - The request
    # + userId - ID of the user that follows
    # + otherUserId - ID of the user being followed
    @http:ResourceConfig {
        methods: ["GET"],
        path: "users/{" + USER_ID + "}/following/{" + OTHER_USER_ID + "}"
    }
    resource function getFollow(http:Caller caller, http:Request request, string userId, string otherUserId )
    {
        io:println("getFollow(" + userId + "," + otherUserId + ")");
        boolean|error r = controller:follows(userId, otherUserId);
        if ( r is error )
        {
            sendErrorResponse(caller, 500, INTERNAL_DATABASE_ERROR);
        }
        else
        {
            sendOKResponse(caller, {"follows": r} );   
        }
    }

}
