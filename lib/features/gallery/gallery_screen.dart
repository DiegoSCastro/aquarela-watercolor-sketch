import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:aquarela_watercolor_sketch/config/premium_config.dart';
import 'package:aquarela_watercolor_sketch/theme/components/empty_state.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/radius.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/spacing.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/typography.dart';

/// A saved painting on disk.
class GalleryItem {
  const GalleryItem({required this.file, required this.createdAt});

  final File file;
  final DateTime createdAt;

  String get fileName => file.path.split(Platform.pathSeparator).last;
}

/// In-app gallery: lists PNGs saved under app docs/gallery. Lets
/// the user share or delete them. Free tier caps the visible
/// items at [PremiumConfig.maxSavedPaintings].
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _loading = true;
  String? _error;
  List<GalleryItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/gallery');
      if (!dir.existsSync()) {
        setState(() {
          _items = const [];
          _loading = false;
        });
        return;
      }

      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.png'))
          .toList();

      // Newest first.
      files.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );

      // Apply the free-tier cap so users see what their tier allows.
      final cap = PremiumConfig.current.maxSavedPaintings;
      final visible = cap < 0 ? files : files.take(cap).toList();

      final items = visible
          .map(
            (f) => GalleryItem(
              file: f,
              createdAt: f.statSync().modified,
            ),
          )
          .toList();

      setState(() {
        _items = items;
        _loading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _share(GalleryItem item) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(item.file.path)],
        text: 'Pintei no Aquarela',
      ),
    );
  }

  Future<void> _delete(GalleryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar obra?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await item.file.delete();
      await _load();
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao apagar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paper.white,
      appBar: AppBar(
        title: const Text('Galeria'),
        backgroundColor: Paper.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Text(
            'Erro ao carregar galeria: $_error',
            style: AquarelaTypography.bodyMedium.copyWith(color: Paper.ink),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.brush_outlined,
          title: 'Nenhuma obra ainda',
          message: 'Suas pinturas salvas aparecem aqui.',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.all(Space.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: Space.md,
          crossAxisSpacing: Space.md,
          childAspectRatio: 0.85,
        ),
        itemCount: _items.length,
        itemBuilder: (context, i) => _GalleryTile(
          item: _items[i],
          onShare: () => _share(_items[i]),
          onDelete: () => _delete(_items[i]),
        ),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.item,
    required this.onShare,
    required this.onDelete,
  });

  final GalleryItem item;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(RadiusToken.md),
      child: Container(
        decoration: BoxDecoration(
          color: Paper.cream,
          borderRadius: BorderRadius.circular(RadiusToken.md),
          border: Border.all(
            color: Paper.mist.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _openFullScreen(context),
                child: Image.file(
                  item.file,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: Paper.cream,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Paper.charcoal,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.sm,
                vertical: Space.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDate(item.createdAt),
                      style: AquarelaTypography.caption.copyWith(
                        color: Paper.charcoal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.ios_share_rounded,
                      size: 18,
                      color: Paper.charcoal,
                    ),
                    onPressed: onShare,
                    tooltip: 'Compartilhar',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Paper.charcoal,
                    ),
                    onPressed: onDelete,
                    tooltip: 'Apagar',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullScreenImage(file: item.file),
        fullscreenDialog: true,
      ),
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatDate(DateTime dt) {
    return '${_two(dt.day)}/${_two(dt.month)} ${_two(dt.hour)}:${_two(dt.minute)}';
  }
}

class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Paper.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Image.file(file),
        ),
      ),
    );
  }
}
