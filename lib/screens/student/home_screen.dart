import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme.dart';
import '../../services/api_service.dart';
import 'profile_screen.dart';
import 'my_reservations_screen.dart';
import 'service_details_screen.dart';
import 'trips_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

String _toPersianDigits(String value) {
  const english = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';

  return value.split('').map((char) {
    final index = english.indexOf(char);
    return index >= 0 ? persian[index] : char;
  }).join();
}

class _HomePageState extends State<HomePage> {
  TripData? nearestTrip;

  int reservedSeated = 0;
  int reservedStanding = 0;

  bool isLoadingTrip = true;
  String? tripError;

  bool isLoadingReservableTrips = true;
  String? reservableTripsError;
  List<TripData> reservableTrips = [];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    await Future.wait([
      _loadNearestTrip(),
      _loadReservableTrips(),
    ]);
  }

  Future<void> _loadNearestTrip() async {
    setState(() {
      isLoadingTrip = true;
      tripError = null;
    });

    try {
      final universityId = ApiService.currentUser?.universityId;

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
      ]);

      final scheduledTrips =
          results[0] as List<TripData>;

      final boardingTrips =
          results[1] as List<TripData>;

      final inProgressTrips =
          results[2] as List<TripData>;

      final activeScheduledTrips = scheduledTrips
          .where((trip) => trip.isActive)
          .toList();

      final activeBoardingTrips = boardingTrips
          .where((trip) => trip.isActive)
          .toList();

      final activeInProgressTrips = inProgressTrips
          .where((trip) => trip.isActive)
          .toList();

      TripData? selectedTrip;

      // اولویت اول: در حال سوار شدن
      if (activeBoardingTrips.isNotEmpty) {
        activeBoardingTrips.sort(
          (a, b) => _tripDateTime(a)
              .compareTo(_tripDateTime(b)),
        );

        selectedTrip = activeBoardingTrips.first;
      }

      // اولویت دوم: در حال حرکت
      if (selectedTrip == null &&
          activeInProgressTrips.isNotEmpty) {
        activeInProgressTrips.sort(
          (a, b) => _tripDateTime(a)
              .compareTo(_tripDateTime(b)),
        );

        selectedTrip = activeInProgressTrips.first;
      }

      // اولویت سوم: نزدیک‌ترین سفر برنامه‌ریزی‌شده
      if (selectedTrip == null) {
        final now = DateTime.now();

        final today = DateTime(
          now.year,
          now.month,
          now.day,
        );

        final upcomingTrips = activeScheduledTrips
            .where(
              (trip) {
                final tripDate = DateTime(
                  trip.tripDate.year,
                  trip.tripDate.month,
                  trip.tripDate.day,
                );

                return !tripDate.isBefore(today);
              },
            )
            .toList();

        upcomingTrips.sort(
          (a, b) => _tripDateTime(a)
              .compareTo(_tripDateTime(b)),
        );

        if (upcomingTrips.isNotEmpty) {
          selectedTrip = upcomingTrips.first;
        }
      }

      if (selectedTrip == null) {
        if (!mounted) return;

        setState(() {
          nearestTrip = null;
          reservedSeated = 0;
          reservedStanding = 0;
          isLoadingTrip = false;
          tripError =
              'در حال حاضر سفری برای نمایش وجود ندارد.';
        });

        return;
      }

      final reservations =
          await ApiService.getReservations(
        tripId: selectedTrip.id,
        onlyActive: true,
      );

      int seated = 0;
      int standing = 0;

      for (final reservation in reservations) {
        if (reservation.isStanding) {
          standing++;
        } else {
          seated++;
        }
      }

      if (!mounted) return;

      setState(() {
        nearestTrip = selectedTrip;
        reservedSeated = seated;
        reservedStanding = standing;
        isLoadingTrip = false;
        tripError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        nearestTrip = null;
        reservedSeated = 0;
        reservedStanding = 0;
        isLoadingTrip = false;
        tripError = e.toString();
      });
    }
  }

  Future<void> _loadReservableTrips() async {
    setState(() {
      isLoadingReservableTrips = true;
      reservableTripsError = null;
    });

    try {
      final user = ApiService.currentUser;

      if (user == null) {
        throw ApiException(
          'اطلاعات کاربر در دسترس نیست',
        );
      }

      final universityId = user.universityId;

      if (universityId == null) {
        throw ApiException(
          'دانشگاه حساب کاربری شما مشخص نیست',
        );
      }

      final trips = await ApiService.getTrips(
        universityId: universityId,
        status: 'scheduled',
      );

      final reservations =
          user.studentId == null
              ? <ReservationData>[]
              : await ApiService.getReservations(
                  studentId: user.studentId,
                  onlyActive: true,
                );

      final reservedTripIds = reservations
          .map((reservation) => reservation.tripId)
          .toSet();

      final now = DateTime.now();

      final today = DateTime(
        now.year,
        now.month,
        now.day,
      );

      final availableTrips = trips.where((trip) {
        if (!trip.isActive) {
          return false;
        }

        final tripDate = DateTime(
          trip.tripDate.year,
          trip.tripDate.month,
          trip.tripDate.day,
        );

        if (tripDate.isBefore(today)) {
          return false;
        }

        if (reservedTripIds.contains(trip.id)) {
          return false;
        }

        return true;
      }).toList();

      availableTrips.sort(
        (a, b) => _tripDateTime(a)
            .compareTo(_tripDateTime(b)),
      );

      final firstThree = availableTrips.take(3).toList();

      if (!mounted) return;

      setState(() {
        reservableTrips = firstThree;
        isLoadingReservableTrips = false;
        reservableTripsError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        reservableTrips = [];
        isLoadingReservableTrips = false;
        reservableTripsError = e.toString();
      });
    }
  }

  DateTime _tripDateTime(TripData trip) {
    return DateTime(
      trip.tripDate.year,
      trip.tripDate.month,
      trip.tripDate.day,
      trip.plannedDepartureTime.hour,
      trip.plannedDepartureTime.minute,
      trip.plannedDepartureTime.second,
    );
  }

  void _selectBottomItem(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfilePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: HammasirTheme.background,

        drawer: _HomeDrawer(
          onProfileTap: _openProfile,
        ),

        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _HomeContent(
                isLoadingTrip: isLoadingTrip,
                tripError: tripError,
                nearestTrip: nearestTrip,
                reservedSeated: reservedSeated,
                reservedStanding: reservedStanding,
                onRefresh: _loadHomeData,
                onDetails: nearestTrip == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ServiceDetailsPage(
                              tripId: nearestTrip!.id,
                            ),
                          ),
                        );
                      },
                isLoadingReservableTrips:
                    isLoadingReservableTrips,
                reservableTrips:
                    reservableTrips,
                reservableTripsError:
                    reservableTripsError,
              ),

              const TripsPage(),

              const _NotificationsPage(),

              const MyReservationsPage(),
            ],
          ),
        ),

        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected:
              _selectBottomItem,
          backgroundColor: Colors.white,
          indicatorColor:
              HammasirTheme.primary.withOpacity(0.12),
          height: 72,
          destinations: const [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
              ),
              selectedIcon: Icon(
                Icons.home,
              ),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.directions_bus_outlined,
              ),
              selectedIcon: Icon(
                Icons.directions_bus,
              ),
              label: 'سفرها',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.notifications_none_outlined,
              ),
              selectedIcon: Icon(
                Icons.notifications,
              ),
              label: 'اعلان‌ها',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.confirmation_number_outlined,
              ),
              selectedIcon: Icon(
                Icons.confirmation_number,
              ),
              label: 'رزروهای من',
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// محتوای صفحه خانه
// ==========================================================

