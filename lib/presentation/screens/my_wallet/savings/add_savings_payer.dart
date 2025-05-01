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

    DataSnapshot snapshot = (await savingsRef
        .child('savings')
        .get()) as dynamic;

    var currentSavings = (snapshot.value) as dynamic;

    // Verificar que hay suficiente saldo disponible
    if (double.parse(amountController.text) > currentSavings) {
      ToastMessage().toastMessage('Saldo insuficiente', Colors.red);
      return;
    }

    // Agregar los datos del ahorro
    final savingsData = {
      'name': nameController.text,
      'amount': double.parse(amountController.text),
      'accountNumber': accountNumberController.text,
      'shortDescription': shortDescriptionController.text,
      'paymentDateTime': now.toIso8601String(),
    };

    // Actualizar el saldo de ahorros (DISMINUIR en lugar de aumentar)
    var updatedSavings = currentSavings - double.parse(amountController.text);

    await savingsRef.update({
      'savings': updatedSavings,
      'savingsSpendings': ServerValue.increment(double.parse(amountController.text)),
    });

    // Registrar la transacción en los ahorros
    savingsRef
        .child('savingsTransactions')
        .push()
        .set(savingsData);

    // Registrar en todas las transacciones con signo negativo para indicar gasto
    final allTransactionSaver = {
      ...savingsData,
      'amount': '- ${amountController.text}'  // Cambio a signo negativo
    };
    savingsRef
        .child('allTransactions')
        .push()
        .set(allTransactionSaver);

    Navigator.pop(context);
    ToastMessage().toastMessage('¡Ahorro registrado con éxito!', Colors.green);
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
                          SizedBox(
                            height: constraints.maxHeight * 0.03,
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(Icons.keyboard_backspace),
                              ),
                              SizedBox(
                                width: constraints.maxWidth * 0.03,
                              ),
                              const Text(
                                'Agregar gasto',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: constraints.maxHeight * 0.03,
                          ),
                          CustomTextField(
                            hint: 'Nombre del gasto',
                            iconName: Icons.savings,
                            controller: nameController,
                            validator: _validateFormField,
                          ),
                          SizedBox(
                            height: constraints.maxHeight * 0.02,
                          ),
                          CustomTextField(
                              hint: 'Monto a gastar',
                              iconName: Icons.attach_money,
                              controller: amountController,
                              validator: _validateNumber,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ]),
                          SizedBox(
                            height: constraints.maxHeight * 0.02,
                          ),
                          CustomTextField(
                            hint: 'Objetivo o descripción',
                            iconName: Icons.subject,
                            controller: shortDescriptionController,
                            validator: null,
                          ),
                          SizedBox(
                            height: constraints.maxHeight * 0.04,
                          ),
                          TButton(
                              constraints: constraints,
                              btnColor: Theme.of(context).primaryColor,
                              btnText: 'Guardar gasto',
                              onPressed: _addSavings),
                          SizedBox(
                            height: constraints.maxHeight * 0.04,
                          ),
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