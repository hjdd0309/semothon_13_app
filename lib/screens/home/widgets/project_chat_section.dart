import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/chat_message_model.dart';
import '../../models/project_detail_model.dart';
import '../../services/project_service.dart';

String formatTimeOfDayForChat(TimeOfDay time) {
  final period = time.hour < 12 ? '오전' : '오후';
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$period $hour:$minute';
}

class ProjectChatSection extends StatefulWidget {
  final ProjectDetailModel project;
  final ProjectService service;
  final Future<void> Function() onReload;
  final void Function(String) onError;
  final void Function(String)? onSuccess;

  const ProjectChatSection({
    super.key,
    required this.project,
    required this.service,
    required this.onReload,
    required this.onError,
    this.onSuccess,
  });

  @override
  State<ProjectChatSection> createState() => _ProjectChatSectionState();
}

class _ProjectChatSectionState extends State<ProjectChatSection> {
  static const Color kWine = Color(0xFFA31621);
  static const Color kCream = Color(0xFFFCFAF7);
  static const Color kCard = Color(0xFFFFFFFF);
  static const Color kSoft = Color(0xFFF7F3EF);
  static const Color kText = Color(0xFF231A1C);
  static const Color kSub = Color(0xFF8C7E7F);
  static const Color kBlue = Color(0xFF4E6EF2);
  static const Color kGreen = Color(0xFF2E9B64);

  final TextEditingController chatController = TextEditingController();
  final ScrollController chatScrollController = ScrollController();
  final FocusNode chatFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSendingChat = false;

  List<ChatMessageModel> get chatMessages => widget.project.chatMessages;

  @override
  void initState() {
    super.initState();
    chatFocusNode.addListener(() {
      if (!mounted) return;
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollChatToBottom();
    });
  }

  @override
  void dispose() {
    chatController.dispose();
    chatScrollController.dispose();
    chatFocusNode.dispose();
    super.dispose();
  }

  int _maxBy<T>(List<T> items, int Function(T) pick) {
    if (items.isEmpty) return 0;
    return items.map(pick).reduce((a, b) => a > b ? a : b);
  }

  int _nextChatId() => _maxBy(chatMessages, (item) => item.id) + 1;

  String _nowLabel() {
    final now = TimeOfDay.now();
    return formatTimeOfDayForChat(now);
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!chatScrollController.hasClients) return;
      chatScrollController.animateTo(
        chatScrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String fileTypeLabel(String message) {
    final firstLine = message.split('\n').first.toLowerCase();

    if (firstLine.startsWith('http://') || firstLine.startsWith('https://')) {
      return '링크';
    }

    if (firstLine.endsWith('.jpg') ||
        firstLine.endsWith('.jpeg') ||
        firstLine.endsWith('.png') ||
        firstLine.endsWith('.gif') ||
        firstLine.endsWith('.mp4') ||
        firstLine.endsWith('.mov')) {
      return '사진/동영상';
    }

    return '파일';
  }

  IconData fileTypeIcon(String message) {
    final type = fileTypeLabel(message);
    if (type == '사진/동영상') return Icons.photo_library_rounded;
    if (type == '링크') return Icons.link_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color fileTypeColor(String message) {
    final type = fileTypeLabel(message);
    if (type == '사진/동영상') return const Color(0xFF16A34A);
    if (type == '링크') return const Color(0xFF2F80ED);
    return const Color(0xFF6B7280);
  }

  Future<void> _markAllChatAsRead() async {
    try {
      await widget.service.readAllChat(widget.project.projectNumber);
      await widget.onReload();
    } on UnsupportedError {
      // mock fallback 없음: 상위 화면의 project를 직접 수정할 수 없으므로 무시
    } catch (e) {
      widget.onError('채팅 읽음 처리에 실패했어요.');
    }
  }

  Future<void> sendChatMessage() async {
    final text = chatController.text.trim();
    if (text.isEmpty || _isSendingChat) return;

    setState(() {
      _isSendingChat = true;
    });

    try {
      await widget.service.sendChat(
        projectNumber: widget.project.projectNumber,
        message: text,
        isFile: false,
      );
      chatController.clear();
      await widget.onReload();
      _scrollChatToBottom();
    } on UnsupportedError {
      widget.onError('현재 이 프로젝트는 로컬 mock 상태라 채팅 전송 API를 사용할 수 없어요.');
    } catch (e) {
      widget.onError('채팅 전송에 실패했어요.');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSendingChat = false;
      });
    }
  }

