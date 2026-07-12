import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/asset_url.dart';

class ImagemBadgeMobile extends StatelessWidget {
  final String? urlImagem;
  final double tamanho;
  final bool cinzento;
  final BoxFit fit;
  final EdgeInsets padding;

  const ImagemBadgeMobile({
    super.key,
    this.urlImagem,
    this.tamanho = 80,
    this.cinzento = false,
    this.fit = BoxFit.contain,
    this.padding = const EdgeInsets.all(6),
  });

  @override
  Widget build(BuildContext context) {
    final src = AssetUrl.imagemBadge(urlImagem);
    final isSvg = src.toLowerCase().contains('.svg') ||
        src.toLowerCase().contains('/raw/upload/');
    final fallback = Icon(
      Icons.workspace_premium,
      size: tamanho * 0.5,
      color: cinzento ? Colors.grey : const Color(0xFF34659D),
    );

    final image = isSvg
        ? SvgPicture.network(
            src,
            width: tamanho,
            height: tamanho,
            fit: fit,
            placeholderBuilder: (_) => fallback,
          )
        : Image.network(
            src,
            width: tamanho,
            height: tamanho,
            fit: fit,
            errorBuilder: (_, __, ___) => fallback,
          );

    final content = Padding(padding: padding, child: image);
    if (!cinzento) return content;

    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: Opacity(opacity: 0.75, child: content),
    );
  }
}
