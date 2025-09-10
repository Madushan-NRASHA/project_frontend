import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class JobFilterPage extends StatefulWidget {
  @override
  _JobFilterPageState createState() => _JobFilterPageState();
}

class _JobFilterPageState extends State<JobFilterPage> {
  late Map<String, dynamic> userArgs;
  late String authToken;
  late bool isDarkTheme;
  late int userId; // Added to store current user's ID
  final String baseUrl = 'http://10.0.2.2:8000'; // Adjust for your environment

  // Data
  List<dynamic> jobs = [];
  List<String> jobCategories = [];
  Map<String, dynamic> filterCounts = {};

  // Loading states
  bool isLoading = false;
  bool isCategoriesLoading = false;
  String? errorMessage;

  // Filter controllers
  final TextEditingController searchController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController salaryRangeController = TextEditingController();
  final TextEditingController jobTypeController = TextEditingController();

  // Filter values
  String? selectedCategory;
  List<String> selectedCategories = [];
  DateTime? dateFrom;
  DateTime? dateTo;
  String sortBy = 'created_at';
  String sortOrder = 'desc';
  int perPage = 15;
  int currentPage = 1;

  // Pagination
  int totalResults = 0;
  int totalPages = 1;

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
    userId = userArgs['user_id'] as int? ?? 0; // Ensure userId is an integer or default to 0
    if (userId == 0) {
      _showErrorSnackBar('Invalid user ID');
      Navigator.pop(context);
      return;
    }
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchJobCategories(),
      _fetchFilterCounts(),
      _fetchJobs(),
    ]);
  }

  // API Calls (unchanged, assumed functional)
  Future<void> _fetchJobs() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = Uri.parse("$baseUrl/api/jobs/filter");
      final body = _buildQueryParams();

      print("Fetching filtered jobs from: $url with body: $body");
      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json",
        },
        body: json.encode(body),
      ).timeout(Duration(seconds: 15));

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          setState(() {
            jobs = responseData['data']['data'] ?? [];
            totalResults = responseData['total_results'] ?? responseData['data']['total'] ?? 0;
            totalPages = responseData['data']['total'] != null
                ? (responseData['data']['total'] / perPage).ceil()
                : 1;
            isLoading = false;
          });
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch jobs');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again');
      } else if (response.statusCode == 422) {
        final responseData = json.decode(response.body);
        throw Exception('Validation error: ${responseData['message']}');
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to load jobs');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching jobs: $e';
        isLoading = false;
      });
      _showErrorSnackBar(errorMessage!);
      if (errorMessage!.contains('Unauthorized')) {
        Navigator.pop(context); // Redirect to login
      }
    }
  }

  Future<void> _fetchJobCategories() async {
    setState(() => isCategoriesLoading = true);
    try {
      final url = Uri.parse("$baseUrl/api/jobs/categories");
      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          setState(() {
            jobCategories = (responseData['data'] as List)
                .map((item) => item.toString())
                .toList();
            isCategoriesLoading = false;
          });
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch categories');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to load categories');
      }
    } catch (e) {
      setState(() => isCategoriesLoading = false);
      print('Error fetching categories: $e');
      _showErrorSnackBar('Error fetching categories: $e');
    }
  }

  Future<void> _fetchFilterCounts() async {
    try {
      final url = Uri.parse("$baseUrl/api/jobs/stats");
      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          setState(() {
            filterCounts = responseData['data'];
          });
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch stats');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to load stats');
      }
    } catch (e) {
      print('Error fetching filter counts: $e');
      _showErrorSnackBar('Error fetching filter counts: $e');
    }
  }

  Future<void> _fetchJobsByCategory(String category) async {
    setState(() {
      isLoading = true;
      selectedCategory = category;
    });

    try {
      final url = Uri.parse("$baseUrl/api/jobs/category/$category");
      final queryParams = <String, String>{};

      if (searchController.text.isNotEmpty) {
        queryParams['search'] = searchController.text;
      }
      if (locationController.text.isNotEmpty) {
        queryParams['location'] = locationController.text;
      }
      if (salaryRangeController.text.isNotEmpty) {
        queryParams['salary_range'] = salaryRangeController.text;
      }
      if (jobTypeController.text.isNotEmpty) {
        queryParams['job_type'] = jobTypeController.text;
      }

      final finalUrl = url.replace(queryParameters: queryParams);
      final response = await http.get(
        finalUrl,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
        },
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          setState(() {
            jobs = responseData['data'];
            totalResults = responseData['count'];
            totalPages = 1; // No pagination in getByCategory
            isLoading = false;
          });
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch jobs');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to load jobs');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching jobs by category: $e';
        isLoading = false;
      });
      _showErrorSnackBar(errorMessage!);
    }
  }

  Map<String, String> _buildQueryParams() {
    final params = <String, String>{};

    if (selectedCategory != null) {
      params['job_category'] = selectedCategory!;
    }
    if (selectedCategories.isNotEmpty) {
      params['categories'] = selectedCategories.join(',');
    }
    if (searchController.text.isNotEmpty) {
      params['search'] = searchController.text;
    }
    if (locationController.text.isNotEmpty) {
      params['location'] = locationController.text;
    }
    if (salaryRangeController.text.isNotEmpty) {
      params['salary_range'] = salaryRangeController.text;
    }
    if (jobTypeController.text.isNotEmpty) {
      params['job_type'] = jobTypeController.text;
    }
    if (dateFrom != null) {
      params['date_from'] = dateFrom!.toIso8601String().split('T')[0];
    }
    if (dateTo != null) {
      params['date_to'] = dateTo!.toIso8601String().split('T')[0];
    }

    params['sort_by'] = sortBy;
    params['sort_order'] = sortOrder;
    params['per_page'] = perPage.toString();
    params['page'] = currentPage.toString();

    return params;
  }

  void _clearFilters() {
    setState(() {
      searchController.clear();
      locationController.clear();
      salaryRangeController.clear();
      jobTypeController.clear();
      selectedCategory = null;
      selectedCategories.clear();
      dateFrom = null;
      dateTo = null;
      sortBy = 'created_at';
      sortOrder = 'desc';
      currentPage = 1;
    });
    _fetchJobs();
  }

  void _applyFilters() {
    setState(() => currentPage = 1);
    _fetchJobs();
  }

  void _navigateToConnectPage(Map<String, dynamic> job) {
    final jobPosterId = (job['user_id'] as int?) ?? (job['user']?['id'] as int?) ?? 0;
    final jobId = job['id'] as int? ?? 0;
    final jobPosterName = job['user']?['name'] as String? ?? 'Unknown';

    // print jobPosterId & jobId
    print('User ID: $jobPosterId, Job ID: $jobId');

    if (jobPosterId == 0 || jobId == 0) {
      _showErrorSnackBar('Invalid job or user ID');
      return;
    }

    // Navigate to chat page with all required data
    Navigator.pushNamed(
      context,
      '/user-chat',
      arguments: {
        'token': authToken,
        'current_user_id': userId,
        'job_poster_id': jobPosterId,
        'user_theme': isDarkTheme ? 1 : 0,
        'job_id': jobId,
        'job_data': job,
        'job_poster_name': jobPosterName,
      },
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

  void _showJobDetails(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.work,
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
              _buildDetailRow('Description', job['description'] ?? job['Description']),
              _buildDetailRow('Category', job['job_catogary'] ?? job['job_category']),
              _buildDetailRow('Location', job['location']),
              _buildDetailRow('Salary Range', job['salary_range']),
              _buildDetailRow('Job Type', job['job_type']),
              if (job['user'] != null)
                _buildDetailRow('Posted by', job['user']['name']),
              _buildDetailRow('Job ID', job['id']?.toString()),
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToConnectPage(job);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.connect_without_contact, size: 16),
                SizedBox(width: 4),
                Text('Connect'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
            ),
          ),
          SizedBox(height: 2),
          Text(
            value.toString(),
            style: TextStyle(
              color: isDarkTheme ? Colors.white70 : Colors.black87,
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
        title: Text(
          'Advanced Filters',
          style: TextStyle(
            color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                ),
                dropdownColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                items: [
                  DropdownMenuItem(value: null, child: Text(
                    'All Categories',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white : Colors.black,
                    ),
                  )),
                  ...jobCategories.map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.black,
                      ),
                    ),
                  )),
                ],
                onChanged: (value) => setState(() => selectedCategory = value),
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on),
                  labelStyle: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                ),
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: salaryRangeController,
                decoration: InputDecoration(
                  labelText: 'Salary Range',
                  prefixIcon: Icon(Icons.attach_money),
                  labelStyle: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                ),
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: jobTypeController,
                decoration: InputDecoration(
                  labelText: 'Job Type',
                  prefixIcon: Icon(Icons.access_time),
                  labelStyle: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                ),
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: sortBy,
                      decoration: InputDecoration(
                        labelText: 'Sort By',
                        labelStyle: TextStyle(
                          color: isDarkTheme ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      dropdownColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                      items: [
                        DropdownMenuItem(
                          value: 'created_at',
                          child: Text(
                            'Date Created',
                            style: TextStyle(
                              color: isDarkTheme ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'updated_at',
                          child: Text(
                            'Date Updated',
                            style: TextStyle(
                              color: isDarkTheme ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'job_name',
                          child: Text(
                            'Job Name',
                            style: TextStyle(
                              color: isDarkTheme ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => sortBy = value!),
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: sortOrder,
                      decoration: InputDecoration(
                        labelText: 'Order',
                        labelStyle: TextStyle(
                          color: isDarkTheme ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      dropdownColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                      items: [
                        DropdownMenuItem(
                          value: 'desc',
                          child: Text(
                            'Descending',
                            style: TextStyle(
                              color: isDarkTheme ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'asc',
                          child: Text(
                            'Ascending',
                            style: TextStyle(
                              color: isDarkTheme ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => sortOrder = value!),
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
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
            onPressed: _clearFilters,
            child: Text(
              'Clear All',
              style: TextStyle(color: Colors.orange),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _applyFilters();
            },
            child: Text(
              'Apply',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: isDarkTheme ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Job Search & Filter'),
          backgroundColor: isDarkTheme ? Color(0xFF1a1a2e) : Color(0xFFe8f2ff),
          actions: [
            IconButton(
              icon: Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
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
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search jobs...',
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              _applyFilters();
                            },
                          )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                          hintStyle: TextStyle(
                            color: isDarkTheme ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : Colors.black,
                        ),
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _applyFilters,
                      child: Icon(Icons.search),
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              if (filterCounts.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Total Jobs',
                        filterCounts['total_jobs']?.toString() ?? '0',
                        Icons.work,
                      ),
                      _buildStatCard(
                        'Categories',
                        filterCounts['categories_count']?.toString() ?? '0',
                        Icons.category,
                      ),
                      _buildStatCard(
                        'Recent',
                        filterCounts['recent_jobs']?.toString() ?? '0',
                        Icons.new_releases,
                      ),
                    ],
                  ),
                ),
              if (!isCategoriesLoading && jobCategories.isNotEmpty)
                Container(
                  height: 50,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: jobCategories.length,
                    itemBuilder: (context, index) {
                      final category = jobCategories[index];
                      final isSelected = selectedCategory == category;
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              _fetchJobsByCategory(category);
                            } else {
                              setState(() => selectedCategory = null);
                              _fetchJobs();
                            }
                          },
                          backgroundColor: isDarkTheme ? Color(0xFF2a2a4e) : Colors.white,
                          selectedColor: Colors.blue,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDarkTheme ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Results: $totalResults jobs',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkTheme ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (selectedCategory != null ||
                        searchController.text.isNotEmpty ||
                        locationController.text.isNotEmpty)
                      TextButton(
                        onPressed: _clearFilters,
                        child: Text('Clear Filters'),
                      ),
                  ],
                ),
              ),
              Expanded(
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
                        textAlign: TextAlign.center,
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
                      Icon(
                        Icons.work_off,
                        size: 64,
                        color: isDarkTheme ? Colors.white30 : Colors.black26,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No jobs found',
                        style: TextStyle(
                          fontSize: 18,
                          color: isDarkTheme ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Try adjusting your filters',
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
                            backgroundColor: isDarkTheme ? Color(0xFF1a1a2e) : Color(0xFFe8f2ff),
                            child: Icon(
                              Icons.work,
                              color: isDarkTheme ? Colors.white : Color(0xFF2d3748),
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
                              if (job['description'] != null || job['Description'] != null)
                                Text(
                                  job['description'] ?? job['Description'] ?? '',
                                  style: TextStyle(
                                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  if (job['job_catogary'] != null && job['job_catogary'].isNotEmpty) ...[
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDarkTheme ? Color(0xFF1a1a2e) : Color(0xFFe8f2ff),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        job['job_catogary'],
                                        style: TextStyle(
                                          color: isDarkTheme ? Colors.white70 : Color(0xFF2d3748),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                  ],
                                  if (job['location'] != null && job['location'].isNotEmpty) ...[
                                    Icon(
                                      Icons.location_on,
                                      size: 12,
                                      color: isDarkTheme ? Colors.white60 : Colors.black45,
                                    ),
                                    Text(
                                      job['location'],
                                      style: TextStyle(
                                        color: isDarkTheme ? Colors.white60 : Colors.black45,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: isDarkTheme ? Colors.white60 : Colors.black45,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (totalPages > 1)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: currentPage > 1
                            ? () {
                          setState(() => currentPage--);
                          _fetchJobs();
                        }
                            : null,
                        child: Text('Previous'),
                      ),
                      Text('Page $currentPage of $totalPages'),
                      ElevatedButton(
                        onPressed: currentPage < totalPages
                            ? () {
                          setState(() => currentPage++);
                          _fetchJobs();
                        }
                            : null,
                        child: Text('Next'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkTheme ? Color(0xFF2a2a4e).withOpacity(0.7) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkTheme ? Colors.white30 : Colors.black12,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDarkTheme ? Colors.white70 : Colors.black54,
          ),
          SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDarkTheme ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: isDarkTheme ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    locationController.dispose();
    salaryRangeController.dispose();
    jobTypeController.dispose();
    super.dispose();
  }
}