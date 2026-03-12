import 'package:flutter/material.dart';

// void main() {
//   runApp(MaterialApp(
//     debugShowCheckedModeBanner: false,
//     home: EnglishActivitiesScreen(),
//     theme: ThemeData(
//       primaryColor: const Color(0xFF4A90A4),
//       hintColor: const Color(0xFF4A90A4),
//       fontFamily: 'Roboto', // You can change this to any custom font you like.
//     ),
//   ));
// }

class EnglishActivitiesScreen extends StatefulWidget {
  const EnglishActivitiesScreen({super.key});

  @override
  _EnglishActivitiesScreenState createState() =>
      _EnglishActivitiesScreenState();
}

class _EnglishActivitiesScreenState extends State<EnglishActivitiesScreen> {
  int currentActivityIndex = 0;

  final List<Map<String, dynamic>> activities = [
    {
      'title': 'Activity 1: Vocabulary Building',
      'description':
          'In this activity, you will be given a list of words. Try to use them in sentences and learn their meanings.',
      'words': ['apple', 'dog', 'car', 'book'],
      'userInput': '',
      'isCorrect': false,
      'correctAnswer':
          'I eat an apple. The dog is playing. The car is red. I read a book.'
    },
    {
      'title': 'Activity 2: Sentence Construction',
      'description':
          'Here, you will be given a jumbled set of words. Rearrange them to form meaningful sentences.',
      'words': ['playing', 'dog', 'the', 'is'],
      'userInput': '',
      'isCorrect': false,
      'correctAnswer': 'The dog is playing.'
    },
    {
      'title': 'Activity 3: Short Story Creation',
      'description':
          'Create a short story using the following prompts: "A mysterious object," "a lost traveler," and "a hidden message."',
      'userInput': '',
      'isCorrect': false,
      'correctAnswer':
          'A mysterious object was found by a lost traveler. The traveler discovered a hidden message inside it.'
    }
  ];

  // Function to move to the next activity
  void goToNextActivity() {
    setState(() {
      currentActivityIndex = (currentActivityIndex + 1) % activities.length;
    });
  }

  // Function to validate user input
  void validateActivity() {
    setState(() {
      final activity = activities[currentActivityIndex];

      // Check if user input matches the correct answer
      activity['isCorrect'] = activity['userInput'].toLowerCase().trim() ==
          activity['correctAnswer'].toLowerCase().trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activity = activities[currentActivityIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('English Learning Activities',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Activity Title
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              alignment: Alignment.center,
              child: Text(
                activity['title']!,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A90A4)),
              ),
            ),
            const SizedBox(height: 15),

            // Activity Description
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                activity['description']!,
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),

            // Different input types based on the activity
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (currentActivityIndex == 0) ...[
                      // Activity 1: Vocabulary Building
                      const Text(
                        'Use the words in sentences:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A90A4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Words: ${activity['words'].join(', ')}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 20),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            activity['userInput'] = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Type your sentence here',
                          labelStyle: const TextStyle(color: Color(0xFF4A90A4)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                        ),
                      ),
                    ] else if (currentActivityIndex == 1) ...[
                      // Activity 2: Sentence Construction
                      const Text(
                        'Rearrange the words to form a sentence:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A90A4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Words: ${activity['words'].join(' ')}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 20),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            activity['userInput'] = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Rearrange the words',
                          labelStyle: const TextStyle(color: Color(0xFF4A90A4)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                        ),
                      ),
                    ] else if (currentActivityIndex == 2) ...[
                      // Activity 3: Short Story Creation
                      const Text(
                        'Create a short story using the following prompts:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A90A4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Prompts: "A mysterious object," "a lost traveler," and "a hidden message."',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            activity['userInput'] = value;
                          });
                        },
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Type your story here',
                          labelStyle: const TextStyle(color: Color(0xFF4A90A4)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Check Answer Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90A4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: validateActivity,
                child: const Text(
                  "Check Answer",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Show if the answer is correct or not
            if (activity['isCorrect'])
              const Text(
                'Correct! 🎉',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.green,
                    fontWeight: FontWeight.bold),
              ),
            if (!activity['isCorrect'] && activity['userInput'].isNotEmpty)
              const Text(
                'Incorrect. Try again!',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.red,
                    fontWeight: FontWeight.bold),
              ),

            const SizedBox(height: 20),

            // Next Activity Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90A4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: goToNextActivity,
                child: const Text(
                  "Next Activity",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
