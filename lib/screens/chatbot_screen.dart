import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:technex/data/local_db.dart';

/// Chatbot screen that queries services using FastAPI backend.
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // API base URL - automatically detects platform
  // For Android emulator: uses 10.0.2.2 (special IP that maps to host's localhost)
  // For iOS simulator/desktop/web: uses 127.0.0.1
  // For physical Android device: change to your computer's local IP (e.g., http://192.168.x.x:8000)
  static String get _apiBaseUrl {
    if (kIsWeb) {
      return 'https://rolland-unbribed-valentino.ngrok-free.dev';
    }
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host's localhost
      // For physical device, you'll need to change this to your computer's IP
      return 'https://rolland-unbribed-valentino.ngrok-free.dev';
    }
    // iOS simulator, desktop, etc.
    return 'https://rolland-unbribed-valentino.ngrok-free.dev';
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final query = _queryController.text.trim();
    if (query.isEmpty || _isLoading) return;

    // Add user message to the list
    setState(() {
      _messages.add(ChatMessage(text: query, isUser: true));
      _isLoading = true;
    });
    _queryController.clear();
    _scrollToBottom();

    try {
      // Make POST request to FastAPI endpoint
      final url = '$_apiBaseUrl/query';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query': query,
        }),
      ).timeout(
        const Duration(seconds: 15), // Reduced timeout - if server doesn't respond in 15s, it's likely not working
        onTimeout: () {
          throw Exception('Connection timed out. Server at $url is not responding.');
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final parseResult = _parseResponse(responseData);
        
        setState(() {
          _messages.add(ChatMessage(
            text: parseResult.text,
            isUser: false,
            serviceName: parseResult.serviceName,
          ));
          _isLoading = false;
        });
      } else {
        // Try to parse error response as JSON
        String errorText = response.body;
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('detail')) {
            errorText = errorData['detail'].toString();
          } else if (errorData is Map && errorData.containsKey('message')) {
            errorText = errorData['message'].toString();
          }
        } catch (_) {
          // Keep original error text if JSON parsing fails
        }
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Error ${response.statusCode}: $errorText',
              isUser: false,
            ),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage;
      final errorStr = e.toString();
      final apiUrl = _apiBaseUrl;
      
      if (errorStr.contains('timeout') || errorStr.contains('Connection timed out') || errorStr.contains('SocketException')) {
        errorMessage = 'Connection timed out.\n\nServer URL: $apiUrl/query\n\nTroubleshooting:\n1. Verify FastAPI is running:\n   • Check terminal where you started uvicorn\n   • Server should show "Uvicorn running on..."\n\n2. Test server from your computer:\n   • Open browser: http://127.0.0.1:8000/docs\n   • Or run: curl http://127.0.0.1:8000/docs\n\n3. Ensure server binds to 0.0.0.0:\n   • Start with: uvicorn main:app --host 0.0.0.0 --port 8000\n\n4. Check firewall:\n   • Windows Firewall may block port 8000\n   • Allow Python/uvicorn through firewall';
      } else if (errorStr.contains('Failed host lookup') || 
                 errorStr.contains('Connection refused') ||
                 errorStr.contains('Network is unreachable')) {
        final platformHint = Platform.isAndroid 
            ? '\n• For physical Android device, change the API URL in code to your computer\'s local IP (e.g., http://192.168.x.x:8000)'
            : '';
        errorMessage = 'Cannot connect to server.\n\nAttempted URL: $apiUrl/query\n\nPlease ensure:\n• FastAPI server is running (try: python -m uvicorn main:app --reload)\n• Server is listening on 0.0.0.0:8000 (not just 127.0.0.1)\n• Check firewall settings$platformHint';
      } else {
        errorMessage = 'Error: ${e.toString()}\n\nServer URL: $apiUrl/query\n\nPlease ensure the FastAPI server is running and accessible.';
      }
      setState(() {
        _messages.add(
          ChatMessage(
            text: errorMessage,
            isUser: false,
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  _ParseResult _parseResponse(dynamic responseData) {
    String? serviceName;
    String text;
    
    // Handle different response formats from FastAPI
    if (responseData is String) {
      text = responseData;
      serviceName = _extractServiceName(text);
    } else if (responseData is Map) {
      // Try to extract service name from the response
      serviceName = responseData['service_name']?.toString() ?? 
                   responseData['name']?.toString() ?? 
                   responseData['title']?.toString();
      
      // Try common response keys (check nested structures too)
      if (responseData.containsKey('response')) {
        text = _formatValue(responseData['response']);
        if (serviceName == null) serviceName = _extractServiceName(text);
      } else if (responseData.containsKey('message')) {
        text = _formatValue(responseData['message']);
        if (serviceName == null) serviceName = _extractServiceName(text);
      } else if (responseData.containsKey('answer')) {
        text = _formatValue(responseData['answer']);
        if (serviceName == null) serviceName = _extractServiceName(text);
      } else if (responseData.containsKey('result')) {
        text = _formatValue(responseData['result']);
        if (serviceName == null) serviceName = _extractServiceName(text);
      } else if (responseData.containsKey('data')) {
        text = _formatValue(responseData['data']);
        if (serviceName == null) serviceName = _extractServiceName(text);
      } else if (responseData.containsKey('content')) {
        text = _formatValue(responseData['content']);
        if (serviceName == null) serviceName = _extractServiceName(text);
      } else if (responseData.containsKey('text')) {
        text = _formatValue(responseData['text']);
        if (serviceName == null) serviceName = _extractServiceName(text);
      } else {
        // If it's a complex object, try to extract meaningful data
        // Check if it's a list of service providers or similar structured data
        if (responseData.length == 1) {
          // Single key-value pair, return the value formatted
          final value = responseData.values.first;
          text = _formatValue(value);
          if (serviceName == null) serviceName = _extractServiceName(text);
        } else {
          // Multiple keys - format as readable text
          final buffer = StringBuffer();
          responseData.forEach((key, value) {
            if (value != null && value.toString().isNotEmpty && value.toString() != 'null') {
              final formattedValue = _formatValue(value);
              if (formattedValue.isNotEmpty) {
                // Capitalize first letter of key
                final displayKey = key.toString().split('_').map((word) {
                  if (word.isEmpty) return word;
                  return word[0].toUpperCase() + word.substring(1);
                }).join(' ');
                buffer.writeln('$displayKey: $formattedValue');
              }
            }
          });
          text = buffer.toString().trim();
          if (text.isEmpty) text = responseData.toString();
          if (serviceName == null) serviceName = _extractServiceName(text);
        }
      }
    } else if (responseData is List) {
      // If response is a list, format each item
      if (responseData.isEmpty) {
        text = 'No results found.';
      } else if (responseData.isNotEmpty && responseData.first is Map) {
        // Check if it's a list of maps (like service providers)
        final buffer = StringBuffer();
        String? firstServiceName;
        for (var i = 0; i < responseData.length; i++) {
          final item = responseData[i] as Map<dynamic, dynamic>;
          final itemMap = Map<String, dynamic>.from(item);
          if (i == 0) {
            // Extract service name from first item - try multiple field names
            firstServiceName = (itemMap['service_name']?.toString() ?? '').trim();
            if (firstServiceName.isEmpty) {
              firstServiceName = (itemMap['name']?.toString() ?? '').trim();
            }
            if (firstServiceName.isEmpty) {
              firstServiceName = (itemMap['title']?.toString() ?? '').trim();
            }
            if (firstServiceName.isEmpty) {
              firstServiceName = (itemMap['Service Name']?.toString() ?? '').trim();
            }
            if (firstServiceName.isEmpty) {
              firstServiceName = (itemMap['serviceName']?.toString() ?? '').trim();
            }
            
            // If still empty, try to get from formatted output
            if (firstServiceName.isEmpty) {
              final formatted = _formatServiceProvider(itemMap);
              final lines = formatted.split('\n');
              if (lines.isNotEmpty) {
                firstServiceName = lines.first.trim();
              }
            }
          }
          buffer.writeln('${i + 1}. ${_formatServiceProvider(itemMap)}');
          if (i < responseData.length - 1) buffer.writeln('');
        }
        text = buffer.toString().trim();
        serviceName = firstServiceName ?? _extractServiceName(text);
      } else {
        // Simple list of strings/values
        text = responseData.map((e) => _formatValue(e)).where((e) => e.isNotEmpty).join('\n');
        serviceName = _extractServiceName(text);
      }
    } else {
      text = responseData.toString();
      serviceName = _extractServiceName(text);
    }
    
    return _ParseResult(text: text, serviceName: serviceName);
  }

  /// Extract service name from text by looking for common patterns
  String? _extractServiceName(String text) {
    if (text.isEmpty) return null;
    
    // Look for service name patterns in the text
    // Common patterns: "Service Name:", "1. Service Name", etc.
    final lines = text.split('\n');
    
    // First, try to find the first non-empty line that looks like a service name
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      // Remove numbering if present (e.g., "1. Service Name" -> "Service Name")
      String cleaned = trimmed.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
      
      // Skip if it's clearly a label (contains colon and common field names)
      if (cleaned.contains(':')) {
        final parts = cleaned.split(':');
        if (parts.length > 1) {
          final label = parts[0].toLowerCase().trim();
          if (label.contains('category') || 
              label.contains('location') || 
              label.contains('contact') || 
              label.contains('phone') ||
              label.contains('mobile') ||
              label.contains('rating') || 
              label.contains('description') ||
              label.contains('area') ||
              label.contains('address') ||
              label.contains('status') ||
              label.contains('created')) {
            continue; // Skip this line, it's a label
          }
          // If it's not a known label, the value after colon might be the service name
          final value = parts.sublist(1).join(':').trim();
          if (value.isNotEmpty && value.length <= 100 && value.length >= 3) {
            return value;
          }
        }
      }
      
      // Check if it looks like a service name
      // Should be reasonable length and not contain common field indicators
      if (cleaned.length >= 3 && 
          cleaned.length <= 100 &&
          !cleaned.toLowerCase().contains('category:') &&
          !cleaned.toLowerCase().contains('location:') &&
          !cleaned.toLowerCase().contains('contact:') &&
          !cleaned.toLowerCase().contains('rating:') &&
          !cleaned.toLowerCase().contains('description:') &&
          !cleaned.toLowerCase().contains('status:') &&
          !cleaned.toLowerCase().startsWith('category') &&
          !cleaned.toLowerCase().startsWith('location') &&
          !cleaned.toLowerCase().startsWith('contact') &&
          !cleaned.toLowerCase().startsWith('rating') &&
          !cleaned.toLowerCase().startsWith('description')) {
        // If it has a colon, take the part after it (might be a value)
        if (cleaned.contains(':')) {
          final parts = cleaned.split(':');
          if (parts.length > 1) {
            final value = parts.sublist(1).join(':').trim();
            if (value.isNotEmpty && value.length <= 100) {
              return value;
            }
          }
        }
        // Otherwise return the cleaned line
        return cleaned;
      }
    }
    
    // If no clear service name found, try the first substantial line
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.length >= 3 && trimmed.length <= 100) {
        final cleaned = trimmed.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        // Skip if it's clearly metadata
        if (!cleaned.toLowerCase().startsWith('category') &&
            !cleaned.toLowerCase().startsWith('location') &&
            !cleaned.toLowerCase().startsWith('contact') &&
            !cleaned.toLowerCase().startsWith('phone') &&
            !cleaned.toLowerCase().startsWith('mobile') &&
            !cleaned.toLowerCase().startsWith('rating') &&
            !cleaned.toLowerCase().startsWith('description') &&
            !cleaned.toLowerCase().startsWith('status') &&
            !cleaned.toLowerCase().startsWith('created') &&
            !cleaned.contains('@') && // Skip email addresses
            !RegExp(r'^\d+$').hasMatch(cleaned)) { // Skip pure numbers
          // If it has a colon, take the part before it (might be the service name)
          if (cleaned.contains(':')) {
            return cleaned.split(':').first.trim();
          }
          return cleaned;
        }
      }
    }
    
    // Last resort: if text contains service-related keywords, extract first meaningful phrase
    if (text.toLowerCase().contains('service') || 
        text.toLowerCase().contains('provider') ||
        text.toLowerCase().contains('booking')) {
      // Try to extract first capitalized word or phrase
      final words = text.split(RegExp(r'[\s\n:]+'));
      for (final word in words) {
        final trimmed = word.trim();
        if (trimmed.length >= 3 && 
            trimmed.length <= 50 &&
            trimmed[0] == trimmed[0].toUpperCase() &&
            !trimmed.toLowerCase().contains('category') &&
            !trimmed.toLowerCase().contains('location') &&
            !trimmed.toLowerCase().contains('contact') &&
            !trimmed.toLowerCase().contains('rating') &&
            !trimmed.toLowerCase().contains('description')) {
          return trimmed;
        }
      }
    }
    
    return null;
  }

  String _formatValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num) {
      // Format numbers properly, including integers and decimals
      if (value is int) {
        return value.toString();
      } else {
        // For doubles, remove trailing zeros if it's a whole number
        final str = value.toString();
        if (str.contains('.')) {
          final parts = str.split('.');
          if (parts.length == 2 && parts[1] == '0') {
            return parts[0]; // Return as integer if it's a whole number
          }
          // Remove trailing zeros
          return value.toString().replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
        }
        return str;
      }
    }
    if (value is bool) return value.toString();
    if (value is List) {
      return value.map((e) => _formatValue(e)).where((e) => e.isNotEmpty).join(', ');
    }
    if (value is Map) {
      // If it's a nested map, try to extract key information
      final mapValue = Map<dynamic, dynamic>.from(value);
      if (mapValue.containsKey('name') || mapValue.containsKey('service_name') || mapValue.containsKey('title')) {
        return _formatServiceProvider(Map<String, dynamic>.from(mapValue));
      }
      // Otherwise format as key-value pairs
      final buffer = StringBuffer();
      mapValue.forEach((k, v) {
        if (v != null && v.toString() != 'null') {
          final formatted = _formatValue(v);
          // Include numbers even if formatted is empty (for 0)
          if (formatted.isNotEmpty || v is num) {
            final displayValue = v is num ? v.toString() : formatted;
            buffer.write('${k.toString()}: $displayValue; ');
          }
        }
      });
      return buffer.toString().trim();
    }
    return value.toString();
  }

  String _formatServiceProvider(Map<String, dynamic> provider) {
    final buffer = StringBuffer();
    
    // Extract common service provider fields
    final name = provider['service_name'] ?? provider['name'] ?? provider['title'];
    final category = provider['service_category'] ?? provider['category'];
    final location = provider['location'] ?? provider['area'];
    final contact = provider['contact'] ?? provider['phone'] ?? provider['mobile'];
    final rating = provider['rating'];
    final description = provider['description'];
    
    // Display name if present
    if (name != null) {
      buffer.writeln(_formatValue(name));
    }
    
    // Display category if present
    if (category != null) {
      buffer.writeln('Category: ${_formatValue(category)}');
    }
    
    // Display location if present
    if (location != null) {
      buffer.writeln('Location: ${_formatValue(location)}');
    }
    
    // Display contact if present
    if (contact != null) {
      buffer.writeln('Contact: ${_formatValue(contact)}');
    }
    
    // Display rating if present (including 0)
    if (rating != null) {
      buffer.writeln('Rating: ${_formatValue(rating)}');
    }
    
    // Display description if present
    if (description != null) {
      buffer.writeln('Description: ${_formatValue(description)}');
    }
    
    // Add any other fields (including numbers)
    provider.forEach((key, value) {
      if (value != null && 
          value.toString() != 'null' &&
          !['service_name', 'name', 'title', 'service_category', 'category', 
            'location', 'area', 'contact', 'phone', 'mobile', 'rating', 'description'].contains(key)) {
        final formatted = _formatValue(value);
        // Include numbers even if they are 0 or empty string representation
        if (formatted.isNotEmpty || value is num) {
          final displayKey = key.toString().replaceAll('_', ' ').split(' ').map((w) {
            if (w.isEmpty) return w;
            return w[0].toUpperCase() + w.substring(1);
          }).join(' ');
          final displayValue = value is num ? value.toString() : formatted;
          buffer.writeln('$displayKey: $displayValue');
        }
      }
    });
    
    return buffer.toString().trim();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  //    appBar: AppBar(
   //     title: const Text('Chatbot Assistant'),
   //   ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ask me about services',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.6),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Server: $_apiBaseUrl',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground
                                      .withOpacity(0.4),
                                  fontSize: 11,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        // Loading indicator
                        return Padding(
                          padding: const EdgeInsets.only(left: 48, top: 8, bottom: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final message = _messages[index];
                      return _MessageBubble(
                        message: message,
                        apiBaseUrl: _apiBaseUrl,
                        onBookingConfirmed: (String serviceName, String requirements) {
                          // Add confirmation message to chat
                          setState(() {
                            _messages.add(ChatMessage(
                              text: '✅ Order confirmed!\n\nService: $serviceName\nRequirements: $requirements\n\nYour order has been successfully booked and will appear in "Your Orders".',
                              isUser: false,
                            ));
                          });
                          _scrollToBottom();
                        },
                      );
                    },
                  ),
          ),
          // Input area
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      decoration: InputDecoration(
                        hintText: 'Type your query...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              size: 24,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String? serviceName;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.serviceName,
  });
}

