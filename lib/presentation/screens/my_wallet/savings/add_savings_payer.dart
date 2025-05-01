import 'package:creacode_finanzas/presentation/widgets/button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../logic/flutter_toast.dart';
import '../../../widgets/text_field.dart';

class AddSavingsPayer extends StatefulWidget {
  const AddSavingsPayer({super.key});

  @override
  State<AddSavingsPayer> createState() => _AddSavingsPayerState();
}

class _AddSavingsPayerState extends State<AddSavingsPayer> {
  DatabaseReference ref = FirebaseDatabase.instance.ref().child('Users');

  final user = FirebaseAuth.instance.currentUser!;

  DateTime now = DateTime.now();

  final _formKey = GlobalKey<FormState>();

  // Controllers for textfields
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  final accountNumberController = TextEditingController();
  final shortDescriptionController = TextEditingController();

  // Validators for form fields
  String? _validateFormField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es obligatorio';
    }
    final double? amount = double.tryParse(value);
    if (amount == null) {
      return 'Este campo debe ser un número';
    }
    if (amount <= 0) {
      return 'El monto debe ser mayor que 0';
    }
    return null;
  }

  void _addSavings() async {
    if (_formKey.currentState!.validate()) {
      DatabaseReference savingsRef = ref.child(user.uid).child('split');

      // Obtener saldo disponible de savings
      DataSnapshot savingsSnapshot =
          (await savingsRef.child('savings').get()) as dynamic;
      var currentSavings = (savingsSnapshot.value) as dynamic ?? 0;

      // Monto a gastar
      double amountToSpend = double.parse(amountController.text);

      // Verificar primero si hay suficiente saldo en savings
      if (amountToSpend <= currentSavings) {
        // Hay suficiente saldo en savings, proceder normalmente
        processTransaction(savingsRef, currentSavings, false);
      } else {
        // No hay suficiente saldo en savings, verificar totalSavings
        DataSnapshot totalSavingsSnapshot =
            (await savingsRef.child('totalSavings').get()) as dynamic;
        var currentTotalSavings = (totalSavingsSnapshot.value) as dynamic ?? 0;

        if (amountToSpend <= currentTotalSavings) {
          // Hay suficiente en totalSavings, preguntar al usuario
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Saldo insuficiente en ahorros'),
                content: const Text(
                  'No tienes suficiente saldo en tus ahorros actuales, ¿deseas utilizar tu ahorro total acumulado?',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Cerrar diálogo
                    },
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Cerrar diálogo
                      // Procesar transacción usando totalSavings
                      processTransaction(savingsRef, currentTotalSavings, true);
                    },
                    child: const Text(
                      'Sí, usar ahorro total',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              );
            },
          );
        } else {
          // No hay suficiente saldo en ninguno de los dos
          ToastMessage().toastMessage(
            'Saldo insuficiente en ahorros actuales y ahorro total',
            Colors.red,
          );
        }
      }
    }
  }

  // Función para procesar la transacción
  void processTransaction(
    DatabaseReference savingsRef,
    dynamic currentBalance,
    bool useTotal,
  ) async {
    // Obtener monto a gastar
    double amount = double.parse(amountController.text);

    // Crear datos de la transacción
    final savingsData = {
      'name': nameController.text,
      'amount': amount,
      'shortDescription': shortDescriptionController.text,
      'paymentDateTime': now.toIso8601String(),
    };

    // Actualizar el saldo correspondiente
    var updatedBalance = currentBalance - amount;

    if (useTotal) {
      // Usar totalSavings
      await savingsRef.update({
        'totalSavings': updatedBalance,
        'savingsSpendings': ServerValue.increment(amount),
      });
    } else {
      // Usar savings normal
      await savingsRef.update({
        'savings': updatedBalance,
        'savingsSpendings': ServerValue.increment(amount),
      });
    }

    // Registrar la transacción en los ahorros
    savingsRef.child('savingsTransactions').push().set(savingsData);

    // Registrar en todas las transacciones con signo negativo
    final allTransactionSaver = {
      ...savingsData,
      'amount': '- ${amount}',
      'usedTotalSavings':
          useTotal, // Agregar campo para indicar si se usó ahorro total
    };

    savingsRef.child('allTransactions').push().set(allTransactionSaver);

    Navigator.pop(context);

    if (useTotal) {
      ToastMessage().toastMessage(
        '¡Gasto registrado con éxito usando ahorro total!',
        Colors.green,
      );
    } else {
      ToastMessage().toastMessage('¡Gasto registrado con éxito!', Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return OrientationBuilder(
            builder: (BuildContext context, Orientation orientation) {
              return SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          SizedBox(height: constraints.maxHeight * 0.03),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(Icons.keyboard_backspace),
                              ),
                              SizedBox(width: constraints.maxWidth * 0.03),
                              const Text(
                                'Agregar gasto',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: constraints.maxHeight * 0.03),
                          CustomTextField(
                            hint: 'Nombre del gasto',
                            iconName: Icons.savings,
                            controller: nameController,
                            validator: _validateFormField,
                          ),
                          SizedBox(height: constraints.maxHeight * 0.02),
                          CustomTextField(
                            hint: 'Monto a gastar',
                            iconName: Icons.attach_money,
                            controller: amountController,
                            validator: _validateNumber,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          SizedBox(height: constraints.maxHeight * 0.02),
                          CustomTextField(
                            hint: 'Objetivo o descripción',
                            iconName: Icons.subject,
                            controller: shortDescriptionController,
                            validator: null,
                          ),
                          SizedBox(height: constraints.maxHeight * 0.04),
                          TButton(
                            constraints: constraints,
                            btnColor: Theme.of(context).primaryColor,
                            btnText: 'Guardar gasto',
                            onPressed: _addSavings,
                          ),
                          SizedBox(height: constraints.maxHeight * 0.04),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
