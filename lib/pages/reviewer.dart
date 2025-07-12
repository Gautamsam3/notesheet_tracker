import 'package:flutter/material.dart';
import 'package:notesheet_tracker/main.dart';
import 'package:notesheet_tracker/pages/hod.dart';

class ReviewerPage extends StatefulWidget {
  const ReviewerPage({super.key});

  @override
  _ReviewerPageState createState() => _ReviewerPageState();
}

class _ReviewerPageState extends State<ReviewerPage> {
  String selectedFilter = 'All';

  final List<Map<String, dynamic>> allSubmissions = List.generate(15, (index) {
    final statuses = [
      'Forwarded',
      'Forwarded',
      'Forwarded',
      'Forwarded',
      'Forwarded',
      'Forwarded',
      'Forwarded',
      'Forwarded',
      'Forwarded',
      'Forwarded',
      'Rejected',
      'Rejected',
      'Rejected',
      'Pending',
      'Pending',
    ];
    final colors = {
      'Forwarded': Colors.green,
      'Rejected': Colors.red,
      'Pending': Colors.orange,
    };
    return {
      'document': 'ReviewDoc_${index + 1}.pdf',
      'student': 'Student ${String.fromCharCode(65 + index)}',
      'status': statuses[index],
      'date': '2024-07-${(15 - index).toString().padLeft(2, '0')}',
      'statusColor': colors[statuses[index]],
    };
  });

  List<Map<String, dynamic>> get filteredSubmissions {
    if (selectedFilter == 'All') return allSubmissions;
    return allSubmissions
        .where((submission) => submission['status'] == selectedFilter)
        .toList();
  }

  void _onAccept(String document) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Forwarded $document to HOD')));
  }

  void _onReject(String document) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Rejected $document')));
  }

  void _navigateTo(String page) {
    if (page == 'Student') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else if (page == 'HOD') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HodDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Reviewer Review Page'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: _navigateTo,
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'Student',
                child: Text('Student Submission Page'),
              ),
              const PopupMenuItem<String>(
                value: 'HOD',
                child: Text('HOD Review Page'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Reviews',
                    '15',
                    Icons.folder,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Forwarded',
                    '10',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Rejected',
                    '3',
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Pending',
                    '2',
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Submissions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        DropdownButton<String>(
                          value: selectedFilter,
                          items: ['All', 'Forwarded', 'Pending', 'Rejected']
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedFilter = value!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredSubmissions.length,
                      itemBuilder: (context, index) {
                        final submission = filteredSubmissions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.description,
                                      color: Colors.blue[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            submission['document'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Student: ${submission['student']}\nDate: ${submission['date']}',
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: submission['statusColor'],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            submission['status'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.download),
                                          onPressed: () {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Downloading ${submission['document']}',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (submission['status'] == 'Pending')
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.green[100],
                                        ),
                                        onPressed: () =>
                                            _onAccept(submission['document']),
                                        child: const Text(
                                          'Forward to HOD',
                                          style: TextStyle(color: Colors.green),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.red[100],
                                        ),
                                        onPressed: () =>
                                            _onReject(submission['document']),
                                        child: const Text(
                                          'Reject',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (submission['status'] == 'Approved')
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.red[100],
                                      ),
                                      onPressed: () =>
                                          _onReject(submission['document']),
                                      child: const Text(
                                        'Reject',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ),
                                if (submission['status'] == 'Rejected')
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.green[100],
                                      ),
                                      onPressed: () =>
                                          _onAccept(submission['document']),
                                      child: const Text(
                                        'Forward to HOD',
                                        style: TextStyle(color: Colors.green),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
