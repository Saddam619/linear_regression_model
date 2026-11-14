import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// TODO: PASTE YOUR NEW RENDER API URL HERE (no trailing slash).
const String apiBaseUrl = 'PASTE_YOUR_RENDER_API_URL_HERE';

enum FieldKind { number, text }

class AppField {
  final String label;
  final String jsonKey;
  final FieldKind kind;
  final TextInputType keyboardType;
  final TextEditingController controller;

  const AppField({
    required this.label,
    required this.jsonKey,
    required this.kind,
    required this.keyboardType,
    required this.controller,
  });
}

final List<AppField> appFields = [
  AppField(
    label: 'Year (1991-2030)',
    jsonKey: 'year',
    kind: FieldKind.number,
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    controller: TextEditingController(),
  ),
  AppField(
    label: 'GDP growth (annual %)',
    jsonKey: 'gdp_growth',
    kind: FieldKind.number,
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    controller: TextEditingController(),
  ),
  AppField(
    label: 'GDP per capita (current US\$)',
    jsonKey: 'gdp_per_capita',
    kind: FieldKind.number,
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    controller: TextEditingController(),
  ),
  AppField(
    label: 'Inflation, consumer prices (annual %)',
    jsonKey: 'inflation',
    kind: FieldKind.number,
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    controller: TextEditingController(),
  ),
  AppField(
    label: 'Labor force participation rate (%)',
    jsonKey: 'labor_force_participation',
    kind: FieldKind.number,
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    controller: TextEditingController(),
  ),
  AppField(
    label: 'Population growth (annual %)',
    jsonKey: 'population_growth',
    kind: FieldKind.number,
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    controller: TextEditingController(),
  ),
  AppField(
    label: 'Urban population (% of total)',
    jsonKey: 'urban_population',
    kind: FieldKind.number,
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    controller: TextEditingController(),
  ),
  AppField(
    label: 'Trade (% of GDP)',
    jsonKey: 'trade_pct_gdp',
    kind: FieldKind.number,
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    controller: TextEditingController(),
  ),
  AppField(
    label: 'FDI (% of GDP)',
    jsonKey: 'fdi_pct_gdp',
    kind: FieldKind.number,
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    controller: TextEditingController(),
  ),
  AppField(
    label: 'Agriculture (% of GDP)',
    jsonKey: 'agriculture_pct_gdp',
    kind: FieldKind.number,
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    controller: TextEditingController(),
  ),
  AppField(
    label: 'Industry (% of GDP)',
    jsonKey: 'industry_pct_gdp',
    kind: FieldKind.number,
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    controller: TextEditingController(),
  ),
  AppField(
    label: 'Secondary school enrollment (%)',
    jsonKey: 'secondary_enrollment',
    kind: FieldKind.number,
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    controller: TextEditingController(),
  ),
  AppField(
    label: 'Life expectancy (years)',
    jsonKey: 'life_expectancy',
    kind: FieldKind.number,
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    controller: TextEditingController(),
  ),
  AppField(
    label: 'Country (e.g. Kenya, Nigeria, Egypt)',
    jsonKey: 'country',
    kind: FieldKind.text,
    keyboardType: TextInputType.text,
    controller: TextEditingController(),
  ),
];

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Africa Unemployment Predictor',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const PredictionPage(),
    );
  }
}

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  String _resultText = '';
  bool _isLoading = false;

  Future<void> _predict() async {
    for (final field in appFields) {
      final value = field.controller.text.trim();
      if (value.isEmpty) {
        setState(() {
          _resultText = 'Please fill in: ${field.label}';
          _isLoading = false;
        });
        return;
      }
    }

    final body = <String, dynamic>{};

    for (final field in appFields) {
      final value = field.controller.text.trim();

      if (field.kind == FieldKind.number) {
        final parsed = num.tryParse(value);
        if (parsed == null) {
          setState(() {
            _resultText = '${field.label} must be a number';
            _isLoading = false;
          });
          return;
        }
        body[field.jsonKey] = parsed;
      } else {
        body[field.jsonKey] = value;
      }
    }

    setState(() {
      _isLoading = true;
      _resultText = '';
    });

    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prediction = data['predicted_unemployment_rate'];
        setState(() {
          _resultText = 'Predicted unemployment rate: $prediction %';
        });
      } else if (response.statusCode == 422) {
        final decoded = jsonDecode(response.body);
        final detail = decoded['detail'];
        final messages = <String>[];

        if (detail is List) {
          for (final item in detail) {
            if (item is Map<String, dynamic>) {
              final loc = item['loc'];
              final fieldName = loc is List && loc.isNotEmpty
                  ? loc.last.toString()
                  : 'field';
              final message = item['msg'] ?? 'Invalid value';
              messages.add('$fieldName: $message');
            }
          }
        }

        setState(() {
          _resultText = messages.isNotEmpty
              ? messages.join('\n')
              : 'Validation error.';
        });
      } else {
        setState(() {
          _resultText = 'Server error (${response.statusCode})';
        });
      }
    } catch (_) {
      setState(() {
        _resultText =
            'Could not reach the API. The free server may be waking up; wait a minute and try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField(AppField field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: field.controller,
        keyboardType: field.keyboardType,
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Africa Unemployment Predictor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final field in appFields) _buildTextField(field),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _predict,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Predict', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _resultText.isEmpty
                    ? 'Prediction result will appear here.'
                    : _resultText,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
