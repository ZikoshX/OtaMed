import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/localization/app_localization.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

var logger = Logger();

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        title: Text(
          appLocalizations.translate('help'),
          style: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildFaqTile(appLocalizations, 'us', 'usAnswer', textColor, theme),
            _buildFaqTile(appLocalizations, 'searchHelp', 'searchAnswer', textColor, theme),
            _buildFaqTile(appLocalizations, 'ai_help', 'ai_answer', textColor, theme),
            _buildFaqTile(appLocalizations, 'contact', 'contact_answer', textColor, theme),
            _buildFaqTile(appLocalizations, 'important', 'impor_answer', textColor, theme),
            _buildFaqTile(appLocalizations, 'faq', 'faq', textColor, theme),
            _buildFaqTile(appLocalizations, 'procedure', 'procedure_answer', textColor, theme),
            _buildFaqTile(appLocalizations, 'rating', 'rating_answer', textColor, theme),
            _buildFaqTile(appLocalizations, 'number', 'number_answer', textColor, theme),
            _buildFaqTile(appLocalizations, 'correct', 'correct_answer', textColor, theme),
            _buildFaqTile(appLocalizations, 'filter', 'filter_answer', textColor, theme),
            _buildFaqTile(appLocalizations, 'incorrect', 'incorrect_answer', textColor, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile(AppLocalizations appLocalizations, String questionKey, String answerKey, Color textColor, ThemeData theme) {
    bool isFaqTitle = questionKey == 'faq';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: expandedIndex == questionKey.hashCode
          ? theme.colorScheme.surfaceContainerHighest
          : theme.cardColor,
      elevation: expandedIndex == questionKey.hashCode ? 0 : 1,
      child: ExpansionTile(
        initiallyExpanded: expandedIndex == questionKey.hashCode,
        title: Text(
          appLocalizations.translate(questionKey),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isFaqTitle ? Colors.blueAccent : textColor,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: questionKey == 'contact'
                ? GestureDetector(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 14, color: textColor),
                        children: [
                          const TextSpan(
                            text: "If you have troubles in app or have questions, you can write to our official mail: ",
                          ),
                          TextSpan(
                            text: "helpdesk@otamedteam.com",
                            style: const TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                                decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                openGmailCompose(context, "helpdesk@otamedteam.com");
                              },
                          ),
                        ],
                      ),
                    ),
                  )
                : Text(
                    appLocalizations.translate(answerKey),
                    style: TextStyle(fontSize: 14, color: textColor),
                  ),
          ),
        ],
        onExpansionChanged: (expanded) {
          setState(() {
            expandedIndex = expanded ? questionKey.hashCode : null;
          });
        },
      ),
    );
  }

  Future<void> openGmailCompose(BuildContext context, String email) async {
    final Uri gmailUrl = Uri.parse(
      'https://mail.google.com/mail/?view=cm&to=$email&su=Ota+Med+App+Inquiry&body=Hello%2C+I+have+a+question+about+the+Ota+Med+app.',
    );

    logger.w('Trying to launch Gmail compose: $gmailUrl');

    if (await canLaunchUrl(gmailUrl)) {
      await launchUrl(gmailUrl, mode: LaunchMode.externalApplication);
    } else {
      logger.w('Could not open Gmail compose.');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Gmail compose page.')),
      );
    }
  }
}
