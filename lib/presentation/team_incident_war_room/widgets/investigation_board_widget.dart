import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/team_incident_war_room_service.dart';
import '../../../theme/app_theme.dart';

class InvestigationBoardWidget extends StatefulWidget {
  final String roomId;

  const InvestigationBoardWidget({super.key, required this.roomId});

  @override
  State<InvestigationBoardWidget> createState() =>
      _InvestigationBoardWidgetState();
}

class _InvestigationBoardWidgetState extends State<InvestigationBoardWidget> {
  final _warRoomService = TeamIncidentWarRoomService.instance;

  Map<String, List<Map<String, dynamic>>> _tasksByStatus = {
    'todo': [],
    'in_progress': [],
    'blocked': [],
    'done': [],
  };

  @override
  void initState() {
    super.initState();
    _subscribeToTasks();
  }

  void _subscribeToTasks() {
    _warRoomService.getTasksStream(widget.roomId).listen((tasks) {
      setState(() {
        _tasksByStatus = {
          'todo': [],
          'in_progress': [],
          'blocked': [],
          'done': [],
        };

        for (final task in tasks) {
          final status = task['status'] as String;
          _tasksByStatus[status]?.add(task);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add task button
        Container(
          padding: EdgeInsets.all(2.w),
          color: Colors.white,
          child: ElevatedButton.icon(
            onPressed: _showAddTaskDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              minimumSize: Size(double.infinity, 6.h),
            ),
          ),
        ),
        // Kanban board
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildColumn('To Do', 'todo', Colors.blue),
                _buildColumn('In Progress', 'in_progress', Colors.orange),
                _buildColumn('Blocked', 'blocked', Colors.red),
                _buildColumn('Done', 'done', Colors.green),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(String title, String status, Color color) {
    final tasks = _tasksByStatus[status] ?? [];

    return Container(
      width: 80.w,
      margin: EdgeInsets.all(2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Container(
                  width: 12.0,
                  height: 12.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          // Tasks
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return _buildTaskCard(tasks[index], status);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, String currentStatus) {
    final priority = task['priority'] as String?;
    final priorityColor = _getPriorityColor(priority);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => _showTaskDetailDialog(task),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Priority badge
              if (priority != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                ),
              SizedBox(height: 1.h),
              // Task title
              Text(
                task['title'],
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Task description
              if (task['description'] != null)
                Padding(
                  padding: EdgeInsets.only(top: 0.5.h),
                  child: Text(
                    task['description'],
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              SizedBox(height: 1.h),
              // Assigned to
              if (task['assigned_to'] != null)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10.sp,
                      backgroundColor: AppTheme.primaryLight,
                      child: Icon(
                        Icons.person,
                        size: 12.sp,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Assigned',
                      style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                    ),
                  ],
                ),
              // Status change buttons
              SizedBox(height: 1.h),
              Row(
                children: [
                  if (currentStatus != 'todo')
                    _buildStatusButton(
                      'Move to To Do',
                      Icons.arrow_back,
                      () => _updateTaskStatus(task['task_id'], 'todo'),
                    ),
                  if (currentStatus == 'todo')
                    _buildStatusButton(
                      'Start',
                      Icons.play_arrow,
                      () => _updateTaskStatus(task['task_id'], 'in_progress'),
                    ),
                  if (currentStatus == 'in_progress')
                    _buildStatusButton(
                      'Complete',
                      Icons.check,
                      () => _updateTaskStatus(task['task_id'], 'done'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 12.sp),
        label: Text(label, style: TextStyle(fontSize: 10.sp)),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 1.h),
        ),
      ),
    );
  }

  Future<void> _updateTaskStatus(String taskId, String newStatus) async {
    await _warRoomService.updateTaskStatus(taskId: taskId, status: newStatus);
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedPriority = 'medium';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'Enter task title',
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter task description',
                ),
                maxLines: 3,
              ),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String>(
                initialValue: selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['critical', 'high', 'medium', 'low']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) selectedPriority = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;

              await _warRoomService.createTask(
                roomId: widget.roomId,
                title: titleController.text,
                description: descriptionController.text.isNotEmpty
                    ? descriptionController.text
                    : null,
                priority: selectedPriority,
              );

              if (mounted) Navigator.pop(context);
            },
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  void _showTaskDetailDialog(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task['description'] != null) Text(task['description']),
            SizedBox(height: 2.h),
            Text('Priority: ${task['priority']}'),
            Text('Status: ${task['status']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
