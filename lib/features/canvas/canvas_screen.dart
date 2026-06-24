import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:aquarela_watercolor_sketch/config/palette_ids.dart';
import 'package:aquarela_watercolor_sketch/engine/canvas_painter.dart';
import 'package:aquarela_watercolor_sketch/engine/pigment.dart';
import 'package:aquarela_watercolor_sketch/features/canvas/canvas_cubit.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/pigment.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/radius.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/typography.dart';
import 'package:aquarela_watercolor_sketch/features/palette/palette_screen.dart';

/// The painting surface. Fullscreen, gesture-driven, with a
/// minimalist top bar (save + clear) and bottom bar (open palette).
///
/// On a real device the user just drags a finger. We capture
/// pointer events via [GestureDetector] and emit stamps in real
/// time — every waypoint triggers a paint frame, so the user sees
/// the pigment as soon as the finger touches down, not only on
/// finger lift.
class CanvasScreen extends StatelessWidget {
  const CanvasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paper.white,
      body: BlocProvider(
        create: (_) => CanvasCubit(),
        child: const _CanvasView(),
      ),
    );
  }
}

class _CanvasView extends StatefulWidget {
  const _CanvasView();

  @override
  State<_CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends State<_CanvasView> {
  final GlobalKey _canvasKey = GlobalKey();

  Future<void> _save(BuildContext context) async {
    final cubit = context.read<CanvasCubit>();
    if (cubit.state.strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pinte algo antes de salvar'),
          backgroundColor: BrandPigment.ultramar,
        ),
      );
      return;
    }

    try {
      final bytes = await _capturePng();
      if (bytes == null) {
        throw StateError('Falha ao capturar o canvas');
      }
      final savedFile = await _persistPng(bytes);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Salvo na galeria'),
          backgroundColor: BrandPigment.ultramar,
          action: SnackBarAction(
            label: 'Compartilhar',
            textColor: Paper.white,
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                files: [XFile(savedFile.path)],
                text: 'Pintei no Aquarela',
              ),
            ),
          ),
        ),
      );
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          // Material error red — only used for transient save errors.
          backgroundColor: const Color(0xFFB00020),
        ),
      );
    }
  }

  /// Render the canvas at 2x to a PNG byte buffer. Returns null if
  /// the repaint boundary is missing (e.g. widget unmounted mid-draw).
  Future<Uint8List?> _capturePng() async {
    final boundary =
        _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  /// Save [bytes] to the system gallery and a copy in our app docs.
  /// Returns the local app-docs file so the share action can pick
  /// it up without re-reading the system gallery.
  Future<File> _persistPng(Uint8List bytes) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'aquarela_$ts';

    // System gallery — visible to the user in Photos / Gallery apps.
    await Gal.putImageBytes(bytes, name: fileName);

    // App docs — our own gallery feature reads this directory.
    final docs = await getApplicationDocumentsDirectory();
    final galleryDir = Directory('${docs.path}/gallery');
    if (!galleryDir.existsSync()) {
      galleryDir.createSync(recursive: true);
    }
    final file = File('${galleryDir.path}/$fileName.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // Canvas
          Positioned.fill(
            child: RepaintBoundary(
              key: _canvasKey,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) =>
                    context.read<CanvasCubit>().startStroke(d.localPosition),
                onPanUpdate: (d) =>
                    context.read<CanvasCubit>().addPoint(d.localPosition),
                onPanEnd: (_) => context.read<CanvasCubit>().endStroke(),
                onPanCancel: () => context.read<CanvasCubit>().cancelStroke(),
                child: BlocBuilder<CanvasCubit, CanvasState>(
                  builder: (context, state) {
                    return CustomPaint(
                      painter: CanvasPainter(
                        strokes: state.renderableStrokes,
                        paperColor: Paper.cream,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _CanvasTopBar(
              onSave: () => _save(context),
              onClear: () => context.read<CanvasCubit>().clear(),
            ),
          ),

          // Bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _CanvasBottomBar(
              onOpenPalette: () {
                showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: Paper.white,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(RadiusToken.lg),
                    ),
                  ),
                  builder: (_) => BlocProvider.value(
                    value: context.read<CanvasCubit>(),
                    child: const PaletteScreen(),
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

class _CanvasTopBar extends StatelessWidget {
  const _CanvasTopBar({required this.onSave, required this.onClear});

  final VoidCallback onSave;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Paper.white.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: Paper.mist.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Paper.charcoal),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Paper.charcoal,
            ),
            onPressed: onClear,
            tooltip: 'Limpar',
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined, color: BrandPigment.ultramar),
            onPressed: onSave,
            tooltip: 'Salvar',
          ),
        ],
      ),
    );
  }
}

class _CanvasBottomBar extends StatelessWidget {
  const _CanvasBottomBar({required this.onOpenPalette});

  final VoidCallback onOpenPalette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Paper.white.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: Paper.mist.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          BlocBuilder<CanvasCubit, CanvasState>(
            buildWhen: (a, b) => a.currentPigment != b.currentPigment,
            builder: (context, state) {
              final color = _colorFor(state.currentPigment);
              return GestureDetector(
                onTap: onOpenPalette,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Paper.ink.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Paper.shadow(opacity: 0.18),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: BlocBuilder<CanvasCubit, CanvasState>(
              buildWhen: (a, b) =>
                  a.currentBrush.waterRatio != b.currentBrush.waterRatio,
              builder: (context, state) {
                return Row(
                  children: [
                    const Icon(
                      Icons.water_drop_outlined,
                      size: 18,
                      color: Paper.charcoal,
                    ),
                    Expanded(
                      child: Slider(
                        value: state.currentBrush.waterRatio,
                        onChanged: (v) =>
                            context.read<CanvasCubit>().setWaterRatio(v),
                        activeColor: BrandPigment.ultramar,
                        inactiveColor: Paper.mist,
                      ),
                    ),
                    Text(
                      'Água',
                      style: AquarelaTypography.caption.copyWith(
                        color: Paper.charcoal,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(PigmentId id) {
    final p = Pigment.byId(id);
    return p?.color ?? BrandPigment.ultramar;
  }
}
