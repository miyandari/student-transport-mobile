import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../app/theme.dart';
import '../../services/api_service.dart';
import '../../utils/persian_date_utils.dart';

class TripStatusPage extends StatelessWidget {
  const TripStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('وضعیت سفر'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 0,
              color: const Color(0xFFEAF6F7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: HammasirTheme.primary,
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'رزرو شما تأیید شده است',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'سرویس در حال نزدیک‌شدن به ایستگاه شماست.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _TripProgress(),
            const SizedBox(height: 18),
            const _InfoRow(
              icon: Icons.location_on_outlined,
              title: 'ایستگاه سوارشدن',
              value: 'ایستگاه اصلی دانشگاه',
            ),
            const _InfoRow(
              icon: Icons.access_time_rounded,
              title: 'زمان تقریبی رسیدن',
              value: '۴ دقیقه',
            ),
            const _InfoRow(
              icon: Icons.directions_bus_outlined,
              title: 'وسیله',
              value: 'مینی‌بوس ۳',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('لغو رزرو'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripProgress extends StatelessWidget {
  const _TripProgress();

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('رزرو تأیید شد', true),
      ('خودرو در مسیر', true),
      ('نزدیک ایستگاه', true),
      ('سوارشدن', false),
      ('پایان سفر', false),
    ];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFE3E8EA),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: List.generate(
            steps.length,
            (index) {
              final item = steps[index];

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: item.$2
                            ? HammasirTheme.primary
                            : const Color(0xFFE1E6E8),
                        child: item.$2
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              )
                            : null,
                      ),
                      if (index != steps.length - 1)
                        Container(
                          width: 2,
                          height: 28,
                          color: item.$2
                              ? HammasirTheme.primary
                              : const Color(0xFFE1E6E8),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.$1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            item.$2 ? FontWeight.bold : FontWeight.normal,
                        color: item.$2 ? Colors.black87 : Colors.black45,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  bool _isLoading = true;
  String? _errorMessage;

  List<ReservationData> _reservations = [];
  List<TripData> _trips = [];
  List<ServiceData> _services = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ApiService.currentUser;

      if (user == null || user.studentId == null) {
        throw ApiException(
          'اطلاعات دانشجو در حساب کاربری موجود نیست',
        );
      }

      final universityId = user.universityId;

      final results = await Future.wait([
        ApiService.getReservations(
          studentId: user.studentId,
          onlyActive: false,
        ),

        // سفرهای برنامه‌ریزی‌شده
        ApiService.getTrips(
          universityId: universityId,
          status: 'scheduled',
        ),

        // سفرهای در حال سوارشدن
        ApiService.getTrips(
          universityId: universityId,
          status: 'boarding',
        ),

        // سفرهای در حال حرکت
        ApiService.getTrips(
          universityId: universityId,
          status: 'in_progress',
        ),

        // سفرهای انجام‌شده
        ApiService.getTrips(
          universityId: universityId,
          status: 'completed',
        ),

        // سفرهای لغوشده
        ApiService.getTrips(
          universityId: universityId,
          status: 'cancelled',
        ),

        ApiService.getServices(
          universityId: universityId,
          isActive: true,
        ),
      ]);

      if (!mounted) return;

      final reservations =
          results[0] as List<ReservationData>;

      final scheduledTrips =
          results[1] as List<TripData>;

      final boardingTrips =
          results[2] as List<TripData>;

      final inProgressTrips =
          results[3] as List<TripData>;

      final completedTrips =
          results[4] as List<TripData>;

      final cancelledTrips =
          results[5] as List<TripData>;

      final services =
          results[6] as List<ServiceData>;

      // همه سفرها را در یک لیست قرار می‌دهیم.
      final allTrips = <TripData>[
        ...scheduledTrips,
        ...boardingTrips,
        ...inProgressTrips,
        ...completedTrips,
        ...cancelledTrips,
      ];

      // جلوگیری از تکراری‌شدن سفرها در صورت دریافت
      // یک سفر در بیش از یک پاسخ.
      final uniqueTrips = <int, TripData>{};

      for (final trip in allTrips) {
        uniqueTrips[trip.id] = trip;
      }

      setState(() {
        _reservations = reservations;
        _trips = uniqueTrips.values.toList();
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e is ApiException
            ? e.message
            : 'دریافت اطلاعات سفرها ناموفق بود';
      });
    }
  }

  ServiceData? _findService(int serviceId) {
    for (final service in _services) {
      if (service.id == serviceId) {
        return service;
      }
    }

    return null;
  }

  ReservationData? _findReservationForTrip(int tripId) {
    ReservationData? latestReservation;

    for (final reservation in _reservations) {
      if (reservation.tripId != tripId) {
        continue;
      }

      if (latestReservation == null) {
        latestReservation = reservation;
        continue;
      }

      final currentStatus =
          reservation.status.toLowerCase();

      final previousStatus =
          latestReservation.status.toLowerCase();

      if (_reservationStatusPriority(currentStatus) >
          _reservationStatusPriority(previousStatus)) {
        latestReservation = reservation;
      }
    }

    return latestReservation;
  }

  int _reservationStatusPriority(String status) {
    switch (status) {
      case 'confirmed':
      case 'active':
        return 5;

      case 'waitlisted':
      case 'waiting':
        return 4;

      case 'completed':
        return 3;

      case 'no_show':
        return 2;

      case 'cancelled':
      case 'canceled':
        return 1;

      default:
        return 0;
    }
  }

  List<_ReservationTripItem> _buildItems() {
    final items = <_ReservationTripItem>[];

    /*
     * مبنای نمایش، تمام سفرهای دانشگاه است؛
     * نه فقط سفرهایی که دانشجو برایشان رزرو دارد.
     *
     * بنابراین دانشجو می‌تواند سفر آینده را ببیند
     * و در صورت نداشتن رزرو، آن را قابل رزرو ببیند.
     */
    for (final trip in _trips) {
      final service = _findService(trip.serviceId);
      final reservation =
          _findReservationForTrip(trip.id);

      items.add(
        _ReservationTripItem(
          reservation: reservation,
          trip: trip,
          service: service,
        ),
      );
    }

    items.sort(
      (a, b) {
        final dateCompare =
            a.trip.tripDate.compareTo(
          b.trip.tripDate,
        );

        if (dateCompare != 0) {
          return dateCompare;
        }

        return a.trip.plannedDepartureTime.compareTo(
          b.trip.plannedDepartureTime,
        );
      },
    );

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: HammasirTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'سفرها',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(54),
            child: Container(
              color: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12),
              child: const TabBar(
                labelColor: HammasirTheme.primary,
                unselectedLabelColor: Colors.black54,
                indicatorColor: HammasirTheme.primary,
                indicatorWeight: 3,
                labelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                tabs: [
                  Tab(text: 'امروز'),
                  Tab(text: 'آینده'),
                  Tab(text: 'گذشته'),
                ],
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: HammasirTheme.primary,
                ),
              )
            : _errorMessage != null
                ? _ErrorView(
                    message: _errorMessage!,
                    onRetry: _loadTrips,
                  )
                : TabBarView(
                    children: [
                      _TripList(
                        items: _todayTrips(items),
                        emptyMessage:
                            'امروز سفری برای شما ثبت نشده است.',
                      ),
                      _TripList(
                        items: _upcomingTrips(items),
                        emptyMessage:
                            'سفر آینده‌ای برای شما ثبت نشده است.',
                      ),
                      _TripList(
                        items: _pastTrips(items),
                        emptyMessage:
                            'سفر گذشته‌ای برای شما ثبت نشده است.',
                      ),
                    ],
                  ),
      ),
    );
  }

  List<_ReservationTripItem> _todayTrips(
    List<_ReservationTripItem> items,
  ) {
    final today = _dateOnly(DateTime.now());

    return items.where((item) {
      final date = _dateOnly(item.trip.tripDate);

      if (date != today) {
        return false;
      }

      final status =
          item.trip.status.toLowerCase();

      return status != 'completed' &&
          status != 'cancelled' &&
          status != 'canceled';
    }).toList();
  }

  List<_ReservationTripItem> _upcomingTrips(
    List<_ReservationTripItem> items,
  ) {
    final today = _dateOnly(DateTime.now());

    return items.where((item) {
      final date =
          _dateOnly(item.trip.tripDate);

      final status =
          item.trip.status.toLowerCase();

      /*
       * سفر آینده باید برنامه‌ریزی‌شده باشد.
       * سفرهای completed/cancelled در آینده نمایش داده نمی‌شوند.
       */
      if (status == 'completed' ||
          status == 'cancelled' ||
          status == 'canceled') {
        return false;
      }

      return date.isAfter(today);
    }).toList();
  }

  List<_ReservationTripItem> _pastTrips(
    List<_ReservationTripItem> items,
  ) {
    final today = _dateOnly(DateTime.now());

    return items.where((item) {
      final date =
          _dateOnly(item.trip.tripDate);

      final status =
          item.trip.status.toLowerCase();

      final isOlderDate =
          date.isBefore(today);

      final isFinishedToday =
          date == today &&
          (status == 'completed' ||
              status == 'cancelled' ||
              status == 'canceled');

      return isOlderDate || isFinishedToday;
    }).toList();
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }
}

