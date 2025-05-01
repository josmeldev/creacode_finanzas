import 'dart:async';

import 'package:creacode_finanzas/presentation/widgets/button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../budgeto_themes.dart';
import '../../../../colors.dart';
import '../../../../logic/autopay.dart';
import '../../../../logic/flutter_toast.dart';
import '../../../widgets/text_field.dart';

class AddNeedPayer extends StatefulWidget {
  const AddNeedPayer({super.key});

  @override
  State<AddNeedPayer> createState() => _AddNeedPayerState();
}

class _AddNeedPayerState extends State<AddNeedPayer> {
  DatabaseReference ref = FirebaseDatabase.instance.ref().child('Users');

  final user = FirebaseAuth.instance.currentUser!;

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final amountController = TextEditingController();
  final accountNumberController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final shortDescriptionController = TextEditingController();

  bool isAutoPayOn = false;
  DateTime? paymentDateTime;

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  Future<void> _selectedDateTime(BuildContext context) async {
    ThemeData currentTheme = Theme.of(context);

    if (currentTheme.brightness == Brightness.light) {
      currentTheme = BudgetoThemes.lightTheme;
    } else {
      currentTheme = BudgetoThemes.darkTheme;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: currentTheme.copyWith(
            dialogBackgroundColor: Theme.of(context).cardColor,
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Theme.of(context).cardColor,
              onSurface: Theme.of(context).primaryColor,
              surface: Theme.of(context).cardColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor:
                    Theme.of(context).primaryColor, // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final TimeOfDay? pickedTime =
          // ignore: use_build_context_synchronously
          await showTimePicker(
        context: context,
        initialTime: selectedTime,
        builder: (context, child) {
          return Theme(
            data: currentTheme.copyWith(
              dialogBackgroundColor: Theme.of(context).cardColor,
              colorScheme: ColorScheme.light(
                surface: Theme.of(context).cardColor,
                primary: Theme.of(context).primaryColor,
                onPrimary: Theme.of(context).cardColor,
                onSurface: Theme.of(context).primaryColor,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).primaryColor, // button text color
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          selectedDate = DateTime(picked.year, picked.month, picked.day,
              pickedTime.hour, pickedTime.minute);
          selectedTime = pickedTime;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

// Validator for name
  String? _validateFormField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

// Validator for numeber realted textfields
  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es obligatorio';
    }
    final double? amount = double.tryParse(value);
    if (amount == null) {
      return 'Por favor, introduzca un importe válido';
    }
    if (amount <= 0) {
      return 'El importe debe ser mayor que 0';
    }
    return null;
  }

  void _addAutopay() async {
    if (_formKey.currentState!.validate()) {
      if (isAutoPayOn) {
        DatabaseReference needIncomeRef = ref.child(user.uid).child('split');

        DataSnapshot snapshot = (await needIncomeRef
            .child('needAvailableBalance')
            .get()) as dynamic;

        var currentNeedAvailable = (snapshot.value) as dynamic;

        if (double.parse(amountController.text) > currentNeedAvailable) {
          ToastMessage().toastMessage('Saldo insuficiente', Colors.red);
        } else {
          // Check if payer already exists
          DataSnapshot payerSnapshot = await needIncomeRef
              .child('needPayers')
              .orderByChild('accountNumber')
              .equalTo(accountNumberController.text)
              .get() as dynamic;

          final payerData = {
            'name': nameController.text,
            'amount': double.parse(amountController.text),
            'accountNumber': accountNumberController.text,
            'phoneNumber': phoneNumberController.text,
            'shortDescription': shortDescriptionController.text,
            'isAutopayOn': isAutoPayOn,
            'paymentDateTime': selectedDate.toIso8601String(),
          };

          // adding to autopay transaction list
          if (payerSnapshot.value == null) {
            ref
                .child(user.uid)
                .child('split')
                .child('needPayers')
                .push()
                .set(payerData);
          }
          // add transaction to needAutopay
          ref
              .child(user.uid)
              .child('split')
              .child('needAutopay')
              .push()
              .set(payerData)
              .then((value) async {
            Navigator.of(context).pop();
            ToastMessage().toastMessage('Añadido a Autopago!', Colors.green);

            // Starting autopay method by creating an instance
            Autopay instance = Autopay();
            instance.autoPay();
          }).onError((error, stackTrace) {
            ToastMessage().toastMessage(error.toString(), Colors.red);
          });
        }
      } else {
        ToastMessage().toastMessage('Por favor seleccione fecha y hora', Colors.red);
      }
    }
  }

  void _addAndPay() async {
    if (_formKey.currentState!.validate()) {
      DatabaseReference needIncomeRef = ref.child(user.uid).child('split');

      DataSnapshot snapshot =
          (await needIncomeRef.child('needAvailableBalance').get()) as dynamic;

      var currentNeedAvailable = (snapshot.value) as dynamic;

      if (double.parse(amountController.text) > currentNeedAvailable) {
        ToastMessage().toastMessage('Insufficient Balance', Colors.red);
      } else {
        // Check if payer already exists
        DataSnapshot payerSnapshot = await needIncomeRef
            .child('needPayers')
            .orderByChild('accountNumber')
            .equalTo(accountNumberController.text)
            .get() as dynamic;

        // store payer data from textfields
        final payerData = {
          'name': nameController.text,
          'amount': double.parse(amountController.text),
          'accountNumber': accountNumberController.text,
          'phoneNumber': phoneNumberController.text,
          'shortDescription': shortDescriptionController.text,
          'isAutopayOn': isAutoPayOn,
          'paymentDateTime': selectedDate.toIso8601String(),
        };

        // Payer does not exists, add it to payer list
        if (payerSnapshot.value == null) {
          ref
              .child(user.uid)
              .child('split')
              .child('needPayers')
              .push()
              .set(payerData);
        }

        var updatedNeedAvailable =
            currentNeedAvailable - double.parse(amountController.text);

        // Updating balance
        await ref.child(user.uid).child('split').update({
          'needSpendings':
              ServerValue.increment(double.parse(amountController.text)),
          'needAvailableBalance': updatedNeedAvailable,
        });

        // add transaction to needTransactions
        ref
            .child(user.uid)
            .child('split')
            .child('needTransactions')
            .push()
            .set(payerData);

        // add transaction to allTransactions
        final payeeData = {...payerData};
        final allTransactionPayer = {
          ...payeeData,
          'amount': '- ${amountController.text}'
        };
        ref
            .child(user.uid)
            .child('split')
            .child('allTransactions')
            .push()
            .set(allTransactionPayer);

        Navigator.pop(context);
        ToastMessage().toastMessage('Exitoso!', Colors.green);
      }
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
                                'Añadir Pago',
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
                            hint: 'Producto o servicio',
                            iconName: Icons.person,
                            controller: nameController,
                            keyboardType: TextInputType.text,
                            validator: _validateFormField,
                          ),
                          SizedBox(
                            height: constraints.maxHeight * 0.02,
                          ),
                          CustomTextField(
                              hint: 'Monto',
                              iconName: Icons.attach_money,
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              validator: _validateNumber,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ]),
                          SizedBox(
                            height: constraints.maxHeight * 0.02,
                          ),
                          CustomTextField(
                              hint: 'Numero de cuenta',
                              iconName: Icons.account_balance,
                              controller: accountNumberController,
                              keyboardType: TextInputType.number,
                              validator: _validateNumber,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ]),
                          SizedBox(
                            height: constraints.maxHeight * 0.02,
                          ),
                          CustomTextField(
                              hint: 'Numero de teléfono',
                              iconName: Icons.call,
                              controller: phoneNumberController,
                              keyboardType: TextInputType.phone,
                              validator: _validateNumber,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ]),
                          SizedBox(
                            height: constraints.maxHeight * 0.02,
                          ),
                          CustomTextField(
                            hint: 'Pequeña descripción',
                            iconName: Icons.subject,
                            validator: null,
                            controller: shortDescriptionController,
                          ),
                          SizedBox(
                            height: constraints.maxHeight * 0.02,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Autopago',
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                              Switch(
                                  activeColor: kGreenColor,
                                  value: isAutoPayOn,
                                  onChanged: (value) {
                                    setState(() {
                                      isAutoPayOn = value;
                                    });
                                  }),
                            ],
                          ),
                          SizedBox(
                            height: constraints.maxHeight * 0.01,
                          ),
                          if (isAutoPayOn)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: GestureDetector(
                                onTap: () {
                                  _selectedDateTime(context);
                                },
                                child: Row(children: [
                                  const Icon(
                                    Icons.date_range,
                                    color: kGrayTextC,
                                  ),
                                  const SizedBox(
                                    width: 15,
                                  ),
                                  Text(
                                    DateFormat('dd-MM-yyyy  hh:mm a').format(
                                        DateTime(
                                            selectedDate.year,
                                            selectedDate.month,
                                            selectedDate.day,
                                            selectedTime.hour,
                                            selectedTime.minute)),
                                    style: const TextStyle(color: kGrayTextC),
                                  )
                                ]),
                              ),
                            ),
                          SizedBox(
                            height: constraints.maxHeight * 0.04,
                          ),
                          TButton(
                              constraints: constraints,
                              btnColor: Theme.of(context).primaryColor,
                              btnText: 'Añadir a autopago',
                              onPressed: _addAutopay),
                          SizedBox(
                            height: constraints.maxHeight * 0.04,
                          ),
                          TButton(
                              constraints: constraints,
                              btnColor: Theme.of(context).primaryColor,
                              btnText: 'Añadir y pagar',
                              onPressed: _addAndPay),
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
