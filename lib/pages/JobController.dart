import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class JobsScreen extends StatefulWidget {
  @override
  _JobsScreenState createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  late Map<String, dynamic> userArgs;
  late String authToken;
  late bool isDarkTheme;
  final String baseUrl = 'http://10.0.2.2:8000';
  List<dynamic> jobs = [];
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
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = Uri.parse("$baseUrl/api/jobs"); // Consistent with Laravel route
      print("Fetching jobs from: $url at ${DateTime.now()}");

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
        setState(() {
          jobs = responseData is List ? responseData : [];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load jobs: ${response.statusCode}';
          isLoading = false;
        });
        _showErrorSnackBar(errorMessage!);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching jobs: $e';
        isLoading = false;
      });
      _showErrorSnackBar(errorMessage!);
    }
  }

  Future<void> _createJob(Map<String, dynamic> jobData) async {
    try {
      final url = Uri.parse("$baseUrl/api/jobs");
      print("Creating job at: $url");
      print("Job data: $jobData");

      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: json.encode(jobData),
      ).timeout(Duration(seconds: 10));

      print("Create status: ${response.statusCode}");
      print("Create body: ${response.body}");

      if (response.statusCode == 201) {
        _showSuccessSnackBar('Job created successfully');
        await _fetchJobs();
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar('Failed to create job: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      _showErrorSnackBar('Error creating job: $e');
    }
  }

  Future<void> _updateJob(int jobId, Map<String, dynamic> jobData) async {
    try {
      final url = Uri.parse("$baseUrl/api/jobs/$jobId"); // Corrected endpoint
      print("Updating job at: $url");
      print("Job data: $jobData");

      final response = await http.put(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: json.encode(jobData),
      ).timeout(Duration(seconds: 10));

      print("Update status: ${response.statusCode}");
      print("Update body: ${response.body}");

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Job updated successfully');
        await _fetchJobs();
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar('Failed to update job: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating job: $e');
    }
  }

  Future<void> _deleteJob(int jobId) async {
    try {
      final url = Uri.parse("$baseUrl/api/jobs/$jobId");
      print("Deleting job at: $url at ${DateTime.now()}");
      print("Job ID: $jobId");
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
        _showSuccessSnackBar('Job deleted successfully');
        await _fetchJobs();
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar('Failed to delete job: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print("Delete error: $e");
      _showErrorSnackBar('Error deleting job: $e');
    }
  }

  void _showJobForm({Map<String, dynamic>? job}) {
    final isEditing = job != null;
    final titleController = TextEditingController(text: job?['job_name'] ?? '');
    final descriptionController = TextEditingController(text: job?['Description'] ?? '');
    final categoryController = TextEditingController(text: job?['job_catogary'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Job' : 'Create Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Job Name'),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            TextField(
              controller: categoryController,
              decoration: InputDecoration(labelText: 'Job Category'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty &&
                  categoryController.text.isNotEmpty) {
                final jobData = {
                  'job_name': titleController.text,
                  'Description': descriptionController.text,
                  'job_catogary': categoryController.text,
                  'user_id': userArgs['user_id'],
                };

                if (isEditing) {
                  await _updateJob(job!['id'], jobData);
                } else {
                  await _createJob(jobData);
                }
                Navigator.pop(context);
                await _fetchJobs();
              } else {
                _showErrorSnackBar('Please fill all fields');
              }
            },
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Job'),
        content: Text('Are you sure you want to delete "${job['job_name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _deleteJob(job['id']);
              Navigator.pop(context);
              await _fetchJobs(); // Refresh after dialog closes
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
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
          title: Text('Jobs'),
          backgroundColor: isDarkTheme ? Color(0xFF1a1a2e) : Color(0xFFe8f2ff),
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _showJobForm(),
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
                  onPressed: _fetchJobs,
                  child: Text('Retry'),
                ),
              ],
            ),
          )
              : jobs.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No jobs found',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showJobForm(),
                  child: Text('Create First Job'),
                ),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: _fetchJobs,
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                  child: ListTile(
                    leading: Icon(
                      Icons.work,
                      color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                    ),
                    title: Text(
                      job['job_name'] ?? 'Unknown',
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (job['Description'] != null)
                          Text(
                            job['Description'],
                            style: TextStyle(
                              color: isDarkTheme ? Colors.white70 : Colors.black54,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        SizedBox(height: 4),
                        if (job['job_catogary'] != null)
                          Text(
                            'Category: ${job['job_catogary']}',
                            style: TextStyle(
                              color: isDarkTheme ? Colors.white60 : Colors.black45,
                              fontSize: 12,
                            ),
                          ),
                        if (job['user'] != null)
                          Text(
                            'Posted by: ${job['user']['name'] ?? 'Unknown'}',
                            style: TextStyle(
                              color: isDarkTheme ? Colors.white60 : Colors.black45,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showJobForm(job: job);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(job);
                        }
                      },
                      itemBuilder: (context) => [
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
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showJobForm(),
          child: Icon(Icons.add),
          backgroundColor: isDarkTheme ? Color(0xFF2a2a4e) : Color(0xFFe8f2ff),
        ),
      ),
    );
  }
}