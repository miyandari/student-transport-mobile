import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme.dart';
import '../../services/api_service.dart';

class ServiceDetailsPage extends StatefulWidget {
  const ServiceDetailsPage({super.key});

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  String selectedStation = 'ایستگاه اصلی دانشگاه';

  bool isLoading = true;
  bool isSubmitting = false;
  bool isCancelling = false;

  String? errorMessage;

  TripData? trip;
  ReservationData? activeReservation;

  int seatedReserved = 0;
  int standingReserved = 0;

  static const LatLng center = LatLng(35.7219, 51.3347);

  static final List<LatLng> routePoints = [
    const LatLng(35.7219, 51.3347),
    const LatLng(35.7209, 51.3362),
    const LatLng(35.7198, 51.3376),
    const LatLng(35.7187, 51.3390),
    const LatLng(35.7175, 51.3405),
  ];

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final universityId = ApiService.currentUser?.universityId;

      if (universityId == null) {
        throw ApiException(
          'دانشگاه حساب کاربری شما مشخص نیست',
        );
      }

      final trips = await ApiService.getTrips(
        universityId: universityId,
        status: 'scheduled',
      );

      if (trips.isEmpty) {
        throw ApiException(
          'در حال حاضر سفر برنامه‌ریزی‌شده‌ای برای شما وجود ندارد',
        );
      }

      final activeTrips = trips
          .where((item) => item.isActive)
          .toList();

      if (activeTrips.isEmpty) {
        throw ApiException(
          'در حال حاضر سفر فعالی برای شما وجود ندارد',
        );
      }

      activeTrips.sort(
        (a, b) => a.plannedDepartureTime.compareTo(
          b.plannedDepartureTime,
        ),
      );

      final selectedTrip = activeTrips.first;

      final studentId = ApiService.currentUser?.studentId;

      ReservationData? studentActiveReservation;

      if (studentId != null) {
        final studentReservations =
            await ApiService.getReservations(
          tripId: selectedTrip.id,
          studentId: studentId,
          onlyActive: true,
        );

        if (studentReservations.isNotEmpty) {
          studentActiveReservation =
              studentReservations.first;
        }
      }

      final allReservations =
          await ApiService.getReservations(
        tripId: selectedTrip.id,
        onlyActive: true,
      );

      int seated = 0;
      int standing = 0;

      for (final reservation in allReservations) {
        if (reservation.isStanding) {
          standing++;
        } else {
          seated++;
        }
      }

      if (!mounted) return;

