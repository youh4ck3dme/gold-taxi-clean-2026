import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold_taxi/core/widgets/buttons/primary_button.dart';
import 'package:gold_taxi/core/widgets/fields/app_text_field.dart';
import '../bloc/reviews_bloc.dart';
import '../bloc/reviews_event.dart';
import '../bloc/reviews_state.dart';
import 'rating_stars.dart';

class ReviewForm extends StatefulWidget {
  final int postId;
  final VoidCallback onSuccess;

  const ReviewForm({
    super.key,
    required this.postId,
    required this.onSuccess,
  });

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _commentController = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<ReviewsBloc>().add(
            SubmitReview(
              postId: widget.postId,
              authorName: _nameController.text,
              authorEmail: _emailController.text,
              rating: _rating,
              comment: _commentController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReviewsBloc, ReviewsState>(
      listener: (context, state) {
        if (state is ReviewSubmissionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recenzia bola úspešne odoslaná!')),
          );
          widget.onSuccess();
          Navigator.of(context).pop();
        } else if (state is ReviewSubmissionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Nepodarilo sa odoslať recenziu: ${state.message}')),
          );
        }
      },
      child: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Pridať recenziu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Hodnotenie:'),
              const SizedBox(height: 8),
              Center(
                child: RatingStars(
                  rating: _rating.toDouble(),
                  size: 32,
                  onRatingChanged: (value) {
                    setState(() {
                      _rating = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _nameController,
                labelText: 'Meno',
                hintText: 'Vaše meno',
                keyboardType: TextInputType.name,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Prosím zadajte meno' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _emailController,
                labelText: 'E-mail',
                hintText: 'Váš e-mail',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Prosím zadajte e-mail';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Zadajte platnú e-mailovú adresu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _commentController,
                labelText: 'Text recenzie',
                hintText: 'Napíšte vaše skúsenosti...',
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Prosím zadajte text recenzie' : null,
              ),
              const SizedBox(height: 24),
              BlocBuilder<ReviewsBloc, ReviewsState>(
                builder: (context, state) {
                  final isLoading = state is ReviewSubmissionInProgress;
                  return PrimaryButton(
                    text: isLoading ? 'Odosiela sa...' : 'Odoslať recenziu',
                    onPressed: isLoading ? null : _submit,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
