// Fixture data for the design-QA harness (lib/main_chat_preview.dart).
// Mirrors the sample content in docs/chat_redesign_wireframes.html so screens
// can be compared side by side with the wireframes.

import '../data/chat_models.dart';
import '../state/chat_list_cubit.dart';
import '../state/chat_thread_cubit.dart';

const me = 'me';

DateTime _today(int h, int m) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day, h, m);
}

DateTime _daysAgo(int d, [int h = 18, int m = 5]) {
  final n = DateTime.now().subtract(Duration(days: d));
  return DateTime(n.year, n.month, n.day, h, m);
}

final roomAnand = ChatRoom(
  roomId: 'r-anand',
  adId: 'ad-swift',
  myRole: ChatRole.selling,
  unreadCount: 2,
  createdAt: _daysAgo(3),
  otherUser: const ChatOtherUser(id: 'anand', name: 'Anand K', phoneNumber: '9847012345', countryCode: '+91'),
  ad: const ChatAd(id: 'ad-swift', title: 'Maruti Swift VXI 2019', price: 540000),
  lastMessage: ChatLastMessage(
    id: 'm6', type: MessageType.text, preview: 'Can you do 5 lakh?', senderId: 'anand', createdAt: _today(9, 32)),
);

final roomFathima = ChatRoom(
  roomId: 'r-fathima',
  adId: 'ad-classic',
  myRole: ChatRole.selling,
  createdAt: _daysAgo(2),
  otherUser: const ChatOtherUser(id: 'fathima', name: 'Fathima R'),
  ad: const ChatAd(id: 'ad-classic', title: 'Royal Enfield Classic 350', price: 135000),
  lastMessage: ChatLastMessage(
    id: 'f2', type: MessageType.text, preview: 'Yes, still available', senderId: me, createdAt: _daysAgo(1),
    status: MessageStatus.read),
);

final roomJoseph = ChatRoom(
  roomId: 'r-joseph',
  adId: 'ad-ace',
  myRole: ChatRole.buying,
  unreadCount: 1,
  createdAt: _daysAgo(6),
  otherUser: const ChatOtherUser(id: 'joseph', name: 'Joseph Motors'),
  ad: const ChatAd(id: 'ad-ace', title: 'Tata Ace Gold 2021', price: 385000),
  lastMessage: ChatLastMessage(
    id: 'j9', type: MessageType.image, preview: 'Photo', senderId: 'joseph', createdAt: _daysAgo(4, 11)),
);

final roomSreeja = ChatRoom(
  roomId: 'r-sreeja',
  adId: 'ad-flat',
  myRole: ChatRole.buying,
  createdAt: _daysAgo(20),
  otherUser: const ChatOtherUser(id: 'sreeja', name: 'Sreeja M'),
  ad: const ChatAd(id: 'ad-flat', title: '2BHK flat, Kakkanad', price: 4200000, availability: AdAvailability.sold),
  lastMessage: ChatLastMessage(
    id: 's3', type: MessageType.audio, preview: 'Voice message · 0:24', senderId: 'sreeja', createdAt: _daysAgo(9)),
);

final rooms = [roomAnand, roomFathima, roomJoseph, roomSreeja];

// ---- list states -------------------------------------------------------------

final listDefault = ChatListState(status: ChatListStatus.loaded, rooms: rooms, connection: ChatConnectionStatus.online);
const listLoading = ChatListState(status: ChatListStatus.loading);
const listEmpty = ChatListState(status: ChatListStatus.loaded);
const listError = ChatListState(status: ChatListStatus.error, failure: ChatFailure(ChatFailureKind.offline));
final listSearch = ChatListState(status: ChatListStatus.loaded, rooms: rooms, query: 'swift', searchingRemote: true);

// ---- thread states -------------------------------------------------------------

ChatMessage _m(String id, String sender, String text, DateTime at, {MessageStatus status = MessageStatus.sent}) =>
    ChatMessage(id: id, roomId: 'r-anand', senderId: sender, type: MessageType.text, content: text, createdAt: at, status: status);

