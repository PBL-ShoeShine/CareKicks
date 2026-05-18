import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../../../../core/widgets/custom_scaffold.dart';
import '../controllers/shop_profile_controller.dart';
import '../models/shop_profile_model.dart';

class ProfilTokoPage extends StatefulWidget {
  final String token;

  const ProfilTokoPage({super.key, required this.token});

  @override
  State<ProfilTokoPage> createState() => _ProfilTokoPageState();
}

class _ProfilTokoPageState extends State<ProfilTokoPage> {
  final _formKey = GlobalKey<FormState>();
  late ShopProfileController _controller;

  final _namaController = TextEditingController();
  final _deskController = TextEditingController();
  final _alamatController = TextEditingController();
  final _emailController = TextEditingController();
  final _waController = TextEditingController();
  final _spesialisasiController = TextEditingController();
  final _tglBerdiriController = TextEditingController();

  File? _selectedPhoto;
  double? _latValue;
  double? _longValue;
  DateTime? _selectedDate;
  bool _isFormInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = ShopProfileController();
    _controller.fetchProfile(widget.token);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskController.dispose();
    _alamatController.dispose();
    _emailController.dispose();
    _waController.dispose();
    _spesialisasiController.dispose();
    _tglBerdiriController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedPhoto = File(image.path);
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 5, now.month, now.day),
      firstDate: DateTime(1950),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _tglBerdiriController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickLocation() async {
    final initial = LatLng(_latValue ?? -6.200000, _longValue ?? 106.816666);

    final picked = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        LatLng? selected = _latValue != null && _longValue != null
            ? LatLng(_latValue!, _longValue!)
            : null;

        return StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.82,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Text(
                    'Pilih Lokasi GPS',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: selected ?? initial,
                          initialZoom: 15,
                          onTap: (tapPosition, point) {
                            setState(() => selected = point);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'carekicks',
                          ),
                          if (selected != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: selected!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: AppColors.primaryDark,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          selected == null
                              ? 'Tap peta untuk memilih lokasi'
                              : 'Lat ${selected!.latitude.toStringAsFixed(5)}, Long ${selected!.longitude.toStringAsFixed(5)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: selected == null
                                ? null
                                : () => Navigator.pop(context, selected),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Gunakan Lokasi',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _latValue = picked.latitude;
        _longValue = picked.longitude;
      });
    }
  }

  void _syncFormWithProfile(ShopProfileModel profile, {bool force = false}) {
    if (_isFormInitialized && !force) return;

    _namaController.text = profile.nmToko ?? '';
    _deskController.text = profile.deskToko ?? '';
    _alamatController.text = profile.alamatToko ?? '';
    _emailController.text = profile.emailToko ?? '';
    _waController.text = profile.waToko ?? '';
    _spesialisasiController.text = profile.spesialisasi ?? '';
    _selectedDate = profile.tglBerdiri;
    _tglBerdiriController.text = profile.tglBerdiriFormatted ?? '';
    _latValue = profile.latToko;
    _longValue = profile.longToko;
    _isFormInitialized = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ShopProfileModel(
      nmToko: _namaController.text.trim(),
      deskToko: _deskController.text.trim(),
      alamatToko: _alamatController.text.trim(),
      latToko: _latValue,
      longToko: _longValue,
      spesialisasi: _spesialisasiController.text.trim(),
      tglBerdiri: _selectedDate,
      emailToko: _emailController.text.trim(),
      waToko: _waController.text.trim(),
    );

    final success = await _controller.updateProfile(
      token: widget.token,
      profile: profile,
      fotoToko: _selectedPhoto,
    );

    if (!mounted) return;

    if (success) {
      _selectedPhoto = null;
      if (_controller.profile != null) {
        _syncFormWithProfile(_controller.profile!, force: true);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil toko berhasil diperbarui'),
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
        title: 'Profil Toko',
        showBackButton: true,
      ),
      backgroundColor: Colors.white,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.errorMessage != null && _controller.profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_controller.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _controller.fetchProfile(widget.token),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final profile = _controller.profile;
          if (profile != null) {
            _syncFormWithProfile(profile);
          }

          final photoProvider = _buildPhotoProvider(profile);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.lightBlue,
                              backgroundImage: photoProvider,
                              child: photoProvider == null
                                  ? const Icon(
                                      Icons.storefront,
                                      size: 40,
                                      color: AppColors.primaryBlue,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _pickPhoto,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryDark,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ubah Foto Profil',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _label('Nama Toko'),
                  _buildField(
                    controller: _namaController,
                    hint: 'Contoh: Bengkel Sepatu',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama toko wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _label('Deskripsi Toko'),
                  _buildField(
                    controller: _deskController,
                    hint: 'Tuliskan deskripsi toko',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _label('Alamat Lengkap'),
                  _buildField(
                    controller: _alamatController,
                    hint: 'Alamat lengkap toko',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _label('Lokasi GPS'),
                  _buildLocationCard(),
                  const SizedBox(height: 16),
                  _label('Email Toko'),
                  _buildField(
                    controller: _emailController,
                    hint: 'contoh@email.com',
                    keyboardType: TextInputType.emailAddress,
                    enabled: false,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      if (!value.contains('@')) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  const SizedBox(height: 16),
                  _label('WhatsApp Bisnis'),
                  _buildField(
                    controller: _waController,
                    hint: '08xxxxxxxxxx',
                    keyboardType: TextInputType.phone,
                    enabled: false,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  const SizedBox(height: 16),
                  _label('Spesialisasi'),
                  _buildField(
                    controller: _spesialisasiController,
                    hint: 'Misal: Sneakers, Sepatu Kulit',
                  ),
                  const SizedBox(height: 16),
                  _label('Tanggal Berdiri'),
                  _buildField(
                    controller: _tglBerdiriController,
                    hint: 'Pilih tanggal',
                    readOnly: true,
                    onTap: _pickDate,
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
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
                              'Simpan Perubahan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  ImageProvider? _buildPhotoProvider(ShopProfileModel? profile) {
    if (_selectedPhoto != null) {
      return FileImage(_selectedPhoto!);
    }
    final fotoUrl = profile?.fotoToko;
    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      return NetworkImage(fotoUrl);
    }
    return null;
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryDark,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool readOnly = false,
    bool enabled = true,
    VoidCallback? onTap,
    Widget? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      enabled: enabled,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue),
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    final hasLocation = _latValue != null && _longValue != null;
    final center = hasLocation
        ? LatLng(_latValue!, _longValue!)
        : const LatLng(-6.200000, 106.816666);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 160,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'carekicks',
                ),
                if (hasLocation)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 32,
                        height: 32,
                        child: const Icon(
                          Icons.location_pin,
                          color: AppColors.primaryDark,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          hasLocation
              ? 'Lat ${_latValue!.toStringAsFixed(5)}, Long ${_longValue!.toStringAsFixed(5)}'
              : 'Lokasi belum dipilih',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickLocation,
          icon: const Icon(Icons.map_outlined),
          label: const Text('Pilih Lokasi GPS'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
