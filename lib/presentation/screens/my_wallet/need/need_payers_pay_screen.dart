import 'package:creacode_finanzas/presentation/widgets/button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../colors.dart';
import '../../../../logic/flutter_toast.dart';
import '../../../widgets/text_field.dart';

class NeedPayersPayScreen extends StatefulWidget {
  const NeedPayersPayScreen({
    super.key,
    required this.name,
    required this.accountNumber,
  });

  final dynamic name;
  final dynamic accountNumber;

  @override
  State<NeedPayersPayScreen> createState() => _NeedPayersPayScreenState();
}

class _NeedPayersPayScreenState extends State<NeedPayersPayScreen> {
  final DatabaseReference ref = FirebaseDatabase.instance.ref().child('Users');
  final user = FirebaseAuth.instance.currentUser!;

  var now = DateTime.now();

  final _formKey = GlobalKey<FormState>();

  final amountController = TextEditingController();
  final shortDescriptionController = TextEditingController();

  String? checkValidPercentage(value) {
    if (value.isEmpty) {
      return 'Please enter correct value';
    }
    return null;
  }

  void _addAndPay() async {
    if (_formKey.currentState!.validate()) {
      DatabaseReference needAvailRef = ref.child(user.uid).child('split');

      DataSnapshot snapshot =
          (await needAvailRef.child('needAvailableBalance').get()) as dynamic;

      var currentNeedAvail = (snapshot.value) as dynamic;

      final payerData = {
        'name': widget.name,
        'amount': double.parse(amountController.text),
        'accountNumber': widget.accountNumber,
        'shortDescription': shortDescriptionController.text,
        'paymentDateTime': now.toIso8601String(),
      };

      var updatedNeedAvail =
          currentNeedAvail - double.parse(amountController.text);

      await ref.child(user.uid).child('split').update({
        'needSpendings':
            ServerValue.increment(double.parse(amountController.text)),
        'needAvailableBalance': updatedNeedAvail,
      });

      ref
          .child(user.uid)
          .child('split')
          .child('needTransactions')
          .push()
          .set(payerData);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return OrientationBuilder(
              builder: (BuildContext context, Orientation orientation) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                'Seguir pagando',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        
                        SizedBox(
                          height: constraints.maxHeight * 0.02,
                        ),
                        
                        SizedBox(
                          height: constraints.maxHeight * 0.04,
                        ),
                        const Text(
                          'Nombre del beneficiario',
                          style: TextStyle(fontSize: 22, color: kGreenColor),
                        ),
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 24,
                          ),
                        ),
                        SizedBox(
                          height: constraints.maxHeight * 0.02,
                        ),
                        const Text(
                          'Numero de cuenta',
                          style: TextStyle(fontSize: 22, color: kGreenColor),
                        ),
                        Text(
                          widget.accountNumber,
                          style: const TextStyle(
                            fontSize: 24,
                          ),
                        ),
                        SizedBox(
                          height: constraints.maxHeight * 0.02,
                        ),
                        const Text(
                          'Monto a pagar',
                          style: TextStyle(fontSize: 22, color: kGreenColor),
                        ),
                        SizedBox(
                          height: constraints.maxHeight * 0.02,
                        ),
                        Form(
                          key: _formKey,
                          child: CustomTextField(
                              hint: 'Introduzca el monto a pagar',
                              iconName: Icons.attach_money,
                              controller: amountController,
                              validator: checkValidPercentage,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ]),
                        ),
                        SizedBox(
                          height: constraints.maxHeight * 0.02,
                        ),
                        const Text(
                          'Descripcion corta',
                          style: TextStyle(fontSize: 22, color: kGreenColor),
                        ),
                        SizedBox(
                          height: constraints.maxHeight * 0.02,
                        ),
                        CustomTextField(
                          hint: 'Introduzca una breve descripcion',
                          iconName: Icons.subject,
                          controller: shortDescriptionController,
                          validator: checkValidPercentage,
                        ),
                        SizedBox(
                          height: constraints.maxHeight * 0.05,
                        ),
                        TButton(
                            constraints: constraints,
                            btnColor: Theme.of(context).primaryColor,
                            btnText: 'Pagar',
                            onPressed: _addAndPay)
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
}
