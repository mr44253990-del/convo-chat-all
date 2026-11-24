/// Direct Dart port of app/src/main/java/com/example/data/Models.kt.
/// Field names keep the exact wire format used by Firebase RTDB/Firestore.
library;

class User {
  final String uid;
  final String name;
  final String dob;
  final String username;
  final String fcmToken;
  final String profileImageUrl;
  final bool isOnline;
  final int lastActive;
  final int onlineUntil;
  final int offlineSince;
  final List<String> blockedUsers;
  final int createdAt;
  final List<String> friends;
  final String bio;
  final String coverImageUrl;
  final List<String> followers;
  final List<String> following;
  final int followerGrowth;
  final String role;
  final bool isPremium;
  final String premiumPlan;
  final int premiumUntil;
  final int premiumApprovedAt;
  final bool premiumTrialClaimed;
  final String premiumSource;
  final double coverScale;
  final double coverOffsetY;
  final bool profileHidden;
  final bool awayReplyEnabled;
  final String awayReplyText;
  final int awayReplyUntil;
  final String activeProfileType;
  final String profileVisibility;
  final String pronouns;
  final String professionalTitle;
  final String publicContactEmail;
  final Map<String, String> socialLinks;
  final String staffRole;
  final List<String> staffPermissions;
  final String staffTitle;
  final bool mfaEnabled;
  final String appVersion;
  final int appVersionCode;
  final int appVersionAt;
  final String deviceModel;
  final String androidVersion;
  final String phoneHash;

  const User({
    this.uid = "",
    this.name = "",
    this.dob = "",
    this.username = "",
    this.fcmToken = "",
    this.profileImageUrl = "",
    this.isOnline = false,
    this.lastActive = 0,
    this.onlineUntil = 0,
    this.offlineSince = 0,
    this.blockedUsers = const [],
    this.createdAt = 0,
    this.friends = const [],
    this.bio = "",
    this.coverImageUrl = "",
    this.followers = const [],
    this.following = const [],
    this.followerGrowth = 0,
    this.role = "user",
    this.isPremium = false,
    this.premiumPlan = "",
    this.premiumUntil = 0,
    this.premiumApprovedAt = 0,
    this.premiumTrialClaimed = false,
    this.premiumSource = "",
    this.coverScale = 1.0,
    this.coverOffsetY = 0.0,
    this.profileHidden = false,
    this.awayReplyEnabled = false,
    this.awayReplyText = "",
    this.awayReplyUntil = 0,
    this.activeProfileType = "Personal",
    this.profileVisibility = "everyone",
    this.pronouns = "",
    this.professionalTitle = "",
    this.publicContactEmail = "",
    this.socialLinks = const {},
    this.staffRole = "",
    this.staffPermissions = const [],
    this.staffTitle = "",
    this.mfaEnabled = false,
    this.appVersion = "",
    this.appVersionCode = 0,
    this.appVersionAt = 0,
    this.deviceModel = "",
    this.androidVersion = "",
    this.phoneHash = "",
  });

