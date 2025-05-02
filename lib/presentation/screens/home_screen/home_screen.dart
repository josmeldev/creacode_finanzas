import 'package:creacode_finanzas/budgeto_themes.dart';
import 'package:creacode_finanzas/logic/autopay.dart';
import 'package:creacode_finanzas/logic/flutter_toast.dart';
import 'package:creacode_finanzas/presentation/screens/home_screen/add_funds_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:creacode_finanzas/presentation/widgets/custom_card.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import '../../../colors.dart';
import '../../../logic/autodeduct_carplan.dart';
import '../../../logic/autodeduct_emergencyfunds.dart';
import '../../../logic/autodeduct_monthend.dart';
import '../../widgets/button.dart';
import '../../widgets/null_error_message_widget.dart';
import '../../widgets/transaction_card.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DatabaseReference ref = FirebaseDatabase.instance.ref().child('Users');

  final user = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();

    AutoDeductEmergencyFunds emergencyEMI = AutoDeductEmergencyFunds();
    emergencyEMI.autoDeductEmergencyFunds();

    AutodeductMonthend deductBal = AutodeductMonthend();
    deductBal.autodeductMonthend();

    AutoDeductCarFunds carEMI = AutoDeductCarFunds();
    carEMI.autoDeductCarFunds();

    // if (isAutoPayOn) {
    Autopay instance = Autopay();
    instance.autoPay();

    // }
  }

  // @override
  // void dispose() {
  //   isAutoPayOn = false;
  //   super.dispose();
  // }

  dynamic accountNumber;
  void getAccountNum() {
    DatabaseReference accNumRef = ref
        .child(user.uid.toString())
        .child('bankAccNumber');

    accNumRef.once().then((snapshot) {
      if (mounted) {
        setState(() {
          accountNumber = (snapshot.snapshot.value) as dynamic;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    getAccountNum();
    return WillPopScope(
      onWillPop: () async {
        // isAutoPayOn = false;
        SystemNavigator.pop();
        return true;
      },
      child: StreamBuilder(
        stream: ref.child(user.uid.toString()).child('split').onValue,
        builder: ((context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.snapshot.value == null) {
              return LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const NullErrorMessage(
                          message:
                              '¡Algo salió mal!\n Asegúrate de haber verificado tu correo',
                        ),
                        const SizedBox(height: 20),
                        TButton(
                          constraints: constraints,
                          btnColor: Theme.of(context).primaryColor,
                          btnText: '¡Regístrate de nuevo!',
                          onPressed: () {
                            FirebaseAuth.instance.currentUser!.delete();
                            FirebaseAuth.instance.signOut;
                            PersistentNavBarNavigator.pushNewScreen(
                              context,
                              screen: const LoginScreen(),
                              withNavBar:
                                  false, // OPTIONAL VALUE. True by default.
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            } else {
              Map<dynamic, dynamic> map = snapshot.data.snapshot.value;

              dynamic total =
                  (map['needAvailableBalance'] +
                          map['expensesAvailableBalance'] +
                          map['savings'])
                      as dynamic;

              return WillPopScope(
                onWillPop: () async {
                  // isAutoPayOn = false;
                  SystemNavigator.pop();
                  return true;
                },
                child: Scaffold(
                  body: SafeArea(
                    child: LayoutBuilder(
                      builder: (
                        BuildContext context,
                        BoxConstraints constraints,
                      ) {
                        return OrientationBuilder(
                          builder: (
                            BuildContext context,
                            Orientation orientation,
                          ) {
                            return SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: constraints.maxHeight * 0.03,
                                    ),
                                    Text(
                                      'Presupuesto',
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                        fontSize: 32,
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(
                                      height: constraints.maxHeight * 0.02,
                                    ),
                                    Stack(
                                      children: [
                                        // Contenedor principal con efecto de tarjeta de crédito
                                        Container(
                                          height:
                                              orientation ==
                                                      Orientation.portrait
                                                  ? constraints.maxHeight * 0.25
                                                  : constraints.maxHeight * 0.6,
                                          decoration: BoxDecoration(
                                            // Gradiente para efecto reluciente
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Theme.of(context).primaryColor,
                                                Theme.of(
                                                  context,
                                                ).primaryColor.withBlue(180),
                                                Theme.of(
                                                  context,
                                                ).primaryColor.withRed(150),
                                              ],
                                            ),
                                            borderRadius:
                                                const BorderRadius.all(
                                                  Radius.circular(20),
                                                ),
                                            // Sombra para dar efecto de profundidad
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                spreadRadius: 1,
                                                blurRadius: 10,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          // Efecto de brillo
                                          child: Stack(
                                            children: [
                                              // Círculos semi-transparentes para efecto de brillo
                                              Positioned(
                                                top: -40,
                                                right: -20,
                                                child: Container(
                                                  height: 100,
                                                  width: 100,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white
                                                        .withOpacity(0.1),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: -50,
                                                left: -30,
                                                child: Container(
                                                  height: 150,
                                                  width: 150,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white
                                                        .withOpacity(0.1),
                                                  ),
                                                ),
                                              ),
                                              // Líneas horizontales para simular chip
                                              Positioned(
                                                bottom: 50,
                                                right: 30,
                                                child: Container(
                                                  height: 30,
                                                  width: 45,
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber
                                                        .withOpacity(0.8),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          5,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Resto del contenido (texto, iconos, etc.)
                                        const Positioned(
                                          top: 40,
                                          left: 30,
                                          child: Text(
                                            'Saldo Total',
                                            style: TextStyle(
                                              fontSize: 25,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        // ...resto del código sin cambios
                                        const Positioned(
                                          bottom: 75,
                                          left: 20,
                                          child: Icon(
                                            Icons.attach_money,
                                            size: 48,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 70,
                                          left: 70,
                                          child: SizedBox(
                                            height: 60,
                                            width:
                                                200, // Definir un ancho máximo
                                            child: FittedBox(
                                              fit:
                                                  BoxFit
                                                      .scaleDown, // Reduce el tamaño del texto si es necesario
                                              alignment:
                                                  Alignment
                                                      .centerLeft, // Alinear a la izquierda
                                              child: Text(
                                                (total).toStringAsFixed(0),
                                                style: const TextStyle(
                                                  fontSize:
                                                      50, // Tamaño base que puede reducirse
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 30,
                                          bottom: 15,
                                          child: Container(
                                            height:
                                                orientation ==
                                                        Orientation.portrait
                                                    ? constraints.maxHeight *
                                                        0.05
                                                    : constraints.maxHeight *
                                                        0.1,
                                            width:
                                                orientation ==
                                                        Orientation.portrait
                                                    ? constraints.maxWidth *
                                                        0.34
                                                    : constraints.maxWidth *
                                                        0.18,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.all(
                                                    Radius.circular(25),
                                                  ),
                                              color:
                                                  BudgetoThemes.isDarkMode(
                                                            context,
                                                          ) ==
                                                          true
                                                      ? kDarkGreenBackC
                                                      : kGreenDarkC,
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 5,
                                                  ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  const Icon(
                                                    Icons.account_balance,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                  Text(
                                                    'Platinium' ??
                                                        'Cargando...',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 15,
                                          right: 20,
                                          child: Text(
                                            'CreaCode Card',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: Colors.white.withOpacity(
                                                0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 20,
                                          right: 20,
                                          child: GestureDetector(
                                            onTap: () {
                                              getAccountNum();
                                              accountNumber == ""
                                                  ? ToastMessage().toastMessage(
                                                    'Please update your account!',
                                                    Colors.red,
                                                  )
                                                  : Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              const AddFundsScreen(),
                                                    ),
                                                  );
                                            },
                                            child: Container(
                                              height:
                                                  orientation ==
                                                          Orientation.portrait
                                                      ? constraints.maxHeight *
                                                          0.05
                                                      : constraints.maxHeight *
                                                          0.1,
                                              width:
                                                  orientation ==
                                                          Orientation.portrait
                                                      ? constraints.maxWidth *
                                                          0.32
                                                      : constraints.maxWidth *
                                                          0.18,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    const BorderRadius.all(
                                                      Radius.circular(25),
                                                    ),
                                                color:
                                                    BudgetoThemes.isDarkMode(
                                                              context,
                                                            ) ==
                                                            true
                                                        ? kDarkGreenBackC
                                                        : kGreenDarkC,
                                              ),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 15,
                                                  vertical: 5,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.add,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text(
                                                      'Agregar',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: constraints.maxHeight * 0.02,
                                    ),
                                    const Text(
                                      'Equilibrio de categorías',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    SizedBox(
                                      height: constraints.maxHeight * 0.02,
                                    ),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center, // Centrar horizontalmente
                                      children: [
                                        CustomCard(
                                          orientation: orientation,
                                          verHeight:
                                              constraints.maxHeight *
                                              0.14, // Misma altura que las otras
                                          horiHeight:
                                              constraints.maxHeight * 0.35,
                                          // Hacer que el ancho sea proporcional a las otras pero un poco más grande
                                          verWidth:
                                              constraints.maxWidth *
                                              0.9, // 90% del ancho de la pantalla
                                          horiWidth: constraints.maxWidth * 0.9,
                                          cardTitle: 'Necesidades',
                                          cardBalance:
                                              map['needAvailableBalance']
                                                  .toStringAsFixed(0),
                                          isCentered:
                                              true, // Nueva propiedad para indicar centrado de contenido
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: constraints.maxHeight * 0.02,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        CustomCard(
                                          orientation: orientation,
                                          verHeight:
                                              constraints.maxHeight * 0.14,
                                          horiHeight:
                                              constraints.maxHeight * 0.35,
                                          verWidth:
                                              constraints.maxHeight * 0.22,
                                          horiWidth:
                                              constraints.maxWidth * 0.45,
                                          cardTitle: 'Deseos',
                                          cardBalance:
                                              map['expensesAvailableBalance']
                                                  .toStringAsFixed(0),
                                          isCentered: true,        
                                        ),
                                        CustomCard(
                                          orientation: orientation,
                                          verHeight:
                                              constraints.maxHeight * 0.14,
                                          horiHeight:
                                              constraints.maxHeight * 0.35,
                                          verWidth:
                                              constraints.maxHeight * 0.23,
                                          horiWidth:
                                              constraints.maxWidth * 0.45,
                                          cardTitle: 'Ahorros',
                                          cardBalance: map['savings']
                                              .toStringAsFixed(0),
                                        isCentered: true,
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: constraints.maxHeight * 0.02,
                                    ),

                                    SizedBox(
                                      height: constraints.maxHeight * 0.02,
                                    ),
                                    const Text(
                                      'Todas las transacciones',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    SizedBox(
                                      height: constraints.maxHeight * 0.015,
                                    ),
                                    map['allTransactions'] == null
                                        ? const Center(
                                          child: Text(
                                            'No hay transacciones aún',
                                          ),
                                        )
                                        : StreamBuilder(
                                          stream:
                                              ref
                                                  .child(user.uid)
                                                  .child('split')
                                                  .child('allTransactions')
                                                  .onValue,
                                          builder: (
                                            context,
                                            AsyncSnapshot<DatabaseEvent>
                                            snapshot,
                                          ) {
                                            if (!snapshot.hasData) {
                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(
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
                                                (a, b) => b['paymentDateTime']
                                                    .compareTo(
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
                                                final formatted = formatter
                                                    .format(newDate);

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
                                                                  0.4
                                                              : constraints
                                                                      .maxHeight *
                                                                  0.6,
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
                                                            constraints:
                                                                constraints,
                                                            dateAndTime: formatDate(
                                                              list[index]['paymentDateTime'],
                                                            ),
                                                            transactionAmount:
                                                                list[index]['amount']
                                                                    .toString(),
                                                            transactionName:
                                                                list[index]['name'],
                                                            width:
                                                                constraints
                                                                    .maxWidth *
                                                                0.05,
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
                                    SizedBox(
                                      height:
                                          orientation == Orientation.portrait
                                              ? constraints.maxHeight * 0.04
                                              : constraints.maxHeight * 0.1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              );
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(color: kGreenColor),
            );
          }
        }),
      ),
    );
  }
}
