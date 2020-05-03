import 'dart:async';

import 'package:flutter/services.dart';

import 'rongcloud_im_plugin.dart';
import 'common_define.dart';
import 'info/connection_status_convert.dart';
import 'method_key.dart';
import 'util/message_factory.dart';
import 'util/type_util.dart';

class RongIMEngine {
  static final MethodChannel _channel = const MethodChannel('rongcloud_im_plugin');

  static Map sendMessageCallbacks = Map();

  ///初始化 SDK
  ///
  ///[appkey] appkey
  static void init(String appkey) {
    _channel.invokeMethod(RCMethodKey.Init, appkey);
    _addNativeMethodCallHandler();
  }

  ///配置 SDK
  ///
  ///[conf] 具体配置
  static void config(Map conf) {
    _channel.invokeMethod(RCMethodKey.Config, conf);
  }

  ///连接 SDK
  ///
  ///[token] 融云 im token
  ///
  ///[code] 参见 [RCErrorCode]
  static Future<int> connect(String token) async {
    final int code = await _channel.invokeMethod(RCMethodKey.Connect, token);
    return code;
  }

  ///断开连接
  ///
  ///[needPush] 断开连接之后是否需要远程推送
  static void disconnect(bool needPush) {
    _channel.invokeMethod(RCMethodKey.Disconnect, needPush);
  }

  ///设置服务器地址，仅限独立数据中心使用，使用前必须先联系商务开通，必须在 [init] 前调用
  ///
  ///[naviServer] 导航服务器地址，具体的格式参考下面的说明
  ///
  ///[fileServer] 文件服务器地址，具体的格式参考下面的说明
  ///
  /// naviServer 和 fileServer 的格式说明：
  ///1、如果使用https，则设置为https://cn.xxx.com:port或https://cn.xxx.com格式，其中域名部分也可以是IP，如果不指定端口，将默认使用443端口。
  ///2、如果使用http，则设置为cn.xxx.com:port或cn.xxx.com格式，其中域名部分也可以是IP，如果不指定端口，将默认使用80端口。
  ///
  static void setServerInfo(String naviServer, String fileServer) {
    Map map = {"naviServer": naviServer, "fileServer": fileServer};
    _channel.invokeMethod(RCMethodKey.SetServerInfo, map);
  }

  ///更新当前用户信息
  ///
  ///[userId] 用户 id
  ///
  ///[name] 用户名称
  ///
  ///[portraitUrl] 用户头像
  /// 此方法只针对iOS生效
  static void updateCurrentUserInfo(String userId, String name, String portraitUrl) {
    Map map = {"userId": userId, "name": name, "portraitUrl": portraitUrl};
    _channel.invokeMethod(RCMethodKey.SetCurrentUserInfo, map);
  }

  ///发送消息
  ///
  ///[conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  ///[targetId] 会话 id
  ///
  ///[content] 消息内容 参见 [MessageContent]
  static Future<Message> sendMessage(
      int conversationType, String targetId, MessageContent content) async {
    return sendMessageCarriesPush(conversationType, targetId, content, "", "");
  }

  ///发送消息
  ///
  ///[conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  ///[targetId] 会话 id
  ///
  ///[content] 消息内容 参见 [MessageContent]
  ///
  /// 当接收方离线并允许远程推送时，会收到远程推送。
  /// 远程推送中包含两部分内容，一是[pushContent]，用于显示；二是[pushData]，用于携带不显示的数据。
  ///
  /// SDK内置的消息类型，如果您将[pushContent]和[pushData]置为空或者为null，会使用默认的推送格式进行远程推送。
  /// 自定义类型的消息，需要您自己设置pushContent和pushData来定义推送内容，否则将不会进行远程推送。
  static Future<Message> sendMessageCarriesPush(int conversationType, String targetId,
      MessageContent content, String pushContent, String pushData) async {
    return sendMessageWithCallBack(
        conversationType, targetId, content, pushContent, pushData, null);
  }

  ///发送消息
  ///
  ///[conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  ///[targetId] 会话 id
  ///
  ///[content] 消息内容 参见 [MessageContent]
  ///
  ///[finished] 回调结果，告知 messageId(消息 id)、status(消息发送状态，参见枚举 [RCSentStatus]) 和 code(具体的错误码，0 代表成功)
  ///
  /// 当接收方离线并允许远程推送时，会收到远程推送。
  /// 远程推送中包含两部分内容，一是[pushContent]，用于显示；二是[pushData]，用于携带不显示的数据。
  ///
  /// SDK内置的消息类型，如果您将[pushContent]和[pushData]置为空或者为null，会使用默认的推送格式进行远程推送。
  /// 自定义类型的消息，需要您自己设置pushContent和pushData来定义推送内容，否则将不会进行远程推送。
  ///
  ///
  /// 发送消息之后有两种查看结果的方式：1、发送消息的 callback 2、onMessageSend；推荐使用 callback 的方式
  /// 如果未实现此方法的 callback，则会通过 onMessageSend 返回发送消息的结果
  static Future<Message> sendMessageWithCallBack(
      int conversationType,
      String targetId,
      MessageContent content,
      String pushContent,
      String pushData,
      Function(int messageId, int status, int code) finished) async {
    if (conversationType == null || targetId == null || content == null) {
      print("send message fail: conversationType or targetId or content is null");
      return null;
    }
    if (pushContent == null) {
      pushContent = "";
    }
    if (pushData == null) {
      pushData = "";
    }
    String jsonStr = content.encode();
    String objName = content.getObjectName();

    // 此处获取当前时间戳传给原生方法，并且当做 sendMessageCallbacks 的 key 记录 finished
    DateTime time = DateTime.now();
    int timestamp = time.millisecondsSinceEpoch;

    Map map = {
      'conversationType': conversationType,
      'targetId': targetId,
      "content": jsonStr,
      "objectName": objName,
      "pushContent": pushContent,
      "pushData": pushData,
      "timestamp": timestamp
    };

    if (finished != null) {
      sendMessageCallbacks[timestamp] = finished;
    }

    Map resultMap = await _channel.invokeMethod(RCMethodKey.SendMessage, map);
    if (resultMap == null) {
      return null;
    }
    String messageString = resultMap["message"];
    Message msg = MessageFactory.instance.string2Message(messageString);
    return msg;
  }