class _ParseResult {
  final String text;
  final String? serviceName;

  _ParseResult({required this.text, this.serviceName});
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String apiBaseUrl;
  final Function(String serviceName, String requirements)? onBookingConfirmed;

  const _MessageBubble({
    required this.message,
    required this.apiBaseUrl,
    this.onBookingConfirmed,
  });

  /// Quick extraction of service name from text for fallback
  String? _extractServiceNameFromText(String text) {
    if (text.isEmpty) return null;
    final lines = text.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.length >= 3 && trimmed.length <= 100) {
        final cleaned = trimmed.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        if (!cleaned.toLowerCase().startsWith('category') &&
            !cleaned.toLowerCase().startsWith('location') &&
            !cleaned.toLowerCase().startsWith('contact') &&
            !cleaned.toLowerCase().startsWith('rating') &&
            !cleaned.toLowerCase().startsWith('description') &&
            !cleaned.contains(':')) {
          return cleaned.split('\n').first.trim();
        }
      }
    }
    return null;
  }

  /// Generate random cost between 100-900, rounded to nearest hundred
  int _generateRandomCost() {
    final random = Random();
    // Generate random number between 100-900
    final baseCost = 100 + random.nextInt(801); // 100 to 900
    // Round to nearest hundred
    return ((baseCost / 100).round() * 100);
  }

  void _bookService(BuildContext context, String serviceName, String apiBaseUrl) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final TextEditingController requirementsController =
            TextEditingController();
        bool isBooking = false;
        int? serviceCost;
        bool showCost = false;
        
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Book Service'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (serviceName.isNotEmpty) ...[
                    Text(
                      'Service: $serviceName',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (showCost && serviceCost != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Estimated Cost:',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '₹$serviceCost',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: requirementsController,
                    maxLines: 3,
                    enabled: !isBooking,
                    decoration: const InputDecoration(
                      hintText: 'What are your requirements?',
                      labelText: 'Requirements',
                    ),
                  ),
                  if (isBooking) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isBooking
                      ? null
                      : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                if (!showCost)
                  OutlinedButton.icon(
                    onPressed: isBooking
                        ? null
                        : () {
                            setDialogState(() {
                              serviceCost = _generateRandomCost();
                              showCost = true;
                            });
                          },
                    icon: const Icon(Icons.currency_rupee, size: 18),
                    label: const Text('View Cost'),
                  ),
                ElevatedButton(
                  onPressed: isBooking
                      ? null
                      : () async {
                        final requirements = requirementsController.text.trim();
                        if (requirements.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter your requirements'),
                            ),
                          );
                          return;
                        }

                        setDialogState(() {
                          isBooking = true;
                        });

                        try {
                          // Call FastAPI /book endpoint
                          final response = await http.post(
                            Uri.parse('$apiBaseUrl/book'),
                            headers: {
                              'Content-Type': 'application/json',
                            },
                            body: jsonEncode({
                              'service_name': serviceName,
                              'requirements': requirements,
                            }),
                          ).timeout(
                            const Duration(seconds: 15),
                            onTimeout: () {
                              throw Exception('Request timeout');
                            },
                          );

                          if (!ctx.mounted) return;

                          if (response.statusCode == 200 || response.statusCode == 201) {
                            // Parse response
                            final responseData = jsonDecode(response.body);
                            final message = responseData['message']?.toString() ??
                                          responseData['response']?.toString() ??
                                          'Service booked successfully!';

                            // Also save to local DB for orders screen
                            final db = LocalDb.instance;
                            await db.createOrder(
                              title: serviceName,
                              description: requirements,
                              status: 'Pending',
                            );

                            Navigator.of(ctx).pop();
                            
                            // Add confirmation message to chatbot
                            if (onBookingConfirmed != null) {
                              onBookingConfirmed!(serviceName, requirements);
                            }
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            // Error response
                            String errorMessage = 'Failed to book service';
                            try {
                              final errorData = jsonDecode(response.body);
                              errorMessage = errorData['detail']?.toString() ??
                                           errorData['message']?.toString() ??
                                           errorMessage;
                            } catch (_) {
                              errorMessage = 'Error ${response.statusCode}: ${response.body}';
                            }

                            setDialogState(() {
                              isBooking = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          if (!ctx.mounted) return;

                          setDialogState(() {
                            isBooking = false;
                          });

                          String errorMsg = 'Failed to book service';
                          if (e.toString().contains('timeout')) {
                            errorMsg = 'Request timed out. Please try again.';
                          } else if (e.toString().contains('Failed host lookup') ||
                                     e.toString().contains('Connection refused')) {
                            errorMsg = 'Cannot connect to server. Please ensure the FastAPI server is running.';
                          } else {
                            errorMsg = 'Error: ${e.toString()}';
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMsg),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                  child: const Text('Confirm Booking'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.smart_toy,
                size: 18,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                  bottomLeft: message.isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  if (!message.isUser) ...[
                    // Show Book Service button if service name is detected OR if message contains service-related content
                    if (message.serviceName != null || 
                        message.text.toLowerCase().contains('service') ||
                        message.text.toLowerCase().contains('provider') ||
                        message.text.toLowerCase().contains('booking')) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _bookService(
                            context, 
                            message.serviceName ?? _extractServiceNameFromText(message.text) ?? 'Service',
                            apiBaseUrl
                          ),
                          icon: const Icon(Icons.book_online, size: 18),
                          label: const Text('Book Service'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Icon(
                Icons.person,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