  Future<void> _sendAttachmentMessage(String message) async {
    try {
      await widget.service.sendChat(
        projectNumber: widget.project.projectNumber,
        message: message,
        isFile: true,
      );
      await widget.onReload();
      _scrollChatToBottom();
    } on UnsupportedError {
      widget.onError('현재 이 프로젝트는 로컬 mock 상태라 파일 공유 API를 사용할 수 없어요.');
    } catch (e) {
      widget.onError('파일 공유에 실패했어요.');
    }
  }

  Future<void> _pickImageFromGallery() async {
    final status = await Permission.photos.request();
    if (!status.isGranted && !status.isLimited) {
      widget.onError('사진 접근 권한이 필요해요.');
      return;
    }

    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    await _sendAttachmentMessage(picked.path);
  }

  Future<void> _pickImageFromCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      widget.onError('카메라 권한이 필요해요.');
      return;
    }

    final picked = await _imagePicker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    await _sendAttachmentMessage(picked.path);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null || path.isEmpty) {
      widget.onError('파일 경로를 읽을 수 없어요.');
      return;
    }

    await _sendAttachmentMessage(path);
  }

  Future<void> _showAttachmentSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7DDD7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '첨부하기',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: kText,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _AttachmentTile(
                  icon: Icons.photo_library_rounded,
                  title: '갤러리에서 사진 선택',
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImageFromGallery();
                  },
                ),
                _AttachmentTile(
                  icon: Icons.camera_alt_rounded,
                  title: '카메라로 촬영',
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImageFromCamera();
                  },
                ),
                _AttachmentTile(
                  icon: Icons.insert_drive_file_rounded,
                  title: '파일 선택',
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickFile();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    final isMe = message.isMe;
    final isFile = message.isFile;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 4),
                child: Text(
                  message.sender,
                  style: const TextStyle(
                    fontSize: 12,
                    color: kSub,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isFile ? 14 : 16,
                vertical: isFile ? 12 : 13,
              ),
              decoration: BoxDecoration(
                color: isMe ? kWine : kCard,
                borderRadius: BorderRadius.circular(18),
                border: isMe ? null : Border.all(color: const Color(0xFFE8DFD9)),
                boxShadow: isMe
                    ? null
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isFile
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    fileTypeIcon(message.message),
                    size: 20,
                    color: isMe
                        ? Colors.white
                        : fileTypeColor(message.message),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      message.message.split('\n').first,
                      style: TextStyle(
                        color: isMe ? Colors.white : kText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              )
                  : Text(
                message.message,
                style: TextStyle(
                  color: isMe ? Colors.white : kText,
                  height: 1.42,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                message.time,
                style: const TextStyle(
                  fontSize: 11,
                  color: kSub,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = chatMessages
        .where((message) => message.sender != '나' && !message.isRead)
        .length;

    return Container(
      color: kCream,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: const BoxDecoration(
              color: kCream,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE7DDD7)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, color: kWine),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '팀 채팅',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: kText,
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEE9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '안 읽음 $unreadCount',
                      style: const TextStyle(
                        color: kWine,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _markAllChatAsRead,
                  child: const Text(
                    '모두 읽음',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: chatMessages.isEmpty
                ? const Center(
              child: Text(
                '아직 채팅이 없어요.',
                style: TextStyle(
                  color: kSub,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
                : ListView.builder(
              controller: chatScrollController,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                final message = chatMessages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE7DDD7)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _showAttachmentSheet,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: kWine,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: kSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: chatFocusNode.hasFocus
                              ? kWine.withOpacity(0.35)
                              : const Color(0xFFE7DDD7),
                        ),
                      ),
                      child: TextField(
                        controller: chatController,
                        focusNode: chatFocusNode,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => sendChatMessage(),
                        decoration: const InputDecoration(
                          hintText: '메시지를 입력하세요',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _isSendingChat ? null : sendChatMessage,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isSendingChat ? kSub : kWine,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _isSendingChat
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _AttachmentTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFF7F3EF),
        child: Icon(icon, color: const Color(0xFFA31621)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF231A1C),
        ),
      ),
      onTap: onTap,
    );
  }
}