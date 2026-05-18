import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../../../../core/widgets/custom_scaffold.dart';
import '../controllers/operating_hours_controller.dart';
import '../models/operating_hour_model.dart';

class JamOperasionalPage extends StatefulWidget {
  final String token;

  const JamOperasionalPage({super.key, required this.token});

  @override
  State<JamOperasionalPage> createState() => _JamOperasionalPageState();
}

class _JamOperasionalPageState extends State<JamOperasionalPage> {
  late OperatingHoursController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OperatingHoursController();
    _controller.fetchHours(widget.token);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickTime(int index, bool isOpenTime) async {
    final hour = _controller.hours[index];
    final initialTime = isOpenTime
        ? (hour.openTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (hour.closeTime ?? const TimeOfDay(hour: 18, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null) return;

    final openTime = isOpenTime ? picked : hour.openTime;
    final closeTime = isOpenTime ? hour.closeTime : picked;

    if (openTime != null && closeTime != null) {
      if (!_isTimeRangeValid(openTime, closeTime)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jam buka harus lebih awal dari jam tutup'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
        return;
      }
    }

    if (isOpenTime) {
      _controller.setOpenTime(index, picked);
    } else {
      _controller.setCloseTime(index, picked);
    }
  }

  Future<void> _submit() async {
    final success = await _controller.updateHours(widget.token);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam operasional berhasil diperbarui'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } else if (_controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: const CustomAppBar(
        title: 'Jam Operasional',
        showBackButton: true,
      ),
      backgroundColor: Colors.white,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.errorMessage != null && _controller.hours.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_controller.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _controller.fetchHours(widget.token),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemBuilder: (context, index) {
                    final hour = _controller.hours[index];
                    return _buildDayCard(hour, index);
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemCount: _controller.hours.length,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _controller.isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _controller.isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Simpan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDayCard(ShopOperatingHour hour, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hour.dayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: hour.isOpen,
                activeColor: AppColors.primaryDark,
                onChanged: (value) => _controller.setIsOpen(index, value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hour.isOpen)
            Row(
              children: [
                Expanded(
                  child: _buildTimeField(
                    label: 'Buka',
                    time: hour.openTime,
                    onTap: () => _pickTime(index, true),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('-', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeField(
                    label: 'Tutup',
                    time: hour.closeTime,
                    onTap: () => _pickTime(index, false),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Toko Tutup',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              _formatTime(time),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _isTimeRangeValid(TimeOfDay open, TimeOfDay close) {
    final openMinutes = open.hour * 60 + open.minute;
    final closeMinutes = close.hour * 60 + close.minute;
    return openMinutes < closeMinutes;
  }
}