  factory User.fromJson(Map<dynamic, dynamic> j, {String uid = ""}) => User(
        uid: (j["uid"] as String?) ?? uid,
        name: (j["name"] as String?) ?? "",
        dob: (j["dob"] as String?) ?? "",
        username: (j["username"] as String?) ?? "",
        fcmToken: (j["fcmToken"] as String?) ?? "",
        profileImageUrl: (j["profileImageUrl"] as String?) ?? "",
        isOnline: (j["isOnline"] as bool?) ?? false,
        lastActive: _toI(j["lastActive"]),
        onlineUntil: _toI(j["onlineUntil"]),
        offlineSince: _toI(j["offlineSince"]),
        blockedUsers: _toS(j["blockedUsers"]),
        createdAt: _toI(j["createdAt"]),
        friends: _toS(j["friends"]),
        bio: (j["bio"] as String?) ?? "",
        coverImageUrl: (j["coverImageUrl"] as String?) ?? "",
        followers: _toS(j["followers"]),
        following: _toS(j["following"]),
        followerGrowth: _toI(j["followerGrowth"]),
        role: (j["role"] as String?) ?? "user",
        isPremium: (j["isPremium"] as bool?) ?? false,
        premiumPlan: (j["premiumPlan"] as String?) ?? "",
        premiumUntil: _toI(j["premiumUntil"]),
        premiumApprovedAt: _toI(j["premiumApprovedAt"]),
        premiumTrialClaimed: (j["premiumTrialClaimed"] as bool?) ?? false,
        premiumSource: (j["premiumSource"] as String?) ?? "",
        coverScale: (j["coverScale"] as num?)?.toDouble() ?? 1.0,
        coverOffsetY: (j["coverOffsetY"] as num?)?.toDouble() ?? 0.0,
        profileHidden: (j["profileHidden"] as bool?) ?? false,
        awayReplyEnabled: (j["awayReplyEnabled"] as bool?) ?? false,
        awayReplyText: (j["awayReplyText"] as String?) ?? "",
        awayReplyUntil: _toI(j["awayReplyUntil"]),
        activeProfileType: (j["activeProfileType"] as String?) ?? "Personal",
        profileVisibility: (j["profileVisibility"] as String?) ?? "everyone",
        pronouns: (j["pronouns"] as String?) ?? "",
        professionalTitle: (j["professionalTitle"] as String?) ?? "",
        publicContactEmail: (j["publicContactEmail"] as String?) ?? "",
        socialLinks: _stringMap(j["socialLinks"]),
        staffRole: (j["staffRole"] as String?) ?? "",
        staffPermissions: _toS(j["staffPermissions"]),
        staffTitle: (j["staffTitle"] as String?) ?? "",
        mfaEnabled: (j["mfaEnabled"] as bool?) ?? false,
        appVersion: (j["appVersion"] as String?) ?? "",
        appVersionCode: _toI(j["appVersionCode"]),
        appVersionAt: _toI(j["appVersionAt"]),
        deviceModel: (j["deviceModel"] as String?) ?? "",
        androidVersion: (j["androidVersion"] as String?) ?? "",
        phoneHash: (j["phoneHash"] as String?) ?? "",
      );

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "name": name,
        "dob": dob,
        "username": username,
        "fcmToken": fcmToken,
        "profileImageUrl": profileImageUrl,
        "isOnline": isOnline,
        "lastActive": lastActive,
        "onlineUntil": onlineUntil,
        "offlineSince": offlineSince,
        "blockedUsers": blockedUsers,
        "createdAt": createdAt,
        "friends": friends,
        "bio": bio,
        "coverImageUrl": coverImageUrl,
        "followers": followers,
        "following": following,
        "followerGrowth": followerGrowth,
        "role": role,
        "isPremium": isPremium,
        "premiumPlan": premiumPlan,
        "premiumUntil": premiumUntil,
        "premiumApprovedAt": premiumApprovedAt,
        "premiumTrialClaimed": premiumTrialClaimed,
        "premiumSource": premiumSource,
        "coverScale": coverScale,
        "coverOffsetY": coverOffsetY,
        "profileHidden": profileHidden,
        "awayReplyEnabled": awayReplyEnabled,
        "awayReplyText": awayReplyText,
        "awayReplyUntil": awayReplyUntil,
        "activeProfileType": activeProfileType,
        "profileVisibility": profileVisibility,
        "pronouns": pronouns,
        "professionalTitle": professionalTitle,
        "publicContactEmail": publicContactEmail,
        "socialLinks": socialLinks,
        "staffRole": staffRole,
        "staffPermissions": staffPermissions,
        "staffTitle": staffTitle,
        "mfaEnabled": mfaEnabled,
        "appVersion": appVersion,
        "appVersionCode": appVersionCode,
        "appVersionAt": appVersionAt,
        "deviceModel": deviceModel,
        "androidVersion": androidVersion,
        "phoneHash": phoneHash,
      };

  User copyWith({String? name, bool? isOnline, int? lastActive, List<String>? friends, String? appVersion}) =>
      User(
        uid: uid,
        name: name ?? this.name,
        dob: dob,
        username: username,
        fcmToken: fcmToken,
        profileImageUrl: profileImageUrl,
        isOnline: isOnline ?? this.isOnline,
        lastActive: lastActive ?? this.lastActive,
        onlineUntil: onlineUntil,
        offlineSince: offlineSince,
        blockedUsers: blockedUsers,
        createdAt: createdAt,
        friends: friends ?? this.friends,
        bio: bio,
        coverImageUrl: coverImageUrl,
        followers: followers,
        following: following,
        followerGrowth: followerGrowth,
        role: role,
        isPremium: isPremium,
        premiumPlan: premiumPlan,
        premiumUntil: premiumUntil,
        premiumApprovedAt: premiumApprovedAt,
        premiumTrialClaimed: premiumTrialClaimed,
        premiumSource: premiumSource,
        coverScale: coverScale,
        coverOffsetY: coverOffsetY,
        profileHidden: profileHidden,
        awayReplyEnabled: awayReplyEnabled,
        awayReplyText: awayReplyText,
        awayReplyUntil: awayReplyUntil,
        activeProfileType: activeProfileType,
        profileVisibility: profileVisibility,
        pronouns: pronouns,
        professionalTitle: professionalTitle,
        publicContactEmail: publicContactEmail,
        socialLinks: socialLinks,
        staffRole: staffRole,
        staffPermissions: staffPermissions,
        staffTitle: staffTitle,
        mfaEnabled: mfaEnabled,
        appVersion: appVersion ?? this.appVersion,
        appVersionCode: appVersionCode,
        appVersionAt: appVersionAt,
        deviceModel: deviceModel,
        androidVersion: androidVersion,
        phoneHash: phoneHash,
      );
}

