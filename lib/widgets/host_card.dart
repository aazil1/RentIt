import 'package:flutter/material.dart';
import '../models/user_model.dart';

class HostCard extends StatelessWidget {
  final UserModel owner;
  final VoidCallback? onChatPressed;

  const HostCard({
    super.key,
    required this.owner,
    this.onChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.deepPurple.shade100,
              child: Text(
                owner.name.substring(0, 2).toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    owner.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 15, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text('${owner.renterRating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(' (Renter)', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      const SizedBox(width: 8),
                      const Icon(Icons.verified_user, size: 13, color: Colors.blue),
                      const SizedBox(width: 2),
                      Text('${owner.borrowerRating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(' (Borrower)', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            if (onChatPressed != null)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: onChatPressed,
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('Chat'),
              ),
          ],
        ),
      ),
    );
  }
}