import 'package:flutter/material.dart';
import '../services/asset_url.dart';

class AvatarUtilizadorMobile extends StatelessWidget {
  final String nome;
  final String? foto;
  final double raio;
  final Color backgroundColor;
  final Color foregroundColor;

  const AvatarUtilizadorMobile({
    super.key,
    required this.nome,
    this.foto,
    this.raio = 20,
    this.backgroundColor = const Color(0xFF34659D),
    this.foregroundColor = Colors.white,
  });

  String get _iniciais {
    final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final src = AssetUrl.resolver(foto);
    return CircleAvatar(
      radius: raio,
      backgroundColor: backgroundColor,
      child: src == null
          ? Text(
              _iniciais,
              style: TextStyle(
                color: foregroundColor,
                fontSize: raio * 0.75,
                fontWeight: FontWeight.bold,
              ),
            )
          : ClipOval(
              child: Image.network(
                src,
                width: raio * 2,
                height: raio * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    _iniciais,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: raio * 0.75,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
