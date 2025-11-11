import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:watch_next/services/feedback_service.dart';

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  int _step = 0; // 0: initial question, 1: review prompt, 2: feedback form
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_step) {
      case 0:
        return _buildInitialQuestion();
      case 1:
        return _buildReviewPrompt();
      case 2:
        return _buildFeedbackForm();
      default:
        return const SizedBox();
    }
  }

  Widget _buildInitialQuestion() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'enjoying_watch_next'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildButton(
                text: 'yes'.tr(),
                color: Colors.green,
                onPressed: () {
                  setState(() => _step = 1);
                  FeedbackService.markFeedbackDialogShown();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildButton(
                text: 'not_really'.tr(),
                color: Colors.grey[700]!,
                onPressed: () {
                  setState(() => _step = 2);
                  FeedbackService.markFeedbackDialogShown();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewPrompt() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'leave_review_title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'leave_review_message'.tr(),
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildButton(
                text: 'maybe_later'.tr(),
                color: Colors.grey[700]!,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildButton(
                text: 'leave_review'.tr(),
                color: Colors.orange,
                onPressed: () async {
                  await FeedbackService.requestReview();
                  if (mounted) Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedbackForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'send_feedback_title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'send_feedback_message'.tr(),
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: TextField(
            controller: _feedbackController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'feedback_hint'.tr(),
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildButton(
                text: 'cancel'.tr(),
                color: Colors.grey[700]!,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildButton(
                text: _isSubmitting ? 'sending'.tr() : 'send'.tr(),
                color: Colors.orange,
                onPressed: _isSubmitting ? null : _submitFeedback,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButton({
    required String text,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: onPressed == null ? Colors.grey[800] : color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await FeedbackService.submitFeedback(
      _feedbackController.text.trim(),
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('feedback_sent'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('feedback_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
