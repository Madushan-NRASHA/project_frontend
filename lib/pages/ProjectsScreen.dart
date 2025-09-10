import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProjectsScreen extends StatefulWidget {
  @override
  _ProjectsScreenState createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  late Map<String, dynamic> userArgs;
  late String authToken;
  late bool isDarkTheme;
  final String baseUrl = 'http://10.0.2.2:8000';
  List<dynamic> projects = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeArgs = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (routeArgs == null || routeArgs['token'] == null) {
      _showErrorSnackBar('Authentication required');
      Navigator.pop(context);
      return;
    }
    userArgs = routeArgs;
    authToken = userArgs['token'];
    isDarkTheme = (userArgs['user_theme'] ?? 0) == 1;
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final url = Uri.parse("$baseUrl/api/projects");
      print("Fetching projects from: $url at ${DateTime.now()}");
      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
        },
      ).timeout(Duration(seconds: 10));
      print("Fetch status: ${response.statusCode}");
      print("Fetch body: ${response.body}");
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final filteredProjects = (responseData as List).where((project) {
          return project['user_id'] == userArgs['user_id'];
        }).toList();
        setState(() {
          projects = filteredProjects;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load projects: ${response.statusCode}';
          isLoading = false;
        });
        _showErrorSnackBar(errorMessage!);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching projects: $e';
        isLoading = false;
      });
      _showErrorSnackBar(errorMessage!);
    }
  }

  Future<void> _createProject(Map<String, dynamic> projectData) async {
    try {
      final url = Uri.parse("$baseUrl/api/projects");
      print("Creating project at: $url");
      print("Project data: $projectData");
      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: json.encode(projectData),
      ).timeout(Duration(seconds: 10));
      print("Create status: ${response.statusCode}");
      print("Create body: ${response.body}");
      if (response.statusCode == 201) {
        _showSuccessSnackBar('Project created successfully');
        await _fetchProjects();
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar('Failed to create project: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      _showErrorSnackBar('Error creating project: $e');
    }
  }

  Future<void> _updateProject(int projectId, Map<String, dynamic> projectData) async {
    try {
      final url = Uri.parse("$baseUrl/api/projects/$projectId");
      print("Updating project at: $url");
      print("Project data: $projectData");
      final response = await http.put(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: json.encode(projectData),
      ).timeout(Duration(seconds: 10));
      print("Update status: ${response.statusCode}");
      print("Update body: ${response.body}");
      if (response.statusCode == 200) {
        _showSuccessSnackBar('Project updated successfully');
        await _fetchProjects();
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar('Failed to update project: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating project: $e');
    }
  }

  Future<void> _deleteProject(int projectId) async {
    try {
      final url = Uri.parse("$baseUrl/api/projects/$projectId");
      print("Deleting project at: $url at ${DateTime.now()}");
      print("Project ID: $projectId");
      print("Token: $authToken");
      final response = await http.delete(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
        },
      ).timeout(Duration(seconds: 10));
      print("Delete status: ${response.statusCode}");
      print("Delete body: ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSuccessSnackBar('Project deleted successfully');
        await _fetchProjects();
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar('Failed to delete project: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print("Delete error: $e");
      _showErrorSnackBar('Error deleting project: $e');
    }
  }

  Future<void> _shareProject(Map<String, dynamic> project) async {
    final projectId = project['id'] ?? 0;
    if (projectId == 0) {
      _showErrorSnackBar('Invalid project ID');
      return;
    }

    // Prompt user to select a recipient (since job_poster_id isn't directly available)
    final recipientId = await _selectRecipient();
    if (recipientId == null) {
      _showErrorSnackBar('No recipient selected');
      return;
    }

    final projectData = {
      'title': project['name'] ?? 'Untitled Project',
      'description': project['description'] ?? '',
      'budget': project['budget'] ?? 0, // Adjust if budget exists in your API
      'photo': project['photo'] ?? '',
      'link': project['link'] ?? 'myapp://project/$projectId', // Use existing link or deep link
    };
    final url = Uri.parse("$baseUrl/api/messages");
    try {
      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: json.encode({
          "sender_id": userArgs['user_id'],
          "receiver_id": recipientId,
          "job_id": projectId,
          "type": "project",
          "message": "Shared a project: ${projectData['link']}",
          "project_data": projectData,
        }),
      ).timeout(Duration(seconds: 10));
      print("Share status: ${response.statusCode}");
      print("Share body: ${response.body}");
      if (response.statusCode == 201) {
        _showSuccessSnackBar('Project shared successfully');
        // Navigate to UserChatPage
        Navigator.pushNamed(
          context,
          '/user-chat',
          arguments: {
            'token': authToken,
            'current_user_id': userArgs['user_id'],
            'job_poster_id': recipientId,
            'job_id': projectId,
            'job_poster_name': 'User $recipientId', // Replace with actual name if available
            'user_theme': isDarkTheme ? 1 : 0,
            'job_data': projectData,
          },
        );
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar('Failed to share project: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      _showErrorSnackBar('Error sharing project: $e');
      print("Share error: $e");
    }
  }

  Future<int?> _selectRecipient() async {
    // Mock recipient selection (replace with actual API call or user list)
    // For now, show a dialog with a text field to enter recipient ID
    final TextEditingController recipientController = TextEditingController();
    int? recipientId;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
        title: Text(
          'Select Recipient',
          style: TextStyle(
            color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
          ),
        ),
        content: TextField(
          controller: recipientController,
          decoration: InputDecoration(
            labelText: 'Recipient User ID',
            prefixIcon: Icon(
              Icons.person,
              color: isDarkTheme ? Colors.white70 : Colors.black54,
            ),
            labelStyle: TextStyle(
              color: isDarkTheme ? Colors.white70 : Colors.black54,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDarkTheme ? Colors.white30 : Colors.black26,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDarkTheme ? Colors.white70 : Colors.blue,
              ),
            ),
          ),
          style: TextStyle(
            color: isDarkTheme ? Colors.white : Colors.black,
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkTheme ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              recipientId = int.tryParse(recipientController.text);
              Navigator.pop(context);
            },
            child: Text(
              'Share',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
    return recipientId;
  }

  void _showProjectDetails(Map<String, dynamic> project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.folder,
              color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                project['name'] ?? 'Unknown Project',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (project['description'] != null && project['description'].isNotEmpty) ...[
                Text(
                  'Description:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  project['description'],
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
              ],
              if (project['link'] != null && project['link'].isNotEmpty) ...[
                Text(
                  'Project Link:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkTheme ? Color(0xFF1a1a2e) : Color(0xFFe8f8f5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkTheme ? Colors.blue[300]! : Colors.blue,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link,
                        size: 16,
                        color: isDarkTheme ? Colors.blue[300] : Colors.blue,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          project['link'],
                          style: TextStyle(
                            color: isDarkTheme ? Colors.blue[300] : Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],
              if (project['photo'] != null && project['photo'].isNotEmpty) ...[
                Text(
                  'Photo URL:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDarkTheme ? Colors.white30 : Colors.black26,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      project['photo'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDarkTheme ? Color(0xFF1a1a2e) : Colors.grey[200],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: isDarkTheme ? Colors.white60 : Colors.black54,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    color: isDarkTheme ? Colors.white60 : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: isDarkTheme ? Color(0xFF1a1a2e) : Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
              if (project['user'] != null) ...[
                Text(
                  'Created by:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  project['user']['name'] ?? 'Unknown User',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
              ],
              Text(
                'Project ID: ${project['id']}',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white60 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              if (project['created_at'] != null) ...[
                SizedBox(height: 4),
                Text(
                  'Created: ${project['created_at']}',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white60 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: isDarkTheme ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showProjectForm(project: project);
            },
            icon: Icon(Icons.edit, size: 16, color: Colors.blue),
            label: Text(
              'Edit',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation(project);
            },
            icon: Icon(Icons.delete, size: 16, color: Colors.red),
            label: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showProjectForm({Map<String, dynamic>? project}) {
    final isEditing = project != null;
    final nameController = TextEditingController(text: project?['name'] ?? '');
    final descriptionController = TextEditingController(text: project?['description'] ?? '');
    final photoController = TextEditingController(text: project?['photo'] ?? '');
    final linkController = TextEditingController(text: project?['link'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
        title: Text(
          isEditing ? 'Edit Project' : 'Create Project',
          style: TextStyle(
            color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Project Name *',
                  prefixIcon: Icon(
                    Icons.folder,
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                  labelStyle: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isDarkTheme ? Colors.white30 : Colors.black26,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isDarkTheme ? Colors.white70 : Colors.blue,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(
                    Icons.description,
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                  labelStyle: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isDarkTheme ? Colors.white30 : Colors.black26,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isDarkTheme ? Colors.white70 : Colors.blue,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              TextField(
                controller: photoController,
                decoration: InputDecoration(
                  labelText: 'Photo URL',
                  prefixIcon: Icon(
                    Icons.image,
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                  labelStyle: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isDarkTheme ? Colors.white30 : Colors.black26,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isDarkTheme ? Colors.white70 : Colors.blue,
                    ),
                  ),
                  hintText: 'https://example.com/image.jpg',
                  hintStyle: TextStyle(
                    color: isDarkTheme ? Colors.white30 : Colors.black26,
                  ),
                ),
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: linkController,
                decoration: InputDecoration(
                  labelText: 'Project Link',
                  prefixIcon: Icon(
                    Icons.link,
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                  labelStyle: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isDarkTheme ? Colors.white30 : Colors.black26,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isDarkTheme ? Colors.white70 : Colors.blue,
                    ),
                  ),
                  hintText: 'https://github.com/user/project',
                  hintStyle: TextStyle(
                    color: isDarkTheme ? Colors.white30 : Colors.black26,
                  ),
                ),
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkTheme ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final projectData = {
                  'name': nameController.text,
                  'description': descriptionController.text,
                  'photo': photoController.text,
                  'link': linkController.text,
                  'user_id': userArgs['user_id'],
                };
                if (isEditing) {
                  await _updateProject(project!['id'], projectData);
                } else {
                  await _createProject(projectData);
                }
                Navigator.pop(context);
              } else {
                _showErrorSnackBar('Please enter a project name');
              }
            },
            child: Text(
              isEditing ? 'Update' : 'Create',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
        title: Text(
          'Delete Project',
          style: TextStyle(
            color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${project['name']}"?\n\nThis action cannot be undone.',
          style: TextStyle(
            color: isDarkTheme ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkTheme ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _deleteProject(project['id']);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: isDarkTheme ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Projects'),
          backgroundColor: isDarkTheme ? Color(0xFF1a1a2e) : Color(0xFFe8f2ff),
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _showProjectForm(),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkTheme
                  ? [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)]
                  : [Color(0xFFf8f9ff), Color(0xFFe8f2ff), Color(0xFFd6e9ff)],
            ),
          ),
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  errorMessage!,
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchProjects,
                  child: Text('Retry'),
                ),
              ],
            ),
          )
              : projects.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No projects found',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showProjectForm(),
                  child: Text('Create First Project'),
                ),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: _fetchProjects,
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                  child: ListTile(
                    onTap: () => _showProjectDetails(project),
                    leading: CircleAvatar(
                      backgroundColor: isDarkTheme ? Color(0xFF1a1a2e) : Color(0xFFe8f2ff),
                      child: Icon(
                        Icons.folder,
                        color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                      ),
                    ),
                    title: Text(
                      project['name'] ?? 'Unknown',
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (project['description'] != null && project['description'].isNotEmpty)
                          Text(
                            project['description'],
                            style: TextStyle(
                              color: isDarkTheme ? Colors.white70 : Colors.black54,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        SizedBox(height: 4),
                        if (project['link'] != null && project['link'].isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.link,
                                size: 12,
                                color: isDarkTheme ? Colors.blue[300] : Colors.blue,
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  project['link'],
                                  style: TextStyle(
                                    color: isDarkTheme ? Colors.blue[300] : Colors.blue[700],
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                        ],
                        Row(
                          children: [
                            Text(
                              'Tap to view details',
                              style: TextStyle(
                                color: isDarkTheme ? Colors.blue[300] : Colors.blue,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            Spacer(),
                            if (project['user'] != null)
                              Text(
                                'By: ${project['user']['name'] ?? 'Unknown'}',
                                style: TextStyle(
                                  color: isDarkTheme ? Colors.white60 : Colors.black45,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showProjectForm(project: project);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(project);
                        } else if (value == 'details') {
                          _showProjectDetails(project);
                        } else if (value == 'share') {
                          _shareProject(project);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'details',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16),
                              SizedBox(width: 8),
                              Text('View Details'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 16, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Share'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showProjectForm(),
          child: Icon(Icons.add),
          backgroundColor: isDarkTheme ? Color(0xFF2a2a4e) : Color(0xFFe8f2ff),
        ),
      ),
    );
  }
}