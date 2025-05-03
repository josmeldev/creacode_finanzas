import 'package:creacode_finanzas/budgeto_themes.dart';
import 'package:creacode_finanzas/colors.dart';
import 'package:creacode_finanzas/presentation/screens/auth/forgot_password_screen.dart';
import 'package:creacode_finanzas/presentation/screens/user_profile/update_account_screen.dart';
import 'package:creacode_finanzas/presentation/widgets/profile_tab.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:provider/provider.dart';
import '../../widgets/button.dart';
import '../../widgets/null_error_message_widget.dart';
import '../auth/login_screen.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:creacode_finanzas/logic/flutter_toast.dart';
import 'package:creacode_finanzas/presentation/widgets/text_field.dart';

class UserProfileScreeen extends StatefulWidget {
  const UserProfileScreeen({super.key});

  @override
  State<UserProfileScreeen> createState() => _UserProfileScreeenState();
}

class _UserProfileScreeenState extends State<UserProfileScreeen> {
  final ref = FirebaseDatabase.instance.ref('Users');
  final user = FirebaseAuth.instance.currentUser!;
  
  // Define tu email específico aquí
  final String adminEmail = "josmelvt@gmail.com"; // Cambia esto a tu email

  
  void clearUserSplitData() async {
    // Mostrar diálogo de confirmación primero
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Confirmación',
            style: TextStyle(color: kGreenColor),
          ),
          content: const Text(
            '¿Estás seguro de que quieres comenzar un nuevo mes? Esto reiniciará todos tus datos.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Cerrar el diálogo sin hacer nada
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: kGreenColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Cerrar el diálogo y continuar con la acción
                Navigator.of(context).pop();

                // Obtener el usuario autenticado
                User? user = FirebaseAuth.instance.currentUser;

                if (user != null) {
                  DatabaseReference splitRef = ref
                      .child(user.uid.toString())
                      .child('split');

                  // Obtenemos los valores actuales antes de reiniciar
                  DataSnapshot snapshot = await splitRef.get();
                  if (snapshot.exists) {
                    Map<dynamic, dynamic> currentData =
                        snapshot.value as Map<dynamic, dynamic>;

                    // Obtenemos el valor del ahorro disponible y totalSavings actual
                    // Obtenemos el valor del ahorro disponible y totalSavings actual
                    double currentSavings =
                        (currentData['savings'] ?? 0)
                            .toDouble();
                    double currentTotalSavings =
                        (currentData['totalSavings'] ?? 0).toDouble();

                    double currentNeedAvailableBalance =
                        (currentData['needAvailableBalance'] ?? 0)
                            .toDouble();

                    double currentExpensesAvailableBalance =
                        (currentData['expensesAvailableBalance'] ?? 0)
                            .toDouble();
                    double currentAmount = (currentData['amount'] ?? 0).toDouble();
                            
                    // Sumamos el ahorro disponible actual al total acumulado
                    double newTotalSavings =
                        currentTotalSavings + currentSavings + 
                            currentNeedAvailableBalance +
                            currentExpensesAvailableBalance;

                    
                    // Establecemos los nuevos valores, incluyendo el totalSavings actualizado
                    splitRef
                        .set({
                          'amount': currentAmount,
                          'need': 0,
                          'expenses': 0,
                          'savings': 0,
                          'totalBalance': 0,
                          'needAvailableBalance': 0,
                          'expensesAvailableBalance': 0,
                          'savingsAvailableBalance': 0,
                          'totalSavings':
                              newTotalSavings, // Acumulamos el ahorro del mes anterior
                          'count': 1,
                          'isEFenabled': false,
                          'isCPenabled': false,
                          'isAutopayOn': false,
                          'targetEmergencyFunds': 0,
                          'collectedEmergencyFunds': 0,
                          'savingsSpendings':
                              0, // Reiniciamos los gastos del mes
                          'needSpendings': 0,
                          'expensesSpendings': 0,
                        })
                        .then((_) {
                          ToastMessage().toastMessage(
                            'Comenzando un nuevo mes! Ahorro acumulado: $newTotalSavings',
                            Colors.green,
                          );
                        })
                        .catchError((error) {
                          ToastMessage().toastMessage(
                            'Error al comenzar un nuevo mes!',
                            Colors.red,
                          );
                        });
                  } else {
                    // Si no hay datos existentes, inicializar con valores predeterminados
                    splitRef
                        .set({
                          'amount': 0,
                          'need': 0,
                          'expenses': 0,
                          'savings': 0,
                          'totalBalance': 0,
                          'needAvailableBalance': 0,
                          'expensesAvailableBalance': 0,
                          'savingsAvailableBalance': 0,
                          'totalSavings': 0,
                          'count': 1,
                          'isEFenabled': false,
                          'isCPenabled': false,
                          'isAutopayOn': false,
                          'targetEmergencyFunds': 0,
                          'collectedEmergencyFunds': 0,
                          'savingsSpendings': 0,
                          'needSpendings': 0,
                          'expensesSpendings': 0,
                        })
                        .then((_) {
                          ToastMessage().toastMessage(
                            'Comenzando un nuevo mes!',
                            Colors.green,
                          );
                        })
                        .catchError((error) {
                          ToastMessage().toastMessage(
                            'Error al comenzar un nuevo mes!',
                            Colors.red,
                          );
                        });
                  }
                } else {
                  print("No hay usuario autenticado.");
                }
              },
              child: const Text('OK', style: TextStyle(color: kGreenColor)),
            ),
          ],
        );
      },
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ref.child(user.uid.toString()).onValue,
      builder: ((context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.snapshot.value == null ||
              snapshot.data.snapshot.value == "") {
            return SafeArea(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        NullErrorMessage(message: 'Algo salió mal!'),
                      ],
                    ),
                  );
                },
              ),
            );
          } else {
            Map<dynamic, dynamic> map = snapshot.data.snapshot.value;
            
            // Verificar si el usuario actual es el administrador
            bool isAdmin = user.email == adminEmail;
            
            return Scaffold(
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return OrientationBuilder(
                      builder: (BuildContext context, Orientation orientation) {
                        return SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: constraints.maxHeight * 0.03),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Perfil',
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    
                                    // Mostrar un badge pequeño si eres admin
                                    if (isAdmin)
                                      const Icon(
                                        Icons.admin_panel_settings,
                                        color: Colors.amber,
                                      ),
                                  ],
                                ),
                                
                                // Código existente sin cambios...
                                SizedBox(height: constraints.maxHeight * 0.03),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      height:
                                          orientation == Orientation.portrait
                                              ? constraints.maxHeight * 0.2
                                              : constraints.maxHeight * 0.4,
                                      width:
                                          orientation == Orientation.portrait
                                              ? constraints.maxHeight * 0.2
                                              : constraints.maxHeight * 0.4,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 4,
                                          color: Theme.of(context).cardColor,
                                        ),
                                        shape: BoxShape.circle,
                                        color: Theme.of(context).canvasColor,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        child:
                                            map['profilePic'].toString() == ""
                                                ? const Icon(
                                                  Icons.person,
                                                  size: 90,
                                                  color: kGrayTextC,
                                                )
                                                : Image.network(
                                                  map['profilePic'].toString(),
                                                  fit: BoxFit.cover,
                                                ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: constraints.maxHeight * 0.03),
                                ProfileTab(
                                  constraints: constraints,
                                  title: 'Nombre', 
                                  iconName: Icons.person,
                                  titleValue: map['fullName'],
                                ),
                                ProfileTab(
                                  constraints: constraints,
                                  title: 'Telefono',
                                  iconName: Icons.call,
                                  titleValue: map['phoneNumber'],
                                ),
                                ProfileTab(
                                  constraints: constraints,
                                  title: 'Número de cuenta',
                                  iconName: Icons.account_balance,
                                  titleValue: map['bankAccNumber'],
                                ),
                                ProfileTab(
                                  constraints: constraints,
                                  title: 'DNI',
                                  iconName: Icons.person,
                                  titleValue: map['kyc'],
                                ),
                                ProfileTab(
                                  constraints: constraints,
                                  title: 'Edad',
                                  iconName: Icons.person,
                                  titleValue: map['age'],
                                ),
                                ProfileTab(
                                  constraints: constraints,
                                  title: 'Rango de ingresos',
                                  iconName: Icons.attach_money,
                                  titleValue: map['incomeRange'],
                                ),
                                SizedBox(height: constraints.maxHeight * 0.01),
                                Row(
                                  children: [
                                    const Text(
                                      'Modo Oscuro',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    const Spacer(),
                                    themeSwitch(context),
                                  ],
                                ),
                                
                                SizedBox(height: constraints.maxHeight * 0.04),
                                
                                // Botón de administrador - solo visible para ti
                                if (isAdmin)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 15),
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                                      label: const Text(
                                        'Crear Usuario (Admin)',
                                        style: TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber[800],
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                      ),
                                      onPressed: () {
                                        _showCreateUserDialog(context);
                                      },
                                    ),
                                  ),
                                
                                // Botones existentes sin cambios...
                                TButton(
                                  constraints: constraints,
                                  btnColor: Theme.of(context).primaryColor,
                                  btnText: 'Salir',
                                  onPressed: () {
                                    FirebaseAuth.instance.signOut();
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const LoginScreen(),
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: constraints.maxHeight * 0.03),
                                TButton(
                                  constraints: constraints,
                                  btnColor: Theme.of(context).primaryColor,
                                  btnText: 'Iniciar nuevo Mes',
                                  onPressed: () {
                                    clearUserSplitData();
                                  },
                                ),

                                SizedBox(height: constraints.maxHeight * 0.06),
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
      }),
    );
  }

  // Método para mostrar diálogo de creación de usuario
  void _showCreateUserDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController fullNameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController accountNumberController = TextEditingController();
    final TextEditingController dniController = TextEditingController();
    final TextEditingController ageController = TextEditingController();
    final TextEditingController incomeController = TextEditingController();
    
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Crear Nuevo Usuario',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          hint: 'Correo electrónico',
                          iconName: Icons.email,
                          obscureText: false,
                          controller: emailController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Ingrese un correo';
                            } else if (!RegExp(
                              r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
                            ).hasMatch(value)) {
                              return 'Ingrese un correo válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          hint: 'Contraseña',
                          iconName: Icons.lock,
                          obscureText: true,
                          controller: passwordController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Ingrese una contraseña';
                            } else if (value.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          hint: 'Nombre completo',
                          iconName: Icons.person,
                          obscureText: false,
                          controller: fullNameController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Ingrese un nombre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          hint: 'Teléfono',
                          iconName: Icons.phone,
                          obscureText: false,
                          controller: phoneController,
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          hint: 'Número de cuenta',
                          iconName: Icons.account_balance,
                          obscureText: false,
                          controller: accountNumberController,
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          hint: 'DNI',
                          iconName: Icons.badge,
                          obscureText: false,
                          controller: dniController,
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          hint: 'Edad',
                          iconName: Icons.cake,
                          obscureText: false,
                          controller: ageController,
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          hint: 'Rango de ingresos',
                          iconName: Icons.money,
                          obscureText: false,
                          controller: incomeController,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGreenColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (formKey.currentState!.validate()) {
                                      setState(() {
                                        isLoading = true;
                                      });
                                      
                                      try {
                                        // Guardar usuario actual (admin)
                                        final currentAdmin = FirebaseAuth.instance.currentUser;
                                        
                                        // Crear usuario nuevo
                                        UserCredential userCredential = 
                                            await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                              email: emailController.text.trim(),
                                              password: passwordController.text.trim(),
                                            );
                                        
                                        // Crear estructura de datos exactamente como pediste
                                        await ref.child(userCredential.user!.uid).set({
                                          "age": ageController.text,
                                          "bankAccNumber": accountNumberController.text,
                                          "email": emailController.text.trim(),
                                          "fullName": fullNameController.text,
                                          "incomeRange": incomeController.text,
                                          "kyc": dniController.text,
                                          "phoneNumber": phoneController.text,
                                          "profilePic": "",
                                          "split": {
                                            "amount": 0,
                                            "collectedEmergencyFunds": 0,
                                            "count": 1,
                                            "expenses": 0,
                                            "expensesAvailableBalance": 0,
                                            "isAutopayOn": false,
                                            "isCPenabled": false,
                                            "isEFenabled": false,
                                            "need": 0,
                                            "needAvailableBalance": 0,
                                            "savings": 0,
                                            "targetEmergencyFunds": 0,
                                            "totalBalance": 0,
                                            "totalSavings": 0
                                          },
                                          "uid": userCredential.user!.uid
                                        });
                                        
                                        // Volver a iniciar sesión como admin
                                        if (currentAdmin != null) {
                                          await FirebaseAuth.instance.signInWithEmailAndPassword(
                                            email: adminEmail,
                                            password: passwordController.text,
                                          );
                                        }
                                        
                                        if (mounted) {
                                          ToastMessage().toastMessage(
                                            'Usuario creado exitosamente', 
                                            Colors.green
                                          );
                                          Navigator.of(context).pop();
                                        }
                                      } catch (error) {
                                        ToastMessage().toastMessage(
                                          'Error: ${error.toString()}',
                                          Colors.red
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            isLoading = false;
                                          });
                                        }
                                      }
                                    }
                                  },
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Crear Usuario',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  // Método existente sin cambios
  FlutterSwitch themeSwitch(BuildContext context) {
    final switchThemeIns = Provider.of<ThemeSwitch>(context);
    return FlutterSwitch(
      width: 50,
      height: 30,
      padding: 0,
      activeToggleColor: kDarkCardC,
      inactiveToggleColor: Theme.of(context).primaryColor,
      activeSwitchBorder: Border.all(color: kDarkGreenBackC, width: 4),
      inactiveSwitchBorder: Border.all(color: kTextFieldBorderC, width: 4),
      activeColor: kDarkGreenColor,
      inactiveColor: kTextFieldColor,
      activeIcon: Icon(
        Icons.nightlight_round,
        color: Theme.of(context).primaryColor,
      ),
      inactiveIcon: const Icon(Icons.wb_sunny, color: kTextFieldColor),
      value: switchThemeIns.isDarkMode,
      onToggle: (value) {
        final provider = Provider.of<ThemeSwitch>(context, listen: false);
        provider.switchTheme(value);
      },
    );
  }
}