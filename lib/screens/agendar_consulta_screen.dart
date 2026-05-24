import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AgendarConsultaScreen extends StatefulWidget {
  const AgendarConsultaScreen({super.key});

  @override
  State<AgendarConsultaScreen> createState() => _AgendarConsultaScreenState();
}

class _AgendarConsultaScreenState extends State<AgendarConsultaScreen> {
  String? _medicoSelecionado;
  String? _especialidadeSelecionada;
  final _notasController = TextEditingController();
  DateTime? _dataSelecionada;
  TimeOfDay? _horaSelecionada;
  bool _isLoading = false;

  final List<String> _medicos = [
    'Francisco Paulo',
    'Maria Eduarda',
    'Cristina Ricardo',
    'Mateus Mario'
  ];

  final List<String> _especialidades = [
    'Cardiologia',
    'Oftalmologia',
    'Pediatria',
    'Urologia',
    'Dermatologia'
  ];

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (data != null) setState(() => _dataSelecionada = data);
  }

  Future<void> _selecionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (hora != null) setState(() => _horaSelecionada = hora);
  }

  Future<void> _agendar() async {
    if (_medicoSelecionado == null || _especialidadeSelecionada == null) {
      _showSnack('Preencha o medico e a especialidade');
      return;
    }
    if (_dataSelecionada == null) {
      _showSnack('Seleccione uma data');
      return;
    }
    if (_horaSelecionada == null) {
      _showSnack('Seleccione uma hora');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final dataHora = DateTime(
        _dataSelecionada!.year,
        _dataSelecionada!.month,
        _dataSelecionada!.day,
        _horaSelecionada!.hour,
        _horaSelecionada!.minute,
      );

      await FirebaseFirestore.instance.collection('consultas').add({
        'userId': user.uid,
        'username': user.email?.split('@').first ?? '',
        'medico': _medicoSelecionado,
        'especialidade': _especialidadeSelecionada,
        'notas': _notasController.text.trim(),
        'dataHora': Timestamp.fromDate(dataHora),
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showSnack('Esta registado');
      Navigator.pop(context);
    } catch (e) {
      _showSnack('Erro ao agendar consulta. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Consulta'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nova Consulta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _medicoSelecionado,
              hint: const Text('Seleccione o Medico'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              items: _medicos.map((String medico) {
                return DropdownMenuItem<String>(
                  value: medico,
                  child: Text(medico),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() => _medicoSelecionado = newValue);
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _especialidadeSelecionada,
              hint: const Text('Seleccione a Especialidade'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.medical_services_outlined),
                border: OutlineInputBorder(),
              ),
              items: _especialidades.map((String especialidade) {
                return DropdownMenuItem<String>(
                  value: especialidade,
                  child: Text(especialidade),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() => _especialidadeSelecionada = newValue);
              },
            ),
            const SizedBox(height: 16),

            // Data
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: Text(
                _dataSelecionada == null
                    ? 'Seleccionar Data'
                    : '${_dataSelecionada!.day.toString().padLeft(2, '0')}/'
                    '${_dataSelecionada!.month.toString().padLeft(2, '0')}/'
                    '${_dataSelecionada!.year}',
                style: TextStyle(
                  color: _dataSelecionada == null ? Colors.grey : Colors.black,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selecionarData,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            // Hora
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time, color: Colors.blue),
              title: Text(
                _horaSelecionada == null
                    ? 'Seleccionar Hora'
                    : '${_horaSelecionada!.hour.toString().padLeft(2, '0')}:'
                    '${_horaSelecionada!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: _horaSelecionada == null ? Colors.grey : Colors.black,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selecionarHora,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _notasController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _agendar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Agendar', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
