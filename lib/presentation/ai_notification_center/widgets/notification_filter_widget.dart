class NotificationFilterWidget {
  final Function(String) onFilterSelected;

  const NotificationFilterWidget({required this.onFilterSelected});

  dynamic build(dynamic context) {
    return {
      'padding': _edgeInsetsAll(3.0),
      'child': {
        'crossAxisAlignment': 'start',
        'mainAxisSize': 'min',
        'children': [
          {
            'text': 'Filter Notifications',
            'style': {'fontSize': 16.0, 'fontWeight': 'bold'},
          },
          {'height': 2.0},
          {
            'leading': {'icon': 'all_inclusive', 'color': 'grey'},
            'title': 'All Notifications',
            'onTap': () => onFilterSelected('all'),
          },
          {
            'leading': {'icon': 'security', 'color': 'red'},
            'title': 'Security Alerts',
            'onTap': () => onFilterSelected('security'),
          },
          {
            'leading': {'icon': 'lightbulb', 'color': 'blue'},
            'title': 'AI Recommendations',
            'onTap': () => onFilterSelected('recommendations'),
          },
          {
            'leading': {'icon': 'emoji_events', 'color': 'green'},
            'title': 'Quest Updates',
            'onTap': () => onFilterSelected('quests'),
          },
          {
            'leading': {'icon': 'mark_email_read', 'color': 'orange'},
            'title': 'Unread Only',
            'onTap': () => onFilterSelected('unread'),
          },
        ],
      },
    };
  }

  Map<String, dynamic> _edgeInsetsAll(double value) {
    return {'all': value};
  }
}