class MessageEditRecord {
  final String text;
  final int editedAt;
  final String editedBy;

  const MessageEditRecord({this.text = "", this.editedAt = 0, this.editedBy = ""});

  factory MessageEditRecord.fromJson(Map<dynamic, dynamic> j) => MessageEditRecord(
        text: (j["text"] as String?) ?? "",
        editedAt: _toI(j["editedAt"]),
        editedBy: (j["editedBy"] as String?) ?? "",
      );

  Map<String, dynamic> toJson() => {"text": text, "editedAt": editedAt, "editedBy": editedBy};
}

class Message {
  final String messageId;
  final String senderId;
  final String senderName;
  final String senderUsername;
  final String text;
  final int timestamp;
  final bool edited;
  final String? replyToId;
  final String? replyToText;
  final String? replyToSenderName;
  final String? imageUrl;
  final String? voiceUrl;
  final int? voiceDurationSec;
  final String? remoteVoiceUrl;
  final String? fileUrl;
  final String? remoteFileUrl;
  final String? fileName;
  final String? fileMimeType;
  final int? fileSize;
  final bool seenByRecipient;
  final bool deliveredToRecipient;
  final int expiresAt;
  final List<MessageEditRecord> editHistory;
  final Map<String, String> reactions;
  final bool cloudText;

  const Message({
    this.messageId = "",
    this.senderId = "",
    this.senderName = "",
    this.senderUsername = "",
    this.text = "",
    this.timestamp = 0,
    this.edited = false,
    this.replyToId,
    this.replyToText,
    this.replyToSenderName,
    this.imageUrl,
    this.voiceUrl,
    this.voiceDurationSec,
    this.remoteVoiceUrl,
    this.fileUrl,
    this.remoteFileUrl,
    this.fileName,
    this.fileMimeType,
    this.fileSize,
    this.seenByRecipient = false,
    this.deliveredToRecipient = false,
    this.expiresAt = 0,
    this.editHistory = const [],
    this.reactions = const {},
    this.cloudText = false,
  });