  ///发送定向消息
  ///
  ///[conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  ///[targetId] 会话 id
  ///
  ///[userIdList] 接收消息的用户 ID 列表
  ///
  ///[content] 消息内容 参见 [MessageContent]
  ///
  ///[pushContent] 接收方离线时需要显示的远程推送内容
  ///
  ///[pushData] 接收方离线时需要在远程推送中携带的非显示数据
  ///
  /// 此方法用于在群组和讨论组中发送消息给其中的部分用户，其它用户不会收到这条消息。
  /// 目前仅支持群组和讨论组。
  static Future<Message> sendDirectionalMessage(
      int conversationType, String targetId, List userIdList, MessageContent content,
      {String pushContent, String pushData}) async {
    if (conversationType == null || targetId == null || content == null) {
      print("send directional message fail: conversationType or targetId or content is null");
      return null;
    }
    if (userIdList.length <= 0) {
      print("userIdList 为空");
      return null;
    }
    if (pushContent == null) {
      pushContent = "";
    }
    if (pushData == null) {
      pushData = "";
    }
    String jsonStr = content.encode();
    String objName = content.getObjectName();
    Map map = {
      'conversationType': conversationType,
      'targetId': targetId,
      'userIdList': userIdList,
      "content": jsonStr,
      "objectName": objName,
      "pushContent": pushContent,
      "pushData": pushData
    };

    Map resultMap = await _channel.invokeMethod(RCMethodKey.SendDirectionalMessage, map);
    if (resultMap == null) {
      return null;
    }
    String messageString = resultMap["message"];
    Message msg = MessageFactory.instance.string2Message(messageString);
    return msg;
  }

  ///获取历史消息
  ///
  ///[conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  ///[targetId] 会话 id
  ///
  ///[messageId] 消息 id，每次进入聊天页面可以传 0
  ///
  ///[count] 需要获取的消息数
  static Future<List> getHistoryMessage(
      int conversationType, String targetId, int messageId, int count) async {
    Map map = {
      'conversationType': conversationType,
      'targetId': targetId,
      "messageId": messageId,
      "count": count
    };
    List list = await _channel.invokeMethod(RCMethodKey.GetHistoryMessage, map);
    if (list == null) {
      return null;
    }
    List msgList = new List();
    for (String msgStr in list) {
      Message msg = MessageFactory.instance.string2Message(msgStr);
      msgList.add(msg);
    }
    return msgList;
  }

  ///获取特定方向的历史消息
  ///
  ///[conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  ///[targetId] 会话 id
  ///
  ///[objName] 消息的 objectName，如果传有效的 objectName，那么只会获取该类型的消息；如果传 null，则会获取全部的消息类型
  ///
  ///[messageId] 消息 id，基于该消息获取更多的消息
  ///
  ///[historyMsgDirection] 历史消息的方向，����于 messageId 获取之前的消息还是之后的消息，参见枚举 [RCHistoryMessageDirection]，非法值按 Behind 处理
  ///
  ///[count] 需要获取的消息数
  ///
  ///[return] 获取到的消息列表
  static Future<List> getHistoryMessages(
      int conversationType, String targetId, int sentTime, int beforeCount, int afterCount) async {
    if (conversationType == null || targetId == null) {
      print("getHistoryMessages error: conversationType or targetId null");
      return null;
    }
    Map map = {
      'conversationType': conversationType,
      'targetId': targetId,
      "sentTime": TypeUtil.getProperInt(sentTime),
      "beforeCount": TypeUtil.getProperInt(beforeCount),
      "afterCount": TypeUtil.getProperInt(afterCount),
    };
    List list = await _channel.invokeMethod(RCMethodKey.GetHistoryMessages, map);
    if (list == null) {
      return null;
    }
    List msgList = new List();
    for (String msgStr in list) {
      Message msg = MessageFactory.instance.string2Message(msgStr);
      msgList.add(msg);
    }
    return msgList;
  }

  static clearHistoryMessages(int conversationType, String targetId, int recordTime,
      bool clearRemote, Function(int code) finished) async {
    if (conversationType == null || targetId == null) {
      print("getHistoryMessages error: conversationType or targetId null");
      return null;
    }
    Map map = {
      'conversationType': conversationType,
      'targetId': targetId,
      "recordTime": TypeUtil.getProperInt(recordTime),
      "clearRemote": clearRemote,
    };

    int code = await _channel.invokeMethod(RCMethodKey.ClearHistoryMessages, map);
    if (finished != null) {
      finished(code);
    }
  }

  ///获取本地单条消息
  ///
  ///[messageId] 消息 id
  static Future<Message> getMessage(int messageId) async {
    Map map = {"messageId": messageId};
    String msgStr = await _channel.invokeMethod(RCMethodKey.GetMessage, map);
    if (msgStr == null) {
      return null;
    }
    Message msg = MessageFactory.instance.string2Message(msgStr);
    return msg;
  }

//  ///获取会话列表
//  static Future<List> getConversationList() async {
//    List list = await _channel.invokeMethod(RCMethodKey.GetConversationList);
//    if (list == null) {
//      return null;
//    }
//    List conList = new List();
//    for (String conStr in list) {
//      Conversation con = MessageFactory.instance.string2Conversation(conStr);
//      conList.add(con);
//    }
//    return conList;
//  }

  ///根据传入的会话类型来获取会话列表
  ///
  /// [conversationTypeList] 会话类型数组，参见枚举 [RCConversationType]
  static Future<List /*Conversation*/ > getConversationList(
      List<int /*RCConversationType*/ > conversationTypeList) async {
    Map map = {"conversationTypeList": conversationTypeList};
    List list = await _channel.invokeMethod(RCMethodKey.GetConversationList, map);
    if (list == null) {
      return null;
    }
    List conList = new List();
    for (String conStr in list) {
      Conversation con = MessageFactory.instance.string2Conversation(conStr);
      conList.add(con);
    }
    return conList;
  }

  ///根据传入的会话类型来分页获取会话列表
  ///
  /// [conversationTypeList] 会话类型数组，参见枚举 [RCConversationType]
  ///
  /// [count] 需要获取的会话个数，当实际取回的会话个数小于 count 值时，表明已取完数据
  ///
  /// [startTime] 会话的时间戳，获取这个时间戳之前的会话列表，第一次传 0
  static Future<List /*Conversation*/ > getConversationListByPage(
      List<int /*RCConversationType*/ > conversationTypeList, int count, int startTime) async {
    Map map = {
      "conversationTypeList": conversationTypeList,
      "count": count,
      "startTime": startTime
    };
    List list = await _channel.invokeMethod(RCMethodKey.GetConversationListByPage, map);
    if (list == null) {
      return null;
    }
    List conList = new List();
    for (String conStr in list) {
      Conversation con = MessageFactory.instance.string2Conversation(conStr);
      conList.add(con);
    }
    return conList;
  }

  ///获取特定会话的详细信息
  ///
  ///[conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  ///[targetId] 会话 id
  ///
  ///[return] 返回结果为会话的详细数据，如果不存在该会话，那么会返回 null
  static Future<Conversation> getConversation(int conversationType, String targetId) async {
    if (conversationType == null || targetId == null) {
      print("getConversation error, conversationType or targetId is null");
      return null;
    }
    Map param = {"conversationType": conversationType, "targetId": targetId};
    String conStr = await _channel.invokeMethod(RCMethodKey.GetConversation, param);
    Conversation con = MessageFactory.instance.string2Conversation(conStr);
    return con;
  }

  ///删除指定会话
  ///
  ///[conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  ///[targetId] 会话 id
  ///
  ///[finished] 回调结果，告知结果成功与否
  static void removeConversation(
      int conversationType, String targetId, Function(bool success) finished) async {
    Map map = {'conversationType': conversationType, 'targetId': targetId};
    bool success = await _channel.invokeMethod(RCMethodKey.RemoveConversation, map);
    if (finished != null) {
      finished(success);
    }
  }