      setState(() {
        trip = selectedTrip;
        activeReservation = studentActiveReservation;
        seatedReserved = seated;
        standingReserved = standing;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  int get seatedCapacity => trip?.seatedCapacity ?? 0;

  int get standingCapacity => trip?.standingCapacity ?? 0;

  int get emptySeats {
    final value = seatedCapacity - seatedReserved;
    return value < 0 ? 0 : value;
  }

  int get emptyStanding {
    final value = standingCapacity - standingReserved;
    return value < 0 ? 0 : value;
  }

  bool get hasActiveReservation =>
      activeReservation != null &&
      (activeReservation!.status == 'active' ||
          activeReservation!.status == 'waitlisted');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات سرویس'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 52,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _loadTrip,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تلاش دوباره'),
              ),
            ],
          ),
        ),
      );
    }

    if (trip == null) {
      return const Center(
        child: Text('اطلاعات سفر پیدا نشد'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrip,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          30,
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 260,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 15.8,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'ir.hammasir.student_transport',
                      maxZoom: 19,
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          strokeWidth: 5,
                          color: HammasirTheme.primary,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: routePoints[0],
                          width: 42,
                          height: 42,
                          child: const _MapMarker(
                            icon: Icons.school_rounded,
                            color: HammasirTheme.primary,
                          ),
                        ),
                        Marker(
                          point: routePoints[2],
                          width: 42,
                          height: 42,
                          child: const _MapMarker(
                            icon: Icons.directions_bus_rounded,
                            color: Color(0xFFEF7D32),
                          ),
                        ),
                        Marker(
                          point: routePoints[4],
                          width: 42,
                          height: 42,
                          child: const _MapMarker(
                            icon: Icons.home_rounded,
                            color: Color(0xFF5B6B7A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _ServiceHeader(),
            const SizedBox(height: 16),
            _StationCard(
              selectedStation: selectedStation,
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedStation = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _CapacityCard(
              emptySeats: emptySeats,
              emptyStanding: emptyStanding,
              passengers:
                  seatedReserved + standingReserved,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.access_time_rounded,
              title: 'زمان حرکت',
              value: _formatTime(
                trip!.plannedDepartureTime,
              ),
            ),
            const _InfoRow(
              icon: Icons.location_on_outlined,
              title: 'مقصد',
              value: 'خوابگاه',
            ),
            _InfoRow(
              icon: Icons.directions_bus_outlined,
              title: 'شناسه سفر',
              value: '#${trip!.id}',
            ),
            const SizedBox(height: 18),
            _buildReservationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationSection() {
    if (hasActiveReservation) {
      return _ActiveReservationCard(
        reservation: activeReservation!,
        isCancelling: isCancelling,
        onCancel: _confirmCancelReservation,
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed:
            isSubmitting ? null : _showReservationSheet,
        style: FilledButton.styleFrom(
          backgroundColor: HammasirTheme.primary,
          padding: const EdgeInsets.symmetric(
            vertical: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'درخواست سوارشدن',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _showReservationSheet() async {
    final currentTrip = trip;

    if (currentTrip == null) return;

    final studentId =
        ApiService.currentUser?.studentId;

    if (studentId == null) {
      _showMessage(
        'حساب کاربری شما به دانشجو متصل نیست.',
        isError: true,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final canStand =
            currentTrip.allowStanding &&
            emptyStanding > 0;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              0,
              20,
              25,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'انتخاب نوع سفر',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor:
                        Color(0xFFE7F5F6),
                    child: Icon(
                      Icons.event_seat_outlined,
                      color: HammasirTheme.primary,
                    ),
                  ),
                  title: const Text('صندلی'),
                  subtitle: Text(
                    emptySeats > 0
                        ? '$emptySeats صندلی خالی'
                        : 'ظرفیت صندلی تکمیل است',
                  ),
                  trailing: const Icon(
                    Icons.chevron_left,
                  ),
                  enabled: emptySeats > 0,
                  onTap: emptySeats <= 0
                      ? null
                      : () {
                          Navigator.pop(
                            sheetContext,
                          );
                          _createReservation(
                            isStanding: false,
                          );
                        },
                ),
                const SizedBox(height: 6),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor:
                        Color(0xFFFFF1E8),
                    child: Icon(
                      Icons.accessibility_new_rounded,
                      color: Color(0xFFEF7D32),
                    ),
                  ),
                  title: const Text(
                    'سفر ایستاده',
                  ),
                  subtitle: Text(
                    !currentTrip.allowStanding
                        ? 'برای این سفر مجاز نیست'
                        : canStand
                            ? '$emptyStanding ظرفیت ایستاده'
                            : 'ظرفیت ایستاده تکمیل است',
                  ),
                  trailing: const Icon(
                    Icons.chevron_left,
                  ),
                  enabled: canStand,
                  onTap: !canStand
                      ? null
                      : () {
                          Navigator.pop(
                            sheetContext,
                          );
                          _createReservation(
                            isStanding: true,
                          );
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createReservation({
    required bool isStanding,
  }) async {
    final currentTrip = trip;
    final studentId =
        ApiService.currentUser?.studentId;

    if (currentTrip == null ||
        studentId == null) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final reservation =
          await ApiService.createReservation(
        tripId: currentTrip.id,
        studentId: studentId,
        isStanding: isStanding,
      );

      if (!mounted) return;

      await _loadTrip();

      if (!mounted) return;

      final statusText =
          reservation.status == 'waitlisted'
              ? 'در صف انتظار'
              : 'تأیید شد';

      _showMessage(
        'درخواست شما $statusText شد.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString(),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Future<void> _confirmCancelReservation() async {
    final reservation = activeReservation;

    if (reservation == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('لغو رزرو'),
          content: const Text(
            'آیا مطمئن هستید که می‌خواهید رزرو این سفر را لغو کنید؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('لغو رزرو'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _cancelReservation(reservation.id);
  }

  Future<void> _cancelReservation(
    int reservationId,
  ) async {
    setState(() {
      isCancelling = true;
    });

    try {
      await ApiService.cancelReservation(
        reservationId,
      );

      if (!mounted) return;

      await _loadTrip();

      if (!mounted) return;

      _showMessage(
        'رزرو شما با موفقیت لغو شد.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString(),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isCancelling = false;
        });
      }
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : null,
        ),
      );
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();

    final hour =
        local.hour.toString().padLeft(2, '0');
    final minute =
        local.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

class _MapMarker extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MapMarker({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black26,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 21,
      ),
    );
  }
}

class _ServiceHeader extends StatelessWidget {
  const _ServiceHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: const Color(0xFFEAF6F7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Padding(
        padding: EdgeInsets.all(17),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor:
                  HammasirTheme.primary,
              child: Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'سرویس دانشجویی',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'سفر برنامه‌ریزی‌شده',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  final String selectedStation;
  final ValueChanged<String?> onChanged;

  const _StationCard({
    required this.selectedStation,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFE3E8EA),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'ایستگاه سوارشدن',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 9),
            DropdownButtonFormField<String>(
              initialValue: selectedStation,
              decoration: InputDecoration(
                filled: true,
                fillColor:
                    const Color(0xFFF6F8F9),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(13),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'ایستگاه اصلی دانشگاه',
                  child:
                      Text('ایستگاه اصلی دانشگاه'),
                ),
                DropdownMenuItem(
                  value: 'ایستگاه دانشکده',
                  child: Text('ایستگاه دانشکده'),
                ),
                DropdownMenuItem(
                  value: 'ایستگاه خوابگاه',
                  child: Text('ایستگاه خوابگاه'),
                ),
              ],
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _CapacityCard extends StatelessWidget {
  final int emptySeats;
  final int emptyStanding;
  final int passengers;

  const _CapacityCard({
    required this.emptySeats,
    required this.emptyStanding,
    required this.passengers,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFE3E8EA),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            Expanded(
              child: _CapacityItem(
                icon:
                    Icons.event_seat_outlined,
                value: '$emptySeats',
                title: 'صندلی خالی',
              ),
            ),
            Expanded(
              child: _CapacityItem(
                icon:
                    Icons.accessibility_new_rounded,
                value: '$emptyStanding',
                title: 'ظرفیت ایستاده',
              ),
            ),
            Expanded(
              child: _CapacityItem(
                icon:
                    Icons.people_outline_rounded,
                value: '$passengers',
                title: 'رزرو',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapacityItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;

  const _CapacityItem({
    required this.icon,
    required this.value,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: HammasirTheme.primary,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: HammasirTheme.primary,
            size: 21,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveReservationCard extends StatelessWidget {
  final ReservationData reservation;
  final bool isCancelling;
  final VoidCallback onCancel;

  const _ActiveReservationCard({
    required this.reservation,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isWaitlisted =
        reservation.status == 'waitlisted';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isWaitlisted
          ? const Color(0xFFFFF7E8)
          : const Color(0xFFEAF6F7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isWaitlisted
              ? const Color(0xFFF0C36A)
              : const Color(0xFFB7E1E4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isWaitlisted
                      ? const Color(0xFFFFE7B5)
                      : const Color(0xFFD5F0F2),
                  child: Icon(
                    isWaitlisted
                        ? Icons.hourglass_top_rounded
                        : Icons.check_circle_outline_rounded,
                    color: isWaitlisted
                        ? const Color(0xFFD68A00)
                        : HammasirTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        isWaitlisted
                            ? 'در صف انتظار هستید'
                            : 'رزرو شما ثبت شده است',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        reservation.isStanding
                            ? 'نوع سفر: ایستاده'
                            : 'نوع سفر: صندلی',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Divider(height: 1),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    isCancelling ? null : onCancel,
                icon: isCancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.cancel_outlined,
                      ),
                label: Text(
                  isCancelling
                      ? 'در حال لغو...'
                      : 'لغو رزرو',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(
                    color: Colors.red,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}