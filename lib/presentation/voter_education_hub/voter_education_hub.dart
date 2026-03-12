import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class VoterEducationHub extends StatefulWidget {
  const VoterEducationHub({super.key});

  @override
  State<VoterEducationHub> createState() => _VoterEducationHubState();
}

class _VoterEducationHubState extends State<VoterEducationHub>
    with TickerProviderStateMixin {
  int _selectedTopicIndex = 0;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<Map<String, String>> _chatHistory = [];
  bool _showChat = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<Map<String, dynamic>> _topics = [
    {
      'title': 'Blockchain Verification',
      'icon': Icons.link,
      'color': Color(0xFF1565C0),
      'gradient': [Color(0xFF1565C0), Color(0xFF42A5F5)],
      'steps': [
        {
          'title': 'What is Blockchain?',
          'description':
              'A blockchain is a distributed ledger — a chain of blocks each containing vote data, cryptographically linked to the previous block.',
          'icon': Icons.storage,
          'animation': 'chain',
        },
        {
          'title': 'Immutable Records',
          'description':
              'Once your vote is recorded on the blockchain, it cannot be altered. Each block contains a hash of the previous block, making tampering mathematically impossible.',
          'icon': Icons.lock,
          'animation': 'lock',
        },
        {
          'title': 'Distributed Consensus',
          'description':
              'Multiple nodes across the network must agree before a vote is recorded. No single entity controls the ledger — ensuring true decentralization.',
          'icon': Icons.hub,
          'animation': 'network',
        },
        {
          'title': 'Audit Trail',
          'description':
              'Every vote creates a permanent, verifiable audit trail. Anyone can verify the integrity of the election without revealing individual votes.',
          'icon': Icons.verified,
          'animation': 'check',
        },
      ],
    },
    {
      'title': 'Zero-Knowledge Proofs',
      'icon': Icons.visibility_off,
      'color': Color(0xFF6A1B9A),
      'gradient': [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
      'steps': [
        {
          'title': 'What is ZKP?',
          'description':
              'Zero-Knowledge Proofs allow you to prove something is true without revealing the underlying information. You prove you voted without revealing HOW you voted.',
          'icon': Icons.psychology,
          'animation': 'brain',
        },
        {
          'title': 'Proving Without Revealing',
          'description':
              'Imagine proving you know a secret password without actually saying it. ZKP uses advanced mathematics to achieve this cryptographic magic.',
          'icon': Icons.key,
          'animation': 'key',
        },
        {
          'title': 'Vote Privacy',
          'description':
              'Your vote is encrypted with ZKP. The system can verify your vote is valid and counted, but no one — not even the platform — can see your choice.',
          'icon': Icons.shield,
          'animation': 'shield',
        },
        {
          'title': 'Mathematical Guarantee',
          'description':
              'ZKP provides a cryptographic guarantee of privacy. The proof is mathematically verifiable, making it impossible to fake or forge.',
          'icon': Icons.calculate,
          'animation': 'math',
        },
      ],
    },
    {
      'title': 'MCQ Encryption',
      'icon': Icons.quiz,
      'color': Color(0xFF00695C),
      'gradient': [Color(0xFF00695C), Color(0xFF26A69A)],
      'steps': [
        {
          'title': 'Encrypted Questions',
          'description':
              'Multiple Choice Questions are encrypted end-to-end. Questions are delivered securely and your answers are encrypted before transmission.',
          'icon': Icons.question_answer,
          'animation': 'encrypt',
        },
        {
          'title': 'Answer Anonymization',
          'description':
              'Your MCQ answers are anonymized using homomorphic encryption — allowing statistical analysis without ever decrypting individual responses.',
          'icon': Icons.person_off,
          'animation': 'anon',
        },
        {
          'title': 'Tamper Detection',
          'description':
              'Each MCQ response includes a cryptographic signature. Any attempt to modify answers in transit is immediately detected and rejected.',
          'icon': Icons.gpp_bad,
          'animation': 'detect',
        },
        {
          'title': 'Secure Aggregation',
          'description':
              'Results are aggregated using secure multi-party computation. The final tally is computed without any single party seeing individual answers.',
          'icon': Icons.bar_chart,
          'animation': 'aggregate',
        },
      ],
    },
    {
      'title': 'Vote Receipt Validation',
      'icon': Icons.receipt_long,
      'color': Color(0xFFE65100),
      'gradient': [Color(0xFFE65100), Color(0xFFFF7043)],
      'steps': [
        {
          'title': 'Your Vote Receipt',
          'description':
              'After voting, you receive a cryptographic receipt — a unique hash that proves your vote was recorded without revealing your choice.',
          'icon': Icons.receipt,
          'animation': 'receipt',
        },
        {
          'title': 'Verification Portal',
          'description':
              'Enter your receipt hash in the public verification portal to confirm your vote is included in the final tally. Anyone can verify without compromising privacy.',
          'icon': Icons.search,
          'animation': 'search',
        },
        {
          'title': 'Merkle Tree Proof',
          'description':
              'Your receipt is part of a Merkle tree — a mathematical structure that lets you verify your vote is included without revealing other votes.',
          'icon': Icons.account_tree,
          'animation': 'tree',
        },
        {
          'title': 'End-to-End Verifiability',
          'description':
              'The entire election is end-to-end verifiable. You can verify your vote was cast, recorded, and counted correctly — all while maintaining ballot secrecy.',
          'icon': Icons.verified_user,
          'animation': 'e2e',
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _selectTopic(int index) {
    setState(() => _selectedTopicIndex = index);
    _animController.reset();
    _animController.forward();
  }

  void _sendChatMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final topic = _topics[_selectedTopicIndex]['title'] as String;
    setState(() {
      _chatHistory.add({'role': 'user', 'content': text});
    });
    _chatController.clear();

    setState(() {
      _chatHistory.add({
        'role': 'assistant',
        'content':
            'Chat functionality requires provider setup. Please configure the chat provider.',
      });
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final topic = _topics[_selectedTopicIndex];
    final gradient = topic['gradient'] as List<Color>;
    final topicColor = topic['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Voter Education Hub',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
        backgroundColor: topicColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showChat ? Icons.school : Icons.chat_bubble_outline),
            onPressed: () => setState(() => _showChat = !_showChat),
            tooltip: _showChat ? 'View Tutorial' : 'Ask Claude AI',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTopicSelector(topicColor),
          Expanded(
            child: _showChat
                ? _buildChatPanel(topicColor)
                : _buildTutorialPanel(topic, gradient, topicColor),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _showChat = !_showChat),
        backgroundColor: topicColor,
        foregroundColor: Colors.white,
        icon: Icon(_showChat ? Icons.school : Icons.smart_toy),
        label: Text(
          _showChat ? 'View Tutorial' : 'Ask Claude AI',
          style: GoogleFonts.inter(fontSize: 12.sp),
        ),
      ),
    );
  }

  Widget _buildTopicSelector(Color activeColor) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 1.5.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        child: Row(
          children: _topics.asMap().entries.map((entry) {
            final i = entry.key;
            final t = entry.value;
            final isSelected = i == _selectedTopicIndex;
            final color = t['color'] as Color;
            return GestureDetector(
              onTap: () => _selectTopic(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.only(right: 2.w),
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      size: 14.sp,
                      color: isSelected ? Colors.white : color,
                    ),
                    SizedBox(width: 1.5.w),
                    Text(
                      t['title'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTutorialPanel(
    Map<String, dynamic> topic,
    List<Color> gradient,
    Color topicColor,
  ) {
    final steps = topic['steps'] as List<Map<String, dynamic>>;
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopicHeader(topic, gradient),
              SizedBox(height: 3.h),
              Text(
                'Step-by-Step Walkthrough',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 2.h),
              ...steps.asMap().entries.map(
                (e) => _buildStepCard(e.key, e.value, topicColor),
              ),
              SizedBox(height: 2.h),
              _buildAskClaudePrompt(topicColor),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopicHeader(Map<String, dynamic> topic, List<Color> gradient) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(
              topic['icon'] as IconData,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic['title'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${(topic['steps'] as List).length} interactive steps',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.white.withAlpha(204),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(int index, Map<String, dynamic> step, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(step['icon'] as IconData, size: 14.sp, color: color),
                      SizedBox(width: 1.5.w),
                      Expanded(
                        child: Text(
                          step['title'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    step['description'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.grey[600],
                      height: 1.5,
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

  Widget _buildAskClaudePrompt(Color color) {
    return GestureDetector(
      onTap: () => setState(() => _showChat = true),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withAlpha(26), color.withAlpha(13)],
          ),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Row(
          children: [
            Icon(Icons.smart_toy, color: color, size: 20.sp),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Have questions? Ask Claude AI',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'Get instant answers about this topic from our AI assistant',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 14.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildChatPanel(Color topicColor) {
    final topic = _topics[_selectedTopicIndex];
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          color: Colors.white,
          child: Row(
            children: [
              Icon(Icons.smart_toy, color: topicColor, size: 18.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Claude AI — ${topic['title']}',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Ask anything about this topic',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (_chatHistory.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _chatHistory.clear()),
                  child: Text(
                    'Clear',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: topicColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _chatHistory.isEmpty
              ? _buildChatEmptyState(topicColor)
              : ListView.builder(
                  controller: _chatScrollController,
                  padding: EdgeInsets.all(3.w),
                  itemCount: _chatHistory.length,
                  itemBuilder: (context, index) {
                    return _buildChatBubble(_chatHistory[index], topicColor);
                  },
                ),
        ),
        _buildChatInput(topicColor),
      ],
    );
  }

  Widget _buildChatEmptyState(Color color) {
    final topic = _topics[_selectedTopicIndex];
    final suggestions = [
      'How does ${topic['title']} protect my vote?',
      'Can you explain this in simple terms?',
      'What happens if someone tries to hack it?',
    ];
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          SizedBox(height: 3.h),
          Icon(Icons.smart_toy, size: 40.sp, color: color.withAlpha(128)),
          SizedBox(height: 2.h),
          Text(
            'Ask Claude about ${topic['title']}',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            'Tap a suggestion or type your own question',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          ...suggestions.map(
            (s) => GestureDetector(
              onTap: () {
                _chatController.text = s;
                _sendChatMessage();
              },
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 1.5.h),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: color.withAlpha(13),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: color.withAlpha(51)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: color, size: 14.sp),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        s,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, String> msg, Color color) {
    final isUser = msg['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 1.5.h),
        constraints: BoxConstraints(maxWidth: 75.w),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isUser ? color : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12.0),
            topRight: const Radius.circular(12.0),
            bottomLeft: Radius.circular(isUser ? 12.0 : 2.0),
            bottomRight: Radius.circular(isUser ? 2.0 : 12.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 4.0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          msg['content'] ?? '',
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: isUser ? Colors.white : Colors.grey[800],
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 1.5.h),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12.0),
            topRight: Radius.circular(12.0),
            bottomRight: Radius.circular(12.0),
            bottomLeft: Radius.circular(2.0),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4.0),
          ],
        ),
        child: _chatHistory.isNotEmpty
            ? Text(
                _chatHistory.last['content'] ?? '',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDot(color, 0),
                  SizedBox(width: 1.w),
                  _buildDot(color, 150),
                  SizedBox(width: 1.w),
                  _buildDot(color, 300),
                ],
              ),
      ),
    );
  }

  Widget _buildDot(Color color, int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, _) => Container(
        width: 2.w,
        height: 2.w,
        decoration: BoxDecoration(
          color: color.withAlpha((value * 255).toInt()),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildChatInput(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                hintText:
                    'Ask about ${_topics[_selectedTopicIndex]['title']}...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.grey[400],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide(color: color),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 1.h,
                ),
                isDense: true,
              ),
              style: GoogleFonts.inter(fontSize: 11.sp),
              onSubmitted: (_) => _sendChatMessage(),
              maxLines: 3,
              minLines: 1,
            ),
          ),
          SizedBox(width: 2.w),
          GestureDetector(
            onTap: _sendChatMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 11.w,
              height: 11.w,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                color: Colors.white,
                size: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}