  factory Message.fromJson(Map<dynamic, dynamic> j, {String messageId = ""}) => Message(
        messageId: (j["messageId"] as String?) ?? messageId,
        senderId: (j["senderId"] as String?) ?? "",
        senderName: (j["senderName"] as String?) ?? "",
        senderUsername: (j["senderUsername"] as String?) ?? "",
        text: (j["text"] as String?) ?? "",
        timestamp: _toI(j["timestamp"]),
        edited: (j["edited"] as bool?) ?? false,
        replyToId: j["replyToId"] as String?,
        replyToText: j["replyToText"] as String?,
        replyToSenderName: j["replyToSenderName"] as String?,
        imageUrl: j["imageUrl"] as String?,
        voiceUrl: j["voiceUrl"] as String?,
        voiceDurationSec: j["voiceDurationSec"] == null ? null : _toI(j["voiceDurationSec"]),
        remoteVoiceUrl: j["remoteVoiceUrl"] as String?,
        fileUrl: j["fileUrl"] as String?,
        remoteFileUrl: j["remoteFileUrl"] as String?,
        fileName: j["fileName"] as String?,
        fileMimeType: j["fileMimeType"] as String?,
        fileSize: j["fileSize"] == null ? null : _toI(j["fileSize"]),
        seenByRecipient: (j["seenByRecipient"] as bool?) ?? false,
        deliveredToRecipient: (j["deliveredToRecipient"] as bool?) ?? false,
        expiresAt: _toI(j["expiresAt"]),
        editHistory: _editHistory(j["editHistory"]),
        reactions: _stringMap(j["reactions"]),
        cloudText: (j["cloudText"] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        "messageId": messageId,
        "senderId": senderId,
        "senderName": senderName,
        "senderUsername": senderUsername,
        "text": text,
        "timestamp": timestamp,
        "edited": edited,
        "replyToId": replyToId,
        "replyToText": replyToText,
        "replyToSenderName": replyToSenderName,
        "imageUrl": imageUrl,
        "voiceUrl": voiceUrl,
        "voiceDurationSec": voiceDurationSec,
        "remoteVoiceUrl": remoteVoiceUrl,
        "fileUrl": fileUrl,
        "remoteFileUrl": remoteFileUrl,
        "fileName": fileName,
        "fileMimeType": fileMimeType,
        "fileSize": fileSize,
        "seenByRecipient": seenByRecipient,
        "deliveredToRecipient": deliveredToRecipient,
        "expiresAt": expiresAt,
        "editHistory": editHistory.map((e) => e.toJson()).toList(),
        "reactions": reactions,
        "cloudText": cloudText,
      };

  bool get visible =>
      expiresAt == 0 ||
      DateTime.fromMillisecondsSinceEpoch(expiresAt).isAfter(DateTime.now());
}

class StoryComment {
  final String commentId;
  final String senderId;
  final String senderName;
  final String text;
  final int timestamp;

  const StoryComment({
    this.commentId = "",
    this.senderId = "",
    this.senderName = "",
    this.text = "",
    this.timestamp = 0,
  });

  factory StoryComment.fromJson(Map<dynamic, dynamic> j, {String commentId = ""}) => StoryComment(
        commentId: (j["commentId"] as String?) ?? commentId,
        senderId: (j["senderId"] as String?) ?? "",
        senderName: (j["senderName"] as String?) ?? "",
        text: (j["text"] as String?) ?? "",
        timestamp: _toI(j["timestamp"]),
      );
}

class Story {
  final String id;
  final String senderId;
  final String senderName;
  final String senderProfilePic;
  final String imageUrl;
  final String videoUrl;
  final String text;
  final int timestamp;
  final Map<String, String> reactions;
  final List<StoryComment> comments;
  final List<String> viewers;
  final Map<String, int> viewCounts;
  final int spotlightUntil;
  final String audioUrl;
  final String audioTitle;
  final String audioArtist;

  const Story({
    this.id = "",
    this.senderId = "",
    this.senderName = "",
    this.senderProfilePic = "",
    this.imageUrl = "",
    this.videoUrl = "",
    this.text = "",
    this.timestamp = 0,
    this.reactions = const {},
    this.comments = const [],
    this.viewers = const [],
    this.viewCounts = const {},
    this.spotlightUntil = 0,
    this.audioUrl = "",
    this.audioTitle = "",
    this.audioArtist = "",
  });

