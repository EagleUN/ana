public type ApiFollow object {
    public string followerId;
    public string followingId;

    public function __init(string followerId, string followingId) {
        self.followerId = followerId;
        self.followingId = followingId;
    }
};

public type ApiUserIdList object {
    public int count;
    public string[] userIds;

    public function addUserId(string userId) {
        self.userIds[self.count] = userId;
        self.count += 1;
    }

    public function __init(string[] userIds) {
        self.count = userIds.length();
        self.userIds = userIds;
    }
};

public type ApiOtherUser object {
    public string id = "";
    public string name = "";
    public string lastName = "";
    public boolean followsMe = false;
    public boolean iFollow = false;
};

public type ApiOtherUserList object {
    public int count = 0;
    public ApiOtherUser[] otherUsers = [];
};