class _HomeContent extends StatelessWidget {
  final bool isLoadingTrip;
  final String? tripError;
  final TripData? nearestTrip;
  final int reservedSeated;
  final int reservedStanding;
  final Future<void> Function() onRefresh;
  final VoidCallback? onDetails;

  final bool isLoadingReservableTrips;
  final List<TripData> reservableTrips;
  final String? reservableTripsError;

  const _HomeContent({
    required this.isLoadingTrip,
    required this.tripError,
    required this.nearestTrip,
    required this.reservedSeated,
    required this.reservedStanding,
    required this.onRefresh,
    required this.onDetails,
    required this.isLoadingReservableTrips,
    required this.reservableTrips,
    required this.reservableTripsError,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                8,
              ),
              child: _HomeHeader(
                onMenuTap: () {
                  Scaffold.of(context)
                      .openDrawer();
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 8),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: _ServiceCard(
                trip: nearestTrip,
                reservedSeated:
                    reservedSeated,
                reservedStanding:
                    reservedStanding,
                isLoading:
                    isLoadingTrip,
                errorMessage:
                    tripError,
                onDetails:
                    onDetails,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 18),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: const _MapCard(),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Align(
                alignment:
                    Alignment.centerRight,
                child: Text(
                  'سفرهای قابل رزرو',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 10),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: _ReservableTripsSection(
                isLoading:
                    isLoadingReservableTrips,
                trips: reservableTrips,
                errorMessage:
                    reservableTripsError,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// هدر صفحه خانه
// ==========================================================

class _HomeHeader extends StatelessWidget {
  final VoidCallback onMenuTap;

  const _HomeHeader({
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onMenuTap,
          tooltip: 'منو',
          icon: const Icon(
            Icons.menu,
            size: 28,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: HammasirTheme.primary,
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.directions_bus,
            color: Colors.white,
            size: 25,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'هم‌مسیر',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================================
// منوی همبرگری
// ==========================================================

class _HomeDrawer extends StatelessWidget {
  final VoidCallback onProfileTap;

  const _HomeDrawer({
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Directionality(
          textDirection:
              TextDirection.rtl,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  28,
                  20,
                  24,
                ),
                decoration: BoxDecoration(
                  color: HammasirTheme.primary,
                  borderRadius:
                      const BorderRadius.only(
                    bottomLeft:
                        Radius.circular(24),
                    bottomRight:
                        Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration:
                          BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.18),
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        color: Colors.white,
                        size: 31,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'هم‌مسیر',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'سامانه حمل‌ونقل دانشجویی',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              ListTile(
                leading: const Icon(
                  Icons.person_outline,
                ),
                title: const Text(
                  'پروفایل من',
                ),
                subtitle: const Text(
                  'مشاهده مشخصات دانشجو',
                ),
                onTap: () {
                  Navigator.pop(context);
                  onProfileTap();
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.settings_outlined,
                ),
                title: const Text(
                  'تنظیمات',
                ),
                subtitle: const Text(
                  'تنظیمات برنامه',
                ),
                onTap: () {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'بخش تنظیمات در حال توسعه است.',
                      ),
                    ),
                  );
                },
              ),

              const Divider(
                height: 20,
                indent: 20,
                endIndent: 20,
              ),

              ListTile(
                leading: const Icon(
                  Icons.info_outline,
                ),
                title: const Text(
                  'درباره هم‌مسیر',
                ),
                onTap: () {
                  Navigator.pop(context);

                  showDialog(
                    context: context,
                    builder: (_) =>
                        const _AboutDialog(),
                  );
                },
              ),

              const Spacer(),

              Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Text(
                  'هم‌مسیر',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// درباره برنامه
// ==========================================================

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.directions_bus,
              color: HammasirTheme.primary,
            ),
            SizedBox(width: 10),
            Text('هم‌مسیر'),
          ],
        ),
        content: const Text(
          'سامانه مدیریت و استفاده از سرویس ایاب‌وذهاب دانشجویی.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// اعلان‌ها
// ==========================================================

class _NotificationsPage
    extends StatelessWidget {
  const _NotificationsPage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                10,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'اعلان‌ها',
                      textAlign:
                          TextAlign.right,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons
                          .notifications_none_outlined,
                      size: 70,
                      color:
                          Colors.grey.shade400,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    const Text(
                      'اعلانی وجود ندارد',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      'اعلان‌های مربوط به سرویس، رزرو و سفرهای شما در این بخش نمایش داده می‌شود.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// سفرهای قابل رزرو
// ==========================================================

class _ReservableTripsSection
    extends StatelessWidget {
  final bool isLoading;
  final List<TripData> trips;
  final String? errorMessage;

  const _ReservableTripsSection({
    required this.isLoading,
    required this.trips,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 40,
              color: Colors.orange,
            ),
            const SizedBox(height: 10),
            const Text(
              'امکان دریافت سفرهای قابل رزرو وجود ندارد.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (trips.isEmpty) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 46,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 10),
            const Text(
              'در حال حاضر سفر قابل رزروی وجود ندارد.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: trips.map((trip) {
        return Padding(
          padding:
              const EdgeInsets.only(
            bottom: 10,
          ),
          child: _ReservableTripCard(
            trip: trip,
          ),
        );
      }).toList(),
    );
  }
}

class _ReservableTripCard
    extends StatelessWidget {
  final TripData trip;

  const _ReservableTripCard({
    required this.trip,
  });

  String _formatDate(DateTime value) {
    final date =
        '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';

    return _toPersianDigits(date);
  }

  String _formatTime(DateTime value) {
    final time =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

    return _toPersianDigits(time);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ServiceDetailsPage(
              tripId: trip.id,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.03),
              blurRadius: 12,
              offset:
                  const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration:
                  BoxDecoration(
                color: HammasirTheme
                    .primary
                    .withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
              ),
              child: const Icon(
                Icons.directions_bus_outlined,
                color:
                    HammasirTheme.primary,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    'سرویس ${_toPersianDigits(trip.serviceId.toString())}',
                    style:
                        const TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatDate(
                          trip.tripDate,
                        ),
                        style:
                            const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatTime(
                          trip
                              .plannedDepartureTime,
                        ),
                        style:
                            const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_left,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// کارت سرویس فعال
// ==========================================================

class _ServiceCard
    extends StatelessWidget {
  final TripData? trip;
  final int reservedSeated;
  final int reservedStanding;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onDetails;

  const _ServiceCard({
    required this.trip,
    required this.reservedSeated,
    required this.reservedStanding,
    required this.isLoading,
    required this.errorMessage,
    required this.onDetails,
  });

  String _formatTime(DateTime value) {
    final hour =
        value.hour.toString().padLeft(2, '0');

    final minute =
        value.minute.toString().padLeft(2, '0');

    return _toPersianDigits(
      '$hour:$minute',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 205,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(22),
        ),
        child: const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (trip == null) {
      return Container(
        padding:
            const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons
                  .directions_bus_outlined,
              size: 40,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            const Text(
              'سرویس فعالی وجود ندارد',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              errorMessage ??
                  'در حال حاضر سفری برای نمایش وجود ندارد.',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final seatedCapacity =
        trip!.seatedCapacity ?? 0;

    final standingCapacity =
        trip!.standingCapacity ?? 0;

    final availableSeats =
        (seatedCapacity -
                reservedSeated)
            .clamp(
              0,
              seatedCapacity,
            );

    final availableStanding =
        (standingCapacity -
                reservedStanding)
            .clamp(
              0,
              standingCapacity,
            );

    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.04),
            blurRadius: 15,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration:
                    BoxDecoration(
                  color: HammasirTheme
                      .primary
                      .withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: const Icon(
                  Icons.directions_bus,
                  color:
                      HammasirTheme.primary,
                  size: 28,
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
                      'سرویس ${_toPersianDigits(trip!.serviceId.toString())}',
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    const Text(
                      'سرویس دانشجویی',
                      style:
                          TextStyle(
                        color: Colors.grey,
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
                  color: Colors.green
                      .withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  trip!.status ==
                          'boarding'
                      ? 'در حال سوارشدن'
                      : trip!.status ==
                              'in_progress'
                          ? 'در حال حرکت'
                          : 'فعال',
                  style:
                      const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon:
                      Icons.access_time,
                  title: 'حرکت',
                  value:
                      _formatTime(
                    trip!
                        .plannedDepartureTime,
                  ),
                ),
              ),
              Expanded(
                child: _InfoItem(
                  icon:
                      Icons.event_seat,
                  title: 'صندلی خالی',
                  value:
                      _toPersianDigits(
                    availableSeats
                        .toString(),
                  ),
                ),
              ),
              Expanded(
                child: _InfoItem(
                  icon: Icons
                      .airline_seat_recline_normal,
                  title: 'ایستاده',
                  value:
                      _toPersianDigits(
                    availableStanding
                        .toString(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child:
                ElevatedButton(
              onPressed: onDetails,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    HammasirTheme
                        .primary,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 13,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                ),
              ),
              child: const Text(
                'مشاهده جزئیات سرویس',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// آیتم اطلاعات سرویس
// ==========================================================

class _InfoItem
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 22,
          color: HammasirTheme.primary,
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ==========================================================
// نقشه
// ==========================================================

class _MapCard extends StatefulWidget {
  const _MapCard();

  @override
  State<_MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<_MapCard> {
  final MapController _mapController =
      MapController();

  void _zoom(double delta) {
    final camera = _mapController.camera;

    final nextZoom = (camera.zoom + delta)
        .clamp(10.0, 18.0)
        .toDouble();

    _mapController.move(
      camera.center,
      nextZoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(
                35.7000,
                51.4000,
              ),
              initialZoom: 12,
              minZoom: 10,
              maxZoom: 18,
              interactionOptions:
                  InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.student_transport',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: const LatLng(
                      35.7000,
                      51.4000,
                    ),
                    width: 45,
                    height: 45,
                    child: Container(
                      decoration:
                          BoxDecoration(
                        color:
                            HammasirTheme.primary,
                        shape:
                            BoxShape.circle,
                        border:
                            Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        color:
                            Colors.white,
                        size: 23,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // وضعیت موقعیت
          const Positioned(
            top: 12,
            right: 12,
            child: _MapStatusBadge(),
          ),

          // کنترل‌های زوم
          Positioned(
            left: 12,
            bottom: 12,
            child: Column(
              children: [
                _MapZoomButton(
                  icon: Icons.add,
                  onPressed: () {
                    _zoom(1);
                  },
                ),
                const SizedBox(height: 6),
                _MapZoomButton(
                  icon: Icons.remove,
                  onPressed: () {
                    _zoom(-1);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MapZoomButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius:
          BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(12),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 22,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// وضعیت نقشه
// ==========================================================

class _MapStatusBadge
    extends StatelessWidget {
  const _MapStatusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.08),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            color: Colors.green,
            size: 17,
          ),
          SizedBox(width: 5),
          Text(
            'موقعیت سرویس',
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}