  factory Story.fromJson(Map<dynamic, dynamic> j, {String id = ""}) => Story(
        id: (j["id"] as String?) ?? id,
        senderId: (j["senderId"] as String?) ?? "",
        senderName: (j["senderName"] as String?) ?? "",
        senderProfilePic: (j["senderProfilePic"] as String?) ?? "",
        imageUrl: (j["imageUrl"] as String?) ?? "",
        videoUrl: (j["videoUrl"] as String?) ?? "",
        text: (j["text"] as String?) ?? "",
        timestamp: _toI(j["timestamp"]),
        reactions: _stringMap(j["reactions"]),
        comments: _comments(j["comments"]),
        viewers: _toS(j["viewers"]),
        viewCounts: _intMap(j["viewCounts"]),
        spotlightUntil: _toI(j["spotlightUntil"]),
        audioUrl: (j["audioUrl"] as String?) ?? "",
        audioTitle: (j["audioTitle"] as String?) ?? "",
        audioArtist: (j["audioArtist"] as String?) ?? "",
      );
}

class PostComment {
  final String commentId;
  final String senderId;
  final String senderName;
  final String text;
  final int timestamp;
  final Map<String, String> reactions;
  final String replyToId;
  final String replyToName;

  const PostComment({
    this.commentId = "",
    this.senderId = "",
    this.senderName = "",
    this.text = "",
    this.timestamp = 0,
    this.reactions = const {},
    this.replyToId = "",
    this.replyToName = "",
  });

  factory PostComment.fromJson(Map<dynamic, dynamic> j, {String commentId = ""}) => PostComment(
        commentId: (j["commentId"] as String?) ?? commentId,
        senderId: (j["senderId"] as String?) ?? "",
        senderName: (j["senderName"] as String?) ?? "",
        text: (j["text"] as String?) ?? "",
        timestamp: _toI(j["timestamp"]),
        reactions: _stringMap(j["reactions"]),
        replyToId: (j["replyToId"] as String?) ?? "",
        replyToName: (j["replyToName"] as String?) ?? "",
      );
}

class Post {
  final String id;
  final String senderId;
  final String senderName;
  final String senderProfilePic;
  final String text;
  final String imageUrl;
  final String audioUrl;
  final String videoUrl;
  final int timestamp;
  final Map<String, String> reactions;
  final List<PostComment> comments;
  final int viewsCount;
  final bool isPrivate;
  final String title;
  final List<String> tags;
  final List<String> taggedUserIds;
  final String feeling;
  final String backgroundStyle;
  final String textAnimation;
  final List<String> r2ObjectKeys;
  final bool isReel;
  final int expiresAt;
  final List<String> imageUrls;
  final String sourceUrl;
  final String embedHtml;
  final String providerName;
  final String thumbnailUrl;
  final bool isAdminReel;
  final bool postEverywhere;
  final bool autoGenerated;
  final String autoPostType;
  final String audioTitle;
  final String audioArtist;
  final String audioArtwork;
  final String audioSource;

  const Post({
    this.id = "",
    this.senderId = "",
    this.senderName = "",
    this.senderProfilePic = "",
    this.text = "",
    this.imageUrl = "",
    this.audioUrl = "",
    this.videoUrl = "",
    this.timestamp = 0,
    this.reactions = const {},
    this.comments = const [],
    this.viewsCount = 0,
    this.isPrivate = false,
    this.title = "",
    this.tags = const [],
    this.taggedUserIds = const [],
    this.feeling = "",
    this.backgroundStyle = "glass",
    this.textAnimation = "none",
    this.r2ObjectKeys = const [],
    this.isReel = false,
    this.expiresAt = 0,
    this.imageUrls = const [],
    this.sourceUrl = "",
    this.embedHtml = "",
    this.providerName = "",
    this.thumbnailUrl = "",
    this.isAdminReel = false,
    this.postEverywhere = true,
    this.autoGenerated = false,
    this.autoPostType = "",
    this.audioTitle = "",
    this.audioArtist = "",
    this.audioArtwork = "",
    this.audioSource = "",
  });

