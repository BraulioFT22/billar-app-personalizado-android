import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../services/storage_service.dart';

class PantallaProductos extends StatefulWidget {
  const PantallaProductos({super.key});

  @override
  State<PantallaProductos> createState() => _PantallaProductosState();
}

class _PantallaProductosState extends State<PantallaProductos> {
  List<Producto> _productos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final productos = await StorageService.cargarProductos();
    setState(() {
      _productos = productos;
      _cargando = false;
    });
  }

  Future<void> _guardar() => StorageService.guardarProductos(_productos);

  void _mostrarDialog({Producto? producto}) {
    final isEdit = producto != null;
    final nombreCtrl = TextEditingController(text: producto?.nombre ?? '');
    final precioCtrl = TextEditingController(
        text: isEdit ? producto.precio.toStringAsFixed(2) : '');
    bool esMesa = isEdit ? producto.esMesa : false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(isEdit ? 'Editar Producto' : 'Nuevo Producto'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del producto',
                    hintText: 'Ej: Mesa Billar, Alitas, Cerveza...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Ingresa un nombre' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: precioCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: 100.00',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa un precio';
                    if (double.tryParse(v) == null) return 'Número inválido';
                    if (double.parse(v) <= 0) return 'Debe ser mayor a 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // ── Toggle tipo de producto ──
                Container(
                  decoration: BoxDecoration(
                    color: esMesa
                        ? Colors.greenAccent.withOpacity(0.1)
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: esMesa
                          ? Colors.greenAccent.withOpacity(0.5)
                          : Colors.white24,
                    ),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      esMesa ? '🎱 Tipo: Mesa de Billar' : '🛒 Tipo: Producto/Consumo',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      esMesa
                          ? 'Aparece al iniciar una mesa (precio/hora)'
                          : 'Aparece al agregar consumos durante la sesión',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: esMesa,
                    activeColor: Colors.greenAccent,
                    onChanged: (val) => setDialog(() => esMesa = val),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx);
                  setState(() {
                    if (isEdit) {
                      producto.nombre = nombreCtrl.text.trim();
                      producto.precio = double.parse(precioCtrl.text);
                      producto.esMesa = esMesa;
                    } else {
                      _productos.add(Producto(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        nombre: nombreCtrl.text.trim(),
                        precio: double.parse(precioCtrl.text),
                        esMesa: esMesa,
                      ));
                    }
                  });
                  _guardar();
                }
              },
              child: Text(isEdit ? 'Guardar cambios' : 'Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  void _eliminar(Producto p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${p.nombre}" del catálogo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _productos.remove(p));
              _guardar();
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
      appBar: AppBar(
        title: const Row(children: [
          Text('🛒 ', style: TextStyle(fontSize: 22)),
          Text('Listado de Productos',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _productos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🛒', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay productos configurados.\nAgrega tu primer producto con el botón +.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _mostrarDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Primer Producto'),
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _productos.length,
                  itemBuilder: (ctx, i) {
                    final p = _productos[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2E7D32),
                          radius: 26,
                          child: Text(
                            p.nombre[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                        ),
                        title: Text(p.nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 17)),
                        subtitle: Text(
                          p.esMesa ? '🎱 Tipo mesa · precio/hora' : '🛒 Producto de consumo',
                          style: TextStyle(
                            color: p.esMesa ? Colors.greenAccent : Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\$${p.precio.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.grey),
                              onPressed: () => _mostrarDialog(producto: p),
                              tooltip: 'Editar precio',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _eliminar(p),
                              tooltip: 'Eliminar',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _productos.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _mostrarDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Producto'),
              backgroundColor: const Color(0xFF2E7D32),
            )
          : null,
    );
  }
}