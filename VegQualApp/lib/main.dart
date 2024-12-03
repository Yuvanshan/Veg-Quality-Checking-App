import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vegetable Quality Checker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueAccent,
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: TextStyle(fontSize: 16),
          ),
        ),
      ),
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  io.File? _imageFile;
  Uint8List? _webImage;
  final picker = ImagePicker();
  int _selectedIndex = 0;

  Future<void> _importImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (kIsWeb) {
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
        });
      }
    } else {
      setState(() {
        if (pickedFile != null) {
          _imageFile = io.File(pickedFile.path);
        } else {
          print('No image selected.');
        }
      });
    }
  }

  Future<void> _takePicture() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (kIsWeb) {
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
        });
      }
    } else {
      setState(() {
        if (pickedFile != null) {
          _imageFile = io.File(pickedFile.path);
        } else {
          print('No image captured.');
        }
      });
    }
  }

  Future<void> _scanImage() async {
    if (kIsWeb && _webImage != null) {
      await _sendToServer(_webImage!);
    } else if (_imageFile != null) {
      final bytes = await _imageFile!.readAsBytes();
      await _sendToServer(bytes);
    } else {
      print('No image selected for scanning.');
    }
  }

  Future<void> _sendToServer(Uint8List bytes) async {
    final url = Uri.parse(
        'http://127.0.0.1:5000/upload'); // Ensure the server URL is correct
    final request = http.MultipartRequest('POST', url)
      ..files.add(http.MultipartFile.fromBytes('image', bytes,
          filename: 'veg_image.jpg', contentType: MediaType('image', 'jpeg')));

    try {
      print('Sending request to server...');
      final response = await request.send();

      // Handle server response status codes and print errors
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        print('Response: $responseData');
        final result = jsonDecode(responseData);

        // Check for errors in response and show alerts as necessary
        if (result.containsKey('error') || result['prediction'] == 'Unknown') {
          _showErrorDialog('Unrecognized Image',
              'The uploaded image does not match any recognized vegetable.');
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultPage(
                herbName: result['prediction'],
                benefits: result['benefits'],
              ),
            ),
          );
        }
      } else {
        print('Server returned error status: ${response.statusCode}');
        _showErrorDialog(
            'Upload Failed', 'Failed to upload image. Please try again.');
      }
    } catch (e) {
      print('Error uploading image: $e');
      _showErrorDialog('Error', 'This is not a Brinjal.');
    }
  }

  // Helper function to show error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        title: Text('Vegetable Quality Checker'),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              // Navigate to Info page or show information dialog
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueAccent,
              ),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                // Navigate to settings page
              },
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: Text('Help'),
              onTap: () {
                // Navigate to help page
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display image container
              Container(
                width: isLargeScreen ? 400 : 300,
                height: isLargeScreen ? 400 : 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blueAccent, width: 2),
                ),
                child: _imageFile == null && _webImage == null
                    ? Center(child: Text('No image selected'))
                    : kIsWeb
                        ? Image.memory(_webImage!, fit: BoxFit.cover)
                        : Image.file(_imageFile!, fit: BoxFit.cover),
              ),
              SizedBox(height: 24),
              _buildActionButton(Icons.upload, 'Upload', _importImage),
              SizedBox(height: 16),
              _buildActionButton(
                  Icons.camera_alt, 'Take a Picture', _takePicture),
              SizedBox(height: 16),
              _buildActionButton(Icons.send, 'Submit', _scanImage),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class ResultPage extends StatelessWidget {
  final String herbName;
  final String benefits;

  ResultPage({required this.herbName, required this.benefits});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quality Results')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quality: $herbName',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent),
            ),
            SizedBox(height: 16),
            Text(
              'Benefits: $benefits',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
