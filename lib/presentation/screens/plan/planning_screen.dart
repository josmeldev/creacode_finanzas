import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// Definir AppColors ya que no está disponible
class AppColors {
  static const Color primary = Colors.blue;
  static const Color secondary = Color(0xFF6200EE);
  static const Color accent = Color(0xFF03DAC6);
  static const Color background = Color(0xFFF5F5F5);
  static const Color expenseColor = Colors.redAccent;
  static const Color savingsColor = Colors.greenAccent;
  static const Color needColor = Colors.orangeAccent;
  static const Color incomeColor = Colors.blueAccent;
}

class PlanningScreeen extends StatefulWidget {
  const PlanningScreeen({super.key});

  @override
  State<PlanningScreeen> createState() => _PlanningScreeenState();
}

class _PlanningScreeenState extends State<PlanningScreeen>
    with SingleTickerProviderStateMixin {
  final DatabaseReference ref = FirebaseDatabase.instance.ref().child('Users');
  final user = FirebaseAuth.instance.currentUser!;
  late TabController _tabController;

  String selectedDateRange = 'Semana';
  List<String> dateRangeOptions = ['Semana', 'Mes', 'Año'];
  List<double> _projectedSavings = [0, 0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavingsProjection();
  }

  void _loadSavingsProjection() {
  final userId = user.uid;
  
  ref.child(userId).child('split/totalSavings')
    .get()
    .then((DataSnapshot snapshot) {
      if (snapshot.exists && snapshot.value != null) {
        double totalSavings = double.parse(snapshot.value.toString());
        
        // Calcular proyecciones (mueve aquí la lógica de proyección)
        // Primero obtén los promedios de las transacciones
        _calculateAndUpdateProjections(totalSavings);
      }
    });
}

void _calculateAndUpdateProjections(double totalSavings) {
  // Obtén las transacciones primero
  ref.child(user.uid).child('split/allTransactions').get().then((snapshot) {
    if (snapshot.exists && snapshot.value != null) {
      Map<dynamic, dynamic> allTransactions = Map<dynamic, dynamic>.from(
        snapshot.value as Map,
      );
      
      List<TransactionData> transactions = _processTransactionsForAnalysis(allTransactions);
      
      // Calcula promedios como antes
      double totalIncome = 0;
      double totalExpenses = 0;
      int incomeCount = 0;
      int expenseCount = 0;
      
      for (var transaction in transactions) {
        if (transaction.amount >= 0) {
          totalIncome += transaction.amount;
          incomeCount++;
        } else {
          totalExpenses += transaction.amount.abs();
          expenseCount++;
        }
      }
      
      double avgIncome = incomeCount > 0 ? totalIncome / incomeCount : 0;
      double avgExpenses = expenseCount > 0 ? totalExpenses / expenseCount : 0;
      double netSavingsPerPeriod = avgIncome - avgExpenses;
      
      // Proyectar para los próximos 6 meses
      List<double> projectedSavings = [];
      double currentSavings = totalSavings;
      
      for (int i = 0; i < 6; i++) {
        currentSavings += netSavingsPerPeriod;
        projectedSavings.add(currentSavings);
      }
      
      // Actualizar una sola vez
      setState(() {
        _projectedSavings = projectedSavings;
      });
    }
  });
}

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Financiero'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Flujo de Caja'),
            
            Tab(text: 'Tendencias'),
          ],
          indicatorColor: Colors.white,
        ),
      ),
      body: StreamBuilder(
        stream: ref.child(user.uid).child('split').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar los datos: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No hay datos disponibles'));
          }

          // Convertir los datos a un formato utilizable
          Map<dynamic, dynamic> splitData = Map<dynamic, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          // Extraer las transacciones
          Map<dynamic, dynamic> allTransactions =
              splitData.containsKey('allTransactions')
                  ? Map<dynamic, dynamic>.from(
                    splitData['allTransactions'] as Map,
                  )
                  : {};

          // Procesar transacciones para análisis
          List<TransactionData> transactionsList =
              _processTransactionsForAnalysis(allTransactions);

          return TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: Flujo de Caja
              _buildCashFlowTab(context, splitData, transactionsList),
              // TAB 3: Tendencias
              _buildTrendsTab(context, splitData, transactionsList),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCashFlowTab(
    BuildContext context,
    Map<dynamic, dynamic> splitData,
    List<TransactionData> transactions,
  ) {
    // Calcular ingresos y gastos por fecha
    final Map<DateTime, double> incomeByDate = {};
    final Map<DateTime, double> expensesByDate = {};

    for (var transaction in transactions) {
      // Normalizar la fecha (solo día, sin hora)
      final normalizedDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      if (transaction.amount >= 0) {
        incomeByDate[normalizedDate] =
            (incomeByDate[normalizedDate] ?? 0) + transaction.amount;
      } else {
        expensesByDate[normalizedDate] =
            (expensesByDate[normalizedDate] ?? 0) + transaction.amount.abs();
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(context, splitData, transactions),
          const SizedBox(height: 20),


          
        ],
      ),
    );
  }



  Widget _buildTrendsTab(
    BuildContext context,
    Map<dynamic, dynamic> splitData,
    List<TransactionData> transactions,
  ) {
    

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Balance de Ahorro',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _buildSavingsBalanceCard(splitData),

          const SizedBox(height: 20),
          const Text(
            'Proyección a Futuro',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _buildFutureProjectionChart(transactions),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    Map<dynamic, dynamic> splitData,
    List<TransactionData> transactions,
  ) {
    double totalBalance = (splitData['amount'] ?? 0).toDouble();
    double expenses = (splitData['expensesSpendings'] ?? 0).toDouble();
    double needs = (splitData['needSpendings'] ?? 0).toDouble();
    double savings = (splitData['savingsSpendings'] ?? 0).toDouble();

    // Calcular tendencias por mes
    Map<int, double> incomeByMonth = {};
    Map<int, double> expensesByMonth = {};

    for (var transaction in transactions) {
      // Clave del mes (Año-Mes)
      final monthKey = transaction.date.month;

      if (transaction.amount >= 0) {
        incomeByMonth[monthKey] =
            (incomeByMonth[monthKey] ?? 0) + transaction.amount;
      } else {
        expensesByMonth[monthKey] =
            (expensesByMonth[monthKey] ?? 0) + transaction.amount.abs();
      }
    }

    return Container(
  width: double.infinity,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const Text(
        'Balance total acumulado',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      Text(
        '\$${totalBalance.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
      
      const SizedBox(height: 20),
          const Text(
            'Proporción de Presupuesto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _buildBudgetProportionChart(splitData),

          const SizedBox(height: 20),
           const Text(
            'Tendencia Mensual',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 300,
            child: _buildMonthlyTrendChart(incomeByMonth, expensesByMonth),
          ),

          const SizedBox(height: 20),
    ],
  ),
);

  }

  

  Widget _buildCashFlowChart(List<TransactionData> transactions) {
    // Filtrar por rango de fechas seleccionado
    DateTime startDate;
    final now = DateTime.now();

    switch (selectedDateRange) {
      case 'Semana':
        startDate = DateTime(now.year, now.month, now.day - 7);
        break;
      case 'Mes':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'Año':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day - 7);
    }

    // Filtrar transacciones por el rango de fechas
    final filteredTransactions =
        transactions
            .where((transaction) => transaction.date.isAfter(startDate))
            .toList();

    // Agrupar por fecha
    Map<DateTime, double> dailyBalances = {};

    // Inicializar días en el rango
    for (int i = 0; i <= now.difference(startDate).inDays; i++) {
      final date = DateTime(startDate.year, startDate.month, startDate.day + i);
      dailyBalances[date] = 0;
    }

    // Sumar transacciones por día
    for (var transaction in filteredTransactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      dailyBalances[date] = (dailyBalances[date] ?? 0) + transaction.amount;
    }

    // Convertir a lista ordenada por fecha
    List<MapEntry<DateTime, double>> sortedEntries =
        dailyBalances.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < sortedEntries.length) {
                  final date = sortedEntries[value.toInt()].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd/MM').format(date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: sortedEntries.length - 1.0,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(sortedEntries.length, (index) {
              return FlSpot(index.toDouble(), sortedEntries[index].value);
            }),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBudgetProportionChart(Map<dynamic, dynamic> splitData) {
    double expenses = (splitData['expensesSpendings'] ?? 0).toDouble();
    double expensesTotal = (splitData['expenses'] ?? 0).toDouble();
    double needs = (splitData['needSpendings'] ?? 0).toDouble();
    double needsTotal = (splitData['need'] ?? 0).toDouble();
    double savings = (splitData['savingsSpendings'] ?? 0).toDouble();
    double savingsTotal = (splitData['savings'] ?? 0).toDouble();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildBudgetBar(
              'Gastos',
              expenses,
              expensesTotal,
              AppColors.expenseColor,
            ),
            const SizedBox(height: 15),
            _buildBudgetBar(
              'Necesidades',
              needs,
              needsTotal,
              AppColors.needColor,
            ),
            const SizedBox(height: 15),
            _buildBudgetBar(
              'Ahorros',
              savings,
              savingsTotal,
              AppColors.savingsColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetBar(
    String category,
    double spent,
    double total,
    Color color,
  ) {
    final percentage = total > 0 ? (spent / total * 100) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(category),
            Text(
              '\$${spent.toStringAsFixed(2)} / \$${total.toStringAsFixed(2)}',
            ),
          ],
        ),
        const SizedBox(height: 5),
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 10,
                  width:
                      constraints.maxWidth * (total > 0 ? (spent / total) : 0),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '${percentage.toStringAsFixed(1)}% utilizado',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrendChart(
    Map<int, double> incomeByMonth,
    Map<int, double> expensesByMonth,
  ) {
    // Crear una lista de todos los meses disponibles
    Set<int> allMonths = {...incomeByMonth.keys, ...expensesByMonth.keys};
    List<int> sortedMonths = allMonths.toList()..sort();

    if (sortedMonths.isEmpty) {
      return const Center(
        child: Text('No hay datos suficientes para mostrar tendencias'),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            [
              incomeByMonth.values.isEmpty
                  ? 0
                  : incomeByMonth.values.reduce((a, b) => a > b ? a : b),
              expensesByMonth.values.isEmpty
                  ? 0
                  : expensesByMonth.values.reduce((a, b) => a > b ? a : b),
            ].reduce((a, b) => a > b ? a : b) *
            1.2,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedMonths.length) {
                  final month = sortedMonths[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _getMonthName(month),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(sortedMonths.length, (index) {
          final month = sortedMonths[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: incomeByMonth[month] ?? 0,
                color: AppColors.incomeColor,
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              BarChartRodData(
                toY: expensesByMonth[month] ?? 0,
                color: AppColors.expenseColor,
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final month = sortedMonths[group.x.toInt()];
              final value = rod.toY;
              final String type = rodIndex == 0 ? 'Ingresos' : 'Gastos';
              return BarTooltipItem(
                '$type: \$${value.toStringAsFixed(2)}',
                const TextStyle(color: Colors.black),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsBalanceCard(Map<dynamic, dynamic> splitData) {
    double savings = (splitData['savings'] ?? 0).toDouble();
    double totalSavings = (splitData['totalSavings'] ?? 0).toDouble();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text(
                  'Ahorros Actuales',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${savings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const VerticalDivider(
              color: Colors.grey,
              thickness: 1,
              width: 30,
              indent: 10,
              endIndent: 10,
            ),
            Column(
              children: [
                const Text(
                  'Ahorros Totales',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${totalSavings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

Widget _buildFutureProjectionChart(List<TransactionData> transactions) {
  // Meses para mostrar en el eje X
  final List<String> months = ['1 Mes', '2 Mes', '3 Mes', '4 Mes', '5 Mes', '6 Mes'];
  
  // Encontrar el valor máximo para el límite superior
  double maxValue = 0;
  if (_projectedSavings.isNotEmpty) {
    maxValue = _projectedSavings.reduce((a, b) => a > b ? a : b);
  }
  
  return SizedBox(
    height: 200,
    child: _projectedSavings.any((value) => value > 0)
      ? LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              // Solo mostrar líneas verticales en enteros
              checkToShowVerticalLine: (value) => value.toInt() == value,
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              // Configuración para el eje X inferior (visible)
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    // Solo mostrar enteros
                    if (value.toInt() == value && value >= 0 && value < months.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          (value + 1).toInt().toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              // Configuración para el eje Y izquierdo (visible)
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    // Solo mostrar números enteros
                    if (value == value.toInt()) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          '\$${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              // Configuración para el eje X superior (oculto)
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              // Configuración para el eje Y derecho (oculto)
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            minX: 0,
            maxX: 5,
            minY: 0,
            maxY: maxValue * 1.2, // Espacio adicional arriba
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  _projectedSavings.length,
                  (index) => FlSpot(index.toDouble(), _projectedSavings[index]),
                ),
                isCurved: true,
                color: AppColors.savingsColor,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.savingsColor.withOpacity(0.2),
                ),
              ),
            ],
          ),
        )
      : const Center(child: Text("Cargando proyecciones..."))
  );
}

List<TransactionData> _processTransactionsForAnalysis(
    Map<dynamic, dynamic> transactions,
  ) {
    List<TransactionData> result = [];

    transactions.forEach((key, value) {
      String amountStr = value['amount'] ?? '0';
      // Determinar si es ingreso o gasto basado en el signo
      bool isIncome = amountStr.contains('+');
      // Remover el signo y convertir a double
      double amount =
          double.tryParse(
            amountStr.replaceAll('+', '').replaceAll('-', '').trim(),
          ) ??
          0;
      // Aplicar signo correcto
      if (!isIncome) amount = -amount;

      DateTime date = DateTime.parse(
        value['paymentDateTime'] ?? DateTime.now().toString(),
      );

      result.add(
        TransactionData(
          id: key,
          name: value['name'] ?? 'Sin nombre',
          amount: amount,
          date: date,
          description: value['shortDescription'] ?? '',
        ),
      );
    });

    // Ordenar por fecha, más recientes primero
    result.sort((a, b) => b.date.compareTo(a.date));

    return result;
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    if (month >= 1 && month <= 12) {
      return monthNames[month - 1];
    } else {
      return '';
    }
  }
}

class TransactionData {
  final String id;
  final String name;
  final double amount;
  final DateTime date;
  final String description;

  TransactionData({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.description,
  });
}
