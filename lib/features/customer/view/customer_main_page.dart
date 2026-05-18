import 'package:flutter/material.dart';

import '../../../core/widgets/custom_scaffold.dart';

class CustomerMainPage extends StatelessWidget {
  final String token;
  final Map<String, dynamic> user;

  const CustomerMainPage({
    super.key,
    required this.token,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return const CustomScaffold(
      body: Center(
        child: Text('Customer Page / Coming Soon'),
      ),
    );
  }
}
