//
//  RCIMFlutterDefine.h
//  RongCloud
//
//  Created by Sin on 2019/6/5.
//
static NSString *RCMethodKeyInit = @"init";
static NSString *RCMethodKeyConnect = @"connect";
static NSString *RCMethodKeyDisconnect = @"disconnect";
static NSString *RCMethodKeyConfig = @"config";
static NSString *RCMethodKeySendMessage = @"sendMessage";
static NSString *RCMethodKeyRefreshUserInfo = @"refreshUserInfo";
static NSString *RCMethodKeyJoinChatRoom = @"joinChatRoom";
static NSString *RCMethodKeyQuitChatRoom = @"quitChatRoom";
static NSString *RCMethodKeyGetHistoryMessage = @"getHistoryMessage";
static NSString *RCMethodKeyGetHistoryMessages = @"getHistoryMessages";
static NSString *RCMethodKeyGetMessage = @"GetMessage";
static NSString *RCMethodKeyGetConversationList = @"getConversationList";
static NSString *RCMethodKeyGetConversationListByPage = @"getConversationListByPage";
static NSString *RCMethodKeyGetConversation = @"GetConversation";
static NSString *RCMethodKeyGetChatRoomInfo = @"getChatRoomInfo";
static NSString *RCMethodKeyClearMessagesUnreadStatus = @"clearMessagesUnreadStatus";
static NSString *RCMethodKeySetServerInfo = @"setServerInfo";
static NSString *RCMethodKeySetCurrentUserInfo = @"setCurrentUserInfo";
static NSString *RCMethodKeyInsertIncomingMessage = @"insertIncomingMessage";
static NSString *RCMethodKeyInsertOutgoingMessage = @"insertOutgoingMessage";
static NSString *RCMethodKeyGetTotalUnreadCount = @"getTotalUnreadCount";
static NSString *RCMethodKeyGetUnreadCountTargetId = @"getUnreadCountTargetId";
static NSString *RCMethodKeyGetUnreadCountConversationTypeList = @"getUnreadCountConversationTypeList";
static NSString *RCMethodKeySetConversationNotificationStatus = @"setConversationNotificationStatus";
static NSString *RCMethodKeyGetConversationNotificationStatus = @"getConversationNotificationStatus";
static NSString *RCMethodKeyRemoveConversation = @"RemoveConversation";
static NSString *RCMethodKeyGetBlockedConversationList = @"getBlockedConversationList";
static NSString *RCMethodKeySetConversationToTop = @"setConversationToTop";
static NSString *RCMethodKeyGetTopConversationList = @"getTopConversationList";
static NSString *RCMethodKeyDeleteMessages = @"DeleteMessages";
static NSString *RCMethodKeyDeleteMessageByIds = @"DeleteMessageByIds";
static NSString *RCMethodKeyAddToBlackList = @"AddToBlackList";
static NSString *RCMethodKeyRemoveFromBlackList = @"RemoveFromBlackList";
static NSString *RCMethodKeyGetBlackListStatus = @"GetBlackListStatus";
static NSString *RCMethodKeyGetBlackList = @"GetBlackList";
static NSString *RCMethodKeySendReadReceiptMessage = @"SendReadReceiptMessage";
static NSString *RCMethodKeySendReadReceiptRequest = @"SendReadReceiptRequest";
static NSString *RCMethodKeySendReadReceiptResponse = @"SendReadReceiptResponse";
static NSString *RCMethodKeyClearHistoryMessages = @"ClearHistoryMessages";
static NSString *RCMethodKeyRecallMessage = @"recallMessage";
static NSString *RCMethodKeySyncConversationReadStatus = @"syncConversationReadStatus";
static NSString *RCMethodKeyGetTextMessageDraft = @"getTextMessageDraft";
static NSString *RCMethodKeySaveTextMessageDraft = @"saveTextMessageDraft";
static NSString *RCMethodKeySearchConversations = @"searchConversations";
static NSString *RCMethodKeySearchMessages = @"searchMessages";
static NSString *RCMethodKeySendTypingStatus = @"sendTypingStatus";
static NSString *RCMethodKeyDownloadMediaMessage = @"downloadMediaMessage";
static NSString *RCMethodKeySetNotificationQuietHours = @"setNotificationQuietHours";
static NSString *RCMethodKeyRemoveNotificationQuietHours = @"removeNotificationQuietHours";
static NSString *RCMethodKeyGetNotificationQuietHours = @"getNotificationQuietHours";
static NSString *RCMethodKeyGetUnreadMentionedMessages = @"getUnreadMentionedMessages";
static NSString *RCMethodKeySendDirectionalMessage = @"sendDirectionalMessage";

// 聊天室状态存储
static NSString *RCMethodKeySetChatRoomEntry = @"SetChatRoomEntry";
static NSString *RCMethodKeyForceSetChatRoomEntry = @"ForceSetChatRoomEntry";
static NSString *RCMethodKeyGetChatRoomEntry = @"GetChatRoomEntry";
static NSString *RCMethodKeyGetAllChatRoomEntries = @"GetAllChatRoomEntries";
static NSString *RCMethodKeyRemoveChatRoomEntry = @"RemoveChatRoomEntry";
static NSString *RCMethodKeyForceRemoveChatRoomEntry = @"ForceRemoveChatRoomEntry";

//callback iOS 通知 flutter
static NSString *RCMethodCallBackKeySendMessage = @"sendMessageCallBack";
static NSString *RCMethodCallBackKeyRefreshUserInfo = @"refreshUserInfoCallBack";
static NSString *RCMethodCallBackKeyReceiveMessage = @"receiveMessageCallBack";
static NSString *RCMethodCallBackKeyJoinChatRoom = @"joinChatRoomCallBack";
static NSString *RCMethodCallBackKeyQuitChatRoom = @"quitChatRoomCallBack";
static NSString *RCMethodCallBackKeyUploadMediaProgress = @"uploadMediaProgressCallBack";
static NSString *RCMethodCallBackKeyGetRemoteHistoryMessages = @"getRemoteHistoryMessagesCallBack";
static NSString *RCMethodCallBackKeyConnectionStatusChange = @"ConnectionStatusChangeCallBack";
static NSString *RCMethodCallBackKeySendDataToFlutter = @"SendDataToFlutterCallBack";
static NSString *RCMethodCallBackKeyReceiveReadReceipt = @"ReceiveReadReceiptCallBack";
static NSString *RCMethodCallBackKeyReceiptRequest = @"ReceiptRequestCallBack";
static NSString *RCMethodCallBackKeyReceiptResponse = @"ReceiptResponseCallBack";
static NSString *RCMethodCallBackKeyTypingStatusChangedCallBack = @"TypingStatusChangedCallBack";
static NSString *RCMethodCallBackKeyDownloadMediaMessageCallBack = @"DownloadMediaMessageCallBack";
static NSString *RCMethodCallBackKeyRecallMessageCallBack = @"RecallMessageCallBack";




