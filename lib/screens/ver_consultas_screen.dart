import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerConsultasScreen extends StatelessWidget {
  const VerConsultasScreen({super.key});

  Future<void> _editarConsulta(BuildContext context, String docId, Map<String, dynamic> data) async {
    final List<String> medicos = [
      'Francisco Paulo',
      'Maria Eduarda',
      'Cristina Ricardo',
      'Mateus Mario'
    ];

    final List<String> especialidades = [
      'Cardiologia',
      'Oftalmologia',
      'Pediatria',
      'Urologia',
      'Dermatologia'
    ];

    String? medicoSelecionado = data['medico'];
    String? especialidadeSelecionada = data['especialidade'];
    
    DateTime dataHoraOriginal = (data['dataHora'] as Timestamp).toDate();
    DateTime dataSelecionada = dataHoraOriginal;
    TimeOfDay horaSelecionada = TimeOfDay.fromDateTime(dataHoraOriginal);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Consulta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Lista de Medicos
                    DropdownButtonFormField<String>(
                      value: medicoSelecionado,
                      items: medicos.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) => setState(() => medicoSelecionado = val),
                      decoration: const InputDecoration(labelText: 'Medico', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    
                    // Lista de Especialidades
                    DropdownButtonFormField<String>(
                      value: especialidadeSelecionada,
                      items: especialidades.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => especialidadeSelecionada = val),
                      decoration: const InputDecoration(labelText: 'Especialidade', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    
                    ListTile(
                      title: Text("Data: ${dataSelecionada.day}/${dataSelecionada.month}/${dataSelecionada.year}"),
                      trailing: const Icon(Icons.calendar_today, color: Colors.blue),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: dataSelecionada,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) setState(() => dataSelecionada = d);
                      },
                    ),
                    ListTile(
                      title: Text("Hora: ${horaSelecionada.format(context)}"),
                      trailing: const Icon(Icons.access_time, color: Colors.blue),
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: horaSelecionada,
                        );
                        if (t != null) setState(() => horaSelecionada = t);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    final novaDataHora = DateTime(
                      dataSelecionada.year,
                      dataSelecionada.month,
                      dataSelecionada.day,
                      horaSelecionada.hour,
                      horaSelecionada.minute,
                    );
                    
                    await FirebaseFirestore.instance.collection('consultas').doc(docId).update({
                      'medico': medicoSelecionado,
                      'especialidade': especialidadeSelecionada,
                      'dataHora': Timestamp.fromDate(novaDataHora),
                    });
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Consulta atualizada com sucesso')),
                      );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _cancelarConsulta(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar Consulta'),
        content: const Text('Tem certeza que deseja cancelar esta consulta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nao'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('consultas').doc(docId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Consulta cancelada')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao cancelar consulta')),
          );
        }
      }
    }
  }

  String _formatarData(Timestamp timestamp) {
    final data = timestamp.toDate();
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}  '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Utilizador nao logado")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Consultas'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('consultas')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar consultas'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  const Text(
                    'Sem consultas agendadas',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final dataHora = data['dataHora'] as Timestamp;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFE0F2F1),
                            child: Icon(Icons.medical_services, color: Colors.teal),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['medico'] ?? 'Sem nome',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  data['especialidade'] ?? 'Clinica Geral',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editarConsulta(context, doc.id, data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _cancelarConsulta(context, doc.id),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.teal),
                          const SizedBox(width: 6),
                          Text(_formatarData(dataHora)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