  ///清除会话的未读消息
  ///
  ///[conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  ///[targetId] 会话 id
  static Future<bool> clearMessagesUnreadStatus(int conversationType, String targetId) async {
    Map map = {'conversationType': conversationType, 'targetId': targetId};
    bool rc = await _channel.invokeMethod(RCMethodKey.ClearMessagesUnreadStatus, map);
    return rc;
  }

  ///加入聊天室
  ///
  ///[targetId] 聊天室 id
  ///
  ///[messageCount] 需要获取的聊天室历史消息数量 0<=messageCount<=50
  /// -1 代表不获取历史消息
  /// 0 代表默认 10 条
  ///
  /// 会通过 [onJoinChatRoom] 回调加入的结果
  static void joinChatRoom(String targetId, int messageCount) {
    Map map = {"targetId": targetId, "messageCount": messageCount};
    _channel.invokeMethod(RCMethodKey.JoinChatRoom, map);
  }

  ///退出聊天室
  ///
  ///[targetId] 聊天室 id
  ///
  /// 会通过 [onQuitChatRoom] 回调退出的结果
  static void quitChatRoom(String targetId) {
    Map map = {"targetId": targetId};
    _channel.invokeMethod(RCMethodKey.QuitChatRoom, map);
  }

  ///获取聊天室信息
  ///
  ///[targetId] 聊天室 id
  ///
  ///[memeberCount] 需要获取的聊天室成员个数 0<=memeberCount<=20
  ///
  ///[memberOrder] 获取的成员加入聊天室的顺序，参见枚举 [RCChatRoomMemberOrder]
  ///
  static Future getChatRoomInfo(String targetId, int memeberCount, int memberOrder) async {
    if (memeberCount > 20) {
      memeberCount = 20;
    }
    Map map = {"targetId": targetId, "memeberCount": memeberCount, "memberOrder": memberOrder};
    Map resultMap = await _channel.invokeMethod(RCMethodKey.GetChatRoomInfo, map);
    return MessageFactory.instance.map2ChatRoomInfo(resultMap);
  }

  /// 返回一个[Map] {"code":...,"messages":...,"isRemaining":...}
  /// code:是否获取成功
  /// messages:获取到的历史消息数组,
  /// isRemaining:是否还有剩余消息 YES 表示还有剩余，NO 表示无剩余
  ///
  /// [conversationType]  会话类型，参见枚举 [RCConversationType]
  ///
  /// [targetId]          聊天室的会话ID
  ///
  /// [recordTime]        起始的消息发送时间戳，毫秒
  ///
  /// [count]             需要获取的消息数量， 0 < count <= 200
  ///
  /// 此方法从服务器端获取之前的历史消息，但是必须先开通历史消息云存储功能。
  /// 例如，本地会话中有10条消息，您想拉取更多保存在服务器的消息的话，recordTime应传入最早的消息的发送时间戳，count传入1~20之间的数值。
  static void getRemoteHistoryMessages(int conversationType, String targetId, int recordTime,
      int count, Function(List/*<Message>*/ msgList, int code) finished) async {
    Map map = {
      'conversationType': conversationType,
      'targetId': targetId,
      'recordTime': recordTime,
      'count': count
    };
    Map resultMap = await _channel.invokeMethod(RCMethodCallBackKey.GetRemoteHistoryMessages, map);
    int code = resultMap["code"];
    if (code == 0) {
      List msgStrList = resultMap["messages"];
      if (msgStrList == null) {
        if (finished != null) {
          finished(null, code);
        }
        return;
      }
      List l = new List();
      for (String msgStr in msgStrList) {
        Message m = MessageFactory.instance.string2Message(msgStr);
        l.add(m);
      }
      if (finished != null) {
        finished(l, code);
      }
    } else {
      if (finished != null) {
        finished(null, code);
      }
    }
  }

  /// 插入一条收到的消息
  ///
  /// [conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  /// [targetId] 会话 id
  ///
  /// [senderUserId] 发送者 id
  ///
  /// [receivedStatus] 接收状态 参见枚举 [RCReceivedStatus]
  ///
  /// [content] 消息内容，参见 [MessageContent]
  ///
  /// [sendTime] 发送时间
  ///
  /// [finished] 回调结果，会告知具体的消息和对应的错�����码
  static void insertIncomingMessage(
      int conversationType,
      String targetId,
      String senderUserId,
      int receivedStatus,
      MessageContent content,
      int sendTime,
      Function(Message msg, int code) finished) async {
    String jsonStr = content.encode();
    String objName = content.getObjectName();
    Map map = {
      "conversationType": conversationType,
      "targetId": targetId,
      "senderUserId": senderUserId,
      "rececivedStatus": receivedStatus,
      "objectName": objName,
      "content": jsonStr,
      "sendTime": sendTime
    };
    Map msgMap = await _channel.invokeMethod(RCMethodKey.InsertIncomingMessage, map);
    String msgString = msgMap["message"];
    int code = msgMap["code"];
    if (msgString == null) {
      if (finished != null) {
        finished(null, code);
      }
      return;
    }
    Message message = MessageFactory.instance.string2Message(msgString);
    if (finished != null) {
      finished(message, code);
    }
  }

  /// 插入一条发出的消息
  ///
  /// [conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  /// [targetId] 会话 id
  ///
  /// [sendStatus] 发送状态，参见枚举 [RCSentStatus]
  ///
  /// [content] 消息内容，参见 [MessageContent]
  ///
  /// [sendTime] 发送时间
  ///
  /// [finished] 回调结果，会告知具体的消息和对应的错误码
  static void insertOutgoingMessage(int conversationType, String targetId, int sendStatus,
      MessageContent content, int sendTime, Function(Message msg, int code) finished) async {
    String jsonStr = content.encode();
    String objName = content.getObjectName();
    Map map = {
      "conversationType": conversationType,
      "targetId": targetId,
      "sendStatus": sendStatus,
      "objectName": objName,
      "content": jsonStr,
      "sendTime": sendTime
    };
    Map msgMap = await _channel.invokeMethod(RCMethodKey.InsertOutgoingMessage, map);
    String msgString = msgMap["message"];
    int code = msgMap["code"];
    if (msgString == null) {
      if (finished != null) {
        finished(null, code);
      }
      return;
    }
    Message message = MessageFactory.instance.string2Message(msgString);
    if (finished != null) {
      finished(message, code);
    }
  }

  /// 删除特定会话的消息
  ///
  /// [conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  /// [targetId] 会话 id
  static void deleteMessages(
      int conversationType, String targetId, Function(int code) finished) async {
    Map map = {"conversationType": conversationType, "targetId": targetId};
    int code = await _channel.invokeMethod(RCMethodKey.DeleteMessages, map);
    if (finished != null) {
      finished(code);
    }
  }

