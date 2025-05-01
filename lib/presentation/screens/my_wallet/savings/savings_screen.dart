import 'package:creacode_finanzas/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../../widgets/balance_card.dart';
import '../../../widgets/null_error_message_widget.dart';
import '../../../widgets/transaction_card.dart';
import '../../../widgets/card_alt.dart';
import '../../../widgets/custom_card.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../widgets/transaction_card.dart';
import '../savings/add_savings_payer.dart';
import '../../../widgets/button.dart'; // Asegúrate de que este import esté presente

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final DatabaseReference ref = FirebaseDatabase.instance.ref().child('Users');
  final user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object>(
      stream: ref.child(user.uid.toString()).child('split').onValue,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.snapshot.value == null) {
            return const NullErrorMessage(message: '¡Algo salió mal!');
          } else {
            Map<dynamic, dynamic> map = snapshot.data.snapshot.value;
            return Scaffold(
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return OrientationBuilder(
                      builder: (BuildContext context, Orientation orientation) {
                        return SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 15,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Balance card
                                BalanceCard(
                                  amount: map['savings'].toStringAsFixed(0),
                                  constraints:
                                      orientation == Orientation.portrait
                                          ? constraints.maxHeight * 0.25
                                          : constraints.maxHeight * 0.8,
                                ),
                                SizedBox(height: constraints.maxHeight * 0.03),

                                // Cards for statistics
                                // En la sección donde muestras las Cards for statistics

                                // Cards for statistics
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    CustomCard(
                                      orientation: orientation,
                                      verHeight: constraints.maxHeight * 0.15,
                                      horiHeight: constraints.maxHeight * 0.5,
                                      verWidth: constraints.maxHeight * 0.23,
                                      horiWidth: constraints.maxWidth * 0.4,
                                      cardTitle: 'Ingreso',
                                      // Ahora el Ingreso es la suma del saldo disponible más lo gastado
                                      cardBalance: ((map['savings'] ?? 0) +
                                              (map['savingsSpendings'] ?? 0))
                                          .toStringAsFixed(0),
                                    ),
                                    CustomCard(
                                      orientation: orientation,
                                      verHeight: constraints.maxHeight * 0.15,
                                      horiHeight: constraints.maxHeight * 0.5,
                                      verWidth: constraints.maxHeight * 0.23,
                                      horiWidth: constraints.maxWidth * 0.4,
                                      cardTitle: 'Gastos',
                                      cardBalance:
                                          map['savingsSpendings'] == null
                                              ? '0'
                                              : map['savingsSpendings']
                                                  .toStringAsFixed(0),
                                    ),
                                  ],
                                ),
                                SizedBox(height: constraints.maxHeight * 0.04),

                                // Botón para agregar nuevo ahorro
                                // Reemplaza el TButton actual con un SizedBox + ElevatedButton
                                SizedBox(
                                  width: double.infinity, // Ocupa todo el ancho
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          kGreenColor, // Color primario verde
                                      foregroundColor:
                                          Colors.white, // Texto blanco
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ), // Padding vertical para hacerlo más alto
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ), // Bordes redondeados
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const AddSavingsPayer(),
                                        ),
                                      );
                                    },
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.currency_exchange, size: 24),
                                        SizedBox(width: 12),
                                        Text(
                                          'Invertir',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: constraints.maxHeight * 0.04),
                                CustomCard(
                                  orientation: orientation,
                                  verHeight: constraints.maxHeight * 0.15,
                                  horiHeight: constraints.maxHeight * 0.5,
                                  verWidth:
                                      constraints.maxWidth *
                                      0.95, // Ancho completo
                                  horiWidth:
                                      constraints.maxWidth *
                                      0.95, // Ancho completo
                                  cardTitle: 'Ahorro Total',
                                  cardBalance:
                                      map['totalSavings'] == null
                                          ? '0'
                                          : map['totalSavings'].toStringAsFixed(
                                            0,
                                          ),
                                ),
                                SizedBox(height: constraints.maxHeight * 0.03),
                                // Transacciones title
                                const Text(
                                  'Transacciones',
                                  style: TextStyle(fontSize: 20),
                                ),
                                SizedBox(height: constraints.maxHeight * 0.03),

                                // Transactions list
                                map['savingsTransactions'] == null
                                    ? const Center(
                                      child: Text('Sin transacciones'),
                                    )
                                    : StreamBuilder(
                                      stream:
                                          ref
                                              .child(user.uid)
                                              .child('split')
                                              .child('savingsTransactions')
                                              .onValue,
                                      builder: (
                                        context,
                                        AsyncSnapshot<DatabaseEvent> snapshot,
                                      ) {
                                        if (!snapshot.hasData) {
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: kGreenColor,
                                            ),
                                          );
                                        } else {
                                          Map<dynamic, dynamic> map =
                                              snapshot.data!.snapshot.value
                                                  as dynamic;
                                          List<dynamic> list = [];
                                          list.clear();
                                          list = map.values.toList();
                                          list.sort(
                                            (a, b) =>
                                                b['paymentDateTime'].compareTo(
                                                  a['paymentDateTime'],
                                                ),
                                          );

                                          dynamic formatDate(String date) {
                                            // Inicializar la configuración regional de español (Perú)
                                            initializeDateFormatting(
                                              'es_PE',
                                              null,
                                            );

                                            // Convertir el string a DateTime
                                            final newDate = DateTime.parse(
                                              date,
                                            );

                                            // Formatear la fecha con el formato deseado
                                            final DateFormat formatter =
                                                DateFormat(
                                                  'E, d MMMM, hh:mm a',
                                                  'es_PE',
                                                );
                                            final formatted = formatter.format(
                                              newDate,
                                            );

                                            return formatted; // Retorna la fecha formateada
                                          }

                                          return Row(
                                            children: [
                                              Expanded(
                                                child: SizedBox(
                                                  height:
                                                      orientation ==
                                                              Orientation
                                                                  .portrait
                                                          ? constraints
                                                                  .maxHeight *
                                                              0.3
                                                          : constraints
                                                                  .maxHeight *
                                                              0.5,
                                                  child: ListView.builder(
                                                    itemCount:
                                                        snapshot
                                                            .data!
                                                            .snapshot
                                                            .children
                                                            .length,
                                                    itemBuilder: ((
                                                      context,
                                                      index,
                                                    ) {
                                                      return TransactionCard(
                                                        dateAndTime: formatDate(
                                                          list[index]['paymentDateTime'],
                                                        ),
                                                        transactionAmount:
                                                            '- ${list[index]['amount']}',
                                                        transactionName:
                                                            list[index]['name'],
                                                        width:
                                                            constraints
                                                                .maxWidth *
                                                            0.05,
                                                        constraints:
                                                            constraints,
                                                      );
                                                    }),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                      },
                                    ),
                                SizedBox(height: constraints.maxHeight * 0.04),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            );
          }
        } else {
          return const Center(
            child: CircularProgressIndicator(color: kGreenColor),
          );
        }
      },
    );
  }
}
