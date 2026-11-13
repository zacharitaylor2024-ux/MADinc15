import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ScienceSignalApp());
}

class ScienceSignalApp extends StatelessWidget {
  const ScienceSignalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Science Signal',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const ScienceQuizScreen(),
    );
  }
}

class ScienceQuestion {
  const ScienceQuestion({required this.text, required this.correctAnswer});

  final String text;
  final String correctAnswer;

  factory ScienceQuestion.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['question'] is! String ||
        value['correct_answer'] is! String ||
        value['incorrect_answers'] is! List) {
      throw const FormatException('Invalid question data.');
    }

    final text = Uri.decodeComponent(value['question'] as String);
    final correctAnswer = Uri.decodeComponent(
      value['correct_answer'] as String,
    );
    final incorrectAnswers = value['incorrect_answers'] as List;
    if (text.trim().isEmpty ||
        (correctAnswer != 'True' && correctAnswer != 'False') ||
        incorrectAnswers.length != 1 ||
        incorrectAnswers.first is! String) {
      throw const FormatException('Invalid true-or-false question.');
    }
    final incorrectAnswer = Uri.decodeComponent(
      incorrectAnswers.first as String,
    );
    if ((incorrectAnswer != 'True' && incorrectAnswer != 'False') ||
        incorrectAnswer == correctAnswer) {
      throw const FormatException('Invalid true-or-false answers.');
    }
    return ScienceQuestion(text: text, correctAnswer: correctAnswer);
  }
}

class ScienceQuizScreen extends StatefulWidget {
  const ScienceQuizScreen({super.key});

  @override
  State<ScienceQuizScreen> createState() => _ScienceQuizScreenState();
}

class _ScienceQuizScreenState extends State<ScienceQuizScreen> {
  static final _questionUri = Uri.https('opentdb.com', '/api.php', {
    'amount': '5',
    'category': '17',
    'difficulty': 'medium',
    'type': 'boolean',
    'encode': 'url3986',
  });

  List<ScienceQuestion> _questions = [];
  bool _loading = true;
  String? _error;

  int _currentQuestionIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  List<String> _userAnswers = [];

  bool _submitting = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _error = null;
      _questions = [];
      _currentQuestionIndex = 0;
      _score = 0;
      _selectedAnswer = null;
      _userAnswers = [];
      _submitting = false;
      _submitted = false;
    });

    try {
      final response = await http
          .get(_questionUri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw FormatException('Server returned HTTP ${response.statusCode}.');
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic> || data['response_code'] != 0) {
        throw const FormatException('The trivia API did not return questions.');
      }
      final results = data['results'];
      if (results is! List || results.length != 5) {
        throw const FormatException('Expected five trivia questions.');
      }
      final questions = results.map(ScienceQuestion.fromJson).toList();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loading = false;
      });
    } on TimeoutException {
      _showError('The request timed out. Please try again.');
    } on http.ClientException catch (error) {
      _showError('The request failed: ${error.message}');
    } on FormatException catch (error) {
      _showError('Could not load questions: ${error.message}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _loading = false;
    });
  }

  void _answerQuestion(String answer) {
    if (_selectedAnswer != null) return;

    setState(() {
      _selectedAnswer = answer;
      _userAnswers.add(answer);

      if (answer == _questions[_currentQuestionIndex].correctAnswer) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_selectedAnswer == null) return;

    setState(() {
      _currentQuestionIndex++;
      _selectedAnswer = null;
    });
  }

  Future<void> _submitScore() async {
    if (_submitting || _submitted) return;

    setState(() {
      _submitting = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _submitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Science Signal')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : _error != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loadQuestions,
                      child: const Text('Retry'),
                    ),
                  ],
                )
              : _currentQuestionIndex >= _questions.length
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Quiz Complete!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your Score: $_score / 5',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Answer Review',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      for (int i = 0; i < _questions.length; i++)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${i + 1}. ${_questions[i].text}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your answer: ${_userAnswers[i]}',
                                  style: TextStyle(
                                    color:
                                        _userAnswers[i] ==
                                            _questions[i].correctAnswer
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                Text(
                                  'Correct answer: ${_questions[i].correctAnswer}',
                                  style: const TextStyle(color: Colors.green),
                                ),
                                Text(
                                  _userAnswers[i] == _questions[i].correctAnswer
                                      ? 'Correct!'
                                      : 'Incorrect!',
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      FilledButton(
                        onPressed: _submitting || _submitted
                            ? null
                            : _submitScore,
                        child: Text(
                          _submitting
                              ? 'Submitting...'
                              : _submitted
                              ? 'Simulation Complete'
                              : 'Submit Score (Simulation)',
                        ),
                      ),

                      if (_submitted) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Simulated submission successful. '
                          'No data was sent to a server.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          const JsonEncoder.withIndent('  ').convert({
                            'score': _score,
                            'total': _questions.length,
                            'category': 'Science & Nature',
                          }),
                        ),
                      ],

                      const SizedBox(height: 12),

                      OutlinedButton(
                        onPressed: _submitting ? null : _loadQuestions,
                        child: const Text('Play Again'),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1} of 5',
                      style: const TextStyle(fontSize: 20),
                    ),

                    const SizedBox(height: 12),

                    LinearProgressIndicator(
                      value: (_currentQuestionIndex + 1) / 5,
                    ),

                    const SizedBox(height: 24),

                    Text(
                      _questions[_currentQuestionIndex].text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22),
                    ),

                    const SizedBox(height: 24),

                    for (final answer in ['True', 'False'])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FilledButton(
                          onPressed: _selectedAnswer == null
                              ? () => _answerQuestion(answer)
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: _selectedAnswer == null
                                ? null
                                : answer ==
                                      _questions[_currentQuestionIndex]
                                          .correctAnswer
                                ? Colors.green
                                : answer == _selectedAnswer
                                ? Colors.red
                                : Colors.grey,
                            disabledBackgroundColor: _selectedAnswer == null
                                ? null
                                : answer ==
                                      _questions[_currentQuestionIndex]
                                          .correctAnswer
                                ? Colors.green
                                : answer == _selectedAnswer
                                ? Colors.red
                                : Colors.grey,
                            disabledForegroundColor: Colors.white,
                          ),
                          child: Text(answer),
                        ),
                      ),

                    if (_selectedAnswer != null) ...[
                      const SizedBox(height: 16),

                      Text(
                        _selectedAnswer ==
                                _questions[_currentQuestionIndex].correctAnswer
                            ? 'Correct!'
                            : 'Incorrect!',
                        style: TextStyle(
                          color:
                              _selectedAnswer ==
                                  _questions[_currentQuestionIndex]
                                      .correctAnswer
                              ? Colors.green
                              : Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      FilledButton(
                        onPressed: _nextQuestion,
                        child: Text(
                          _currentQuestionIndex == 4
                              ? 'View Results'
                              : 'Next Question',
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