  /// 批量删除消息
  ///
  /// [messageIds] 需要删除的 messageId List
  static void deleteMessageByIds(List<int> messageIds, Function(int code) finished) async {
    Map map = {"messageIds": messageIds};
    int code = await _channel.invokeMethod(RCMethodKey.DeleteMessageByIds, map);
    if (finished != null) {
      finished(code);
    }
  }

  /// 获取所有的未读数
  ///
  /// [finished] 回调结果，code 为 0 代表正常
  static void getTotalUnreadCount(Function(int count, int code) finished) async {
    Map map = await _channel.invokeMethod(RCMethodKey.GetTotalUnreadCount);
    if (finished != null) {
      finished(map["count"], map["code"]);
    }
  }

  /// 获取单个会话的未读数
  ///
  /// [conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  /// [targetId] 会话 id
  ///
  /// [finished] 回调结果，code 为 0 代表正常
  static void getUnreadCount(
      int conversationType, String targetId, Function(int count, int code) finished) async {
    Map map = {"conversationType": conversationType, "targetId": targetId};
    Map unreadMap = await _channel.invokeMethod(RCMethodKey.GetUnreadCountTargetId, map);
    if (finished != null) {
      finished(unreadMap["count"], unreadMap["code"]);
    }
  }

  /// 批量获取特定某些会话的未读数
  ///
  /// [conversationTypeList] 会话类型数组，参见枚举 [RCConversationType]
  ///
  /// [isContain] 是否包含免打扰会话
  ///
  /// [finished] 回调结果，code 为 0 代表正常
  static void getUnreadCountConversationTypeList(List<int> conversationTypeList, bool isContain,
      Function(int count, int code) finished) async {
    Map map = {"conversationTypeList": conversationTypeList, "isContain": isContain};
    Map unreadMap =
        await _channel.invokeMethod(RCMethodKey.GetUnreadCountConversationTypeList, map);
    if (finished != null) {
      finished(unreadMap["count"], unreadMap["code"]);
    }
  }

  /// 设置会话的提醒状态
  ///
  /// [conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  /// [targetId] 会话 id
  ///
  /// [finished] 回调结果，status 参见 [RCConversationNotificationStatus]，code 为 0 代表正常
  static void setConversationNotificationStatus(int conversationType, String targetId,
      bool isBlocked, Function(int status, int code) finished) async {
    Map map = {"conversationType": conversationType, "targetId": targetId, "isBlocked": isBlocked};
    Map statusMap = await _channel.invokeMethod(RCMethodKey.SetConversationNotificationStatus, map);
    if (finished != null) {
      finished(statusMap["status"], statusMap["code"]);
    }
  }

  /// 获取会话的提醒状态
  ///
  /// [conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  /// [targetId] 会话 id
  ///
  /// [finished] 回调结果，status 参见 [RCConversationNotificationStatus]，code 为 0 代表正常
  static void getConversationNotificationStatus(
      int conversationType, String targetId, Function(int status, int code) finished) async {
    Map map = {"conversationType": conversationType, "targetId": targetId};
    Map statusMap = await _channel.invokeMethod(RCMethodKey.GetConversationNotificationStatus, map);
    if (finished != null) {
      finished(statusMap["status"], statusMap["code"]);
    }
  }

  /// 获取设置免打扰的会话列表
  ///
  /// [conversationTypeList] 会话类型数组，参见枚举 [RCConversationType]
  ///
  /// [finished] 回调结果，code 为 0 代表正常
  static void getBlockedConversationList(List<int> conversationTypeList,
      Function(List<Conversation> convertionList, int code) finished) async {
    Map map = {"conversationTypeList": conversationTypeList};
    Map conversationMap = await _channel.invokeMethod(RCMethodKey.GetBlockedConversationList, map);

    List conversationList = conversationMap["conversationMap"];
    if (conversationList == null) {
      if (finished != null) {
        finished(null, conversationMap["code"]);
      }
      return;
    }
    List conList = new List();
    for (String conStr in conversationList) {
      Conversation con = MessageFactory.instance.string2Conversation(conStr);
      conList.add(con);
    }
    if (finished != null) {
      finished(conList, conversationMap["code"]);
    }
  }

  /// 设置会话置顶
  ///
  /// [conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  /// [targetId] 会话 id
  ///
  /// [isTop] 是否设置置顶
  ///
  /// [finished] 回调结果，code 为 0 代表正常
  static void setConversationToTop(int conversationType, String targetId, bool isTop,
      Function(bool status, int code) finished) async {
    Map map = {"conversationType": conversationType, "targetId": targetId, "isTop": isTop};
    Map conversationMap = await _channel.invokeMethod(RCMethodKey.SetConversationToTop, map);
    if (finished != null) {
      finished(conversationMap["status"], conversationMap["code"]);
    }
  }

//
//  /// TODO 安卓没有此接口
//  static void getTopConversationList(List<int> conversationTypeList, Function(List<Conversation> convertionList, int code) finished) async {
//    Map map = {
//      "conversationTypeList": conversationTypeList
//    };
//    Map conversationMap = await _channel.invokeMethod(RCMethodKey.GetTopConversationList, map);
//
//    List conversationList = conversationMap["conversationMap"];
//    List conList = new List();
//    for (String conStr in conversationList) {
//      Conversation con = MessageFactory.instance.string2Conversation(conStr);
//      conList.add(con);
//    }
//    if (finished != null) {
//      finished(conList, conversationMap["code"]);
//    }
//  }

  /// 将用户加入黑名单，黑名单针对用户 id 生效，即使换设备也依然生效。
  ///
  /// [userId] 需要加入黑名单的用户 id
  ///
  /// [finished] 回调结果，code 为 0 代表操作成功，其他值代表失败
  static void addToBlackList(String userId, Function(int code) finished) async {
    Map map = {"userId": userId};
    int code = await _channel.invokeMethod(RCMethodKey.AddToBlackList, map);
    if (finished != null) {
      finished(code);
    }
  }

  /// 将用户移除黑名单
  ///
  /// [userId] 需要移除黑名单的用户 id
  ///
  /// [finished] 回调结果，code 为 0 代表操作成功，其他值代表失败
  static void removeFromBlackList(String userId, Function(int code) finished) async {
    Map map = {"userId": userId};
    int code = await _channel.invokeMethod(RCMethodKey.RemoveFromBlackList, map);
    if (finished != null) {
      finished(code);
    }
  }

  /// 获取特定用户的黑名单状态
  ///
  /// [userId] 需要加入黑名单的用户 id
  ///
  /// [finished] 回调结果，code 为 0 代表操作成功，其他值代表失败
  ///
  /// [blackListStatus] 黑名单状态，0 代表在黑名单，1 代表不在黑名单，详细参见 [RCBlackListStatus]
  static void getBlackListStatus(
      String userId, Function(int blackListStatus, int code) finished) async {
    Map map = {"userId": userId};
    Map result = await _channel.invokeMethod(RCMethodKey.GetBlackListStatus, map);
    int status = result["status"];
    int code = result["code"];
    if (finished != null) {
      finished(status, code);
    }
  }

