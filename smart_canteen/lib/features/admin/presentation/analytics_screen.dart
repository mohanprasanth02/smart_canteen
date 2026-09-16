import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../data/admin_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  List<dynamic> _dailySales = [];
  List<dynamic> _peakHours = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = ref.read(adminRepositoryProvider);
      final daily = await repo.getDailyAnalytics();
      final hours = await repo.getPeakHours();
      setState(() {
        _dailySales = daily;
        _peakHours = hours;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryNeon))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Daily Sales Line Chart
                  const Text(
                    'Weekly Sales Curve',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: GlassmorphicCard(
                      padding: const EdgeInsets.only(top: 20, right: 20, left: 10, bottom: 10),
                      child: _dailySales.isEmpty
                          ? const Center(child: Text('No sales data available'))
                          : LineChart(
                              LineChartData(
                                gridData: FlGridData(show: false),
                                titlesData: FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: List.generate(_dailySales.length, (idx) {
                                      final val = _dailySales[idx]['revenue'] as double;
                                      return FlSpot(idx.toDouble(), val);
                                    }),
                                    isCurved: true,
                                    color: AppColors.primaryNeon,
                                    barWidth: 4,
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: AppColors.primaryNeon.withOpacity(0.15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Peak Canteen Order Hours Bar Chart
                  const Text(
                    'Peak Ordering Hours',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: GlassmorphicCard(
                      padding: const EdgeInsets.all(16),
                      child: _peakHours.isEmpty
                          ? const Center(child: Text('No ordering hours recorded'))
                          : BarChart(
                              BarChartData(
                                gridData: FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                barGroups: List.generate(_peakHours.length, (idx) {
                                  final hr = _peakHours[idx];
                                  return BarChartGroupData(
                                    x: hr['hour'] as int,
                                    barRods: [
                                      BarChartRodData(
                                        toY: (hr['orders'] as int).toDouble(),
                                        color: AppColors.warning,
                                        width: 12,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
