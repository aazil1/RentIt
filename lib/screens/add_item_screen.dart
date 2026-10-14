import 'package:flutter/material.dart';

import '../models/item_model.dart';
import '../services/marketplace_scope.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hourlyController = TextEditingController();
  final _dailyController = TextEditingController();
  final _depositController = TextEditingController(text: '0');
  final _imageController = TextEditingController();

  String _category = 'Tech';
  bool _isPublishing = false;

  static const _categories = ['Tech', 'Gaming', 'Tools', 'Home', 'Books'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hourlyController.dispose();
    _dailyController.dispose();
    _depositController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  String? _validatePositiveAmount(String? value, {bool allowZero = false}) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null || !amount.isFinite || (allowZero ? amount < 0 : amount <= 0)) {
      return allowZero ? 'Enter a valid amount of 0 or more' : 'Enter an amount greater than 0';
    }
    return null;
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isPublishing = true);
    final store = MarketplaceScope.of(context);
    try {
      await store.addListing(
        RentalItem(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          title: _titleController.text.trim(),
          category: _category,
          description: _descriptionController.text.trim(),
          hourlyRate: double.parse(_hourlyController.text.trim()),
          dailyRate: double.parse(_dailyController.text.trim()),
          securityDeposit: double.parse(_depositController.text.trim()),
          imageUrl: _imageController.text.trim(),
          owner: store.currentUser,
        ),
      );
      if (!mounted) return;
      _formKey.currentState!.reset();
      _titleController.clear();
      _descriptionController.clear();
      _hourlyController.clear();
      _dailyController.clear();
      _depositController.text = '0';
      _imageController.clear();
      setState(() => _category = 'Tech');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your item is now listed.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not publish listing: $error')));
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List an item')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text('Turn things you own into extra income.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54)),
            const SizedBox(height: 20),
            Container(
              height: 124,
              decoration: BoxDecoration(color: const Color(0xFFE3EFE9), borderRadius: BorderRadius.circular(20)),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 32, color: Color(0xFF176B53)),
                  SizedBox(height: 8),
                  Text('Add a photo URL below', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 3),
                  Text('A clear photo helps your item stand out', style: TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const _SectionHeading(title: 'Item details', subtitle: 'Tell renters what makes it great.'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Listing title', hintText: 'e.g. Mirrorless camera kit'),
              validator: (value) => (value?.trim().length ?? 0) < 4 ? 'Enter at least 4 characters' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Description', hintText: 'Condition, included accessories, pickup details...'),
              validator: (value) => (value?.trim().length ?? 0) < 12 ? 'Add a little more detail (at least 12 characters)' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Photo URL (optional)', prefixIcon: Icon(Icons.link_rounded)),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isNotEmpty && Uri.tryParse(text)?.hasAbsolutePath != true) return 'Enter a valid image URL';
                if (text.isNotEmpty && !text.startsWith('https://')) return 'Use a secure https:// image URL';
                return null;
              },
            ),
            const SizedBox(height: 24),
            const _SectionHeading(title: 'Set your rates', subtitle: 'You can adjust these any time.'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _hourlyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Hourly rate', prefixText: '₱ '),
                    validator: _validatePositiveAmount,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _dailyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Daily rate', prefixText: '₱ '),
                    validator: _validatePositiveAmount,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _depositController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Refundable security deposit',
                prefixText: '₱ ',
                helperText: 'Set to 0 if no deposit is needed.',
              ),
              validator: (value) => _validatePositiveAmount(value, allowZero: true),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isPublishing ? null : _publish,
              icon: _isPublishing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.storefront_outlined),
              label: Text(_isPublishing ? 'Publishing...' : 'Publish listing'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            ),
            const SizedBox(height: 10),
            const Text('Listings are saved on this device in this demo.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
        ],
      );
}