  /// 查询已经设置的黑名单列表
  ///
  /// [finished] 回调结果，code 为 0 代表操作成功，其他值代表失败
  ///
  /// [userIdList] 黑名单用户 id 列表
  static void getBlackList(Function(List/*<String>*/ userIdList, int code) finished) async {
    Map result = await _channel.invokeMethod(RCMethodKey.GetBlackList);
    List userIdList = result["userIdList"];
    int code = result["code"];
    if (finished != null) {
      finished(userIdList, code);
    }
  }

  /// 发送某个会话中消息阅读的回执
  ///
  /// [conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  /// [targetId] 会话 id
  ///
  /// [timestamp] 该会话已阅读的最后一条消息的发送时间戳
  ///
  /// [finished] 回调结果，code 为 0 代表操作成功，其他值代表失败
  /// 此接口只支持单聊
  static void sendReadReceiptMessage(
      int conversationType, String targetId, int timestamp, Function(int code) finished) async {
    Map map = {"conversationType": conversationType, "targetId": targetId, "timestamp": timestamp};

    Map result = await _channel.invokeMethod(RCMethodKey.SendReadReceiptMessage, map);
    int code = result["code"];
    if (finished != null) {
      finished(code);
    }
  }

  /// 请求消息阅读回执
  ///
  /// [message] 要求阅读回执的消息
  ///
  /// [timestamp] 该会话已阅读的最后一条消息的发送时间戳
  ///
  /// [finished] 回调结果，code 为 0 代表操作成功，其他值代表失败
  /// 此接口只支持群组
  static void sendReadReceiptRequest(Message message, Function(int code) finished) async {
    Map messageMap = MessageFactory.instance.message2Map(message);
    Map map = {"messageMap": messageMap};

    Map result = await _channel.invokeMethod(RCMethodKey.SendReadReceiptRequest, map);
    int code = result["code"];
    if (finished != null) {
      finished(code);
    }
  }

  /// 发送阅读回执
  ///
  /// [conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  /// [targetId] 会话 id
  ///
  /// [messageList] 已经阅读了的消息列表
  ///
  /// [finished] 回调结果，code 为 0 代表操作成功，其他值代表失败
  /// 此接口只支持群组
  static void sendReadReceiptResponse(
      int conversationType, String targetId, List messageList, Function(int code) finished) async {
    List messageMaps = List();
    for (Message message in messageList) {
      Map messageMap = MessageFactory.instance.message2Map(message);
      messageMaps.add(messageMap);
    }
    Map map = {
      "conversationType": conversationType,
      "targetId": targetId,
      "messageMapList": messageMaps
    };

    Map result = await _channel.invokeMethod(RCMethodKey.SendReadReceiptResponse, map);
    int code = result["code"];
    if (finished != null) {
      finished(code);
    }
  }

  /// 同步会话阅读状态
  ///
  /// [conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  /// [targetId] 会话 id
  ///
  /// [timestamp] 该会话已阅读的最后一条消息的发送时间戳
  ///
  /// [finished] 回调结果，code 为 0 代表操作成功，其他值代表失败
  ///
  static void syncConversationReadStatus(
      int conversationType, String targetId, int timestamp, Function(int code) finished) async {
    Map map = {"conversationType": conversationType, "targetId": targetId, "timestamp": timestamp};

    int result = await _channel.invokeMethod(RCMethodKey.SyncConversationReadStatus, map);
    if (finished != null) {
      finished(result);
    }
  }

  /// 全局屏蔽某个时间段的消息提醒
  ///
  /// [startTime] 开始屏蔽消息提醒的时间，格式为HH:MM:SS
  ///
  /// [spanMins] 需要屏蔽消息提醒的分钟数，0 < spanMins < 1440
  ///
  /// [finished] 回调结果，code 为 0 代表操作成功，其他值代表失败
  ///
  /// 此方法设置的屏蔽时间会在每天该时间段时生效。
  static void setNotificationQuietHours(
      String startTime, int spanMins, Function(int code) finished) async {
    Map map = {"startTime": startTime, "spanMins": spanMins};
    int result = await _channel.invokeMethod(RCMethodKey.SetNotificationQuietHours, map);
    if (finished != null) {
      finished(result);
    }
  }

  /// 删除已设置的全局时间段消息提醒屏蔽
  ///
  /// [finished] 回调结果，code 为 0 代表操作成功，其他值代表失败
  ///
  static void removeNotificationQuietHours(Function(int code) finished) async {
    int result = await _channel.invokeMethod(RCMethodKey.RemoveNotificationQuietHours);
    if (finished != null) {
      finished(result);
    }
  }

  /// 查询已设置的全局时间段消息提醒屏蔽
  ///
  /// [finished] 回调结果，code 为 0 代表操作成功，其他值代表失败；startTime 代表已设置的屏蔽开始时间，spansMin 代表已设置的屏蔽时间分钟数，0 < spansMin < 1440
  ///
  static void getNotificationQuietHours(
      Function(int code, String startTime, int spansMin) finished) async {
    Map result = await _channel.invokeMethod(RCMethodKey.GetNotificationQuietHours);
    int code = result["code"];
    String startTime = result["startTime"];
    int spansMin = result["spansMin"];
    if (finished != null) {
      finished(code, startTime, spansMin);
    }
  }

  /// 获取会话中@提醒自己的消息
  ///
  /// [conversationType] 会话类型，参见枚举 [RCConversationType]
  ///
  /// [targetId] 会话 id
  ///
  /// 此方法从本地获取被@提醒的消息(最多返回10条信息)
  /// clearMessagesUnreadStatus: targetId: 以及设置消息接收状态接口 setMessageReceivedStatus:receivedStatus:会同步清除被提示信息状态。
  static Future<List /*Message*/ > getUnreadMentionedMessages(
      int conversationType, String targetId) async {
    Map map = {"conversationType": conversationType, "targetId": targetId};
    List list = await _channel.invokeMethod(RCMethodKey.GetUnreadMentionedMessages, map);
    if (list == null) {
      return List();
    }
    List messageList = new List();
    for (String conStr in list) {
      Message msg = MessageFactory.instance.string2Message(conStr);
      messageList.add(msg);
    }
    return messageList;
  }

  /// 设置聊天室自定义属性
  ///
  /// [chatroomId] 聊天室 Id
  ///
  /// [key] 聊天室属性名称，Key 支持大小写英文字母、数字、部分特殊符号 + = - _ 的组合方式，最大长度 128 个字符
  ///
  /// [value] 聊天室属性对应的值，最大长度 4096 个字符
  ///
  /// [sendNotification] 是否需要发送通知，如果发送通知，聊天室中的其他用户会接收到 RCChatroomKVNotificationMessage 通知消息，消息内容中包含操作类型(type)、属性名称(key)、属性名称对应的值(value)和自定义字段(extra)
  ///
  /// [autoDelete] 用户掉线或退出时，是否自动删除该 Key、Value 值；自动删除时不会发送通知
  ///
  /// [notificationExtra] 通知的自定义字段，RC:chrmKVNotiMsg 通知消息中会包含此字段，最大长度 2 kb
  ///
  /// [finished] 回调结果，code 为 0 代表操作成功，其他值代表失败
  /// 此接口只支持聊天室，必须先开通聊天室属性自定义功能
  static void setChatRoomEntry(String chatRoomId, String key, String value, bool sendNotification,
      bool autoDelete, String notificationExtra, Function(int code) finished) async {
    Map map = {
      "chatRoomId": chatRoomId,
      "key": key,
      "value": value,
      "sendNotification": sendNotification,
      "autoDelete": autoDelete,
      "notificationExtra": notificationExtra
    };
    int result = await _channel.invokeMethod(RCMethodKey.SetChatRoomEntry, map);
    if (finished != null) {
      finished(result);
    }
  }

