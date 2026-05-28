import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';

import 'negocio_detalle_screen.dart';
import 'alianza_detalle_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MODELOS
// ═══════════════════════════════════════════════════════════════════════════════

class Negocio {
  final String id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final String? logoUrl;
  final String direccion;
  final bool destacado;
  const Negocio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    this.logoUrl,
    required this.direccion,
    this.destacado = false,
  });
}

class Alianza {
  final String id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final String? logoUrl;
  const Alianza({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    this.logoUrl,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATOS MOCK
// ═══════════════════════════════════════════════════════════════════════════════

const _mockNegocios = [
  Negocio(id: '1', nombre: 'Restaurante El Mesón',  descripcion: 'Comida regional duranguense',          categoria: 'Restaurantes', logoUrl: 'https://picsum.photos/seed/meson/200/200',    direccion: 'Av. 20 de Noviembre 210', destacado: true),
  Negocio(id: '2', nombre: 'Óptica Visión Clara',   descripcion: 'Lentes de medida y de sol',           categoria: 'Salud',        logoUrl: 'https://picsum.photos/seed/optica/200/200',   direccion: 'Blvd. Durango 450',       destacado: true),
  Negocio(id: '3', nombre: 'Boutique Moda Durango', descripcion: 'Ropa y accesorios de moda',           categoria: 'Moda',         logoUrl: 'https://picsum.photos/seed/boutique/200/200', direccion: 'Plaza las Américas L-45', destacado: true),
  Negocio(id: '4', nombre: 'Farmacia San Rafael',   descripcion: 'Medicamentos 24 horas',               categoria: 'Salud',        logoUrl: 'https://picsum.photos/seed/farmacia/200/200', direccion: 'Calle Constitución 88',   destacado: false),
  Negocio(id: '5', nombre: 'Gym PowerFit Durango',  descripcion: 'Gimnasio con clases grupales',        categoria: 'Deportes',     logoUrl: 'https://picsum.photos/seed/gym/200/200',      direccion: 'Av. Fray Juan de Larios', destacado: true),
];

const _mockAlianzas = [
  Alianza(id: '1', nombre: 'Antigua Hacienda de Otinapa', descripcion: 'Renta de cabañas',                    categoria: 'Cabañas',      logoUrl: 'https://picsum.photos/seed/otinapa/200/200'),
  Alianza(id: '2', nombre: 'Paseo de la Sierra',          descripcion: 'Venta de lotes en la sierra',         categoria: 'Tours',        logoUrl: 'https://picsum.photos/seed/sierra/200/200'),
  Alianza(id: '3', nombre: 'Valle de Alcalá',             descripcion: 'Lotes para pisca de manzana en Canatlán', categoria: 'Bienes raíces',logoUrl: 'https://picsum.photos/seed/alcala/200/200'),
  Alianza(id: '4', nombre: 'Sierra Aventura Tours',       descripcion: 'Turismo de aventura en Durango',      categoria: 'Tours',        logoUrl: 'https://picsum.photos/seed/aventura/200/200'),
  Alianza(id: '5', nombre: 'Cabañas El Salto',            descripcion: 'Hospedaje en el bosque',              categoria: 'Cabañas',      logoUrl: 'https://picsum.photos/seed/salto/200/200'),
];

// ═══════════════════════════════════════════════════════════════════════════════
// ENUM DE SECCIÓN
// ═══════════════════════════════════════════════════════════════════════════════

enum _Seccion { redNegocios, alianzas }

// ═══════════════════════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ═══════════════════════════════════════════════════════════════════════════════

class RedNegociosScreen extends ConsumerStatefulWidget {
  const RedNegociosScreen({super.key});

  @override
  ConsumerState<RedNegociosScreen> createState() => _RedNegociosScreenState();
}

class _RedNegociosScreenState extends ConsumerState<RedNegociosScreen>
    with SingleTickerProviderStateMixin {

  // ── Estado ────────────────────────────────────────────────────────────────
  _Seccion _seccionActiva = _Seccion.redNegocios;
  String _categoriaActiva = 'Todos';
  String _busqueda = '';
  bool _menuVisible = false;

  final _searchController = TextEditingController();
  late AnimationController _menuAnimCtrl;
  late Animation<double> _menuFade;
  late Animation<Offset> _menuSlide;

  // ── Categorías por sección ────────────────────────────────────────────────
  static const _categoriasRed = [
    'Todos', 'Restaurantes', 'Farmacias', 'Ferreterías', 'Gimnasios', 'Salud', 'Moda', 'Deportes',
  ];
  static const _categoriasAlianzas = [
    'Todos', 'Cabañas', 'Tours', 'Bienes raíces', 'Gimnasios',
  ];

  List<String> get _categorias =>
      _seccionActiva == _Seccion.redNegocios ? _categoriasRed : _categoriasAlianzas;

  String get _titulo =>
      _seccionActiva == _Seccion.redNegocios ? 'Red de negocios' : 'Alianzas';

  String get _hintBusqueda =>
      _seccionActiva == _Seccion.redNegocios ? 'Buscar negocio' : 'Buscar alianza';

  @override
  void initState() {
    super.initState();
    _menuAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _menuFade  = CurvedAnimation(parent: _menuAnimCtrl, curve: Curves.easeOut);
    _menuSlide = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _menuAnimCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _menuAnimCtrl.dispose();
    super.dispose();
  }

  // ── Cambiar sección ───────────────────────────────────────────────────────
  void _cambiarSeccion(_Seccion seccion) {
    setState(() {
      _seccionActiva    = seccion;
      _categoriaActiva  = 'Todos';
      _busqueda         = '';
      _menuVisible      = false;
    });
    _searchController.clear();
    _menuAnimCtrl.reverse();
  }

  // ── Toggle menú ───────────────────────────────────────────────────────────
  void _toggleMenu() {
    setState(() => _menuVisible = !_menuVisible);
    if (_menuVisible) {
      _menuAnimCtrl.forward();
    } else {
      _menuAnimCtrl.reverse();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF2F5),
        body: GestureDetector(
          // Cerrar menú al tocar fuera
          onTap: () {
            if (_menuVisible) {
              setState(() => _menuVisible = false);
              _menuAnimCtrl.reverse();
            }
          },
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // ── Contenido principal ──────────────────────────────────
              Column(
                children: [
                  _Header(
                    titulo: _titulo,
                    hintBusqueda: _hintBusqueda,
                    searchController: _searchController,
                    categoriaActiva: _categoriaActiva,
                    categorias: _categorias,
                    busqueda: _busqueda,
                    onBusquedaChanged: (v) => setState(() => _busqueda = v),
                    onCategoriaChanged: (v) =>
                        setState(() => _categoriaActiva = v),
                    onClearBusqueda: () {
                      _searchController.clear();
                      setState(() => _busqueda = '');
                    },
                    onMenuTap: _toggleMenu,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: child,
                      ),
                      child: _seccionActiva == _Seccion.redNegocios
                          ? _RedNegociosBody(
                              key: const ValueKey('red'),
                              categoriaActiva: _categoriaActiva,
                              busqueda: _busqueda,
                            )
                          : _AlianzasBody(
                              key: const ValueKey('alianzas'),
                              categoriaActiva: _categoriaActiva,
                              busqueda: _busqueda,
                            ),
                    ),
                  ),
                ],
              ),

              // ── Menú desplegable ─────────────────────────────────────
              if (_menuVisible)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 48,
                  right: 16,
                  child: FadeTransition(
                    opacity: _menuFade,
                    child: SlideTransition(
                      position: _menuSlide,
                      child: _DropdownMenu(
                        seccionActiva: _seccionActiva,
                        onSelect: _cambiarSeccion,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MENÚ DESPLEGABLE
// ═══════════════════════════════════════════════════════════════════════════════

class _DropdownMenu extends StatelessWidget {
  final _Seccion seccionActiva;
  final ValueChanged<_Seccion> onSelect;

  const _DropdownMenu({
    required this.seccionActiva,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MenuItem(
            icon: Icons.storefront_rounded,
            label: 'Red de negocios',
            activo: seccionActiva == _Seccion.redNegocios,
            onTap: () => onSelect(_Seccion.redNegocios),
            isFirst: true,
          ),
          Divider(
            height: 1,
            color: const Color(0xFFEEF2F5),
            indent: 16,
            endIndent: 16,
          ),
          _MenuItem(
            icon: Icons.handshake_outlined,
            label: 'Alianzas',
            activo: seccionActiva == _Seccion.alianzas,
            onTap: () => onSelect(_Seccion.alianzas),
            isFirst: false,
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool activo;
  final VoidCallback onTap;
  final bool isFirst;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.activo,
    required this.onTap,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: activo
              ? AppColors.primaryNavy.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft:     Radius.circular(isFirst ? 14 : 0),
            topRight:    Radius.circular(isFirst ? 14 : 0),
            bottomLeft:  Radius.circular(isFirst ? 0 : 14),
            bottomRight: Radius.circular(isFirst ? 0 : 14),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: activo ? AppColors.primaryNavy : AppColors.supportMedium,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: activo ? AppColors.primaryNavy : AppColors.textDark,
                fontWeight: activo ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (activo)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryNavy,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HEADER — compartido por ambas secciones
// ═══════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final String titulo;
  final String hintBusqueda;
  final TextEditingController searchController;
  final String categoriaActiva;
  final List<String> categorias;
  final String busqueda;
  final ValueChanged<String> onBusquedaChanged;
  final ValueChanged<String> onCategoriaChanged;
  final VoidCallback onClearBusqueda;
  final VoidCallback onMenuTap;

  const _Header({
    required this.titulo,
    required this.hintBusqueda,
    required this.searchController,
    required this.categoriaActiva,
    required this.categorias,
    required this.busqueda,
    required this.onBusquedaChanged,
    required this.onCategoriaChanged,
    required this.onClearBusqueda,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      color: AppColors.primaryNavy,
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + botón hamburguesa
          Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    titulo,
                    key: ValueKey(titulo),
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onMenuTap,
                  child: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Buscador
          Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: searchController,
                onChanged: onBusquedaChanged,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textDark),
                cursorColor: AppColors.primaryNavy,
                decoration: InputDecoration(
                  hintText: hintBusqueda,
                  hintStyle: AppTypography.bodyMedium
                      .copyWith(color: const Color(0xFFAAAAAA)),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFFAAAAAA),
                    size: 20,
                  ),
                  suffixIcon: busqueda.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: Color(0xFFAAAAAA)),
                          onPressed: onClearBusqueda,
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Chips de categoría
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categorias.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = categorias[i];
                final activo = cat == categoriaActiva;
                return GestureDetector(
                  onTap: () => onCategoriaChanged(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: activo ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: activo
                          ? null
                          : Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1,
                            ),
                    ),
                    child: Text(
                      cat,
                      style: AppTypography.labelSmall.copyWith(
                        color: activo ? AppColors.primaryNavy : Colors.white,
                        fontWeight:
                            activo ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BODY — RED DE NEGOCIOS
// ═══════════════════════════════════════════════════════════════════════════════

class _RedNegociosBody extends StatelessWidget {
  final String categoriaActiva;
  final String busqueda;

  const _RedNegociosBody({
    super.key,
    required this.categoriaActiva,
    required this.busqueda,
  });

  List<Negocio> get _filtrados {
    var lista = _mockNegocios.toList();
    if (categoriaActiva != 'Todos') {
      lista = lista.where((n) => n.categoria == categoriaActiva).toList();
    }
    if (busqueda.isNotEmpty) {
      lista = lista
          .where((n) =>
              n.nombre.toLowerCase().contains(busqueda.toLowerCase()))
          .toList();
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final filtrados  = _filtrados;
    final destacados = filtrados.where((n) => n.destacado).toList();

    if (filtrados.isEmpty) return _EmptyState(mensaje: 'Sin negocios encontrados');

    return CustomScrollView(
      slivers: [
        // Destacados
        if (destacados.isNotEmpty && busqueda.isEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text('Destacados',
                  style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textDark, fontWeight: FontWeight.w700)),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: destacados.take(4).map((n) => _DestacadoCard(
                  logoUrl: n.logoUrl, nombre: n.nombre.split(' ').first, subtitulo: n.categoria,
                )).toList(),
              ),
            ),
          ),
        ],

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              busqueda.isNotEmpty ? 'Resultados (${filtrados.length})' : 'Todos los negocios',
              style: AppTypography.titleMedium.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700),
            ),
          ),
        ),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _NegocioTile(
              logoUrl:    filtrados[i].logoUrl,
              nombre:     filtrados[i].nombre,
              subtitulo:  filtrados[i].categoria,
              categoria:  filtrados[i].categoria,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => NegocioDetalleScreen(negocio: filtrados[i]),
              )),
            ).animate().fadeIn(delay: Duration(milliseconds: i * 50)).slideY(begin: 0.05, end: 0),
            childCount: filtrados.length,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BODY — ALIANZAS
// ═══════════════════════════════════════════════════════════════════════════════

class _AlianzasBody extends StatelessWidget {
  final String categoriaActiva;
  final String busqueda;

  const _AlianzasBody({
    super.key,
    required this.categoriaActiva,
    required this.busqueda,
  });

  List<Alianza> get _filtradas {
    var lista = _mockAlianzas.toList();
    if (categoriaActiva != 'Todos') {
      lista = lista.where((a) => a.categoria == categoriaActiva).toList();
    }
    if (busqueda.isNotEmpty) {
      lista = lista
          .where((a) =>
              a.nombre.toLowerCase().contains(busqueda.toLowerCase()))
          .toList();
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _filtradas;

    if (filtradas.isEmpty) return _EmptyState(mensaje: 'Sin alianzas encontradas');

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(
              busqueda.isNotEmpty ? 'Resultados (${filtradas.length})' : 'Todas las alianzas',
              style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textDark, fontWeight: FontWeight.w700),
            ),
          ),
        ),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _NegocioTile(
              logoUrl:   filtradas[i].logoUrl,
              nombre:    filtradas[i].nombre,
              subtitulo: filtradas[i].descripcion,
              categoria: filtradas[i].categoria,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AlianzaDetalleScreen(alianza: filtradas[i]),
              )),
            ).animate().fadeIn(delay: Duration(milliseconds: i * 60)).slideY(begin: 0.05, end: 0),
            childCount: filtradas.length,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS COMPARTIDOS
// ═══════════════════════════════════════════════════════════════════════════════

class _DestacadoCard extends StatelessWidget {
  final String? logoUrl;
  final String nombre;
  final String subtitulo;

  const _DestacadoCard({required this.nombre, required this.subtitulo, this.logoUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: logoUrl != null
                ? Image.network(logoUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.storefront_outlined, color: AppColors.supportMedium))
                : const Icon(Icons.storefront_outlined, color: AppColors.supportMedium),
          ),
        ),
        const SizedBox(height: 6),
        Text(nombre, style: AppTypography.labelSmall.copyWith(color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(subtitulo, style: AppTypography.labelSmall.copyWith(color: AppColors.supportMedium, fontSize: 10), textAlign: TextAlign.center),
      ],
    );
  }
}

class _NegocioTile extends StatelessWidget {
  final String? logoUrl;
  final String nombre;
  final String subtitulo;
  final String categoria;
  final VoidCallback? onTap;

  const _NegocioTile({required this.nombre, required this.subtitulo, required this.categoria, this.logoUrl, this.onTap});

  IconData get _icon {
    switch (categoria) {
      case 'Restaurantes': return Icons.restaurant_outlined;
      case 'Salud':        return Icons.local_hospital_outlined;
      case 'Moda':         return Icons.checkroom_outlined;
      case 'Deportes':     return Icons.fitness_center_outlined;
      case 'Farmacias':    return Icons.local_pharmacy_outlined;
      case 'Cabañas':      return Icons.cabin_outlined;
      case 'Tours':        return Icons.explore_outlined;
      case 'Bienes raíces':return Icons.landscape_outlined;
      default:             return Icons.storefront_outlined;
    }
  }

  Color get _color {
    switch (categoria) {
      case 'Restaurantes': return const Color(0xFFE84040);
      case 'Salud':        return const Color(0xFF00B894);
      case 'Moda':         return const Color(0xFF6C5CE7);
      case 'Deportes':     return const Color(0xFF0984E3);
      case 'Farmacias':    return const Color(0xFF00B894);
      case 'Cabañas':      return const Color(0xFF8B6914);
      case 'Tours':        return const Color(0xFF0984E3);
      case 'Bienes raíces':return const Color(0xFF2ECC71);
      default:             return AppColors.accentCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: logoUrl != null
                  ? Image.network(logoUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(_icon, color: _color, size: 22))
                  : Icon(_icon, color: _color, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textDark, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitulo,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.supportMedium),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: _color, size: 17),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.supportMedium, size: 20),
        ],
      ),
    ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String mensaje;
  const _EmptyState({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront_outlined, size: 56, color: AppColors.supportMedium.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(mensaje, style: AppTypography.bodyMedium.copyWith(color: AppColors.supportMedium)),
        ],
      ),
    );
  }
}