import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserChatPage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const UserChatPage({super.key, required this.arguments});

  @override
  State<UserChatPage> createState() => _UserChatPageState();
}

class _UserChatPageState extends State<UserChatPage> {
  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> userProjects = [];
  TextEditingController messageController = TextEditingController();
  bool isLoading = false;
  bool isLoadingProjects = false;
  late String token;
  late int currentUserId;
  late int jobPosterId;
  late int jobId;
  late String jobPosterName;
  late bool isDarkTheme;
  late Map<String, dynamic>? jobData;

  @override
  void initState() {
    super.initState();
    // Fixed the key mapping issue
    token = widget.arguments['token'] ?? '';
    currentUserId = (widget.arguments['current_user_id'] as int?) ?? 0;
    jobPosterId = (widget.arguments['job_poster_id'] as int?) ?? 0;
    jobId = (widget.arguments['job_id'] as int?) ?? 0;
    jobPosterName = widget.arguments['job_poster_name'] ?? "Unknown";
    isDarkTheme = (widget.arguments['user_theme'] as int?) == 1;
    jobData = widget.arguments['job_data'] as Map<String, dynamic>?;

    if (currentUserId == 0 || jobPosterId == 0 || jobId == 0) {
      // Handle invalid IDs
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid user or job IDs')),
        );
      });
      return;
    }
    fetchMessages();
    fetchUserProjects();
  }

  Future<void> fetchMessages() async {
    setState(() => isLoading = true);
    final url = Uri.parse("http://192.168.0.100:8000/api/messages/$jobId");
    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        setState(() {
          messages = List<Map<String, dynamic>>.from(json.decode(response.body));
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load messages: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching messages')),
      );
    }
  }

  Future<void> fetchUserProjects() async {
    setState(() => isLoadingProjects = true);
    final url = Uri.parse("http://192.168.0.101:8000/api/projects/user-projects/$currentUserId");
    // http://127.0.0.1:8000/api/projects/user-projects/1
    debugPrint('****** Fetching user projects from: $url');
    // {"success":true,"data":[{"id":9,"user_id":1,"name":"My First Project","description":"Test project description","photo":"project.jpg","link":"http:\/\/example.com","created_at":"2025-09-05T07:54:15.000000Z","updated_at":"2025-09-05T07:54:15.000000Z","title":"My First Project","user":{"id":1,"name":"Madushan","email":"madushan@example.com"}},{"id":8,"user_id":1,"name":"My First Project","description":"Test project description","photo":"project.jpg","link":"http:\/\/example.com","created_at":"2025-09-05T07:53:26.000000Z","updated_at":"2025-09-05T07:53:26.000000Z","title":"My First Project","user":{"id":1,"name":"Madushan","email":"madushan@example.com"}},{"id":7,"user_id":1,"name":"My First Project","description":"Test project description","photo":"project.jpg","link":"http:\/\/example.com","created_at":"2025-09-05T07:53:17.000000Z","updated_at":"2025-09-05T07:53:17.000000Z","title":"My First Project","user":{"id":1,"name":"Madushan","email":"madushan@example.com"}},{"id":6,"user_id":1,"name":"My

    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      // ✅ Debug prints
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);

        // Ensure we safely get the list of projects
        final List<dynamic> projectsList = decoded['data'] ?? [];

        setState(() {
          userProjects = List<Map<String, dynamic>>.from(projectsList);
          isLoadingProjects = false;
        });

        print('Loaded ${userProjects.length} user projects');


      } else {
        setState(() => isLoadingProjects = false);
        print('Failed to load user projects: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoadingProjects = false);
      print('Error fetching user projects: $e');
    }
  }


  Future<void> sendMessage({Map<String, dynamic>? sharedProject}) async {
    String messageText = messageController.text.trim();
    if (messageText.isEmpty && sharedProject == null) return;

    if (sharedProject != null) {
      messageText = sharedProject['description'] ?? 'Shared a project';
    }

    final url = Uri.parse("http://192.168.0.100:8000/api/messages");
    try {
      final requestBody = {
        "sender_id": currentUserId,
        "receiver_id": jobPosterId,
        "job_id": jobId,
        "message": messageText,
      };

      if (sharedProject != null) {
        requestBody["message_type"] = "project_share";
        requestBody["shared_project"] = sharedProject;
      }

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        messageController.clear();
        await fetchMessages();
        if (sharedProject != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project shared successfully!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending message')),
      );
    }
  }

  void _showProjectSharingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Share Your Project'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: isLoadingProjects
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading your projects...'),
                    ],
                  ),
                )
                    : userProjects.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No projects found'),
                      const SizedBox(height: 8),
                      const Text(
                        'Create some projects to share them in chat',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          setDialogState(() {});
                          await fetchUserProjects( );
                           setDialogState(() {});
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                    : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${userProjects.length} projects found'),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () async  {
                            setDialogState(() {});
                          await fetchUserProjects();
                             setDialogState(() {});
                          },
                          tooltip: 'Refresh projects',
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: userProjects.length,
                        itemBuilder: (context, index) {
                          final project = userProjects[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  (project['title'] ?? project['name'] ?? 'P')[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                project['title'] ?? project['name'] ?? 'Untitled Project',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    project['description'] ?? 'No description',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  if (project['budget'] != null)
                                    Text(
                                      'Budget: ${project['budget']}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (project['price'] != null)
                                    Text(
                                      'Price: ${project['price']}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: const Icon(Icons.share),
                              onTap: () {
                                Navigator.pop(context);
                                sendMessage(sharedProject: project);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildJobInfoCard() {
    if (jobData == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDarkTheme ? Colors.grey[600]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          if (jobData!['title'] != null)
            Text(
              'Title: ${jobData!['title']}',
              style: TextStyle(
                color: isDarkTheme ? Colors.white70 : Colors.black87,
              ),
            ),
          if (jobData!['description'] != null)
            Text(
              'Description: ${jobData!['description']}',
              style: TextStyle(
                color: isDarkTheme ? Colors.white70 : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (jobData!['budget'] != null)
            Text(
              'Budget: \$${jobData!['budget']}',
              style: TextStyle(
                color: isDarkTheme ? Colors.green[300] : Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe, int index) {
    bool isProjectShare = msg['message_type'] == 'project_share';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: isMe ? (isDarkTheme ? Colors.blue[700] : Colors.blue[200]) : (isDarkTheme ? Colors.grey[700] : Colors.grey[300]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isProjectShare) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.share,
                    size: 16,
                    color: isMe && !isDarkTheme ? Colors.black54 : (isDarkTheme ? Colors.white60 : Colors.black54),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Shared a project',
                    style: TextStyle(
                      color: isMe && !isDarkTheme ? Colors.black54 : (isDarkTheme ? Colors.white60 : Colors.black54),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isMe && !isDarkTheme) ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isMe && !isDarkTheme) ? Colors.black26 : Colors.white24,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg['shared_project']?['title'] != null)
                      Text(
                        msg['shared_project']['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isMe && !isDarkTheme ? Colors.black87 : (isDarkTheme ? Colors.white : Colors.black87),
                        ),
                      ),
                    if (msg['shared_project']?['description'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        msg['shared_project']['description'],
                        style: TextStyle(
                          color: isMe && !isDarkTheme ? Colors.black54 : (isDarkTheme ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ],
                    if (msg['shared_project']?['budget'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Budget: \$${msg['shared_project']['budget']}',
                        style: TextStyle(
                          color: Colors.green[isDarkTheme ? 300 : 700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else
              Text(
                msg['message'] ?? 'No message content',
                style: TextStyle(
                  color: isMe && !isDarkTheme ? Colors.black87 : (isDarkTheme ? Colors.white : Colors.black87),
                  fontSize: 16,
                ),
              ),
            if (msg['created_at'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  msg['created_at'].toString(),
                  style: TextStyle(
                    color: (isMe && !isDarkTheme) ? Colors.black54 : (isDarkTheme ? Colors.white60 : Colors.black54),
                    fontSize: 12,
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
    return Theme(
      data: isDarkTheme ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Chat with $jobPosterName"),
          backgroundColor: isDarkTheme ? Colors.grey[900] : Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _showProjectSharingDialog,
              tooltip: 'Share Project',
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Detailed Debug Info'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current User ID: $currentUserId'),
                          Text('Job Poster ID: $jobPosterId'),
                          Text('Job ID: $jobId'),
                          Text('Job Poster Name: $jobPosterName'),
                          Text('Dark Theme: $isDarkTheme'),
                          Text('Token: ${token.isNotEmpty ? "Present (${token.length} chars)" : "Missing"}'),
                          const Divider(),
                          Text('Job Data: ${jobData != null ? "Present" : "Missing"}'),
                          if (jobData != null) ...[
                            const SizedBox(height: 10),
                            const Text('Job Data Content:'),
                            ...jobData!.entries.map((entry) => Text(' ${entry.key}: ${entry.value}')).toList(),
                          ],
                          const Divider(),
                          Text('User Projects: ${userProjects.length}'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _buildJobInfoCard(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No messages yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start the conversation!',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  bool isMe = msg['sender_id'] == currentUserId;
                  return _buildMessageBubble(msg, isMe, index);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: isDarkTheme ? Colors.grey[800] : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDarkTheme ? Colors.grey[600]! : Colors.grey[300]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[isDarkTheme ? 700 : 200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: _showProjectSharingDialog,
                      tooltip: 'Share Project',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: "Type your message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: isDarkTheme ? Colors.grey[700] : Colors.grey[100],
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}