  /// 强制设置聊天室自定义属性
  ///
  /// [chatroomId] 聊天室 Id
  ///
  /// [key] 聊天室属性名称，Key 支持大小写英文字母、数字、部分特殊符号 + = - _ 的组合方式，最大长度 128 个字符
  ///
  /// [value] 聊天室属性对应的值，最大长度 4096 个字符
  ///
  /// [sendNotification] 是否需要发送通知，如果发送通知，聊天室中的其他用户会接收到 RCChatroomKVNotificationMessage 通知消息，消息内容中包含操作类型(type)、属性名称(key)、属性名称对应的值(value)和自定义字段(extra)
  ///
  /// [autoDelete] 用户掉线或退出时，是否自动删除该 Key、Value 值；自动删除时不会发送通知
  ///
  /// [notificationExtra] 通知的自定义字段，RC:chrmKVNotiMsg 通知消息中会包含此字段，最大长度 2 kb
  ///
  /// [finished] 回调结果，code 为 0 代表操作成功，其他值代表失败
  /// 此接口只支持聊天室，必须先开通聊天室属性自定义功能
  static void forceSetChatRoomEntry(
      String chatRoomId,
      String key,
      String value,
      bool sendNotification,
      bool autoDelete,
      String notificationExtra,
      Function(int code) finished) async {
    Map map = {
      "chatRoomId": chatRoomId,
      "key": key,
      "value": value,
      "sendNotification": sendNotification,
      "autoDelete": autoDelete,
      "notificationExtra": notificationExtra
    };
    int result = await _channel.invokeMethod(RCMethodKey.ForceSetChatRoomEntry, map);
    if (finished != null) {
      finished(result);
    }
  }

  /// 获取聊天室单个属性
  ///
  /// [chatroomId] 聊天室 Id
  ///
  /// [key] 聊天室属性名称
  ///
  /// [finished] 回调结果，code 为 0 代表操作成功，其他值代表失败，entry 为返回的 map
  /// 此接口只支持聊天室，必须先开通聊天室属性自定义功能
  static void getChatRoomEntry(
      String chatRoomId, String key, Function(Map entry, int code) finished) async {
    Map map = {"chatRoomId": chatRoomId, "key": key};

    Map result = await _channel.invokeMethod(RCMethodKey.GetChatRoomEntry, map);
    int code = result["code"];
    Map entry = result["entry"];
    if (finished != null) {
      finished(entry, code);
    }
  }

  /// 获取聊天室所有自定义属性
  ///
  /// [chatroomId] 聊天室 Id
  ///
  /// [finished] 回调结果，code 为 0 代表操作成功，其他值代表失败，entry 为返回的 map
  /// 此接口只支持聊天室，必须先开通聊天室属性自定义功能
  static void getAllChatRoomEntries(
      String chatRoomId, Function(Map entry, int code) finished) async {
    Map map = {"chatRoomId": chatRoomId};

    Map result = await _channel.invokeMethod(RCMethodKey.GetAllChatRoomEntries, map);
    int code = result["code"];
    Map entry = result["entry"];
    if (finished != null) {
      finished(entry, code);
    }
  }

  /// 删除聊天室自定义属性
  ///
  /// [chatroomId] 聊天室 Id
  ///
  /// [key] 聊天室属性名称
  ///
  /// [sendNotification] 是否需要发送通知，如果发送通知，聊天室中的其他用户会接收到 RCChatroomKVNotificationMessage 通知消息，消息内容中包含操作类型(type)、属性名称(key)、属性名称对应的值(value)和自定义字段(extra)
  ///
  /// [notificationExtra] 通知的自定义字段，RC:chrmKVNotiMsg ������消息中会包含此字段，最大长度 2 kb
  ///
  /// [finished] 回调结果，code 为 0 代表操作成功，其他值代表失败
  /// 此接口只支持聊天室，必须先开通聊天室属性自定义功能
  static void removeChatRoomEntry(String chatRoomId, String key, bool sendNotification,
      String notificationExtra, Function(int code) finished) async {
    Map map = {
      "chatRoomId": chatRoomId,
      "key": key,
      "sendNotification": sendNotification,
      "notificationExtra": notificationExtra
    };
    int result = await _channel.invokeMethod(RCMethodKey.RemoveChatRoomEntry, map);
    if (finished != null) {
      finished(result);
    }
  }

  /// 强制删除聊天室自定义属性
  ///
  /// [chatroomId] 聊天室 Id
  ///
  /// [key] 聊天室属性名称
  ///
  /// [sendNotification] 是否需要发送通知，如果发送通知，聊天室中的其他用户会接收到 RCChatroomKVNotificationMessage 通知消息，消息内容中包含操作类型(type)、属性名称(key)、属性名称对应的值(value)和自定义字段(extra)
  ///
  /// [notificationExtra] 通知的自定义字段，RC:chrmKVNotiMsg 通知消息中会包含此字段，最大长度 2 kb
  ///
  /// [finished] 回调结果，code 为 0 代表操作成功，其他值代表失败
  /// 此接口只支持聊天室，必须先开通聊天室属性自定义功能
  static void forceRemoveChatRoomEntry(String chatRoomId, String key, bool sendNotification,
      String notificationExtra, Function(int code) finished) async {
    Map map = {
      "chatRoomId": chatRoomId,
      "key": key,
      "sendNotification": sendNotification,
      "notificationExtra": notificationExtra
    };
    int result = await _channel.invokeMethod(RCMethodKey.ForceRemoveChatRoomEntry, map);
    if (finished != null) {
      finished(result);
    }
  }

  ///连接状态发生变更
  ///
  /// [connectionStatus] 连接状态，具体参见枚举 [RCConnectionStatus]
  static Function(int connectionStatus) onConnectionStatusChange;

  ///调用发送消息接口 [sendMessage] 结果的回调
  ///
  /// [messageId]  消息 id
  ///
  /// [status] 消息发送状态，参见枚举 [RCSentStatus]
  ///
  /// [code] 具体的错误码，0 代表成功
  static Function(int messageId, int status, int code) onMessageSend;

