import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_box.dart'; // Import your UserChatPage

class ChatsListPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const ChatsListPage({
    super.key,
    this.arguments,
  });

  @override
  State<ChatsListPage> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  List<Map<String, dynamic>> chatsList = [];
  bool isLoading = true;
  String searchQuery = '';

  late String token;
  late int currentUserId;
  late bool isDarkTheme;

  @override
  void initState() {
    super.initState();

    // Get data from arguments
    final args = widget.arguments ?? {};
    token = args['token'] ?? '';
    currentUserId = (args['current_user_id'] as int?) ?? 0;
    isDarkTheme = (args['user_theme'] as int?) == 1;

    fetchChatsList();
  }

  Future<void> fetchChatsList() async {
    setState(() => isLoading = true);

    try {
      final url = Uri.parse("http://192.168.0.100:8000/api/chats/$currentUserId");
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          chatsList = data.map((chat) => chat as Map<String, dynamic>).toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load chats: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading chats')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get filteredChats {
    if (searchQuery.isEmpty) return chatsList;
    return chatsList.where((chat) {
      final name = (chat['other_user_name'] ?? '').toString().toLowerCase();
      final lastMessage = (chat['last_message'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase()) ||
          lastMessage.contains(searchQuery.toLowerCase());
    }).toList();
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildChatTile(Map<String, dynamic> chat) {
    final String otherUserName = chat['other_user_name'] ?? 'Unknown User';
    final String lastMessage = chat['last_message'] ?? 'No messages yet';
    final String? timestamp = chat['last_message_time'];
    final bool hasUnread = chat['unread_count'] != null && chat['unread_count'] > 0;
    final int unreadCount = chat['unread_count'] ?? 0;
    final String jobTitle = chat['job_title'] ?? 'Unknown Job';

    return InkWell(
      onTap: () {
        // Navigate to chat page
        Navigator.pushNamed(
          context,
          '/user-chat',
          arguments: {
            'token': token,
            'current_user_id': currentUserId,
            'job_poster_id': chat['other_user_id'],
            'user_theme': isDarkTheme ? 1 : 0,
            'job_id': chat['job_id'],
            'job_data': chat['job_data'] ?? {},
            'job_poster_name': otherUserName,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDarkTheme ? Colors.grey[700]! : Colors.grey[200]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Profile Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: isDarkTheme ? Colors.grey[600] : Colors.grey[300],
              child: Text(
                otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Chat Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Time Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          otherUserName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                            color: isDarkTheme ? Colors.white : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread
                              ? (isDarkTheme ? Colors.green[300] : Colors.green[600])
                              : (isDarkTheme ? Colors.grey[400] : Colors.grey[600]),
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Job Title
                  Text(
                    '💼 $jobTitle',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkTheme ? Colors.blue[300] : Colors.blue[600],
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Last Message and Unread Count Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkTheme ? Colors.grey[300] : Colors.grey[700],
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDarkTheme ? Colors.green[600] : Colors.green[500],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: isDarkTheme ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
          backgroundColor: isDarkTheme ? Colors.grey[900] : Colors.green[700],
          foregroundColor: Colors.white,
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: ChatSearchDelegate(
                    chats: chatsList,
                    isDarkTheme: isDarkTheme,
                    onChatTap: (chat) {
                      Navigator.pop(context); // Close search
                      Navigator.pushNamed(
                        context,
                        '/user-chat',
                        arguments: {
                          'token': token,
                          'current_user_id': currentUserId,
                          'job_poster_id': chat['other_user_id'],
                          'user_theme': isDarkTheme ? 1 : 0,
                          'job_id': chat['job_id'],
                          'job_data': chat['job_data'] ?? {},
                          'job_poster_name': chat['other_user_name'],
                        },
                      );
                    },
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Show menu options
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.refresh),
                          title: const Text('Refresh Chats'),
                          onTap: () {
                            Navigator.pop(context);
                            fetchChatsList();
                          },
                        ),
                        ListTile(
                          leading: Icon(isDarkTheme ? Icons.light_mode : Icons.dark_mode),
                          title: Text(isDarkTheme ? 'Light Mode' : 'Dark Mode'),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              isDarkTheme = !isDarkTheme;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: fetchChatsList,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : chatsList.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No chats yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start applying for jobs to begin chatting!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/find-jobs');
                  },
                  icon: const Icon(Icons.work),
                  label: const Text('Find Jobs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
              : ListView.builder(
            itemCount: filteredChats.length,
            itemBuilder: (context, index) {
              return _buildChatTile(filteredChats[index]);
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Navigate to jobs list or create new chat
            Navigator.pushNamed(context, '/find-jobs');
          },
          backgroundColor: isDarkTheme ? Colors.green[600] : Colors.green[700],
          child: const Icon(Icons.add_comment, color: Colors.white),
        ),
      ),
    );
  }
}

class ChatSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> chats;
  final bool isDarkTheme;
  final Function(Map<String, dynamic>) onChatTap;

  ChatSearchDelegate({
    required this.chats,
    required this.isDarkTheme,
    required this.onChatTap,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredChats = chats.where((chat) {
      final name = (chat['other_user_name'] ?? '').toString().toLowerCase();
      final lastMessage = (chat['last_message'] ?? '').toString().toLowerCase();
      return name.contains(query.toLowerCase()) ||
          lastMessage.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: filteredChats.length,
      itemBuilder: (context, index) {
        final chat = filteredChats[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text((chat['other_user_name'] ?? 'U')[0].toUpperCase()),
          ),
          title: Text(chat['other_user_name'] ?? 'Unknown'),
          subtitle: Text(chat['last_message'] ?? 'No messages'),
          onTap: () => onChatTap(chat),
        );
      },
    );
  }
}