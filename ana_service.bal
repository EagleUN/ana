import ballerina/http;
import ballerina/io;
import ballerinax/docker;

import controller;
import errors;
import notifications;
import utils;
import ballerina/grpc;

#API names for url parameters
const string USER_ID = "userId";
const string OTHER_USER_ID = "otherUserId";

#API names for JSON responses
const string FOLLOWER_ID = "followerId";
const string FOLLOWING_ID = "followingId";

function sendResponse(http:Caller caller, http:Response response) {
    error? result = caller -> respond(response);
    if ( result is error) {
        io:println("Error in responding", result);
    }
}

function sendErrorResponse(http:Caller caller, int code, string message, string description = "") {
    http:Response response = new;
    response.statusCode = code;
    json errorJson = { "code" : code, "id" : message };
    if ( description.length() > 0 ) {
        errorJson["description"] = description;
    }
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

        if ( !utils:isUuid(userId) ) {
            sendErrorResponse(caller, 400, errors:FOLLOWER_ID_MUST_BE_UUID, description = errors:UUID_DESCRIPTION );
            return;
        }

        if ( payload is error )
        {
            sendErrorResponse(caller, 400, errors:NO_JSON_PAYLOAD);
        }
        else
        {
            io:println("payload: " + payload.toString());
            json followingId = payload[FOLLOWING_ID];
            if ( followingId is string )
            {
                if ( !utils:isUuid(followingId) )
                {
                    sendErrorResponse(caller, 400, errors:FOLLOWING_ID_MUST_BE_UUID, description = errors:UUID_DESCRIPTION);
                    return;
                }
                controller:ApiFollow|error r = controller:insertFollow(userId, followingId);
                if (r is error)
                {
                    sendErrorResponse(caller, 400, errors:ERROR_FAILED_TO_INSERT_RECORD);
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
                sendErrorResponse(caller, 400, errors:ERROR_NO_FOLLOWING_ID_IN_JSON);
            }
        }
    }
    
    @http:ResourceConfig {
        methods: ["GET"],
        path: "users/{" + USER_ID + "}/followers"
    }
    resource function getFollowers(http:Caller caller, http:Request request, string userId)
    {
        io:println("getFollowers(" + userId + ")");
        if ( !utils:isUuid(userId) ) {
            sendErrorResponse(caller, 400, errors:USER_ID_MUST_BE_UUID, description = errors:UUID_DESCRIPTION);
            return;
        }
        controller:ApiUserIdList|error r = controller:getFollowers(userId);
        if ( r is error )
        {
            sendErrorResponse(caller, 500, errors:INTERNAL_DATABASE_ERROR);
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
        if ( !utils:isUuid(userId) ) {
            sendErrorResponse(caller, 400, errors:USER_ID_MUST_BE_UUID, description = errors:UUID_DESCRIPTION);
            return;
        }
        controller:ApiUserIdList|error r = controller:getFollowing(userId);
        if ( r is error )
        {
            sendErrorResponse(caller, 500, errors:INTERNAL_DATABASE_ERROR);
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
        if ( !utils:isUuid(userId) || !utils:isUuid(otherUserId) ) {
            sendErrorResponse(caller, 400, errors:USER_ID_MUST_BE_UUID, description = errors:UUID_DESCRIPTION);
            return;
        }
        boolean|error r = controller:deleteFollow(userId, otherUserId);
        if ( r is error )
        {
            sendErrorResponse(caller, 500, errors:INTERNAL_DATABASE_ERROR);
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
        if ( !utils:isUuid(userId) || !utils:isUuid(otherUserId) ) {
            sendErrorResponse(caller, 400, errors:USER_ID_MUST_BE_UUID, description = errors:UUID_DESCRIPTION);
            return;
        }
        boolean|error r = controller:follows(userId, otherUserId);
        if ( r is error )
        {
            sendErrorResponse(caller, 500, errors:INTERNAL_DATABASE_ERROR);
        }
        else
        {
            sendOKResponse(caller, {"follows": r} );   
        }
    }


    @http:ResourceConfig {
        methods: ["GET"],
        path: "users/{" + USER_ID + "}/userList"
    }
    resource function getUserListFor(http:Caller caller, http:Request request, string userId ) {
        io:println("getUserListFor(" + userId + ")");
        if ( !utils:isUuid(userId) ) {
            sendErrorResponse(caller, 400, errors:USER_ID_MUST_BE_UUID, description = errors:UUID_DESCRIPTION);
            return;
        }
        controller:ApiOtherUserList|error r = controller:getUsersListFor(userId);
        if ( r is error ) {
            sendErrorResponse(caller, 500, r.reason());
        }
        else {
            json js = {
                "count": r.count,
                "otherUsers" : [] };
            foreach int i in 0...r.count-1 {
                var user = r.otherUsers[i];
                js["otherUsers"][i] = {
                    "id" : user.id,
                    "name" : user.name,
                    "lastName" : user.lastName,
                    "iFollow" : user.iFollow,
                    "followsMe" : user.followsMe
                };
            }
            sendOKResponse(caller, js );
        }
    }
}
