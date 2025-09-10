import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class JobDeleteScreen extends StatefulWidget {
  @override
  _JobDeleteScreenState createState() => _JobDeleteScreenState();
}

class _JobDeleteScreenState extends State<JobDeleteScreen> {
  late Map<String, dynamic> userArgs;
  late String authToken;
  late bool isDarkTheme;
  final String baseUrl = 'http://10.0.2.2:8000';
  List<dynamic> jobs = [];
  bool isLoading = false;
  String? errorMessage;
  bool isDeletingJob = false;

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
      final url = Uri.parse("$baseUrl/api/jobs");
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
          jobs = responseData is List ? responseData : responseData['data'] ?? [];
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

  Future<void> _deleteJob(int jobId) async {
    setState(() {
      isDeletingJob = true;
    });
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
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _showSuccessSnackBar(responseData['message'] ?? 'Job deleted successfully');
        await _fetchJobs(); // Refresh the list
      } else if (response.statusCode == 404) {
        final responseData = json.decode(response.body);
        _showErrorSnackBar(responseData['message'] ?? 'Job not found');
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar('Failed to delete job: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print("Delete error: $e");
      _showErrorSnackBar('Error deleting job: $e');
    } finally {
      setState(() {
        isDeletingJob = false;
      });
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> job) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28,
            ),
            SizedBox(width: 8),
            Text(
              'Delete Job',
              style: TextStyle(
                color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this job?',
              style: TextStyle(
                color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkTheme ? Color(0xFF1a1a2e) : Color(0xFFf8f9fa),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkTheme ? Colors.white24 : Colors.black12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job Details:',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ID: ${job['id']}',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Name: ${job['job_name'] ?? 'Unknown'}',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (job['job_catogary'] != null)
                    Text(
                      'Category: ${job['job_catogary']}',
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white70 : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkTheme ? Color(0xFF2d1b1b) : Color(0xFFfef2f2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: isDeletingJob ? null : () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkTheme ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: isDeletingJob
                ? null
                : () async {
              Navigator.pop(context);
              await _deleteJob(job['id']);
            },
            icon: isDeletingJob
                ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Icon(Icons.delete_forever, size: 18),
            label: Text(isDeletingJob ? 'Deleting...' : 'Delete Job'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showJobDetails(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.work_outline,
              color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                job['job_name'] ?? 'Unknown Job',
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
              _buildDetailRow('Job ID', job['id'].toString()),
              if (job['Description'] != null && job['Description'].isNotEmpty)
                _buildDetailRow('Description', job['Description']),
              if (job['job_catogary'] != null && job['job_catogary'].isNotEmpty)
                _buildDetailRow('Category', job['job_catogary']),
              if (job['location'] != null && job['location'].isNotEmpty)
                _buildDetailRow('Location', job['location']),
              if (job['salary_range'] != null && job['salary_range'].isNotEmpty)
                _buildDetailRow('Salary Range', job['salary_range']),
              if (job['job_type'] != null && job['job_type'].isNotEmpty)
                _buildDetailRow('Job Type', job['job_type']),
              if (job['created_at'] != null)
                _buildDetailRow('Created', job['created_at']),
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation(job);
            },
            icon: Icon(Icons.delete, size: 18),
            label: Text('Delete Job'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isDarkTheme ? Colors.white70 : Colors.black87,
              fontSize: 14,
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
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
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
          title: Text('Delete Jobs'),
          backgroundColor: isDarkTheme ? Color(0xFF1a1a2e) : Color(0xFFe8f2ff),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _fetchJobs,
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
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading jobs...',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          )
              : errorMessage != null
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: isDarkTheme ? Colors.white30 : Colors.black26,
                ),
                SizedBox(height: 16),
                Text(
                  errorMessage!,
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _fetchJobs,
                  icon: Icon(Icons.refresh),
                  label: Text('Retry'),
                ),
              ],
            ),
          )
              : jobs.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_off,
                  size: 64,
                  color: isDarkTheme ? Colors.white30 : Colors.black26,
                ),
                SizedBox(height: 16),
                Text(
                  'No jobs found to delete',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'All jobs have been removed or none exist.',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white60 : Colors.black45,
                  ),
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
                    onTap: () => _showJobDetails(job),
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      child: Icon(
                        Icons.work_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      job['job_name'] ?? 'Unknown Job',
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID: ${job['id']}',
                          style: TextStyle(
                            color: isDarkTheme ? Colors.white60 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        if (job['job_catogary'] != null && job['job_catogary'].isNotEmpty)
                          Text(
                            'Category: ${job['job_catogary']}',
                            style: TextStyle(
                              color: isDarkTheme ? Colors.white70 : Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        SizedBox(height: 4),
                        Text(
                          'Tap to view details',
                          style: TextStyle(
                            color: isDarkTheme ? Colors.blue[300] : Colors.blue,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    trailing: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () => _showDeleteConfirmation(job),
                        icon: Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                          size: 20,
                        ),
                        tooltip: 'Delete Job',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}