  ///收到消息的回调，功能和 onMessageReceivedWrapper 一样，两个回调只能实现一个，否则会出现重复收到消息的情况
  ///
  ///[msg] 消息
  ///
  ///[left] 剩余未接收的消息个数 left>=0，建议在 left == 0 是刷新会话列表
  ///
  ///如果离线消息量不大，可以使用该回调；如果离线消息量巨大，那么使用下面 [onMessageReceivedWrapper] 回调
  static Function(Message msg, int left) onMessageReceived;

  ///收到消息的回调，功能和 onMessageReceived 一样，两个回调只能实现一个，否则会出现重复收到消息的情况
  ///
  ///[msg] 消息
  ///
  ///[left] 剩余未接收的消息个数 left>=0
  ///
  ///[hasPackage] 是否远端还有尚未被接收的消息，当为 false 是代表远端没有更多的离线消息了
  ///
  ///[offline] 消息是否是离线消息
  ///
  ///SDK 分批拉取离线消息，当离线消息量巨大的时候，建议当 left == 0 且 hasPackage == false 时刷新会话列表
  static Function(Message msg, int left, bool hasPackage, bool offline) onMessageReceivedWrapper;

  ///加入聊天的回调
  ///
  ///[targetId] 聊天室 id
  ///
  ///[status] 参见枚举 [RCOperationStatus]
  static Function(String targetId, int status) onJoinChatRoom;

  ///退出聊天的回调
  ///
  ///[targetId] 聊天室 id
  ///
  ///[status] 参见枚举 [RCOperationStatus]
  static Function(String targetId, int status) onQuitChatRoom;

  ///发送媒体消息（图片/语音消息）的媒体上传进度
  ///
  ///[messageId] 消息 id
  ///
  ///[progress] 上传进度 0~100
  static Function(int messageId, int progress) onUploadMediaProgress;

  ///收到原生数据的回调
  ///
  ///[data] 传递的数据内容
  ///
  /// 如果传送的是push内容 建议在 main.dart 使用
  static Function(Map data) onDataReceived;

  ///收到已读消息回执
  ///
  ///[data] 回执的内容 {messageTime=已��读����最后一条消息的sendTime, tId=会话的targetId, ctype=会话类型}
  ///
  ///eg:{messageTime=1575530815100, tId='c1Its71dc', ctype=1}
  static Function(Map data) onReceiveReadReceipt;

  ///请求消息已读回执
  ///
  ///[data] 回执的内容 {messageUId=请求已读回执的消息ID, conversationType=会话类型, targetId=会话的targetId}
  ///
  static Function(Map data) onMessageReceiptRequest;

  ///消息已读回执响应（收到阅读回执响应，可以按照 messageUId 更新消息的阅读数）
  ///
  ///[data] 回执的内容 {messageUId=请求已读回执的消息ID, conversationType=会话类型, targetId=会话的targetId, userIdList=已读userId列表}
  ///
  static Function(Map data) onMessageReceiptResponse;

  // 下载媒体文件响应
  static Function(int code, int progress, int messageId, Message message)
      onDownloadMediaMessageResponse;

  //输入状态的监听
  static Function(int conversationType, String targetId, List typingStatus) onTypingStatusChanged;

  //撤回消息监听
  static Function(Message msg) onRecallMessageReceived;

  ///响应原生的事件
  ///
  static void _addNativeMethodCallHandler() {
    _channel.setMethodCallHandler((MethodCall call) {
      switch (call.method) {
        case RCMethodCallBackKey.SendMessage:
          {
            Map argMap = call.arguments;
            int msgId = argMap["messageId"];
            int status = argMap["status"];
            int code = argMap["code"];
            int timestamp = argMap["timestamp"];
            if (timestamp != null && timestamp > 0) {
              Function(int messageId, int status, int code) finished =
                  sendMessageCallbacks[timestamp];
              if (finished != null) {
                finished(msgId, status, code);
                sendMessageCallbacks.remove(timestamp);
              } else {
                if (onMessageSend != null) {
                  onMessageSend(msgId, status, code);
                }
              }
            } else {
              if (onMessageSend != null) {
                onMessageSend(msgId, status, code);
              }
            }
          }
          break;

        case RCMethodCallBackKey.ReceiveMessage:
          {
            int count = 0;
            if (onMessageReceived != null) {
              count++;
              Map map = call.arguments;
              int left = map["left"];
              String messageString = map["message"];
              Message msg = MessageFactory.instance.string2Message(messageString);
              onMessageReceived(msg, left);
            }
            if (onMessageReceivedWrapper != null) {
              count++;
              Map map = call.arguments;
              int left = map["left"];
              String messageString = map["message"];
              bool hasPackage = map["hasPackage"];
              bool offline = map["offline"];
              Message msg = MessageFactory.instance.string2Message(messageString);
              onMessageReceivedWrapper(msg, left, hasPackage, offline);
            }
            if (count == 2) {
              print(
                  "警告：同时实现了 onMessageReceived 和 onMessageReceivedWrapper 两个接收消息的回调，可能会出现重复接收消息或者重复刷新的问题，建议只实现其中一个！！！");
            }
          }
          break;

        case RCMethodCallBackKey.JoinChatRoom:
          if (onJoinChatRoom != null) {
            Map map = call.arguments;
            String targetId = map["targetId"];
            int status = map["status"];
            onJoinChatRoom(targetId, status);
          }
          break;

        case RCMethodCallBackKey.QuitChatRoom:
          if (onQuitChatRoom != null) {
            Map map = call.arguments;
            String targetId = map["targetId"];
            int status = map["status"];
            onQuitChatRoom(targetId, status);
          }
          break;

        case RCMethodCallBackKey.UploadMediaProgress:
          if (onUploadMediaProgress != null) {
            Map map = call.arguments;
            int messageId = map["messageId"];
            int progress = map["progress"];
            onUploadMediaProgress(messageId, progress);
          }
          break;

        case RCMethodCallBackKey.ConnectionStatusChange:
          if (onConnectionStatusChange != null) {
            Map map = call.arguments;
            int code = map["status"];
            int status = ConnectionStatusConvert.convert(code);
            onConnectionStatusChange(status);
          }
          break;

        case RCMethodCallBackKey.SendDataToFlutter:
          if (onDataReceived != null) {
            Map map = call.arguments;
            onDataReceived(map);
          }
          break;
        case RCMethodCallBackKey.ReceiveReadReceipt:
          if (onReceiveReadReceipt != null) {
            Map map = call.arguments;
            onReceiveReadReceipt(map);
          }
          break;

        case RCMethodCallBackKey.ReceiptRequest:
          if (onMessageReceiptRequest != null) {
            Map map = call.arguments;
            onMessageReceiptRequest(map);
          }
          break;
        case RCMethodCallBackKey.ReceiptResponse:
          if (onMessageReceiptResponse != null) {
            Map map = call.arguments;
            onMessageReceiptResponse(map);
          }
          break;
        case RCMethodCallBackKey.TypingStatusChanged:
          if (onTypingStatusChanged != null) {
            Map map = call.arguments;
            int conversationType = map["conversationType"];
            String targetId = map["targetId"];
            List list = map["typingStatus"];
            List statusList = new List();
            for (String statusStr in list) {
              TypingStatus status = MessageFactory.instance.string2TypingStatus(statusStr);
              statusList.add(status);
            }
            onTypingStatusChanged(conversationType, targetId, statusList);
          }
          break;
        case RCMethodCallBackKey.DownloadMediaMessage:
          if (onDownloadMediaMessageResponse != null) {
            Map map = call.arguments;
            int code = map["code"];
            int progress = map["progress"];
            int messageId = map["messageId"];
            String messageString = map["message"];
            Message message = MessageFactory.instance.string2Message(messageString);
            onDownloadMediaMessageResponse(code, progress, messageId, message);
          }
          break;
        case RCMethodCallBackKey.RecallMessage:
          if (onRecallMessageReceived != null) {
            Map map = call.arguments;
            String messageString = map["message"];
            Message message = MessageFactory.instance.string2Message(messageString);
            onRecallMessageReceived(message);
          }
          break;
      }
      return;
    });
  }