  factory Post.fromJson(Map<dynamic, dynamic> j, {String id = ""}) => Post(
        id: (j["id"] as String?) ?? id,
        senderId: (j["senderId"] as String?) ?? "",
        senderName: (j["senderName"] as String?) ?? "",
        senderProfilePic: (j["senderProfilePic"] as String?) ?? "",
        text: (j["text"] as String?) ?? "",
        imageUrl: (j["imageUrl"] as String?) ?? "",
        audioUrl: (j["audioUrl"] as String?) ?? "",
        videoUrl: (j["videoUrl"] as String?) ?? "",
        timestamp: _toI(j["timestamp"]),
        reactions: _stringMap(j["reactions"]),
        comments: _postComments(j["comments"]),
        viewsCount: _toI(j["viewsCount"]),
        isPrivate: (j["isPrivate"] as bool?) ?? false,
        title: (j["title"] as String?) ?? "",
        tags: _toS(j["tags"]),
        taggedUserIds: _toS(j["taggedUserIds"]),
        feeling: (j["feeling"] as String?) ?? "",
        backgroundStyle: (j["backgroundStyle"] as String?) ?? "glass",
        textAnimation: (j["textAnimation"] as String?) ?? "none",
        r2ObjectKeys: _toS(j["r2ObjectKeys"]),
        isReel: (j["isReel"] as bool?) ?? false,
        expiresAt: _toI(j["expiresAt"]),
        imageUrls: _toS(j["imageUrls"]),
        sourceUrl: (j["sourceUrl"] as String?) ?? "",
        embedHtml: (j["embedHtml"] as String?) ?? "",
        providerName: (j["providerName"] as String?) ?? "",
        thumbnailUrl: (j["thumbnailUrl"] as String?) ?? "",
        isAdminReel: (j["isAdminReel"] as bool?) ?? false,
        postEverywhere: (j["postEverywhere"] as bool?) ?? true,
        autoGenerated: (j["autoGenerated"] as bool?) ?? false,
        autoPostType: (j["autoPostType"] as String?) ?? "",
        audioTitle: (j["audioTitle"] as String?) ?? "",
        audioArtist: (j["audioArtist"] as String?) ?? "",
        audioArtwork: (j["audioArtwork"] as String?) ?? "",
        audioSource: (j["audioSource"] as String?) ?? "",
      );
}

class Group {
  final String id;
  final String name;
  final String profileUrl;
  final List<String> members;
  final int createdAt;
  final String lastMessage;
  final String createdBy;
  final String activeCallRoomId;
  final String activeCallHostId;
  final String activeCallHostName;
  final bool activeCallVideo;
  final int activeCallStartedAt;
  final String pinnedMessage;
  final String pinnedBy;
  final String description;
  final List<String> admins;
  final bool onlyAdminsCanPost;
  final int slowModeSeconds;
  final Map<String, Map<String, int>> pollVotes;

  const Group({
    this.id = "",
    this.name = "",
    this.profileUrl = "",
    this.members = const [],
    this.createdAt = 0,
    this.lastMessage = "",
    this.createdBy = "",
    this.activeCallRoomId = "",
    this.activeCallHostId = "",
    this.activeCallHostName = "",
    this.activeCallVideo = false,
    this.activeCallStartedAt = 0,
    this.pinnedMessage = "",
    this.pinnedBy = "",
    this.description = "",
    this.admins = const [],
    this.onlyAdminsCanPost = false,
    this.slowModeSeconds = 0,
    this.pollVotes = const {},
  });

  factory Group.fromJson(Map<dynamic, dynamic> j, {String id = ""}) => Group(
        id: (j["id"] as String?) ?? id,
        name: (j["name"] as String?) ?? "",
        profileUrl: (j["profileUrl"] as String?) ?? "",
        members: _toS(j["members"]),
        createdAt: _toI(j["createdAt"]),
        lastMessage: (j["lastMessage"] as String?) ?? "",
        createdBy: (j["createdBy"] as String?) ?? "",
        activeCallRoomId: (j["activeCallRoomId"] as String?) ?? "",
        activeCallHostId: (j["activeCallHostId"] as String?) ?? "",
        activeCallHostName: (j["activeCallHostName"] as String?) ?? "",
        activeCallVideo: (j["activeCallVideo"] as bool?) ?? false,
        activeCallStartedAt: _toI(j["activeCallStartedAt"]),
        pinnedMessage: (j["pinnedMessage"] as String?) ?? "",
        pinnedBy: (j["pinnedBy"] as String?) ?? "",
        description: (j["description"] as String?) ?? "",
        admins: _toS(j["admins"]),
        onlyAdminsCanPost: (j["onlyAdminsCanPost"] as bool?) ?? false,
        slowModeSeconds: _toI(j["slowModeSeconds"]),
        pollVotes: _pollVotes(j["pollVotes"]),
      );
}

class ActiveGroupCallInfo {
  final String roomId;
  final String hostId;
  final String hostName;
  final bool video;
  final int startedAt;
  final int participantCount;

