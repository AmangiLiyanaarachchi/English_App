class EnglishChecker {
  // Simple regex-based English detection
  static final RegExp _englishPattern = RegExp(r'^[a-zA-Z0-9\s.,!?"-]+$');

  // Common non-English characters
  static final RegExp _nonEnglishPattern = RegExp(
      r'[\u0900-\u097F\u0980-\u09FF\u0A00-\u0A7F\u0600-\u06FF\u0750-\u077F\u4E00-\u9FFF\u3040-\u309F\u30A0-\u30FF]');

  // Check if text is in English
  static bool isEnglish(String text) {
    if (text.trim().isEmpty) return true;

    // Remove common punctuation and check
    final cleanedText = text.trim();

    // If contains non-English characters, it's not English
    if (_nonEnglishPattern.hasMatch(cleanedText)) {
      return false;
    }

    // Check if mostly English characters
    return _englishPattern.hasMatch(cleanedText);
  }

  // Calculate English percentage in text
  static double getEnglishPercentage(String text) {
    if (text.isEmpty) return 100.0;

    int englishChars = 0;
    int totalChars = 0;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == ' ' || char == '\n' || char == '\t') continue;

      totalChars++;
      if (_englishPattern.hasMatch(char)) {
        englishChars++;
      }
    }

    if (totalChars == 0) return 100.0;
    return (englishChars / totalChars) * 100;
  }

  // Get suggestion for non-English text
  static String getSuggestion(String text) {
    final percentage = getEnglishPercentage(text);

    if (percentage < 20) {
      return "Let's practice in English! 😊 Try: 'Hello, how are you?'";
    } else if (percentage < 50) {
      return "Good effort! Let's use more English words. You can do it! 💪";
    } else if (percentage < 80) {
      return "Almost there! Just a few more English words would be perfect! 🌟";
    }

    return "Great English! Keep it up! 🎉";
  }

  // Analyze speech/text for fluency (simple scoring)
  static Map<String, dynamic> analyzeFluency(String text) {
    final words = text.split(RegExp(r'\s+'));
    final wordCount = words.length;
    final charCount = text.length;
    final englishPercentage = getEnglishPercentage(text);

    // Simple fluency score calculation
    double fluencyScore = 0.0;

    // Factor 1: English percentage (50% weight)
    fluencyScore += (englishPercentage / 100) * 50;

    // Factor 2: Word count (30% weight) - more words = better
    if (wordCount > 20) {
      fluencyScore += 30;
    } else if (wordCount > 10) {
      fluencyScore += 20;
    } else if (wordCount > 5) {
      fluencyScore += 10;
    }

    // Factor 3: Average word length (20% weight)
    if (wordCount > 0) {
      final avgWordLength = charCount / wordCount;
      if (avgWordLength > 5) {
        fluencyScore += 20;
      } else if (avgWordLength > 3) {
        fluencyScore += 15;
      } else {
        fluencyScore += 10;
      }
    }

    String feedback;
    if (fluencyScore >= 80) {
      feedback = "Excellent fluency! Your English is very good! 🌟";
    } else if (fluencyScore >= 60) {
      feedback = "Good fluency! Keep practicing to improve more! 👍";
    } else if (fluencyScore >= 40) {
      feedback =
          "Fair fluency. Try using more English words and longer sentences! 💪";
    } else {
      feedback = "Keep practicing! English will get easier with time! 😊";
    }

    return {
      'score': fluencyScore.clamp(0, 100),
      'feedback': feedback,
      'wordCount': wordCount,
      'englishPercentage': englishPercentage,
    };
  }

  // Common IELTS topics for practice
  static List<String> getIELTSTopics() {
    return [
      "Describe your hometown",
      "Talk about your favorite book",
      "What are your hobbies?",
      "Describe a memorable journey",
      "Talk about your education",
      "What is your dream job?",
      "Describe a festival in your country",
      "Talk about technology in daily life",
      "What is your opinion on social media?",
      "Describe a person you admire",
      "Talk about environmental issues",
      "What are your future plans?",
      "Describe your family",
      "Talk about food and cuisine",
      "What is your favorite movie?",
    ];
  }

  // Daily idioms for learning
  static List<Map<String, String>> getDailyIdioms() {
    return [
      {
        'idiom': 'Break the ice',
        'meaning': 'To start a conversation in a social setting',
        'example': 'I told a joke to break the ice at the meeting.',
      },
      {
        'idiom': 'Piece of cake',
        'meaning': 'Something very easy',
        'example': 'The English test was a piece of cake!',
      },
      {
        'idiom': 'Hit the books',
        'meaning': 'To study hard',
        'example': 'I need to hit the books for my exam tomorrow.',
      },
      {
        'idiom': 'On cloud nine',
        'meaning': 'Very happy',
        'example': 'She was on cloud nine after getting the job.',
      },
      {
        'idiom': 'The ball is in your court',
        'meaning': 'It\'s your turn to make a decision',
        'example': 'I gave you my offer, now the ball is in your court.',
      },
    ];
  }

  // Validate institute code format
  static bool isValidInstituteCode(String code) {
    // Simple validation: 4-10 alphanumeric characters
    final pattern = RegExp(r'^[A-Z0-9]{4,10}$');
    return pattern.hasMatch(code.toUpperCase());
  }
}
