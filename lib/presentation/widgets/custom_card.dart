import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    required this.orientation,
    required this.verHeight,
    required this.horiHeight,
    required this.horiWidth,
    required this.verWidth,
    required this.cardTitle,
    required this.cardBalance,
    this.isCentered = false, // Propiedad para control de centrado
  });

  final Orientation orientation;
  final dynamic verHeight;
  final dynamic verWidth;
  final dynamic horiHeight;
  final dynamic horiWidth;
  final String cardTitle;
  final String cardBalance;
  final bool isCentered; // Si es true, centra todo el contenido

  @override
  Widget build(BuildContext context) {
    return Container(
      height: orientation == Orientation.portrait ? verHeight : horiHeight,
      width: orientation == Orientation.portrait ? verWidth : horiWidth,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(20),
        ),
        color: Theme.of(context).cardColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          // Centrar todo el contenido verticalmente
          mainAxisAlignment: MainAxisAlignment.center,
          // Centrar o alinear el contenido horizontalmente según la propiedad isCentered
          crossAxisAlignment: isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            // Título centrado o alineado según la propiedad isCentered
            Container(
              width: double.infinity, // Ocupar todo el ancho disponible
              alignment: isCentered ? Alignment.center : Alignment.centerLeft,
              child: Text(
                cardTitle,
                textAlign: isCentered ? TextAlign.center : TextAlign.left,
                style: TextStyle(
                  fontSize: 22,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 5),
            // Fila con icono y balance centrada o alineada según la propiedad isCentered
            Container(
              width: double.infinity, // Ocupar todo el ancho disponible
              alignment: isCentered ? Alignment.center : Alignment.centerLeft,
              child: Row(
                // Centrar o alinear el contenido de la fila según la propiedad
                mainAxisAlignment: isCentered 
                    ? MainAxisAlignment.center 
                    : MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Tamaño mínimo para centrado adecuado
                children: [
                  const Icon(
                    Icons.attach_money,
                    size: 25,
                  ),
                  SizedBox(
                    height: 35,
                    // Ancho adaptable para el texto
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: isCentered ? Alignment.center : Alignment.centerLeft,
                      child: Text(
                        cardBalance,
                        textAlign: isCentered ? TextAlign.center : TextAlign.left,
                        style: const TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}