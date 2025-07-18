import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://fqdyhiejagolscwtmmly.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZxZHloaWVqYWdvbHNjd3RtbWx5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI4NTE1NDcsImV4cCI6MjA2ODQyNzU0N30.bX5LfrqC-Jogz1x8vJbmRfrCky_INWWlghbkZ9vgrZA',
  );
  runApp(const NotesheetTrackerApp());
}

class NotesheetTrackerApp extends StatelessWidget {
  const NotesheetTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Notesheet Tracker',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF1E1E2C),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF2A2A40),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
        ),
      ),
      home: const AuthPage(),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  bool agreeTerms = false;
  bool obscurePassword = true;
  String role = 'Student';
  double passwordStrength = 0.0;

  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final supabase = Supabase.instance.client;

  void toggleMode() {
    setState(() {
      isLogin = !isLogin;
      agreeTerms = false;
      passwordStrength = 0.0;
    });
  }

  void checkPasswordStrength(String password) {
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    final strength = [
      hasUpper,
      hasLower,
      hasDigit,
      hasSpecial,
    ].where((e) => e).length;

    setState(() {
      passwordStrength = strength / 4;
    });
  }

  Color getStrengthColor() {
    if (passwordStrength < 0.34) return Colors.red;
    if (passwordStrength < 0.67) return Colors.orange;
    return Colors.green;
  }

  String getStrengthLabel() {
    if (passwordStrength < 0.34) return 'Weak';
    if (passwordStrength < 0.67) return 'Medium';
    return 'Strong';
  }

  Future<void> registerUserToSupabase() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      final response = await supabase.from('users').insert({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      }).execute();

      if (response.status == 201) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('You have registered successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    isLogin = true;
                    nameController.clear();
                    emailController.clear();
                    passwordController.clear();
                    passwordStrength = 0.0;
                    agreeTerms = false;
                  });
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        final errorString = response.toString().toLowerCase();
        final isDuplicate = errorString.contains('duplicate key value');

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(
              isDuplicate
                  ? 'This email is already registered.'
                  : 'Registration failed. Please try again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      final isDuplicate = e.toString().contains('duplicate key value');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(
            isDuplicate
                ? 'This email is already registered.'
                : 'Unexpected error:\n${e.toString()}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response == null) {
        showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text('Login Failed'),
            content: Text('No such user found!'),
          ),
        );
        return;
      }

      final dbPassword = response['password'];
      final name = response['name'];
      final userRole = response['role'];

      if (password == dbPassword) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Login Successful'),
            content: Text(
              'Welcome $name,\nYou are a $userRole.\nHeading to $userRole Dashboard!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text('Incorrect Password'),
            content: Text('Wrong password, Try Again!'),
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text('Unexpected error: ${e.toString()}'),
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(
                  Icons.note_alt_rounded,
                  color: Colors.indigoAccent,
                  size: 80,
                ),
                const SizedBox(height: 12),
                Text(
                  'Notesheet Tracker',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.indigoAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                if (!isLogin) ...[
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value!.isEmpty ? 'Enter your email' : null,
                ),
                const SizedBox(height: 12),
                if (!isLogin) ...[
                  DropdownButtonFormField<String>(
                    value: role,
                    items: const [
                      DropdownMenuItem(
                        value: 'Student',
                        child: Text('Student'),
                      ),
                      DropdownMenuItem(
                        value: 'Reviewer',
                        child: Text('Reviewer'),
                      ),
                      DropdownMenuItem(value: 'HOD', child: Text('HOD')),
                    ],
                    onChanged: (value) => setState(() => role = value!),
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                  validator: (value) =>
                      value!.length < 6 ? 'Password too short' : null,
                  onChanged: (value) {
                    if (!isLogin) checkPasswordStrength(value);
                  },
                ),
                if (!isLogin) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: passwordStrength,
                    backgroundColor: Colors.grey.shade700,
                    color: getStrengthColor(),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Strength: ${getStrengthLabel()}',
                      style: TextStyle(
                        color: getStrengthColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (!isLogin)
                  CheckboxListTile(
                    value: agreeTerms,
                    onChanged: (val) => setState(() => agreeTerms = val!),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('I agree to the Terms & Conditions'),
                  ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        if (!isLogin && !agreeTerms) {
                          showDialog(
                            context: context,
                            builder: (_) => const AlertDialog(
                              title: Text('Terms Required'),
                              content: Text('Please Agree to the Terms.'),
                            ),
                          );
                          return;
                        }

                        if (!isLogin) {
                          await registerUserToSupabase();
                        } else {
                          await loginUser();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(isLogin ? 'Sign In' : 'Register'),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: toggleMode,
                  child: Text(
                    isLogin
                        ? "Don't have an account? Register"
                        : "Already have an account? Sign In",
                    style: const TextStyle(
                      color: Colors.indigoAccent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