  const ActiveGroupCallInfo({
    this.roomId = "",
    this.hostId = "",
    this.hostName = "",
    this.video = false,
    this.startedAt = 0,
    this.participantCount = 0,
  });
}

class GroupMessage {
  final String messageId;
  final String groupId;
  final String senderId;
  final String senderName;
  final String text;
  final int timestamp;
  final String? imageUrl;
  final String? voiceUrl;
  final int? voiceDurationSec;
  final String? replyToId;
  final String? replyToText;
  final String? replyToSenderName;
  final int expiresAt;

  const GroupMessage({
    this.messageId = "",
    this.groupId = "",
    this.senderId = "",
    this.senderName = "",
    this.text = "",
    this.timestamp = 0,
    this.imageUrl,
    this.voiceUrl,
    this.voiceDurationSec,
    this.replyToId,
    this.replyToText,
    this.replyToSenderName,
    this.expiresAt = 0,
  });

  factory GroupMessage.fromJson(Map<dynamic, dynamic> j, {String messageId = ""}) => GroupMessage(
        messageId: (j["messageId"] as String?) ?? messageId,
        groupId: (j["groupId"] as String?) ?? "",
        senderId: (j["senderId"] as String?) ?? "",
        senderName: (j["senderName"] as String?) ?? "",
        text: (j["text"] as String?) ?? "",
        timestamp: _toI(j["timestamp"]),
        imageUrl: j["imageUrl"] as String?,
        voiceUrl: j["voiceUrl"] as String?,
        voiceDurationSec: j["voiceDurationSec"] == null ? null : _toI(j["voiceDurationSec"]),
        replyToId: j["replyToId"] as String?,
        replyToText: j["replyToText"] as String?,
        replyToSenderName: j["replyToSenderName"] as String?,
        expiresAt: _toI(j["expiresAt"]),
      );

  Map<String, dynamic> toJson() => {
        "messageId": messageId,
        "groupId": groupId,
        "senderId": senderId,
        "senderName": senderName,
        "text": text,
        "timestamp": timestamp,
        "imageUrl": imageUrl,
        "voiceUrl": voiceUrl,
        "voiceDurationSec": voiceDurationSec,
        "replyToId": replyToId,
        "replyToText": replyToText,
        "replyToSenderName": replyToSenderName,
        "expiresAt": expiresAt,
      };
}

class FriendRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String senderProfilePic;

  const FriendRequest({
    this.id = "",
    this.senderId = "",
    this.senderName = "",
    this.senderProfilePic = "",
  });

  factory FriendRequest.fromJson(Map<dynamic, dynamic> j, {String id = ""}) => FriendRequest(
        id: (j["id"] as String?) ?? id,
        senderId: (j["senderId"] as String?) ?? "",
        senderName: (j["senderName"] as String?) ?? "",
        senderProfilePic: (j["senderProfilePic"] as String?) ?? "",
      );
}

class MessageRequest {
  final String id;
  final String senderId;
  final String recipientId;
  final String senderName;
  final String preview;
  final String status;
  final int timestamp;

  const MessageRequest({
    this.id = "",
    this.senderId = "",
    this.recipientId = "",
    this.senderName = "",
    this.preview = "",
    this.status = "pending",
    this.timestamp = 0,
  });