final _anandMessages = [
  _m('m6', 'anand', 'Can you do 5 lakh?', _today(9, 32)),
  _m('m5', me, 'You can see it at Edappally on Saturday', _today(9, 31), status: MessageStatus.read),
  _m('m4', me, 'Yes, available. Full service done in August.', _today(9, 31), status: MessageStatus.read),
  _m('m3', 'anand', 'Serviced recently?', _today(9, 28)),
  _m('m2', 'anand', 'Hi, is the Swift still available?', _today(9, 28)),
  _m('m1', me, 'Posted yesterday — ask me anything.', _daysAgo(1, 20, 14), status: MessageStatus.read),
];

final threadDefault = ChatThreadState(
  roomId: 'r-anand',
  status: ChatThreadStatus.loaded,
  room: roomAnand,
  messages: _anandMessages,
  connection: ChatConnectionStatus.online,
  myUserId: me,
);

final threadLoading = ChatThreadState(roomId: 'r-anand', room: roomAnand, myUserId: me);

final threadEmpty = ChatThreadState(
  roomId: 'r-new',
  status: ChatThreadStatus.loaded,
  room: ChatRoom(
    roomId: 'r-new',
    adId: 'ad-swift',
    myRole: ChatRole.buying,
    createdAt: DateTime.now(),
    otherUser: const ChatOtherUser(id: 'anand', name: 'Anand K', phoneNumber: '9847012345', countryCode: '+91'),
    ad: const ChatAd(id: 'ad-swift', title: 'Maruti Swift VXI 2019 · 42,000 km · Petrol', price: 540000),
  ),
  connection: ChatConnectionStatus.online,
  myUserId: me,
);

final threadSending = threadDefault.copyWith(messages: [
  ChatMessage(
    clientMessageId: 'pending0001',
    roomId: 'r-anand',
    senderId: me,
    type: MessageType.text,
    content: 'Come Saturday and decide',
    createdAt: _today(9, 34),
    status: MessageStatus.sending,
  ),
  _m('m8', me, 'Tyres are new, so it\'s worth it', _today(9, 33)),
  _m('m7', me, '5,20,000 is my last price', _today(9, 33), status: MessageStatus.read),
  ..._anandMessages,
]);

final threadFailed = threadDefault.copyWith(messages: [
  ChatMessage(
    clientMessageId: 'failed0002',
    roomId: 'r-anand',
    senderId: me,
    type: MessageType.text,
    content: 'My number is 98470 12345',
    createdAt: _today(9, 36),
    status: MessageStatus.failed,
    failure: const ChatFailure(ChatFailureKind.blocked, code: 'CONTENT_BLOCKED'),
  ),
  ChatMessage(
    clientMessageId: 'failed0001',
    roomId: 'r-anand',
    senderId: me,
    type: MessageType.text,
    content: 'Can I come today at 5?',
    createdAt: _today(9, 35),
    status: MessageStatus.failed,
    failure: const ChatFailure(ChatFailureKind.offline),
  ),
  ..._anandMessages,
]);

final threadOffline = threadSending.copyWith(connection: ChatConnectionStatus.offline);

final threadAttachments = threadDefault.copyWith(messages: [
  ChatMessage(
    id: 'v1',
    roomId: 'r-anand',
    senderId: me,
    type: MessageType.audio,
    attachments: const [ChatAttachment(type: 'audio', url: 'https://example.com/voice.m4a', durationSec: 24)],
    createdAt: _today(9, 41),
  ),
  ChatMessage(
    clientMessageId: 'img0001',
    roomId: 'r-anand',
    senderId: me,
    type: MessageType.image,
    createdAt: _today(9, 40),
    status: MessageStatus.sending,
    uploadProgress: 0.64,
  ),
  _m('m9', 'anand', 'Can you send interior photos?', _today(9, 40)),
  ..._anandMessages,
]);

final threadDetails = threadDefault;