class _ReservationTripItem {
  final ReservationData? reservation;
  final TripData trip;
  final ServiceData? service;

  const _ReservationTripItem({
    required this.reservation,
    required this.trip,
    required this.service,
  });
}

class _TripList extends StatelessWidget {
  final List<_ReservationTripItem> items;
  final String emptyMessage;

  const _TripList({
    required this.items,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyTripsView(
        message: emptyMessage,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        20,
        16,
        24,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Padding(
          padding:
              const EdgeInsets.only(bottom: 12),
          child: _TripListCard(
            item: item,
          ),
        );
      },
    );
  }
}

class _EmptyTripsView extends StatelessWidget {
  final String message;

  const _EmptyTripsView({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6F7),
                borderRadius:
                    BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.directions_bus_outlined,
                size: 38,
                color: HammasirTheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 54,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon:
                  const Icon(Icons.refresh_rounded),
              label:
                  const Text('تلاش دوباره'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripListCard extends StatelessWidget {
  final _ReservationTripItem item;

  const _TripListCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final trip = item.trip;
    final reservation = item.reservation;
    final service = item.service;

    final title =
        service?.name.trim().isNotEmpty == true
            ? service!.name
            : 'سرویس شماره ${trip.serviceId}';

    final statusInfo =
        _reservationStatus(
      reservation?.status,
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFE5EAEC),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFEAF6F7),
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color:
                        HammasirTheme.primary,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons
                                .access_time_rounded,
                            size: 16,
                            color: Colors.black45,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            PersianDateUtils
                                .formatTime(
                              trip
                                  .plannedDepartureTime,
                            ),
                            style:
                                const TextStyle(
                              fontSize: 13,
                              color:
                                  Colors.black54,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons
                                .calendar_today_outlined,
                            size: 14,
                            color: Colors.black45,
                          ),
                          const SizedBox(width: 5),
                          _PersianDateText(
                            dateTime:
                                trip.tripDate,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        statusInfo.color
                            .withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusInfo.label,
                    style: TextStyle(
                      color:
                          statusInfo.color,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 1,
              color:
                  const Color(0xFFF0F2F3),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.route_outlined,
                  size: 17,
                  color: Colors.black45,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reservation == null
                        ? 'این سفر برای شما قابل رزرو است'
                        : reservation.isStanding
                            ? 'رزرو ایستاده'
                            : 'رزرو صندلی',
                    style: TextStyle(
                      fontSize: 12,
                      color: reservation == null
                          ? const Color(
                              0xFF277A4B,
                            )
                          : Colors.black54,
                      fontWeight:
                          reservation == null
                              ? FontWeight.w600
                              : FontWeight.normal,
                    ),
                  ),
                ),
                Text(
                  _tripStatusLabel(
                    trip.status,
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static _StatusInfo _reservationStatus(
    String? status,
  ) {
    if (status == null ||
        status.isEmpty) {
      return const _StatusInfo(
        label: 'قابل رزرو',
        color: Color(0xFF277A4B),
      );
    }

    switch (status.toLowerCase()) {
      case 'active':
      case 'confirmed':
        return const _StatusInfo(
          label: 'تأیید شده',
          color: Color(0xFF277A4B),
        );

      case 'waitlisted':
      case 'waiting':
        return const _StatusInfo(
          label: 'در انتظار',
          color: Color(0xFFE09B22),
        );

      case 'cancelled':
      case 'canceled':
        return const _StatusInfo(
          label: 'لغوشده',
          color: Color(0xFF68747D),
        );

      case 'completed':
        return const _StatusInfo(
          label: 'تکمیل شده',
          color: Color(0xFF277A4B),
        );

      case 'no_show':
        return const _StatusInfo(
          label: 'عدم حضور',
          color: Color(0xFFC45A3C),
        );

      default:
        return _StatusInfo(
          label: status,
          color: const Color(0xFF68747D),
        );
    }
  }

  static String _tripStatusLabel(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return 'برنامه‌ریزی‌شده';

      case 'boarding':
        return 'در حال سوارشدن';

      case 'in_progress':
        return 'در حال حرکت';

      case 'completed':
        return 'پایان‌یافته';

      case 'cancelled':
      case 'canceled':
        return 'لغوشده';

      default:
        return status;
    }
  }
}

class _PersianDateText
    extends StatelessWidget {
  final DateTime dateTime;

  const _PersianDateText({
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    final date =
        Jalali.fromDateTime(dateTime);

    final day =
        PersianDateUtils.toPersianDigits(
      date.day.toString(),
    );

    final year =
        PersianDateUtils.toPersianDigits(
      date.year.toString(),
    );

    final month =
        PersianDateUtils.monthName(
      date.month,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          Text(
            month,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const Text(
            '-',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          Text(
            year,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusInfo {
  final String label;
  final Color color;

  const _StatusInfo({
    required this.label,
    required this.color,
  });
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
            style: const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}