  factory MessageRequest.fromJson(Map<dynamic, dynamic> j, {String id = ""}) => MessageRequest(
        id: (j["id"] as String?) ?? id,
        senderId: (j["senderId"] as String?) ?? "",
        recipientId: (j["recipientId"] as String?) ?? "",
        senderName: (j["senderName"] as String?) ?? "",
        preview: (j["preview"] as String?) ?? "",
        status: (j["status"] as String?) ?? "pending",
        timestamp: _toI(j["timestamp"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "senderId": senderId,
        "recipientId": recipientId,
        "senderName": senderName,
        "preview": preview,
        "status": status,
        "timestamp": timestamp,
      };
}

class UserReport {
  final String id;
  final String reporterId;
  final String reporterEmail;
  final String targetUid;
  final String category;
  final String description;
  final String status;
  final int createdAt;

  const UserReport({
    this.id = "",
    this.reporterId = "",
    this.reporterEmail = "",
    this.targetUid = "",
    this.category = "",
    this.description = "",
    this.status = "pending",
    this.createdAt = 0,
  });

  factory UserReport.fromJson(Map<dynamic, dynamic> j, {String id = ""}) => UserReport(
        id: (j["id"] as String?) ?? id,
        reporterId: (j["reporterId"] as String?) ?? "",
        reporterEmail: (j["reporterEmail"] as String?) ?? "",
        targetUid: (j["targetUid"] as String?) ?? "",
        category: (j["category"] as String?) ?? "",
        description: (j["description"] as String?) ?? "",
        status: (j["status"] as String?) ?? "pending",
        createdAt: _toI(j["createdAt"]),
      );
}

class CallState {
  final bool active;
  final String chatId;
  final String callerId;
  final String callerName;
  final String calleeId;
  final String type;

  const CallState({
    this.active = false,
    this.chatId = "",
    this.callerId = "",
    this.callerName = "",
    this.calleeId = "",
    this.type = "",
  });

  factory CallState.fromJson(Map<dynamic, dynamic> j) => CallState(
        active: (j["active"] as bool?) ?? false,
        chatId: (j["chatId"] as String?) ?? "",
        callerId: (j["callerId"] as String?) ?? "",
        callerName: (j["callerName"] as String?) ?? "",
        calleeId: (j["calleeId"] as String?) ?? "",
        type: (j["type"] as String?) ?? "",
      );

  Map<String, dynamic> toJson() => {
        "active": active,
        "chatId": chatId,
        "callerId": callerId,
        "callerName": callerName,
        "calleeId": calleeId,
        "type": type,
      };
}

class SessionInfo {
  final String id;
  final String device;
  final String platform;
  final int createdAt;

  const SessionInfo({this.id = "", this.device = "", this.platform = "", this.createdAt = 0});

  factory SessionInfo.fromJson(Map<dynamic, dynamic> j, {String id = ""}) => SessionInfo(
        id: (j["id"] as String?) ?? id,
        device: (j["device"] as String?) ?? "",
        platform: (j["platform"] as String?) ?? "",
        createdAt: _toI(j["createdAt"]),
      );
}

int _toI(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

List<String> _toS(dynamic v) {
  if (v is List) return v.whereType<String>().toList();
  if (v is Map) return v.keys.whereType<String>().toList();
  return const [];
}

Map<String, String> _stringMap(dynamic v) {
  if (v is Map) {
    return v.map((k, e) => MapEntry(k.toString(), e == null ? "" : e.toString()));
  }
  return const {};
}

Map<String, int> _intMap(dynamic v) {
  if (v is Map) {
    return v.map((k, e) => MapEntry(k.toString(), _toI(e)));
  }
  return const {};
}

Map<String, Map<String, int>> _pollVotes(dynamic v) {
  if (v is Map) {
    return v.map((k, e) => MapEntry(k.toString(), _intMap(e)));
  }
  return const {};
}

List<MessageEditRecord> _editHistory(dynamic v) {
  if (v is List) {
    return v.whereType<Map>().map((e) => MessageEditRecord.fromJson(e)).toList();
  }
  return const [];
}

List<StoryComment> _comments(dynamic v) {
  if (v is List) {
    return v.whereType<Map>().map((e) => StoryComment.fromJson(e)).toList();
  }
  if (v is Map) {
    return v.entries.whereType<MapEntry>().map((e) => StoryComment.fromJson(e.value)).toList();
  }
  return const [];
}

List<PostComment> _postComments(dynamic v) {
  if (v is List) {
    return v.whereType<Map>().map((e) => PostComment.fromJson(e)).toList();
  }
  if (v is Map) {
    return v.entries.whereType<MapEntry>().map((e) => PostComment.fromJson(e.value)).toList();
  }
  return const [];
}
