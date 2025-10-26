import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../models/client.dart';
import '../../../providers/client_provider.dart';
import '../../clients/add_edit_client_screen.dart';

class ClientCard extends StatefulWidget {
  final Client client;
  final String? searchQuery;

  const ClientCard({
    super.key,
    required this.client,
    this.searchQuery,
  });

  @override
  State<ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends State<ClientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _navigateToClientDetail(),
                onTapDown: (_) => _onTapDown(),
                onTapUp: (_) => _onTapUp(),
                onTapCancel: () => _onTapUp(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _buildClientAvatar(),
                      const SizedBox(width: 16),

                      Expanded(
                        child: _buildClientInfo(),
                      ),

                      _buildClientActions(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildClientAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.client.name.isNotEmpty
              ? widget.client.name[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildClientInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHighlightedText(
          widget.client.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        if (widget.client.address.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildHighlightedText(
                  widget.client.address,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
        ],
        if (widget.client.phone.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.phone,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              _buildHighlightedText(
                widget.client.phone,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHighlightedText(String text, {required TextStyle style}) {
    if (widget.searchQuery == null || widget.searchQuery!.isEmpty) {
      return Text(text, style: style, overflow: TextOverflow.ellipsis);
    }

    final query = widget.searchQuery!.toLowerCase();
    final lowerText = text.toLowerCase();

    if (!lowerText.contains(query)) {
      return Text(text, style: style, overflow: TextOverflow.ellipsis);
    }

    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(query, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start)));
        }
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: style.copyWith(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildClientActions() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => _showClientOptions(),
            icon: Icon(
              Icons.more_vert,
              color: Colors.grey.shade600,
            ),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
            ),
          ),
        ),
      ],
    );
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _navigateToClientDetail() {
    context.push('/client/${widget.client.id}');
  }

  void _showClientOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            _buildOptionTile(
              Icons.edit,
              'Editează Client',
                  () => _editClient(),
              Colors.blue,
            ),
            _buildOptionTile(
              Icons.assignment,
              'Vizualizează Formulare',
                  () => _navigateToClientDetail(),
              Colors.green,
            ),
            _buildOptionTile(
              Icons.delete,
              'Șterge Client',
                  () => _confirmDelete(),
              Colors.red,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color == Colors.red ? Colors.red : Colors.black87,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _editClient() async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddEditClientScreen(client: widget.client),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
      ),
    );
    if (result == true && context.mounted) {
      context.read<ClientProvider>().loadClients();
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Șterge Client'),
          ],
        ),
        content: Text('Ești sigur că vrei si ștergi "${widget.client.name}"? Această acțiune este ireversibilă.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Renunță'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<ClientProvider>().deleteClient(widget.client.id!);
              if (context.mounted) {
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Ștergerea clientului "${widget.client.name}" a eșuat.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Șterge', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}