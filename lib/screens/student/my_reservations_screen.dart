import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../services/api_service.dart';

class MyReservationsPage extends StatefulWidget {
  const MyReservationsPage({super.key});

  @override
  State<MyReservationsPage> createState() =>
      _MyReservationsPageState();
}

class _MyReservationsPageState
    extends State<MyReservationsPage> {
  bool isLoading = true;
  String? errorMessage;

  List<ReservationData> reservations = [];
  Map<int, TripData> tripsById = {};

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final user = ApiService.currentUser;

      if (user == null) {
        throw ApiException(
          'اطلاعات کاربر در دسترس نیست',
        );
      }

      if (user.studentId == null) {
        throw ApiException(
          'حساب کاربری شما به دانشجو متصل نیست',
        );
      }

      final universityId = user.universityId;

      if (universityId == null) {
        throw ApiException(
          'دانشگاه حساب کاربری شما مشخص نیست',
        );
      }

      final result =
          await ApiService.getReservations(
        studentId: user.studentId,
        onlyActive: false,
      );

      final trips =
          await ApiService.getTrips(
        universityId: universityId,
      );

      final tripMap = <int, TripData>{};

      for (final item in trips) {
        tripMap[item.id] = item;
      }

      result.sort(
        (a, b) => b.reservationTime.compareTo(
          a.reservationTime,
        ),
      );

      if (!mounted) return;

      setState(() {
        reservations = result;
        tripsById = tripMap;
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

  List<ReservationData> get _activeReservations {
    return reservations.where((reservation) {
      return reservation.status == 'active' ||
          reservation.status == 'waitlisted';
    }).toList();
  }

  List<ReservationData> get _cancelledReservations {
    return reservations.where((reservation) {
      return reservation.status == 'cancelled';
    }).toList();
  }

  bool _isActive(ReservationData reservation) {
    return reservation.status == 'active' ||
        reservation.status == 'waitlisted';
  }

  String _statusText(String status) {
    switch (status) {
      case 'active':
        return 'تأیید شده';

      case 'waitlisted':
        return 'صف انتظار';

      case 'cancelled':
        return 'لغو شده';

      case 'completed':
        return 'انجام شده';

      case 'no_show':
        return 'عدم حضور';

      default:
        return status.isEmpty
            ? 'نامشخص'
            : status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return HammasirTheme.primary;

      case 'waitlisted':
        return const Color(0xFFD68A00);

      case 'cancelled':
        return Colors.red;

      case 'completed':
        return Colors.blueGrey;

      case 'no_show':
        return Colors.deepOrange;

      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();

    final year =
        local.year.toString();

    final month =
        local.month.toString().padLeft(2, '0');

    final day =
        local.day.toString().padLeft(2, '0');

    return '$year/$month/$day';
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();

    final hour =
        local.hour.toString().padLeft(2, '0');

    final minute =
        local.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> _cancelReservation(
    ReservationData reservation,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('لغو رزرو'),
          content: const Text(
            'آیا مطمئن هستید که می‌خواهید این رزرو را لغو کنید؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('لغو رزرو'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ApiService.cancelReservation(
        reservation.id,
      );

      if (!mounted) return;

      _showMessage(
        'رزرو با موفقیت لغو شد.',
      );

      await _loadReservations();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString(),
        isError: true,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رزروهای من'),
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
                Icons.error_outline_rounded,
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
                onPressed: _loadReservations,
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

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F5),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: TabBar(
              indicatorSize:
                  TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              labelColor:
                  HammasirTheme.primary,
              unselectedLabelColor:
                  Colors.black54,
              labelStyle:
                  const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              unselectedLabelStyle:
                  const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 13,
              ),
              padding: const EdgeInsets.all(4),
              tabs: [
                Tab(
                  icon: Badge(
                    isLabelVisible:
                        _activeReservations
                            .isNotEmpty,
                    label: Text(
                      _activeReservations
                          .length
                          .toString(),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                    ),
                  ),
                  text: 'رزروهای فعال',
                ),
                Tab(
                  icon: Badge(
                    isLabelVisible:
                        _cancelledReservations
                            .isNotEmpty,
                    label: Text(
                      _cancelledReservations
                          .length
                          .toString(),
                    ),
                    child: const Icon(
                      Icons.event_busy_rounded,
                    ),
                  ),
                  text: 'لغوشده‌ها',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildReservationList(
                  _activeReservations,
                  emptyIcon:
                      Icons.event_available_rounded,
                  emptyTitle:
                      'رزرو فعال ندارید',
                  emptyDescription:
                      'رزروهای تأییدشده و رزروهای موجود در صف انتظار در این قسمت نمایش داده می‌شوند.',
                ),
                _buildReservationList(
                  _cancelledReservations,
                  emptyIcon:
                      Icons.event_busy_rounded,
                  emptyTitle:
                      'رزرو لغوشده‌ای ندارید',
                  emptyDescription:
                      'رزروهایی که لغو کرده‌اید در این قسمت نمایش داده می‌شوند.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationList(
    List<ReservationData> items, {
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptyDescription,
  }) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadReservations,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 110),
            Icon(
              emptyIcon,
              size: 64,
              color: Colors.black26,
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                emptyTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 40,
                ),
                child: Text(
                  emptyDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          30,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final reservation = items[index];

          final trip =
              tripsById[reservation.tripId];

          return Padding(
            padding:
                const EdgeInsets.only(
              bottom: 12,
            ),
            child: _ReservationCard(
              reservation: reservation,
              trip: trip,
              statusText:
                  _statusText(
                reservation.status,
              ),
              statusColor:
                  _statusColor(
                reservation.status,
              ),
              dateText: trip == null
                  ? 'تاریخ نامشخص'
                  : _formatDate(
                      trip.tripDate,
                    ),
              timeText: trip == null
                  ? '--:--'
                  : _formatTime(
                      trip.plannedDepartureTime,
                    ),
              isActive:
                  _isActive(reservation),
              onCancel: () =>
                  _cancelReservation(
                reservation,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReservationCard
    extends StatelessWidget {
  final ReservationData reservation;
  final TripData? trip;

  final String statusText;
  final Color statusColor;

  final String dateText;
  final String timeText;

  final bool isActive;
  final VoidCallback onCancel;

  const _ReservationCard({
    required this.reservation,
    required this.trip,
    required this.statusText,
    required this.statusColor,
    required this.dateText,
    required this.timeText,
    required this.isActive,
    required this.onCancel,
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
        padding:
            const EdgeInsets.all(17),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor:
                      statusColor.withValues(
                    alpha: 0.10,
                  ),
                  child: Icon(
                    reservation.isStanding
                        ? Icons
                            .accessibility_new_rounded
                        : Icons
                            .event_seat_outlined,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        'سرویس دانشجویی',
                        style: TextStyle(
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
                            ? 'نوع رزرو: ایستاده'
                            : 'نوع رزرو: صندلی',
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
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        statusColor.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Divider(height: 1),
            const SizedBox(height: 13),
            _DetailRow(
              icon:
                  Icons.calendar_today_outlined,
              title: 'تاریخ حرکت',
              value: dateText,
            ),
            _DetailRow(
              icon:
                  Icons.access_time_rounded,
              title: 'زمان حرکت',
              value: timeText,
            ),
            _DetailRow(
              icon:
                  Icons.directions_bus_outlined,
              title: 'شناسه سفر',
              value:
                  '#${reservation.tripId}',
            ),
            if (trip != null)
              const _DetailRow(
                icon:
                    Icons.location_on_outlined,
                title: 'مقصد',
                value: 'خوابگاه',
              ),
            if (isActive) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(
                    Icons.cancel_outlined,
                  ),
                  label: const Text(
                    'لغو رزرو',
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
                      vertical: 12,
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
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color:
                HammasirTheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style:
                  const TextStyle(
                color:
                    Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}