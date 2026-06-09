import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:carekicks/core/constants/app_colors.dart';
import '../controllers/customer_profile_controller.dart';
import '../controllers/tambah_alamat_controller.dart';
import '../services/tambah_alamat_service.dart';

class TambahAlamatView extends StatefulWidget {
  final String token;
  final CustomerProfileController profileController;
  final Map<String, dynamic>? existing;

  const TambahAlamatView({
    super.key,
    required this.token,
    required this.profileController,
    this.existing,
  });

  @override
  State<TambahAlamatView> createState() => _TambahAlamatViewState();
}

class _TambahAlamatViewState extends State<TambahAlamatView> {
  late final TambahAlamatController _c;
  bool get _isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _c = TambahAlamatController();
    _c.addListener(() {
      if (mounted) setState(() {});
    });

    if (_isEditMode) {
      _c.initFromExisting(widget.existing!);
    } else {
      // Init GPS saat halaman dibuka
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _c.useCurrentLocation();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // ── SIMPAN ────────────────────────────────────────────────────────────────
  Future<void> _simpan() async {
    FocusScope.of(context).unfocus();

    if (_c.recipientCtrl.text.trim().isEmpty) {
      return _showSnack('Nama penerima wajib diisi!', isError: true);
    }
    if (!_c.isPhoneValid) {
      return _showSnack('Nomor telepon tidak valid!', isError: true);
    }
    if (_c.streetCtrl.text.trim().isEmpty) {
      return _showSnack('Nama jalan wajib diisi!', isError: true);
    }

    setState(() => _c.isSaving = true);

    bool ok;
    if (_isEditMode) {
      ok = await widget.profileController.updateAlamat(
        token: widget.token,
        idAddress: widget.existing!['id_address'],
        recipientName: _c.recipientCtrl.text.trim(),
        phoneNumber: _c.rawPhone,
        fullAddress: _c.fullAddressForSave,
        addressLabel: _c.selectedLabel,
        isDefault: _c.isDefault,
        latitude: _c.pinLocation.latitude,
        longitude: _c.pinLocation.longitude,
      );
    } else {
      ok = await widget.profileController.addAlamat(
        token: widget.token,
        recipientName: _c.recipientCtrl.text.trim(),
        phoneNumber: _c.rawPhone,
        fullAddress: _c.fullAddressForSave,
        addressLabel: _c.selectedLabel,
        isDefault: _c.isDefault,
        latitude: _c.pinLocation.latitude,
        longitude: _c.pinLocation.longitude,
      );
    }

    if (mounted) setState(() => _c.isSaving = false);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'Alamat tersimpan!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context, true);
    } else if (!ok) {
      _showSnack(
        widget.profileController.errorMessage.isNotEmpty
            ? widget.profileController.errorMessage
            : 'Gagal menyimpan alamat.',
        isError: true,
      );
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── PILIH WILAYAH manual (cascade) ───────────────────────────────────────
  Future<void> _pilihWilayah() async {
    final prov = await _pushWilayahPage('Provinsi', WilayahService.getProvinsi);
    if (prov == null || !mounted) return;
    _c.provinsi = prov;
    _c.kabupaten = _c.kecamatan = _c.kelurahan = null;
    setState(() {});

    final kab = await _pushWilayahPage(
      'Kabupaten / Kota',
      () => WilayahService.getKabupaten(prov.id),
    );
    if (kab == null || !mounted) return;
    _c.kabupaten = kab;
    _c.kecamatan = _c.kelurahan = null;
    setState(() {});

    final kec = await _pushWilayahPage(
      'Kecamatan',
      () => WilayahService.getKecamatan(kab.id),
    );
    if (kec == null || !mounted) return;
    _c.kecamatan = kec;
    _c.kelurahan = null;
    setState(() {});

    final kel = await _pushWilayahPage(
      'Kelurahan / Desa',
      () => WilayahService.getKelurahan(kec.id),
    );
    if (kel == null || !mounted) return;
    _c.kelurahan = kel;
    setState(() {});

    // ── Sinkronisasi balik: geocode nama wilayah ke koordinat peta ──
    if (_c.provinsi != null) {
      final query =
          '${_c.kelurahan?.nama ?? ''} ${_c.kecamatan?.nama ?? ''} ${_c.kabupaten?.nama ?? ''} ${_c.provinsi!.nama} Indonesia'
              .trim();
      final results = await GeocodingService.search(query);
      if (results.isNotEmpty && mounted) {
        _c.applySearchResult(results.first);
      }
    }
  }

  Future<Wilayah?> _pushWilayahPage(
    String title,
    Future<List<Wilayah>> Function() loader,
  ) {
    return Navigator.push<Wilayah>(
      context,
      MaterialPageRoute(
        builder: (_) => _PilihWilayahPage(title: title, loader: loader),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Alamat' : 'Tambah Alamat Baru',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── PETA ────────────────────────────────────────────────────
            _buildMap(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label koordinat / resolved address
                  if (_c.resolvedAddress.isNotEmpty) _resolvedAddressChip(),
                  // Search bar → buka halaman pencarian
                  _searchBar(),
                  const SizedBox(height: 12),
                  // Form Alamat
                  _sectionCard('Alamat', [
                    _wilayahTile(),
                    const SizedBox(height: 10),
                    _inputField(
                      controller: _c.streetCtrl,
                      hint: 'Nama Jalan, Gedung, No. Rumah',
                      onTap: _c.markStreetManual,
                    ),
                    const SizedBox(height: 10),
                    _inputField(
                      controller: _c.detailCtrl,
                      hint: 'Detail Lainnya (Blok / Unit No., Patokan)',
                      maxLines: 2,
                    ),
                  ]),
                  const SizedBox(height: 12),
                  // Form Penerima
                  _sectionCard('Informasi Penerima', [
                    _inputField(
                      controller: _c.recipientCtrl,
                      hint: 'Nama Lengkap',
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 10),
                    _phoneField(),
                  ]),
                  const SizedBox(height: 12),
                  // Pengaturan
                  _settingsCard(),
                  const SizedBox(height: 24),
                  // Tombol simpan
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _c.isSaving ? null : _simpan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _c.isSaving
                            ? Colors.grey
                            : AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _c.isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Simpan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── WIDGET BUILDERS ───────────────────────────────────────────────────────

  Widget _buildMap() {
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _c.mapCtrl,
            options: MapOptions(
              initialCenter: _c.pinLocation,
              initialZoom: 15,
              maxZoom: 19,
              onMapReady: () {
                _c.mapReady = true;
                _c.mapCtrl.move(_c.pinLocation, 15);
              },
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && pos.center != null) {
                  _c.pinLocation = pos.center!;
                }
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _c.onMapMoveEnd(_c.pinLocation);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.carekicks.app',
                maxNativeZoom: 19,
              ),
            ],
          ),
          // Pin di tengah
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_pin, color: AppColors.errorRed, size: 42),
                SizedBox(height: 21),
              ],
            ),
          ),
          // Tombol GPS
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _c.isLoadingLoc ? null : () => _c.useCurrentLocation(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _c.isLoadingLoc
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryBlue,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.my_location,
                              color: AppColors.errorRed,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Gunakan Lokasi Saat Ini',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
    );
  }

  Widget _resolvedAddressChip() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: AppColors.primaryBlue.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.location_on, color: AppColors.primaryBlue, size: 15),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _c.resolvedAddress,
            style: const TextStyle(fontSize: 11, color: AppColors.primaryDark),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_c.isGeocoding)
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.primaryBlue,
            ),
          ),
      ],
    ),
  );

  Widget _searchBar() => GestureDetector(
    onTap: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const _CariLokasiPage()),
      );
      if (result != null && mounted) {
        _c.applySearchResult(result as Map<String, dynamic>);
      }
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey, size: 20),
          const SizedBox(width: 10),
          Text(
            'Cari alamatmu di sini',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    ),
  );

  Widget _wilayahTile() {
    final hasValue = _c.provinsi != null;
    return GestureDetector(
      onTap: _pilihWilayah,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue
                    ? _c.wilayahText
                    : 'Provinsi, Kota, Kecamatan, Kelurahan',
                style: TextStyle(
                  fontSize: 14,
                  color: hasValue
                      ? AppColors.primaryDark
                      : Colors.grey.shade400,
                ),
                maxLines: 2,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      children: [
        SwitchListTile(
          title: const Text(
            'Atur sebagai Alamat Utama',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          value: _c.isDefault,
          activeColor: AppColors.primaryBlue,
          onChanged: (v) => setState(() => _c.isDefault = v),
        ),
        Divider(color: Colors.grey.shade200, height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Tandai Sebagai:',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(width: 16),
              _labelChip('Rumah', Icons.home_outlined),
              const SizedBox(width: 8),
              _labelChip('Kantor', Icons.business_outlined),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _sectionCard(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    int maxLines = 1,
    VoidCallback? onTap,
  }) => TextField(
    controller: controller,
    maxLines: maxLines,
    onTap: onTap,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
    ),
  );

  Widget _phoneField() => StatefulBuilder(
    builder: (_, setLocal) => TextField(
      controller: _c.phoneCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-]')),
        _PhoneFormatter(),
      ],
      onChanged: (_) => setLocal(() {}),
      decoration: InputDecoration(
        hintText: '+62-812-3456-7890',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
        helperText: () {
          final digits = _c.phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.length <= 2) return null;
          return _c.isPhoneValid ? '✓ Nomor valid' : 'Nomor terlalu pendek';
        }(),
        helperStyle: TextStyle(
          color: _c.isPhoneValid ? AppColors.successGreen : Colors.orange,
          fontSize: 11,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.5,
          ),
        ),
      ),
    ),
  );

  Widget _labelChip(String label, IconData icon) {
    final sel = _c.selectedLabel == label;
    return GestureDetector(
      onTap: () => setState(() => _c.selectedLabel = sel ? null : label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: sel ? AppColors.primaryBlue : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: sel ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: sel ? Colors.white : Colors.grey.shade700,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN PENCARIAN ALAMAT
// ─────────────────────────────────────────────────────────────────────────────
class _CariLokasiPage extends StatefulWidget {
  const _CariLokasiPage();

  @override
  State<_CariLokasiPage> createState() => _CariLokasiPageState();
}

class _CariLokasiPageState extends State<_CariLokasiPage> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (q.trim().isNotEmpty) _search(q.trim());
    });
  }

  Future<void> _search(String q) async {
    setState(() => _isLoading = true);
    final results = await GeocodingService.search(q);
    if (mounted)
      setState(() {
        _results = results;
        _isLoading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Cari Lokasi',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Cari alamatmu di sini',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _results.clear());
                        },
                      ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _results.isEmpty && !_isLoading
          ? Center(
              child: Text(
                _searchCtrl.text.isEmpty
                    ? 'Ketik nama tempat atau jalan...'
                    : 'Alamat tidak ditemukan',
                style: const TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) =>
                  Divider(color: Colors.grey.shade200, height: 1),
              itemBuilder: (_, i) {
                final item = _results[i];
                return ListTile(
                  leading: const Icon(
                    Icons.location_on,
                    color: AppColors.errorRed,
                  ),
                  title: Text(
                    item['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    item['display_name'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN PILIH WILAYAH
// ─────────────────────────────────────────────────────────────────────────────
class _PilihWilayahPage extends StatefulWidget {
  final String title;
  final Future<List<Wilayah>> Function() loader;

  const _PilihWilayahPage({required this.title, required this.loader});

  @override
  State<_PilihWilayahPage> createState() => _PilihWilayahPageState();
}

class _PilihWilayahPageState extends State<_PilihWilayahPage> {
  List<Wilayah> _all = [], _filtered = [];
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.loader();
      if (mounted) {
        setState(() {
          _all = _filtered = data;
          _loading = false;
          if (data.isEmpty) _error = 'Data tidak tersedia';
        });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Gagal memuat. Periksa koneksi internet.';
        });
    }
  }

  void _filter(String q) => setState(() {
    _filtered = q.isEmpty
        ? _all
        : _all
              .where((w) => w.nama.toLowerCase().contains(q.toLowerCase()))
              .toList();
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Cari ${widget.title.toLowerCase()}...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
              child: Text(_error, style: const TextStyle(color: Colors.grey)),
            )
          : ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) =>
                  Divider(color: Colors.grey.shade100, height: 1),
              itemBuilder: (_, i) => ListTile(
                leading: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
                title: Text(
                  _filtered[i].nama,
                  style: const TextStyle(fontSize: 14),
                ),
                onTap: () => Navigator.pop(context, _filtered[i]),
              ),
            ),
    );
  }
}

// ── FORMATTER HP ─────────────────────────────────────────────────────────────
class _PhoneFormatter extends TextInputFormatter {
  static const int _maxDigits = 12;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('62')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.length > _maxDigits) digits = digits.substring(0, _maxDigits);

    final buf = StringBuffer('+62');
    for (int i = 0; i < digits.length; i++) {
      if (i % 4 == 0) buf.write('-');
      buf.write(digits[i]);
    }
    final result = buf.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
