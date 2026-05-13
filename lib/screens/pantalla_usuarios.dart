import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/database_service.dart';

class PantallaUsuarios extends StatefulWidget {
  const PantallaUsuarios({super.key});

  @override
  State<PantallaUsuarios> createState() => _PantallaUsuariosState();
}

class _PantallaUsuariosState extends State<PantallaUsuarios> {
  List<Usuario> _operadores = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final ops = await DatabaseService.obtenerOperadores();
    setState(() { _operadores = ops; _cargando = false; });
  }

  void _mostrarDialogCrear() {
    final nombreCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    final pin2Ctrl = TextEditingController();
    String error = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Nuevo Operador'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre del operador',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'PIN (4-6 digitos)',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: pin2Ctrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Confirmar PIN',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              if (error.isNotEmpty)
                Text(error, style: const TextStyle(color: Colors.red)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nombreCtrl.text.trim().isEmpty) { setDialog(() => error = 'Ingresa un nombre'); return; }
                if (pinCtrl.text.length < 4) { setDialog(() => error = 'PIN minimo 4 digitos'); return; }
                if (pinCtrl.text != pin2Ctrl.text) { setDialog(() => error = 'Los PINs no coinciden'); return; }
                Navigator.pop(ctx);
                await DatabaseService.crearOperador(nombreCtrl.text.trim(), pinCtrl.text);
                _cargar();
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _eliminar(Usuario u) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar operador'),
        content: Text('Eliminar a "${u.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseService.eliminarUsuario(u.id!);
              _cargar();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion de Usuarios')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _operadores.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No hay operadores creados.\nAgrega uno con el boton +.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _mostrarDialogCrear,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear primer operador'),
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _operadores.length,
                  itemBuilder: (ctx, i) {
                    final u = _operadores[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey,
                          radius: 26,
                          child: Text(u.nombre[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(u.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        subtitle: const Text('Operador - Acceso estandar'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _eliminar(u),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogCrear,
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar Operador'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }
}