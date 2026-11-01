import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../app/theme.dart';
import '../../services/api_service.dart';
import '../../utils/persian_date_utils.dart';

class ServiceDetailsPage extends StatefulWidget {
  final int? tripId;

  const ServiceDetailsPage({
    super.key,
    this.tripId,
  });

  @override
  State<ServiceDetailsPage> createState() =>
      _ServiceDetailsPageState();
}

class _ServiceDetailsPageState
    extends State<ServiceDetailsPage> {
  StationData? selectedStation;

  bool isLoading = true;
  bool isSubmitting = false;
  bool isCancelling = false;
  bool isLoadingStations = false;

  String? errorMessage;

  TripData? trip;
  ServiceData? service;
  ReservationData? activeReservation;

  List<StationData> stations = [];

  int seatedReserved = 0;
  int standingReserved = 0;

  static const LatLng center =
      LatLng(35.7219, 51.3347);

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
      isLoadingStations = false;
      stations = [];
      selectedStation = null;
    });

    try {
      final universityId =
          ApiService.currentUser?.universityId;
debugPrint(
  '=== LOAD TRIP DEBUG ===',
);
debugPrint(
  'currentUser universityId: ${ApiService.currentUser?.universityId}',
);
debugPrint(
  'currentUser studentId: ${ApiService.currentUser?.studentId}',
);
debugPrint(
  'accessToken exists: ${ApiService.accessToken != null}',
);
      if (universityId == null) {
        throw ApiException(
          'دانشگاه حساب کاربری شما مشخص نیست',
        );
      }

      final results = await Future.wait([
        ApiService.getTrips(
          universityId: universityId,
          status: 'scheduled',
        ),
        ApiService.getTrips(
          universityId: universityId,
          status: 'boarding',
        ),
        ApiService.getTrips(
          universityId: universityId,
          status: 'in_progress',
        ),
        ApiService.getServices(
          universityId: universityId,
          isActive: true,
        ),
      ]);

      final scheduledTrips =
          results[0] as List<TripData>;

      final boardingTrips =
          results[1] as List<TripData>;

      final inProgressTrips =
          results[2] as List<TripData>;

      final services =
          results[3] as List<ServiceData>;
      debugPrint(
  'scheduledTrips: ${scheduledTrips.length}',
);
debugPrint(
  'boardingTrips: ${boardingTrips.length}',
);
debugPrint(
  'inProgressTrips: ${inProgressTrips.length}',
);
debugPrint(
  'services: ${services.length}',
);

for (final item in boardingTrips) {
  debugPrint(
    'BOARDING TRIP => id=${item.id}, university=${item.universityId}, service=${item.serviceId}, active=${item.isActive}',
  );
}

for (final item in services) {
  debugPrint(
    'SERVICE => id=${item.id}, university=${item.universityId}, name=${item.name}',
  );
}
      final allTrips = <TripData>[
        ...scheduledTrips,
        ...boardingTrips,
        ...inProgressTrips,
      ];

      if (allTrips.isEmpty) {
        throw ApiException(
          'در حال حاضر سفری برای شما وجود ندارد',
        );
      }

      final activeTrips = allTrips
          .where((item) => item.isActive)
          .toList();

      if (activeTrips.isEmpty) {
        throw ApiException(
          'در حال حاضر سفر فعالی برای شما وجود ندارد',
        );
      }

      TripData selectedTrip;

      if (widget.tripId != null) {
        final matchingTrips = activeTrips
            .where(
              (item) => item.id == widget.tripId,
            )
            .toList();

        if (matchingTrips.isEmpty) {
          throw ApiException(
            'سفر موردنظر دیگر فعال نیست یا پیدا نشد',
          );
        }

        selectedTrip = matchingTrips.first;
      } else {
        /*
         * اولویت انتخاب سفر:
         *
         * 1. سفرهای در حال سوارشدن (boarding)
         * 2. سفرهای در حال حرکت (in_progress)
         * 3. نزدیک‌ترین سفر برنامه‌ریزی‌شده امروز یا آینده
         *
         * نکته مهم:
         * سفر boarding یا in_progress حتی اگر زمان برنامه‌ریزی‌شده
         * آن گذشته باشد، همچنان سفر فعال محسوب می‌شود.
         */

        final activeRunningTrips = activeTrips
            .where(
              (item) =>
                  item.status == 'boarding' ||
                  item.status == 'in_progress',
            )
            .toList();

        if (activeRunningTrips.isNotEmpty) {
          activeRunningTrips.sort((a, b) {
            final aDateTime = DateTime(
              a.tripDate.year,
              a.tripDate.month,
              a.tripDate.day,
              a.plannedDepartureTime.hour,
              a.plannedDepartureTime.minute,
              a.plannedDepartureTime.second,
            );

            final bDateTime = DateTime(
              b.tripDate.year,
              b.tripDate.month,
              b.tripDate.day,
              b.plannedDepartureTime.hour,
              b.plannedDepartureTime.minute,
              b.plannedDepartureTime.second,
            );

            return aDateTime.compareTo(bDateTime);
          });

          selectedTrip = activeRunningTrips.first;
        } else {
          final now = DateTime.now();

          final today = DateTime(
            now.year,
            now.month,
            now.day,
          );

          final upcomingTrips = activeTrips
              .where(
                (item) {
                  if (item.status != 'scheduled') {
                    return false;
                  }

                  final tripDate = DateTime(
                    item.tripDate.year,
                    item.tripDate.month,
                    item.tripDate.day,
                  );

                  return !tripDate.isBefore(today);
                },
              )
              .toList();

          if (upcomingTrips.isEmpty) {
            throw ApiException(
              'در حال حاضر سفر فعال و قابل استفاده‌ای برای شما وجود ندارد',
            );
          }

          upcomingTrips.sort((a, b) {
            final aDateTime = DateTime(
              a.tripDate.year,
              a.tripDate.month,
              a.tripDate.day,
              a.plannedDepartureTime.hour,
              a.plannedDepartureTime.minute,
              a.plannedDepartureTime.second,
            );

            final bDateTime = DateTime(
              b.tripDate.year,
              b.tripDate.month,
              b.tripDate.day,
              b.plannedDepartureTime.hour,
              b.plannedDepartureTime.minute,
              b.plannedDepartureTime.second,
            );

            return aDateTime.compareTo(bDateTime);
          });

          selectedTrip = upcomingTrips.first;
        }
      }

      ServiceData? selectedService;

      final matchingServices = services
          .where(
            (item) =>
                item.id == selectedTrip.serviceId,
          )
          .toList();

      if (matchingServices.isNotEmpty) {
        selectedService = matchingServices.first;
      }

      List<StationData> routeStations = [];

      if (selectedService != null) {
        try {
          routeStations =
              await ApiService.getStationsForRoute(
            routeId: selectedService.routeId,
          );
        } catch (_) {
          routeStations = [];
        }
      }

      final studentId =
          ApiService.currentUser?.studentId;

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

      for (final reservation
          in allReservations) {
        if (reservation.isStanding) {
          standing++;
        } else {
          seated++;
        }
      }

      if (!mounted) return;

      StationData? initialStation;

      if (routeStations.isNotEmpty) {
        initialStation = routeStations.first;

        if (studentActiveReservation?.stationId !=
            null) {
          final matchingStation = routeStations
              .where(
                (station) =>
                    station.id ==
                    studentActiveReservation!
                        .stationId,
              )
              .toList();

          if (matchingStation.isNotEmpty) {
            initialStation =
                matchingStation.first;
          }
        }
      }

      setState(() {
        trip = selectedTrip;
        service = selectedService;
        activeReservation =
            studentActiveReservation;
        seatedReserved = seated;
        standingReserved = standing;
        stations = routeStations;
        selectedStation = initialStation;
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

  int get seatedCapacity =>
      trip?.seatedCapacity ?? 0;

  int get standingCapacity =>
      trip?.standingCapacity ?? 0;

  int get emptySeats {
    final value =
        seatedCapacity - seatedReserved;

    return value < 0 ? 0 : value;
  }

  int get emptyStanding {
    final value =
        standingCapacity - standingReserved;

    return value < 0 ? 0 : value;
  }

  bool get hasActiveReservation =>
      activeReservation != null &&
      (activeReservation!.status == 'active' ||
          activeReservation!.status ==
              'waitlisted');

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
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text(
                  'تلاش دوباره',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (trip == null) {
      return const Center(
        child: Text(
          'اطلاعات سفر پیدا نشد',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrip,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
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
              borderRadius:
                  BorderRadius.circular(22),
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
                          color:
                              HammasirTheme.primary,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: routePoints[0],
                          width: 42,
                          height: 42,
                          child:
                              const _MapMarker(
                            icon: Icons.school_rounded,
                            color:
                                HammasirTheme.primary,
                          ),
                        ),
                        Marker(
                          point: routePoints[2],
                          width: 42,
                          height: 42,
                          child:
                              const _MapMarker(
                            icon: Icons
                                .directions_bus_rounded,
                            color:
                                Color(0xFFEF7D32),
                          ),
                        ),
                        Marker(
                          point: routePoints[4],
                          width: 42,
                          height: 42,
                          child:
                              const _MapMarker(
                            icon: Icons.home_rounded,
                            color:
                                Color(0xFF5B6B7A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            _ServiceHeader(
              serviceName: service?.name,
              tripStatus: trip!.status,
            ),

            const SizedBox(height: 16),

            _StationCard(
              selectedStation: selectedStation,
              stations: stations,
              isLoading: isLoadingStations,
              onChanged: (value) {
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
              value: PersianDateUtils.formatTime(
                trip!.plannedDepartureTime,
              ),
              valueDirection:
                  TextDirection.ltr,
            ),

            _PersianDateRow(
              icon:
                  Icons.calendar_today_outlined,
              title: 'تاریخ سفر',
              date: trip!.tripDate,
            ),

            const _InfoRow(
              icon: Icons.location_on_outlined,
              title: 'مقصد',
              value: 'خوابگاه',
            ),

            _InfoRow(
              icon:
                  Icons.directions_bus_outlined,
              title: 'شناسه سفر',
              value:
                  PersianDateUtils.toPersianDigits(
                '#${trip!.id}',
              ),
              valueDirection:
                  TextDirection.ltr,
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
        stationName: selectedStation?.name,
        isCancelling: isCancelling,
        onCancel: _confirmCancelReservation,
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isSubmitting
            ? null
            : _showReservationSheet,
        style: FilledButton.styleFrom(
          backgroundColor:
              HammasirTheme.primary,
          padding:
              const EdgeInsets.symmetric(
            vertical: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15),
          ),
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(
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

    if (stations.isEmpty || selectedStation == null) {
      _showMessage(
        'لطفاً ابتدا یک ایستگاه سوارشدن انتخاب کنید.',
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
            padding:
                const EdgeInsets.fromLTRB(
              20,
              0,
              20,
              25,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Text(
                  'انتخاب نوع سفر',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ایستگاه: ${selectedStation!.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),

                ListTile(
                  leading:
                      const CircleAvatar(
                    backgroundColor:
                        Color(0xFFE7F5F6),
                    child: Icon(
                      Icons
                          .event_seat_outlined,
                      color:
                          HammasirTheme.primary,
                    ),
                  ),
                  title:
                      const Text('صندلی'),
                  subtitle: Text(
                    emptySeats > 0
                        ? '${PersianDateUtils.toPersianDigits(emptySeats.toString())} صندلی خالی'
                        : 'ظرفیت صندلی تکمیل است',
                  ),
                  trailing:
                      const Icon(
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
                  leading:
                      const CircleAvatar(
                    backgroundColor:
                        Color(0xFFFFF1E8),
                    child: Icon(
                      Icons
                          .accessibility_new_rounded,
                      color:
                          Color(0xFFEF7D32),
                    ),
                  ),
                  title:
                      const Text(
                    'سفر ایستاده',
                  ),
                  subtitle: Text(
                    !currentTrip
                            .allowStanding
                        ? 'برای این سفر مجاز نیست'
                        : canStand
                            ? '${PersianDateUtils.toPersianDigits(emptyStanding.toString())} ظرفیت ایستاده'
                            : 'ظرفیت ایستاده تکمیل است',
                  ),
                  trailing:
                      const Icon(
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

    final stationId =
        selectedStation?.id;

    if (currentTrip == null ||
        studentId == null ||
        stationId == null) {
      _showMessage(
        'اطلاعات سفر یا ایستگاه سوارشدن کامل نیست.',
        isError: true,
      );
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
        stationId: stationId,
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
    final reservation =
        activeReservation;

    if (reservation == null) return;

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('لغو رزرو'),
          content: const Text(
            'آیا مطمئن هستید که می‌خواهید رزرو این سفر را لغو کنید؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
                  const Text('لغو رزرو'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _cancelReservation(
      reservation.id,
    );
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
  final String? serviceName;
  final String tripStatus;

  const _ServiceHeader({
    required this.serviceName,
    required this.tripStatus,
  });

  String get statusText {
    switch (tripStatus) {
      case 'scheduled':
        return 'سفر برنامه‌ریزی‌شده';
      case 'boarding':
        return 'در حال سوارشدن';
      case 'in_progress':
        return 'در حال حرکت';
      case 'completed':
        return 'سفر انجام‌شده';
      case 'cancelled':
        return 'لغوشده';
      default:
        return 'سفر برنامه‌ریزی‌شده';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: const Color(0xFFEAF6F7),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor:
                  HammasirTheme.primary,
              child: Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName ??
                        'سرویس دانشجویی',
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    statusText,
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
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  final StationData? selectedStation;
  final List<StationData> stations;
  final bool isLoading;
  final ValueChanged<StationData?> onChanged;

  const _StationCard({
    required this.selectedStation,
    required this.stations,
    required this.isLoading,
    required this.onChanged,
  });

  void _showStationPicker(
    BuildContext context,
  ) {
    if (stations.isEmpty) {
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                28,
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_off_rounded,
                    size: 44,
                    color: Colors.black38,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ایستگاهی برای این سرویس ثبت نشده است',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'در حال حاضر اطلاعات ایستگاه‌های این مسیر در سامانه ثبت نشده است.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(
                          sheetContext,
                        );
                      },
                      child:
                          const Text('بستن'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              4,
              18,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  child: Text(
                    'انتخاب ایستگاه سوارشدن',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  child: Text(
                    'ایستگاهی را که می‌خواهید از آن سوار سرویس شوید انتخاب کنید.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...stations.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final station = entry.value;
                    final isSelected =
                        station.id ==
                            selectedStation?.id;

                    return Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 8,
                      ),
                      child: Material(
                        color: isSelected
                            ? const Color(
                                0xFFE7F5F6,
                              )
                            : const Color(
                                0xFFF7F8F9,
                              ),
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          onTap: () {
                            onChanged(station);

                            Navigator.pop(
                              sheetContext,
                            );
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 21,
                                  backgroundColor:
                                      isSelected
                                          ? HammasirTheme
                                              .primary
                                          : Colors.white,
                                  child: Text(
                                    PersianDateUtils
                                        .toPersianDigits(
                                      '${index + 1}',
                                    ),
                                    style:
                                        TextStyle(
                                      color:
                                          isSelected
                                              ? Colors
                                                  .white
                                              : HammasirTheme
                                                  .primary,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        station.name,
                                        style:
                                            TextStyle(
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight
                                                      .bold
                                                  : FontWeight
                                                      .w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (station
                                              .estimatedMinutesFromStart !=
                                          null)
                                        const SizedBox(
                                          height: 3,
                                        ),
                                      if (station
                                              .estimatedMinutesFromStart !=
                                          null)
                                        Text(
                                          'حدود ${PersianDateUtils.toPersianDigits(station.estimatedMinutesFromStart.toString())} دقیقه از مبدأ',
                                          style:
                                              const TextStyle(
                                            color:
                                                Colors.black54,
                                            fontSize:
                                                11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons
                                        .check_circle_rounded,
                                    color:
                                        HammasirTheme
                                            .primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEAF6F7),
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFB7E1E4),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: HammasirTheme.primary,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'ایستگاه سوارشدن',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'در حال دریافت ایستگاه‌ها...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 20,
              height: 20,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                color: HammasirTheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    final displayStation =
        selectedStation?.name ??
        (stations.isEmpty
            ? 'ایستگاهی ثبت نشده'
            : 'انتخاب ایستگاه');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showStationPicker(context),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFEAF6F7),
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFB7E1E4),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color:
                        HammasirTheme.primary,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons
                        .location_on_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ایستگاه سوارشدن',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayStation,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              stations.isEmpty
                                  ? Colors.black54
                                  : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        stations.isEmpty
                            ? 'ایستگاه‌های این مسیر هنوز ثبت نشده‌اند'
                            : selectedStation == null
                                ? 'برای انتخاب ایستگاه لمس کنید'
                                : 'برای تغییر ایستگاه لمس کنید',
                        style: TextStyle(
                          color: stations.isEmpty
                              ? Colors.black45
                              : HammasirTheme
                                  .primary,
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons
                      .keyboard_arrow_down_rounded,
                  color: Colors.black54,
                  size: 28,
                ),
              ],
            ),
          ),
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
        borderRadius:
            BorderRadius.circular(18),
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
                value:
                    PersianDateUtils
                        .toPersianDigits(
                  emptySeats.toString(),
                ),
                title: 'صندلی خالی',
              ),
            ),
            Expanded(
              child: _CapacityItem(
                icon: Icons
                    .accessibility_new_rounded,
                value:
                    PersianDateUtils
                        .toPersianDigits(
                  emptyStanding.toString(),
                ),
                title: 'ظرفیت ایستاده',
              ),
            ),
            Expanded(
              child: _CapacityItem(
                icon:
                    Icons.people_outline_rounded,
                value:
                    PersianDateUtils
                        .toPersianDigits(
                  passengers.toString(),
                ),
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
  final TextDirection? valueDirection;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
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
            textDirection: valueDirection,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersianDateRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final DateTime date;

  const _PersianDateRow({
    required this.icon,
    required this.title,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final jalali = Jalali.fromDateTime(date);

    final day = PersianDateUtils.toPersianDigits(
      jalali.day.toString(),
    );

    final year = PersianDateUtils.toPersianDigits(
      jalali.year.toString(),
    );

    final month = PersianDateUtils.monthName(
      jalali.month,
    );

    final formattedDate = '$day $month $year';

    return Padding(
      padding:
          const EdgeInsets.symmetric(
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
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              formattedDate,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveReservationCard
    extends StatelessWidget {
  final ReservationData reservation;
  final String? stationName;
  final bool isCancelling;
  final VoidCallback onCancel;

  const _ActiveReservationCard({
    required this.reservation,
    required this.stationName,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isWaitlisted =
        reservation.status ==
            'waitlisted';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isWaitlisted
          ? const Color(0xFFFFF7E8)
          : const Color(0xFFEAF6F7),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
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
                  backgroundColor:
                      isWaitlisted
                          ? const Color(
                              0xFFFFE7B5,
                            )
                          : const Color(
                              0xFFD5F0F2,
                            ),
                  child: Icon(
                    isWaitlisted
                        ? Icons
                            .hourglass_top_rounded
                        : Icons
                            .check_circle_outline_rounded,
                    color: isWaitlisted
                        ? const Color(
                            0xFFD68A00,
                          )
                        : HammasirTheme
                            .primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        isWaitlisted
                            ? 'در صف انتظار هستید'
                            : 'رزرو شما ثبت شده است',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        reservation.isStanding
                            ? 'نوع سفر: ایستاده'
                            : 'نوع سفر: صندلی',
                        style:
                            const TextStyle(
                          color:
                              Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (stationName != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'ایستگاه سوارشدن: $stationName',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 15),
            const Divider(height: 1),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isCancelling
                    ? null
                    : onCancel,
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
                        Icons
                            .cancel_outlined,
                      ),
                label: Text(
                  isCancelling
                      ? 'در حال لغو...'
                      : 'لغو رزرو',
                ),
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      Colors.red,
                  side:
                      const BorderSide(
                    color: Colors.red,
                  ),
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 13,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
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