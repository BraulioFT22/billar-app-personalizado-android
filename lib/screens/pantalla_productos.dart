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
    setState(() { _productos = productos; _cargando = false; });
  }

  Future<void> _guardar() => StorageService.guardarProductos(_productos);

  Future<String?> _seleccionarIcono(String iconoActual) async {
    String? seleccionado;
    final grupos = CatalogoIconos.porCategoria();

    return await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Selecciona un icono'),
          content: SizedBox(
            width: 520,
            height: 480,
            child: DefaultTabController(
              length: grupos.length,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    tabs: grupos.keys.map((cat) => Tab(text: cat)).toList(),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: grupos.entries.map((entry) {
                        return GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: entry.value.length,
                          itemBuilder: (ctx, i) {
                            final item = entry.value[i];
                            final clave = item.key;
                            final data = item.value;
                            final estaSeleccionado = (seleccionado ?? iconoActual) == clave;
                            return GestureDetector(
                              onTap: () => setDialog(() => seleccionado = clave),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: estaSeleccionado
                                      ? Colors.greenAccent.withOpacity(0.2)
                                      : Colors.white10,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: estaSeleccionado ? Colors.greenAccent : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(data['icono'] as IconData,
                                        size: 28,
                                        color: estaSeleccionado ? Colors.greenAccent : Colors.white70),
                                    const SizedBox(height: 4),
                                    Text(
                                      data['label'] as String,
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: estaSeleccionado ? Colors.greenAccent : Colors.white54),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton.icon(
              onPressed: seleccionado != null ? () => Navigator.pop(ctx, seleccionado) : null,
              icon: const Icon(Icons.check),
              label: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialog({Producto? producto}) {
    final isEdit = producto != null;
    final nombreCtrl = TextEditingController(text: producto?.nombre ?? '');
    final precioCtrl = TextEditingController(
        text: isEdit ? producto.precio.toStringAsFixed(2) : '');
    bool esMesa = isEdit ? producto.esMesa : false;
    String iconoClave = isEdit ? producto.iconoClave : 'sports_bar';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(isEdit ? 'Editar Producto' : 'Nuevo Producto'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final nuevo = await _seleccionarIcono(iconoClave);
                      if (nuevo != null) setDialog(() => iconoClave = nuevo);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.greenAccent),
                      ),
                      child: Row(
                        children: [
                          Icon(CatalogoIconos.obtener(iconoClave),
                              size: 40, color: Colors.greenAccent),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Icono del producto',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Toca para cambiar',
                                  style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    validator: (v) => v == null || v.isEmpty ? 'Ingresa un nombre' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: precioCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                      hintText: 'Ej: 100.00',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa un precio';
                      if (double.tryParse(v) == null) return 'Numero invalido';
                      if (double.parse(v) <= 0) return 'Debe ser mayor a 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: esMesa ? Colors.greenAccent.withOpacity(0.1) : Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: esMesa ? Colors.greenAccent.withOpacity(0.5) : Colors.white24),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        esMesa ? '🎱 Tipo: Mesa de Billar' : '🛒 Tipo: Producto/Consumo',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        esMesa
                            ? 'Aparece al iniciar mesa (precio/hora)'
                            : 'Aparece en consumos durante la sesion',
                        style: const TextStyle(fontSize: 11),
                      ),
                      value: esMesa,
                      activeColor: Colors.greenAccent,
                      onChanged: (val) => setDialog(() => esMesa = val),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx);
                  setState(() {
                    if (isEdit) {
                      producto.nombre = nombreCtrl.text.trim();
                      producto.precio = double.parse(precioCtrl.text);
                      producto.esMesa = esMesa;
                      producto.iconoClave = iconoClave;
                    } else {
                      _productos.add(Producto(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        nombre: nombreCtrl.text.trim(),
                        precio: double.parse(precioCtrl.text),
                        esMesa: esMesa,
                        iconoClave: iconoClave,
                      ));
                    }
                  });
                  _guardar();
                }
              },
              child: Text(isEdit ? 'Guardar' : 'Agregar'),
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
        content: Text('Eliminar "${p.nombre}" del catalogo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
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

  bool _esBebida(String clave) => ['local_bar','wine_bar','liquor','coffee','water_drop','emoji_food_bev','local_cafe','icecream'].contains(clave);
  bool _esComida(String clave) => ['restaurant','lunch_dining','local_pizza','ramen_dining','set_meal','fastfood','cake','kitchen'].contains(clave);
  bool _esServicio(String clave) => ['smoking_rooms','ac_unit','cleaning_services','shopping_bag','receipt','star','card_giftcard','miscellaneous'].contains(clave);

  Widget _encabezadoSeccion(String titulo, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 24,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(titulo, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _gridProductos(List<Producto> lista) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.9,
      ),
      itemCount: lista.length,
      itemBuilder: (ctx, i) {
        final p = lista[i];
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _mostrarDialog(producto: p),
            onLongPress: () => _eliminar(p),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: p.esMesa ? Colors.greenAccent.withOpacity(0.15) : Colors.blue.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(p.icono, size: 30,
                        color: p.esMesa ? Colors.greenAccent : Colors.blueAccent),
                  ),
                  const SizedBox(height: 8),
                  Text(p.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('\$${p.precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mesas = _productos.where((p) => p.esMesa).toList();
    final consumos = _productos.where((p) => !p.esMesa).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Text('🛒 ', style: TextStyle(fontSize: 22)),
          Text('Listado de Productos', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _productos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No hay productos configurados.\nAgrega tu primer producto.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _mostrarDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Primer Producto'),
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (mesas.isNotEmpty) ...[
                      _encabezadoSeccion('🎱 Mesas de Billar', Colors.greenAccent),
                      const SizedBox(height: 10),
                      _gridProductos(mesas),
                      const SizedBox(height: 24),
                    ],
                    if (consumos.where((p) => _esBebida(p.iconoClave)).isNotEmpty) ...[
                      _encabezadoSeccion('🍺 Bebidas', Colors.blueAccent),
                      const SizedBox(height: 10),
                      _gridProductos(consumos.where((p) => _esBebida(p.iconoClave)).toList()),
                      const SizedBox(height: 24),
                    ],
                    if (consumos.where((p) => _esComida(p.iconoClave)).isNotEmpty) ...[
                      _encabezadoSeccion('🍗 Comida', Colors.orangeAccent),
                      const SizedBox(height: 10),
                      _gridProductos(consumos.where((p) => _esComida(p.iconoClave)).toList()),
                      const SizedBox(height: 24),
                    ],
                    if (consumos.where((p) => _esServicio(p.iconoClave)).isNotEmpty) ...[
                      _encabezadoSeccion('⚡ Servicios', Colors.purpleAccent),
                      const SizedBox(height: 10),
                      _gridProductos(consumos.where((p) => _esServicio(p.iconoClave)).toList()),
                      const SizedBox(height: 24),
                    ],
                    if (consumos.where((p) => !_esBebida(p.iconoClave) && !_esComida(p.iconoClave) && !_esServicio(p.iconoClave)).isNotEmpty) ...[
                      _encabezadoSeccion('📦 Otros', Colors.grey),
                      const SizedBox(height: 10),
                      _gridProductos(consumos.where((p) => !_esBebida(p.iconoClave) && !_esComida(p.iconoClave) && !_esServicio(p.iconoClave)).toList()),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar Producto'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }
}