  ///撤回消息
  ///
  ///
  /// 当接收方离线并允许远程推送时，会收到远程推送。
  /// 远程推送中包含两部分内容，一是[pushContent]，用于显示；二是[pushData]，用于携带不显示的数据。
  ///
  /// SDK内置的消息类型，如果您将[pushContent]和[pushData]置为空或者为null，会使用默认的推送格式进行远程推送。
  /// 自定义类型的消息，需要您自己设置pushContent和pushData来定义推送内容，否则将不会进行远程推送。
  static Future<RecallNotificationMessage> recallMessage(
      Message message, String pushContent) async {
    if (message == null) {
      print("send message fail: conversationType or targetId or content is null");
      return null;
    }
    if (pushContent == null) {
      pushContent = "";
    }
    Map msgMap = MessageFactory.instance.message2Map(message);
    Map map = {"message": msgMap, "pushContent": pushContent};
    Map resultMap = await _channel.invokeMethod(RCMethodKey.RecallMessage, map);
    if (resultMap == null) {
      return null;
    }
    String messageString = resultMap["recallNotificationMessage"];
    if (messageString == null || messageString.isEmpty) {
      print("send message fail: conversationType or targetId or content is null");
      return null;
    }
    RecallNotificationMessage msg = MessageFactory.instance
        .string2MessageContent(messageString, RecallNotificationMessage.objectName);
    return msg;
  }

  //根据消息类型，targetId 获取某一会话的文字消息草稿。用于获取用户输入但未发送的暂存消息。
  static Future<String> getTextMessageDraft(int conversationType, String targetId) async {
    if (conversationType == null || targetId == null) {
      print("saveTextMessageDraft fail: conversationType or targetId or content is null");
      return null;
    }
    Map paramMap = {
      "conversationType": conversationType,
      "targetId": targetId,
    };
    String result = await _channel.invokeMethod(RCMethodKey.GetTextMessageDraft, paramMap);
    return result;
  }

  //根据消息类型，targetId 保存某一会话的文字消息草稿。用于暂存用户输入但未发送的消息
  static Future<bool> saveTextMessageDraft(
      int conversationType, String targetId, String textContent) async {
    if (conversationType == null || targetId == null || textContent == null) {
      print("saveTextMessageDraft fail: conversationType or targetId or content is null");
      return null;
    }
    Map paramMap = {
      "conversationType": conversationType,
      "targetId": targetId,
      "content": textContent
    };
    bool result = await _channel.invokeMethod(RCMethodKey.SaveTextMessageDraft, paramMap);
    return result;
  }

  //搜索会话（根据关键词）
  // keyword           搜索的关键字。
  // conversationTypes 搜索的会话类型。
  // objectNames       搜索的消息类型,例如:RC:TxtMsg。
  // resultCallback    搜索结果回调。
  static void searchConversations(String keyword, List conversationTypes, List objectNames,
      Function(int code, List searchConversationResult) finished) async {
    Map paramMap = {
      "keyword": keyword,
      "conversationTypes": conversationTypes,
      "objectNames": objectNames
    };
    Map result = await _channel.invokeMethod(RCMethodKey.SearchConversations, paramMap);
    if (result != null) {
      int code = result['code'];
      List resultList = new List();
      if (code == 0) {
        List searchConversationResult = result['SearchConversationResult'];
        for (String resultStr in searchConversationResult) {
          SearchConversationResult searchConversationResult =
              MessageFactory.instance.string2SearchConversationResult(resultStr);
          resultList.add(searchConversationResult);
        }
      }
      if (finished != null) {
        finished(code, resultList);
      }
    }
  }

  // 根据会话,搜索本地历史消息。
  // 搜索结果可分页返回。
  // conversationType 指定的会话类型。
  // targetId         指定的会话 id。
  // keyword          搜索的关键字。
  // count            返回的搜索结果数量, count > 0。
  // beginTime        查询记录的起始时间, 传0时从最新消息开始搜索。从该时间往前搜索。
  // resultCallback   搜索结果回调。
  static void searchMessages(int conversationType, String targetId, String keyword, int count,
      int beginTime, Function(List/*<Message>*/ msgList, int code) finished) async {
    Map paramMap = {
      "conversationType": conversationType,
      "targetId": targetId,
      "keyword": keyword,
      "count": count,
      "beginTime": beginTime,
    };
    Map resultMap = await _channel.invokeMethod(RCMethodKey.SearchMessages, paramMap);
    int code = resultMap["code"];
    if (code == 0) {
      List msgStrList = resultMap["messages"];
      if (msgStrList == null) {
        if (finished != null) {
          finished(null, code);
        }
        return;
      }
      List l = new List();
      for (String msgStr in msgStrList) {
        Message m = MessageFactory.instance.string2Message(msgStr);
        l.add(m);
      }
      if (finished != null) {
        finished(l, code);
      }
    } else {
      if (finished != null) {
        finished(null, code);
      }
    }
  }

  // 发送输入状态
  static void sendTypingStatus(
      int conversationType, String targetId, String typingContentType) async {
    Map paramMap = {
      "conversationType": conversationType,
      "targetId": targetId,
      "typingContentType": typingContentType,
    };
    await _channel.invokeMethod(RCMethodKey.SendTypingStatus, paramMap);
  }

  // 下载媒体文件
  static void downloadMediaMessage(Message message) async {
    Map msgMap = MessageFactory.instance.message2Map(message);
    Map paramMap = {"message": msgMap};
    await _channel.invokeMethod(RCMethodKey.DownloadMediaMessage, paramMap);
  }

  static void saveMediaToPublicDir(String filePath, String type) async {
    Map paramMap = {"filePath": filePath, "type": type};
    await _channel.invokeMethod(RCMethodKey.SaveMediaToPublicDir, paramMap);
  }

  static void forwardMessageByStep(int conversationType, String targetId, Message message) async {
    Map msgMap = MessageFactory.instance.message2Map(message);
    Map map = {"message": msgMap, "conversationType": conversationType, "targetId": targetId};
    await _channel.invokeMethod(RCMethodKey.ForwardMessageByStep, map);
  }
}
