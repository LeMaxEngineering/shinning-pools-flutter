import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/app_text_field.dart';
import '../services/pool_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pool_repository.dart';
import 'package:geolocator/geolocator.dart';
import '../../../shared/ui/widgets/optimized_maintenance_pools_map.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../../../shared/ui/widgets/collapsible_card.dart';
import 'package:url_launcher/url_launcher.dart';

class MaintenanceFormScreen extends StatefulWidget {
  final String? poolId;
  final String? poolName;
  final Map<String, dynamic>? maintenanceRecord;

  const MaintenanceFormScreen({
    super.key,
    this.poolId,
    this.poolName,
    this.maintenanceRecord,
  });

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _phController = TextEditingController();
  final _chlorineController = TextEditingController();
  final _alkalinityController = TextEditingController();
  final _calciumController = TextEditingController();
  final _costController = TextEditingController();
  final _technicianController = TextEditingController();

  String? _selectedStatus = 'Completed';
  DateTime _selectedDate = DateTime.now();
  DateTime? _nextMaintenanceDate;

  // Pool selection state (when no specific pool is provided)
  String? _selectedPoolId;
  String? _selectedPoolName;
  String? _selectedPoolAddress;
  List<Map<String, dynamic>> _availablePools = [];

  // New pool selection approach
  bool _poolSelected = false;
  bool _showMaintenanceForm = false;
  final TextEditingController _poolSearchController = TextEditingController();
  List<Map<String, dynamic>> _filteredPools = [];
  String _poolSelectionMethod = 'search'; // 'search' or 'map'

  // Selected options
  Set<String> _selectedChemicals = {};
  Set<String> _selectedPhysical = {};

  final List<String> _statusOptions = [
    'Completed',
    'In Progress',
    'Scheduled',
    'Cancelled',
  ];

  bool get _isEditing => widget.maintenanceRecord != null;

  // --- Standard Maintenance State Fields ---
  double _chlorineLiquidGallons = 0.0;
  int _chlorineTablets = 0;
  bool _algaecideUsed = false;
  bool _muriaticAcidUsed = false;
  bool _drySaltUsed = false;
  String _drySaltSize = '10 lbs';
  bool _wallBrushUsed = false;
  bool _cartridgeFilterCleanerUsed = false;
  bool _poolFilterCleanUpUsed = false;

  // Helper for salt system
  bool get _isSaltPool => (widget.maintenanceRecord?['poolType'] ?? '')
      .toString()
      .toLowerCase()
      .contains('salt');

  // Total calculation
  double get _standardTotalGallons =>
      _chlorineLiquidGallons +
      (_algaecideUsed ? 0.125 : 0) +
      (_muriaticAcidUsed ? 0.125 : 0);
  int get _standardTotalTablets => _chlorineTablets;
  int get _standardTotalSaltLbs =>
      _drySaltUsed ? (_drySaltSize == '10 lbs' ? 10 : 40) : 0;

  // --- Detailed Chemical Section State Fields ---
  double _calciumHypochloriteLbs = 0.0;
  bool _copperAlgaecideUsed = false;
  bool _polyquatAlgaecideUsed = false;
  double _quatAmmoniumGallons = 0.0;
  double _sodiumCarbonateLbs = 0.0;
  bool _chelatingUsed = false;
  bool _poolClarifierUsed = false;
  bool _flocculantUsed = false;
  bool _metalRemoverUsed = false;
  double _sodiumBicarbonateLbs = 0.0;

  // --- Detailed Physical Section State Fields ---
  // Pool Filter
  final TextEditingController _filterInstallCostController =
      TextEditingController();
  final TextEditingController _filterReplaceCostController =
      TextEditingController();
  // Pool Pump
  bool _pumpCleanUp = false;
  final TextEditingController _pumpInstallCostController =
      TextEditingController();
  final TextEditingController _pumpReplaceCostController =
      TextEditingController();
  final TextEditingController _pumpRepairCostController =
      TextEditingController();
  // Salt System
  bool _saltCleanUp = false;
  final TextEditingController _saltInstallCostController =
      TextEditingController();
  final TextEditingController _saltReplaceCostController =
      TextEditingController();
  final TextEditingController _saltRepairCostController =
      TextEditingController();
  // Pipe Replace
  bool _pipeCleanUp = false;
  final TextEditingController _pipeInstallCostController =
      TextEditingController();
  final TextEditingController _pipeReplaceCostController =
      TextEditingController();
  final TextEditingController _pipeRepairCostController =
      TextEditingController();
  // Surface Cleaners
  final TextEditingController _surfaceCleanCostController =
      TextEditingController();
  // Enzyme Cleaners
  final TextEditingController _enzymeCleanCostController =
      TextEditingController();
  // Filter Cleaners
  bool _sandFilterClean = false;
  final TextEditingController _deFilterCostController = TextEditingController();

  double get _physicalTotalCost {
    double sum = 0.0;
    List<TextEditingController> controllers = [
      _filterInstallCostController,
      _filterReplaceCostController,
      _pumpInstallCostController,
      _pumpReplaceCostController,
      _pumpRepairCostController,
      _saltInstallCostController,
      _saltReplaceCostController,
      _saltRepairCostController,
      _pipeInstallCostController,
      _pipeReplaceCostController,
      _pipeRepairCostController,
      _surfaceCleanCostController,
      _enzymeCleanCostController,
      _deFilterCostController,
    ];
    for (var c in controllers) {
      final v = double.tryParse(c.text.trim());
      if (v != null && v > 0) sum += v;
    }
    return sum;
  }

  // GPS/location-based pool filtering
  Position? _userPosition;
  List<Map<String, dynamic>> _nearbyPools = [];
  bool _locationError = false;
  bool _loadingLocation = true;
  bool _gpsStepComplete = false;

  // New field for Muriatic Acid
  double _muriaticAcidGallons = 0.0;

  // Add this field to the state class:
  double _standardCalciumHypochloriteLbs = 0.0;

  // Add to _MaintenanceFormScreenState:
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      final record = widget.maintenanceRecord!;
      _selectedPoolId = record['poolId'];
      _selectedPoolName = record['poolName'];
      _selectedPoolAddress = record['address'];
      _poolSelected = true;
      _showMaintenanceForm = true;
      // Initialize all form fields for editing
      _initializeEditingMode();
    }
    if (widget.poolId == null && !_isEditing) {
      _loadAvailablePools();
      _getUserLocationAndFilterPools();
    } else if (widget.poolId != null) {
      _selectedPoolId = widget.poolId;
      _selectedPoolName = widget.poolName;
      _selectedPoolAddress =
          widget.poolName; // Assuming poolName is the address for now
      _poolSelected = true;
      _showMaintenanceForm = true;
    }
  }

  @override
  void didUpdateWidget(covariant MaintenanceFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isEditing && widget.maintenanceRecord != oldWidget.maintenanceRecord) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initializeEditingMode();
      });
    }
  }

  // Security check method
  bool _canEditMaintenanceRecord() {
    if (widget.maintenanceRecord == null) return false;

    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) return false;

    final userCompanyId = currentUser.companyId;
    final maintenanceCompanyId = widget.maintenanceRecord!['companyId'];

    // Root users can edit everything
    if (currentUser.role == 'root') {
      return true;
    }
    // Company admins can edit maintenance records from their own company
    else if (currentUser.role == 'company_admin' &&
        userCompanyId == maintenanceCompanyId) {
      return true;
    }
    // Workers can only edit maintenance records they performed AND belong to their current company
    else if (currentUser.role == 'worker' &&
        currentUser.id == widget.maintenanceRecord!['performedBy'] &&
        userCompanyId == maintenanceCompanyId) {
      return true;
    }

    return false;
  }

  Future<void> _loadAvailablePools() async {
    final authService = context.read<AuthService>();
    final poolService = context.read<PoolService>();
    final currentUser = authService.currentUser;

    if (currentUser?.companyId != null) {
      try {
        // Get all pools for the company directly from repository
        final poolRepository = PoolRepository();
        final querySnapshot = await poolRepository.getCompanyPools(
          currentUser!.companyId!,
        );

        final pools = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {'id': doc.id, ...data};
        }).toList();

        if (mounted) {
          setState(() {
            _availablePools = pools;
            _filteredPools = pools;
          });
          print('✅ Loaded ${pools.length} pools for maintenance form');
          for (final pool in pools) {
            print(
              '🏊 Pool: ${pool['name']} | Address: ${pool['address']} | Coords: ${pool['latitude']}, ${pool['longitude']}',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _availablePools = [];
            _filteredPools = [];
          });
        }
      }
    }
  }

  void _filterPools(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPools = _availablePools;
      } else {
        _filteredPools = _availablePools.where((pool) {
          final name = pool['name']?.toString().toLowerCase() ?? '';
          final address = pool['address']?.toString().toLowerCase() ?? '';
          final customer = pool['customerName']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();

          return name.contains(searchLower) ||
              address.contains(searchLower) ||
              customer.contains(searchLower);
        }).toList();
      }
    });
  }

  void _selectPool(Map<String, dynamic> pool) {
    // Check if pool has already been maintained today
    final poolId = pool['id'];
    final poolName = pool['name'];

    // Check maintenance status for today
    _checkMaintenanceStatusForToday(poolId).then((isMaintainedToday) {
      if (isMaintainedToday) {
        // Show warning that pool has already been maintained today
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ $poolName has already been maintained today. Cannot create duplicate maintenance record.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        return; // Don't select the pool
      }

      // Pool hasn't been maintained today, allow selection
      setState(() {
        _selectedPoolId = poolId;
        _selectedPoolName = poolName;
        _selectedPoolAddress = pool['address'] as String?;
        _poolSelected = true;
        _poolSearchController.text = '${pool['name']} - ${pool['address']}';
      });
    });
  }

  Future<bool> _checkMaintenanceStatusForToday(String poolId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      final companyId = currentUser?.companyId;

      if (companyId == null) {
        print('⚠️ No company ID available for maintenance status check');
        return false;
      }

      final poolRepository = PoolRepository();
      final today = DateTime.now();
      final dateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Check if pool has maintenance record for today
      final maintenanceStatuses = await poolRepository
          .getMaintenanceStatusForPools(
            [poolId],
            dateString,
            companyId: companyId,
          );

      final isMaintainedToday = maintenanceStatuses[poolId] ?? false;
      print(
        '🔍 Pool $poolId maintenance status for today: ${isMaintainedToday ? 'Maintained' : 'Not Maintained'}',
      );
      print('🔍 Date string being checked: $dateString');
      print('🔍 Company ID: $companyId');

      return isMaintainedToday;
    } catch (e) {
      print('❌ Error checking maintenance status for pool $poolId: $e');
      return false; // Allow selection if we can't determine status
    }
  }

  void _startMaintenanceForm() {
    if (_selectedPoolId != null) {
      setState(() {
        _showMaintenanceForm = true;
      });
    }
  }

  void _backToPoolSelection() {
    setState(() {
      _showMaintenanceForm = false;
      _selectedPoolId = null;
      _selectedPoolName = null;
      _selectedPoolAddress = null;
      _poolSelected = false;
      _poolSearchController.clear();
    });
  }

  void _initializeEditingMode() {
    final record = widget.maintenanceRecord!;

    // Basic information
    _notesController.text = record['notes'] ?? '';
    _phController.text = record['waterQuality']?['ph']?.toString() ?? '';
    _chlorineController.text =
        record['waterQuality']?['chlorine']?.toString() ?? '';
    _alkalinityController.text =
        record['waterQuality']?['alkalinity']?.toString() ?? '';
    _calciumController.text =
        record['waterQuality']?['calcium']?.toString() ?? '';
    _costController.text = record['cost']?.toString() ?? '';
    _technicianController.text =
        record['performedByName'] ?? record['performedBy'] ?? '';
    _selectedStatus = record['status'] ?? 'Completed';

    // Dates
    if (record['date'] != null) {
      _selectedDate = (record['date'] as Timestamp).toDate();
    }
    if (record['nextMaintenanceDate'] != null) {
      _nextMaintenanceDate = (record['nextMaintenanceDate'] as Timestamp)
          .toDate();
    }

    // Load selected chemicals and physical items
    if (record['chemicals'] != null) {
      _selectedChemicals = Set<String>.from(record['chemicals'] as List);
    }
    if (record['physical'] != null) {
      _selectedPhysical = Set<String>.from(record['physical'] as List);
    }

    // Standard chemicals
    final standardChemicals =
        record['standardChemicals'] as Map<String, dynamic>? ?? {};
    _chlorineLiquidGallons =
        (standardChemicals['chlorineLiquidGallons'] as num?)?.toDouble() ?? 0.0;
    _chlorineTablets =
        (standardChemicals['chlorineTablets'] as num?)?.toInt() ?? 0;
    _muriaticAcidGallons =
        (standardChemicals['muriaticAcidGallons'] as num?)?.toDouble() ?? 0.0;
    _standardCalciumHypochloriteLbs =
        (standardChemicals['calciumHypochloriteLbs'] as num?)?.toDouble() ??
        0.0;
    _algaecideUsed = standardChemicals['algaecideUsed'] as bool? ?? false;

    // Note: Auto-population moved to end of method to ensure all data is loaded first

    // Standard physical
    final standardPhysical =
        record['standardPhysical'] as Map<String, dynamic>? ?? {};
    _wallBrushUsed = standardPhysical['wallBrushUsed'] as bool? ?? false;
    _cartridgeFilterCleanerUsed =
        standardPhysical['cartridgeFilterCleanerUsed'] as bool? ?? false;
    _poolFilterCleanUpUsed =
        standardPhysical['poolFilterCleanUpUsed'] as bool? ?? false;

    // Note: Auto-population moved to end of method to ensure all data is loaded first

    // Detailed chemicals
    final detailedChemicals =
        record['detailedChemicals'] as Map<String, dynamic>? ?? {};
    _calciumHypochloriteLbs =
        (detailedChemicals['calciumHypochloriteLbs'] as num?)?.toDouble() ??
        0.0;
    _copperAlgaecideUsed =
        detailedChemicals['copperAlgaecideUsed'] as bool? ?? false;
    _polyquatAlgaecideUsed =
        detailedChemicals['polyquatAlgaecideUsed'] as bool? ?? false;
    _quatAmmoniumGallons =
        (detailedChemicals['quatAmmoniumGallons'] as num?)?.toDouble() ?? 0.0;
    _sodiumCarbonateLbs =
        (detailedChemicals['sodiumCarbonateLbs'] as num?)?.toDouble() ?? 0.0;
    _chelatingUsed = detailedChemicals['chelatingUsed'] as bool? ?? false;
    _poolClarifierUsed =
        detailedChemicals['poolClarifierUsed'] as bool? ?? false;
    _flocculantUsed = detailedChemicals['flocculantUsed'] as bool? ?? false;
    _metalRemoverUsed = detailedChemicals['metalRemoverUsed'] as bool? ?? false;
    _sodiumBicarbonateLbs =
        (detailedChemicals['sodiumBicarbonateLbs'] as num?)?.toDouble() ?? 0.0;

    // Detailed physical - Pool Filter
    final detailedPhysical =
        record['detailedPhysical'] as Map<String, dynamic>? ?? {};
    final poolFilter =
        detailedPhysical['poolFilter'] as Map<String, dynamic>? ?? {};
    _filterInstallCostController.text =
        (poolFilter['installCost'] as num?)?.toString() ?? '';
    _filterReplaceCostController.text =
        (poolFilter['replaceCost'] as num?)?.toString() ?? '';

    // Pool Pump
    final poolPump =
        detailedPhysical['poolPump'] as Map<String, dynamic>? ?? {};
    _pumpCleanUp = poolPump['cleanUp'] as bool? ?? false;
    _pumpInstallCostController.text =
        (poolPump['installCost'] as num?)?.toString() ?? '';
    _pumpReplaceCostController.text =
        (poolPump['replaceCost'] as num?)?.toString() ?? '';
    _pumpRepairCostController.text =
        (poolPump['repairCost'] as num?)?.toString() ?? '';

    // Salt System
    final saltSystem =
        detailedPhysical['saltSystem'] as Map<String, dynamic>? ?? {};
    _saltCleanUp = saltSystem['cleanUp'] as bool? ?? false;
    _saltInstallCostController.text =
        (saltSystem['installCost'] as num?)?.toString() ?? '';
    _saltReplaceCostController.text =
        (saltSystem['replaceCost'] as num?)?.toString() ?? '';
    _saltRepairCostController.text =
        (saltSystem['repairCost'] as num?)?.toString() ?? '';

    // Pipe Replace
    final pipeReplace =
        detailedPhysical['pipeReplace'] as Map<String, dynamic>? ?? {};
    _pipeCleanUp = pipeReplace['cleanUp'] as bool? ?? false;
    _pipeInstallCostController.text =
        (pipeReplace['installCost'] as num?)?.toString() ?? '';
    _pipeReplaceCostController.text =
        (pipeReplace['replaceCost'] as num?)?.toString() ?? '';
    _pipeRepairCostController.text =
        (pipeReplace['repairCost'] as num?)?.toString() ?? '';

    // Surface Cleaners
    final surfaceCleaners =
        detailedPhysical['surfaceCleaners'] as Map<String, dynamic>? ?? {};
    _surfaceCleanCostController.text =
        (surfaceCleaners['cost'] as num?)?.toString() ?? '';

    // Enzyme Cleaners
    final enzymeCleaners =
        detailedPhysical['enzymeCleaners'] as Map<String, dynamic>? ?? {};
    _enzymeCleanCostController.text =
        (enzymeCleaners['cost'] as num?)?.toString() ?? '';

    // Filter Cleaners
    final filterCleaners =
        detailedPhysical['filterCleaners'] as Map<String, dynamic>? ?? {};
    _sandFilterClean = filterCleaners['sandFilterClean'] as bool? ?? false;
    _deFilterCostController.text =
        (filterCleaners['deFilterCost'] as num?)?.toString() ?? '';

    // Auto-populate chemicals array based on standard maintenance data (moved here after all data is loaded)
    if (_selectedChemicals.isEmpty) {
      if (_chlorineLiquidGallons > 0) {
        _selectedChemicals.add('Chlorine liquid');
      }
      if (_chlorineTablets > 0) {
        _selectedChemicals.add('Stabilized Chlorine Tablets');
      }
      if (_muriaticAcidGallons > 0) {
        _selectedChemicals.add('Muriatic acid – lowers pH');
      }
      if (_standardCalciumHypochloriteLbs > 0) {
        _selectedChemicals.add('Calcium hypochlorite (Cal-hypo)');
      }
      if (_algaecideUsed) {
        _selectedChemicals.add('Copper-based algaecides');
      }
    }

    // Auto-populate physical array based on standard maintenance data (moved here after all data is loaded)
    if (_selectedPhysical.isEmpty) {
      if (_wallBrushUsed) {
        _selectedPhysical.add('Pool Wall brushes and vacuums');
      }
      if (_cartridgeFilterCleanerUsed) {
        _selectedPhysical.add('Cartridge filter cleaner');
      }
      if (_poolFilterCleanUpUsed) {
        _selectedPhysical.add('Pool Filter');
      }
    }

    // Force a rebuild to ensure UI updates
    if (mounted) {
      setState(() {
        // This will trigger a rebuild with the new values
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _phController.dispose();
    _chlorineController.dispose();
    _alkalinityController.dispose();
    _calciumController.dispose();
    _costController.dispose();
    _poolSearchController.dispose();
    _filterInstallCostController.dispose();
    _filterReplaceCostController.dispose();
    _pumpInstallCostController.dispose();
    _pumpReplaceCostController.dispose();
    _pumpRepairCostController.dispose();
    _saltInstallCostController.dispose();
    _saltReplaceCostController.dispose();
    _saltRepairCostController.dispose();
    _pipeInstallCostController.dispose();
    _pipeReplaceCostController.dispose();
    _pipeRepairCostController.dispose();
    _surfaceCleanCostController.dispose();
    _enzymeCleanCostController.dispose();
    _deFilterCostController.dispose();
    _technicianController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectNextMaintenanceDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _nextMaintenanceDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _nextMaintenanceDate = picked;
      });
    }
  }

  void _toggleChemical(String chemical) {
    setState(() {
      if (_selectedChemicals.contains(chemical)) {
        _selectedChemicals.remove(chemical);
      } else {
        _selectedChemicals.add(chemical);
      }
    });
  }

  void _togglePhysical(String physical) {
    setState(() {
      if (_selectedPhysical.contains(physical)) {
        _selectedPhysical.remove(physical);
      } else {
        _selectedPhysical.add(physical);
      }
    });
  }

  Future<void> _saveMaintenance() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final authService = context.read<AuthService>();
      final poolService = context.read<PoolService>();
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      String? performedById = _isEditing
          ? widget.maintenanceRecord!['performedBy']
          : currentUser.id;
      String? performedByName = _isEditing
          ? _technicianController.text
          : currentUser.displayName ?? currentUser.email;

      final maintenanceData = {
        'status': _selectedStatus,
        'notes': _notesController.text.trim(),
        'cost': double.tryParse(_costController.text.trim()) ?? 0.0,
        'performedBy': performedById,
        'performedByName': performedByName,
        'date': Timestamp.fromDate(_selectedDate),
        'nextMaintenanceDate': _nextMaintenanceDate,
        'chemicals': _selectedChemicals.toList(),
        'physical': _selectedPhysical.toList(),
        'standardChemicals': {
          'chlorineLiquidGallons': _chlorineLiquidGallons,
          'chlorineTablets': _chlorineTablets,
          'muriaticAcidGallons': _muriaticAcidGallons,
          'calciumHypochloriteLbs': _standardCalciumHypochloriteLbs,
          'algaecideUsed': _algaecideUsed,
        },
        'standardPhysical': {
          'wallBrushUsed': _wallBrushUsed,
          'cartridgeFilterCleanerUsed': _cartridgeFilterCleanerUsed,
          'poolFilterCleanUpUsed': _poolFilterCleanUpUsed,
        },
        'detailedChemicals': {
          'calciumHypochloriteLbs': _calciumHypochloriteLbs,
          'copperAlgaecideUsed': _copperAlgaecideUsed,
          'polyquatAlgaecideUsed': _polyquatAlgaecideUsed,
          'quatAmmoniumGallons': _quatAmmoniumGallons,
          'sodiumCarbonateLbs': _sodiumCarbonateLbs,
          'chelatingUsed': _chelatingUsed,
          'poolClarifierUsed': _poolClarifierUsed,
          'flocculantUsed': _flocculantUsed,
          'metalRemoverUsed': _metalRemoverUsed,
          'sodiumBicarbonateLbs': _sodiumBicarbonateLbs,
        },
        'detailedPhysical': {
          'poolFilter': {
            'installCost': double.tryParse(
              _filterInstallCostController.text.trim(),
            ),
            'replaceCost': double.tryParse(
              _filterReplaceCostController.text.trim(),
            ),
          },
          'poolPump': {
            'cleanUp': _pumpCleanUp,
            'installCost': double.tryParse(
              _pumpInstallCostController.text.trim(),
            ),
            'replaceCost': double.tryParse(
              _pumpReplaceCostController.text.trim(),
            ),
            'repairCost': double.tryParse(
              _pumpRepairCostController.text.trim(),
            ),
          },
          'saltSystem': {
            'cleanUp': _saltCleanUp,
            'installCost': double.tryParse(
              _saltInstallCostController.text.trim(),
            ),
            'replaceCost': double.tryParse(
              _saltReplaceCostController.text.trim(),
            ),
            'repairCost': double.tryParse(
              _saltRepairCostController.text.trim(),
            ),
          },
          'pipeReplace': {
            'cleanUp': _pipeCleanUp,
            'installCost': double.tryParse(
              _pipeInstallCostController.text.trim(),
            ),
            'replaceCost': double.tryParse(
              _pipeReplaceCostController.text.trim(),
            ),
            'repairCost': double.tryParse(
              _pipeRepairCostController.text.trim(),
            ),
          },
          'surfaceCleaners': {
            'cost': double.tryParse(_surfaceCleanCostController.text.trim()),
          },
          'enzymeCleaners': {
            'cost': double.tryParse(_enzymeCleanCostController.text.trim()),
          },
          'filterCleaners': {
            'sandFilterClean': _sandFilterClean,
            'deFilterCost': double.tryParse(
              _deFilterCostController.text.trim(),
            ),
          },
        },
        'waterQuality': {
          'ph': double.tryParse(_phController.text.trim()),
          'chlorine': double.tryParse(_chlorineController.text.trim()),
          'alkalinity': double.tryParse(_alkalinityController.text.trim()),
          'calcium': double.tryParse(_calciumController.text.trim()),
        },
      };

      final poolId = _selectedPoolId ?? widget.poolId;
      if (poolId == null) {
        throw Exception('Please select a pool first');
      }
      bool success = false;
      if (_isEditing) {
        final maintenanceId =
            widget.maintenanceRecord!['id'] ??
            widget.maintenanceRecord!['maintenanceId'];
        if (maintenanceId == null)
          throw Exception('Maintenance record ID missing');
        success = await context.read<PoolService>().updateMaintenanceRecord(
          maintenanceId,
          maintenanceData,
        );
      } else {
        success = await context.read<PoolService>().addMaintenanceRecord(
          poolId,
          maintenanceData,
          currentUser.id,
          currentUser.displayName ?? currentUser.email!,
        );
      }
      if (success) {
        // Check if this maintenance completion should close any routes
        if (!_isEditing && currentUser.companyId != null) {
          await _checkAndCloseRoutesForPool(poolId!, currentUser.companyId!);
        }

        if (mounted) {
          Navigator.of(context).pop(true);
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isEditing
                      ? 'Maintenance record updated successfully!'
                      : 'Maintenance record saved successfully!',
                ),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            print('❌ Error showing success notification: $e');
          }
        }
      } else {
        if (mounted) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to save maintenance record: ${context.read<PoolService>().error ?? 'Unknown error'}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          } catch (e) {
            print('❌ Error showing error notification: $e');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        } catch (snackBarError) {
          print('❌ Error showing error snackbar: $snackBarError');
        }
      }
    } finally {
      // Loading state handled by the operation itself
    }
  }

  Widget _buildStandardMaintenanceParentCard() {
    return AppCard(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Standard Maintenance',
                  style: AppTextStyles.headline.copyWith(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Chemical Section
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              child: _buildStandardChemicalSection(),
            ),
            // Physical Section (remove inner AppCard)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Standard Physical Maintenance',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 16),
                  _buildStandardPhysicalSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardChemicalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Standard Chemical Maintenance',
          style: AppTextStyles.subtitle.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        // Chlorine Liquid
        Row(
          children: [
            Expanded(child: Text('Chlorine (gal)', style: AppTextStyles.body)),
            IconButton(
              icon: Icon(
                Icons.remove,
                color: _chlorineLiquidGallons > 0
                    ? AppColors.primary
                    : AppColors.greyDark,
              ),
              onPressed: _chlorineLiquidGallons > 0
                  ? () {
                      setState(() {
                        _chlorineLiquidGallons -= 0.5;
                      });
                    }
                  : null,
            ),
            Text(
              _chlorineLiquidGallons.toStringAsFixed(1),
              style: TextStyle(color: AppColors.textPrimary),
            ),
            IconButton(
              icon: Icon(
                Icons.add,
                color: _chlorineLiquidGallons < 10
                    ? AppColors.primary
                    : AppColors.greyDark,
              ),
              onPressed: _chlorineLiquidGallons < 10
                  ? () {
                      setState(() {
                        _chlorineLiquidGallons += 0.5;
                      });
                    }
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Chlorine Tablets
        Row(
          children: [
            Expanded(
              child: Text('Stabilized Tablets', style: AppTextStyles.body),
            ),
            IconButton(
              icon: Icon(
                Icons.remove,
                color: _chlorineTablets > 0
                    ? AppColors.primary
                    : AppColors.greyDark,
              ),
              onPressed: _chlorineTablets > 0
                  ? () {
                      setState(() {
                        _chlorineTablets -= 1;
                      });
                    }
                  : null,
            ),
            Text(
              _chlorineTablets.toString(),
              style: TextStyle(color: AppColors.textPrimary),
            ),
            IconButton(
              icon: Icon(
                Icons.add,
                color: _chlorineTablets < 10
                    ? AppColors.primary
                    : AppColors.greyDark,
              ),
              onPressed: _chlorineTablets < 10
                  ? () {
                      setState(() {
                        _chlorineTablets += 1;
                      });
                    }
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Muriatic Acid
        Row(
          children: [
            Expanded(
              child: Text('Muriatic Acid (gal)', style: AppTextStyles.body),
            ),
            IconButton(
              icon: Icon(
                Icons.remove,
                color: _muriaticAcidGallons > 0
                    ? AppColors.primary
                    : AppColors.greyDark,
              ),
              onPressed: _muriaticAcidGallons > 0
                  ? () {
                      setState(() {
                        _muriaticAcidGallons -= 0.5;
                      });
                    }
                  : null,
            ),
            Text(
              _muriaticAcidGallons.toStringAsFixed(2),
              style: TextStyle(color: AppColors.textPrimary),
            ),
            IconButton(
              icon: Icon(
                Icons.add,
                color: _muriaticAcidGallons < 10
                    ? AppColors.primary
                    : AppColors.greyDark,
              ),
              onPressed: _muriaticAcidGallons < 10
                  ? () {
                      setState(() {
                        _muriaticAcidGallons += 0.5;
                      });
                    }
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Calcium Hypochlorite
        Row(
          children: [
            Expanded(
              child: Text(
                'Calcium Hypochlorite (lbs)',
                style: AppTextStyles.body,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.remove,
                color: _standardCalciumHypochloriteLbs > 0
                    ? AppColors.primary
                    : AppColors.greyDark,
              ),
              onPressed: _standardCalciumHypochloriteLbs > 0
                  ? () {
                      setState(() {
                        _standardCalciumHypochloriteLbs -= 0.5;
                      });
                    }
                  : null,
            ),
            Text(
              _standardCalciumHypochloriteLbs.toStringAsFixed(1),
              style: TextStyle(color: AppColors.textPrimary),
            ),
            IconButton(
              icon: Icon(
                Icons.add,
                color: _standardCalciumHypochloriteLbs < 10
                    ? AppColors.primary
                    : AppColors.greyDark,
              ),
              onPressed: _standardCalciumHypochloriteLbs < 10
                  ? () {
                      setState(() {
                        _standardCalciumHypochloriteLbs += 0.5;
                      });
                    }
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Algaecide Used
        Row(
          children: [
            Expanded(child: Text('Algaecide Used', style: AppTextStyles.body)),
            Checkbox(
              value: _algaecideUsed,
              onChanged: (val) {
                setState(() {
                  _algaecideUsed = val ?? false;
                });
              },
              side: const BorderSide(color: AppColors.primary, width: 2),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStandardPhysicalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: const Text(
            'Pool Wall brush, cleaning with net, and Vacuum',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          value: _wallBrushUsed,
          onChanged: (val) => setState(() => _wallBrushUsed = val ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          side: const BorderSide(color: AppColors.primary, width: 2),
          activeColor: AppColors.primary,
        ),
        CheckboxListTile(
          title: const Text(
            'Cartridge filter cleaner',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          value: _cartridgeFilterCleanerUsed,
          onChanged: (val) =>
              setState(() => _cartridgeFilterCleanerUsed = val ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          side: const BorderSide(color: AppColors.primary, width: 2),
          activeColor: AppColors.primary,
        ),
        CheckboxListTile(
          title: const Text(
            'Pool Filter Clean Up',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          value: _poolFilterCleanUpUsed,
          onChanged: (val) =>
              setState(() => _poolFilterCleanUpUsed = val ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          side: const BorderSide(color: AppColors.primary, width: 2),
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildDetailedChemicalSection() {
    return AppCard(
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chemicals (Detailed)',
              style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Group 1: Checkbox options
            Text(
              'Additives (Checkbox)',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: Text(
                'Copper-based algaecides',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              value: _copperAlgaecideUsed,
              onChanged: (val) =>
                  setState(() => _copperAlgaecideUsed = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              side: const BorderSide(color: AppColors.primary, width: 2),
              activeColor: AppColors.primary,
            ),
            CheckboxListTile(
              title: Text(
                'Polyquat Algaecides',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              value: _polyquatAlgaecideUsed,
              onChanged: (val) =>
                  setState(() => _polyquatAlgaecideUsed = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              side: const BorderSide(color: AppColors.primary, width: 2),
              activeColor: AppColors.primary,
            ),
            CheckboxListTile(
              title: Text(
                'Chelating',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              value: _chelatingUsed,
              onChanged: (val) => setState(() => _chelatingUsed = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              side: const BorderSide(color: AppColors.primary, width: 2),
              activeColor: AppColors.primary,
            ),
            CheckboxListTile(
              title: Text(
                'Pool clarifier',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              value: _poolClarifierUsed,
              onChanged: (val) =>
                  setState(() => _poolClarifierUsed = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              side: const BorderSide(color: AppColors.primary, width: 2),
              activeColor: AppColors.primary,
            ),
            CheckboxListTile(
              title: Text(
                'Flocculant',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              value: _flocculantUsed,
              onChanged: (val) =>
                  setState(() => _flocculantUsed = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              side: const BorderSide(color: AppColors.primary, width: 2),
              activeColor: AppColors.primary,
            ),
            CheckboxListTile(
              title: Text(
                'Metal removers',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              value: _metalRemoverUsed,
              onChanged: (val) =>
                  setState(() => _metalRemoverUsed = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              side: const BorderSide(color: AppColors.primary, width: 2),
              activeColor: AppColors.primary,
            ),
            const Divider(height: 32),
            // Group 2: Quantity options
            Text(
              'Measured Chemicals (Quantity)',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Quaternary Ammonium [gal]',
                    style: AppTextStyles.body,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.remove,
                    color: _quatAmmoniumGallons > 0
                        ? AppColors.primary
                        : AppColors.greyDark,
                  ),
                  onPressed: _quatAmmoniumGallons > 0
                      ? () {
                          setState(() {
                            _quatAmmoniumGallons -= 0.25;
                          });
                        }
                      : null,
                ),
                Text(
                  _quatAmmoniumGallons.toStringAsFixed(2),
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: _quatAmmoniumGallons < 10
                        ? AppColors.primary
                        : AppColors.greyDark,
                  ),
                  onPressed: _quatAmmoniumGallons < 10
                      ? () {
                          setState(() {
                            _quatAmmoniumGallons += 0.25;
                          });
                        }
                      : null,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sodium carbonate (soda ash) [lbs]',
                    style: AppTextStyles.body,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.remove,
                    color: _sodiumCarbonateLbs > 0
                        ? AppColors.primary
                        : AppColors.greyDark,
                  ),
                  onPressed: _sodiumCarbonateLbs > 0
                      ? () {
                          setState(() {
                            _sodiumCarbonateLbs -= 0.5;
                          });
                        }
                      : null,
                ),
                Text(
                  _sodiumCarbonateLbs.toStringAsFixed(1),
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: _sodiumCarbonateLbs < 10
                        ? AppColors.primary
                        : AppColors.greyDark,
                  ),
                  onPressed: _sodiumCarbonateLbs < 10
                      ? () {
                          setState(() {
                            _sodiumCarbonateLbs += 0.5;
                          });
                        }
                      : null,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sodium bicarbonate [lbs]',
                    style: AppTextStyles.body,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.remove,
                    color: _sodiumBicarbonateLbs > 0
                        ? AppColors.primary
                        : AppColors.greyDark,
                  ),
                  onPressed: _sodiumBicarbonateLbs > 0
                      ? () {
                          setState(() {
                            _sodiumBicarbonateLbs -= 0.5;
                          });
                        }
                      : null,
                ),
                Text(
                  _sodiumBicarbonateLbs.toStringAsFixed(1),
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: _sodiumBicarbonateLbs < 10
                        ? AppColors.primary
                        : AppColors.greyDark,
                  ),
                  onPressed: _sodiumBicarbonateLbs < 10
                      ? () {
                          setState(() {
                            _sodiumBicarbonateLbs += 0.5;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedPhysicalSection() {
    return AppCard(
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Physical (Detailed)',
              style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Pool Filter
            Text(
              'Pool Filter',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            AppTextField(
              controller: _filterInstallCostController,
              label: 'Installation (cost)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            AppTextField(
              controller: _filterReplaceCostController,
              label: 'Replace (cost)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const Divider(),
            // Pool Pump
            Text(
              'Pool Pump',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            CheckboxListTile(
              title: const Text(
                'Clean Up',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              value: _pumpCleanUp,
              onChanged: (val) => setState(() => _pumpCleanUp = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              side: const BorderSide(color: AppColors.primary, width: 2),
              activeColor: AppColors.primary,
            ),
            AppTextField(
              controller: _pumpInstallCostController,
              label: 'Installation (cost)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            AppTextField(
              controller: _pumpReplaceCostController,
              label: 'Replace (cost)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            AppTextField(
              controller: _pumpRepairCostController,
              label: 'Reparation (cost)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const Divider(),
            // Salt System
            Text(
              'Salt System',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            CheckboxListTile(
              title: const Text(
                'Clean Up',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              value: _saltCleanUp,
              onChanged: (val) => setState(() => _saltCleanUp = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              side: const BorderSide(color: AppColors.primary, width: 2),
              activeColor: AppColors.primary,
            ),
            AppTextField(
              controller: _saltInstallCostController,
              label: 'Installation (cost)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            AppTextField(
              controller: _saltReplaceCostController,
              label: 'Replace (cost)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            AppTextField(
              controller: _saltRepairCostController,
              label: 'Reparation (cost)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const Divider(),
            // Pipe Replace
            Text(
              'Pipe Replace',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            CheckboxListTile(
              title: const Text(
                'Clean Up',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              value: _pipeCleanUp,
              onChanged: (val) => setState(() => _pipeCleanUp = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              side: const BorderSide(color: AppColors.primary, width: 2),
              activeColor: AppColors.primary,
            ),
            AppTextField(
              controller: _pipeInstallCostController,
              label: 'Installation (cost)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            AppTextField(
              controller: _pipeReplaceCostController,
              label: 'Replace (cost)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            AppTextField(
              controller: _pipeRepairCostController,
              label: 'Reparation (cost)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const Divider(),
            // Surface Cleaners
            Text(
              'Surface Cleaners',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            AppTextField(
              controller: _surfaceCleanCostController,
              label: 'Tile and vinyl cleaners (cost)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const Divider(),
            // Enzyme Cleaners
            Text(
              'Enzyme Cleaners',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            AppTextField(
              controller: _enzymeCleanCostController,
              label:
                  'Break down oils, lotions, and organic contaminants (cost)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const Divider(),
            // Filter Cleaners
            Text(
              'Filter Cleaners',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            CheckboxListTile(
              title: const Text(
                'Sand filter cleaner',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              value: _sandFilterClean,
              onChanged: (val) =>
                  setState(() => _sandFilterClean = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              side: const BorderSide(color: AppColors.primary, width: 2),
              activeColor: AppColors.primary,
            ),
            AppTextField(
              controller: _deFilterCostController,
              label: 'Diatomaceous Earth (cost)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            Text('Subtotal Cost: ' + _physicalTotalCost.toStringAsFixed(2)),
          ],
        ),
      ),
    );
  }

  Future<void> _getUserLocationAndFilterPools() async {
    setState(() {
      _loadingLocation = true;
      _locationError = false;
      _gpsStepComplete = false;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = true;
          _loadingLocation = false;
        });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = true;
            _loadingLocation = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = true;
          _loadingLocation = false;
        });
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _userPosition = position;
        _loadingLocation = false;
        _nearbyPools = _availablePools.where((pool) {
          if (pool['lat'] == null || pool['lng'] == null) return false;
          double distance = _calculateDistance(
            position.latitude,
            position.longitude,
            pool['lat'],
            pool['lng'],
          );
          return distance <= 20.0; // miles
        }).toList();
      });
    } catch (e) {
      setState(() {
        _locationError = true;
        _loadingLocation = false;
      });
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double R = 3958.8; // Radius of Earth in miles
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);
    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  void _completeGpsStep() {
    setState(() {
      _gpsStepComplete = true;
    });
  }

  void _continueToMaintenance() {
    if (_poolSelected && _selectedPoolId != null) {
      setState(() {
        _showMaintenanceForm = true;
      });
    }
  }

  // Helper method to get customer phone number
  Future<String?> _getCustomerPhoneNumber() async {
    if (_selectedPoolId != null) {
      final pool = _availablePools.firstWhere(
        (pool) => pool['id'] == _selectedPoolId,
        orElse: () => {},
      );

      final customerEmail = pool['customerEmail'];
      if (customerEmail != null) {
        try {
          // Get customer data from Firestore
          final customerDoc = await FirebaseFirestore.instance
              .collection('customers')
              .where('email', isEqualTo: customerEmail)
              .limit(1)
              .get();

          if (customerDoc.docs.isNotEmpty) {
            final customerData = customerDoc.docs.first.data();
            return customerData['phone'] as String?;
          }
        } catch (e) {
          print('❌ Error getting customer phone: $e');
        }
      }
    }
    return null;
  }

  // Method to call pool owner
  Future<void> _callPoolOwner() async {
    final phoneNumber = await _getCustomerPhoneNumber();

    if (phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No phone number available for this pool owner'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Could not launch phone app for: $phoneNumber'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error making call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing && !_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeEditingMode();
        _initialized = true;
      });
    }
    if (!_gpsStepComplete && widget.poolId == null && !_isEditing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Pool for Maintenance')),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: OptimizedMaintenancePoolsMap(
                  companyId:
                      null, // Will be determined by the widget from current user
                  onPoolSelected: (poolId, poolName, address) {
                    final poolData = _availablePools.firstWhere(
                      (pool) => pool['id'] == poolId,
                      orElse: () => {
                        'id': poolId,
                        'name': poolName,
                        'address': address,
                        'latitude': null,
                        'longitude': null,
                      },
                    );
                    _selectPool(poolData);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completeGpsStep,
                  child: const Text('Continue'),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          _showMaintenanceForm
              ? (_isEditing
                    ? 'Edit Maintenance Record'
                    : 'Add Maintenance Record')
              : 'Select Pool for Maintenance',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_showMaintenanceForm && widget.poolId == null) {
              _backToPoolSelection();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          if (_selectedPoolId != null)
            IconButton(
              onPressed: _callPoolOwner,
              icon: const Icon(Icons.phone, color: Colors.white),
              tooltip: 'Call Pool Owner',
            ),
        ],
      ),
      body: () {
        return _showMaintenanceForm
            ? _buildMaintenanceForm()
            : _buildPoolSelectionView();
      }(),
    );
  }

  Widget _buildPoolSelectionView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header section with padding
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Banner
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        Color.fromRGBO(59, 130, 246, 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 20,
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.pool, color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Choose Pool for Maintenance',
                        style: AppTextStyles.headline.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Search for a pool or select from the map below',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Toggle Buttons
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 8),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              setState(() => _poolSelectionMethod = 'search'),
                          icon: const Icon(Icons.search),
                          label: const Text('Search Pools'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _poolSelectionMethod == 'search'
                                ? AppColors.primary
                                : Colors.white,
                            foregroundColor: _poolSelectionMethod == 'search'
                                ? Colors.white
                                : AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              setState(() => _poolSelectionMethod = 'map'),
                          icon: const Icon(Icons.map),
                          label: const Text('Map View'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _poolSelectionMethod == 'map'
                                ? AppColors.primary
                                : Colors.white,
                            foregroundColor: _poolSelectionMethod == 'map'
                                ? Colors.white
                                : AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Continue to Maintenance button - only show if pool is selected
                if (_poolSelected) ...[
                  if (_selectedPoolAddress != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        _selectedPoolAddress!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headline.copyWith(
                          fontSize: 20, // Explicitly setting a larger font size
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _continueToMaintenance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continue to Maintenance',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],

                // Search Input
                if (_poolSelectionMethod == 'search') ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search Pools',
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _poolSearchController,
                          decoration: InputDecoration(
                            hintText:
                                'Search by pool name, address, or customer...',
                            hintStyle: TextStyle(
                              color: Color.fromRGBO(107, 114, 128, 0.7),
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.primary,
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color.fromRGBO(59, 130, 246, 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color.fromRGBO(59, 130, 246, 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 2.0,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                            suffixIcon: _poolSearchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () {
                                      _poolSearchController.clear();
                                      _filterPools('');
                                    },
                                  )
                                : null,
                          ),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          onChanged: _filterPools,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search results
                  if (_poolSearchController.text.isNotEmpty &&
                      _filteredPools.isNotEmpty)
                    AppCard(
                      child: Container(
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Search Results (${_filteredPools.length})',
                              style: AppTextStyles.subtitle,
                            ),
                            const SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredPools.length > 5
                                  ? 5
                                  : _filteredPools.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(),
                              itemBuilder: (context, index) {
                                final pool = _filteredPools[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: const Icon(
                                      Icons.pool,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    pool['name'] ?? 'Unnamed Pool',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    pool['address'] ?? 'No address',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () => _selectPool(pool),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_poolSearchController.text.isEmpty)
                    AppCard(
                      child: Container(
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All Available Pools (${_availablePools.length})',
                              style: AppTextStyles.subtitle,
                            ),
                            const SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _availablePools.length > 10
                                  ? 10
                                  : _availablePools.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(),
                              itemBuilder: (context, index) {
                                final pool = _availablePools[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: const Icon(
                                      Icons.pool,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    pool['name'] ?? 'Unnamed Pool',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    pool['address'] ?? 'No address',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () => _selectPool(pool),
                                );
                              },
                            ),
                            if (_availablePools.length > 10)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Showing first 10 pools. Use search to find specific pools.',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),

          // Map View
          if (_poolSelectionMethod == 'map')
            Expanded(
              child: OptimizedMaintenancePoolsMap(
                companyId:
                    null, // Will be determined by the widget from current user
                onPoolSelected: (poolId, poolName, address) {
                  final poolData = _availablePools.firstWhere(
                    (pool) => pool['id'] == poolId,
                    orElse: () => {
                      'id': poolId,
                      'name': poolName,
                      'address': address,
                      'latitude': null,
                      'longitude': null,
                    },
                  );
                  _selectPool(poolData);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add a colorful header banner
            AppCard(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              child: Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isEditing ? Icons.edit : Icons.add_circle,
                          color: AppColors.primary,
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isEditing
                                ? 'Edit Maintenance Record'
                                : 'Add Maintenance Record',
                            style: AppTextStyles.headline.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEditing
                          ? 'Modify existing maintenance record for this pool'
                          : 'Register all actions and chemicals for this pool',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Selected Pool Display
            AppCard(
              child: Container(
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(Icons.pool, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pool: ${_selectedPoolName ?? widget.poolName}',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // and the SizedBox before it.
            const SizedBox(height: 8),
            // Basic Information Section (restored)
            AppCard(
              child: Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Basic Information',
                          style: AppTextStyles.subtitle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      items: _statusOptions
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                status,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedStatus = val ?? 'Completed'),
                      dropdownColor: AppColors.primary,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.primary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color.fromRGBO(59, 130, 246, 0.3),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      onTap: _selectDate,
                      controller: TextEditingController(
                        text: _selectedDate != null
                            ? DateFormat('MM/dd/yyyy').format(_selectedDate)
                            : '',
                      ),
                      decoration: InputDecoration(
                        labelText: 'Maintenance Date',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color.fromRGBO(59, 130, 246, 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.calendar_today,
                          color: AppColors.primary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _isEditing
                        ? TextFormField(
                            readOnly: true,
                            enabled: false,
                            controller: _technicianController,
                            decoration: InputDecoration(
                              labelText: 'Technician',
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color.fromRGBO(59, 130, 246, 0.3),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : const SizedBox.shrink(),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _costController,
                      label: 'Cost',
                      hint: 'Enter total cost',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Standard Maintenance (parent card)
            _buildStandardMaintenanceParentCard(),
            const SizedBox(height: 32),

            // Detailed Chemical Section (collapsible)
            CollapsibleCard(
              title: 'Chemical Maintenance',
              icon: Icons.science,
              initiallyExpanded: false,
              child: _buildDetailedChemicalSection(),
            ),
            const SizedBox(height: 24),

            // Detailed Physical Section (collapsible)
            CollapsibleCard(
              title: 'Physical Maintenance',
              icon: Icons.build,
              initiallyExpanded: false,
              child: _buildDetailedPhysicalSection(),
            ),
            const SizedBox(height: 24),
            // Water Quality Metrics Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Water Quality Metrics',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _phController,
                          label: 'pH Level',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          controller: _chlorineController,
                          label: 'Chlorine (ppm)',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _alkalinityController,
                          label: 'Total Alkalinity (ppm)',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          controller: _calciumController,
                          label: 'Calcium Hardness (ppm)',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Notes Section (restored)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.folder, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Notes',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _notesController,
                    label: 'Notes',
                    hint: 'Add any additional notes about this maintenance...',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: _isEditing
                    ? 'Update Maintenance Record'
                    : 'Save Maintenance Record',
                onPressed: _saveMaintenance,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Check and close routes that contain this pool if all pools in the route are maintained
  Future<void> _checkAndCloseRoutesForPool(
    String poolId,
    String companyId,
  ) async {
    try {
      print(
        '🔍 Checking if pool $poolId completion should close any routes...',
      );

      // Get current user to check permissions
      final currentUser = context.read<AuthService>().currentUser;
      if (currentUser == null) {
        print('❌ No current user found for route checking');
        return;
      }

      // Only company admins can check and close routes
      if (currentUser.role != 'admin') {
        print('ℹ️ User is not admin, skipping route checking');
        return;
      }

      // Find all routes that contain this pool
      final routesSnapshot = await FirebaseFirestore.instance
          .collection('routes')
          .where('companyId', isEqualTo: companyId)
          .where('status', whereIn: ['ACTIVE', 'active', 'in_progress'])
          .get();

      for (final routeDoc in routesSnapshot.docs) {
        final routeData = routeDoc.data();
        final stops = routeData['stops'] ?? [];

        // Check if this route contains the pool that was just maintained
        bool routeContainsPool = false;
        List<String> poolIds = [];

        if (stops.isNotEmpty && stops.first is String) {
          poolIds = List<String>.from(stops);
          routeContainsPool = poolIds.contains(poolId);
        } else if (stops.isNotEmpty && stops.first is Map<String, dynamic>) {
          poolIds = stops
              .map((stop) => stop['poolId'] ?? stop['id'] ?? '')
              .where((id) => id.isNotEmpty)
              .toList();
          routeContainsPool = poolIds.contains(poolId);
        }

        if (routeContainsPool) {
          print(
            '🔍 Found route ${routeDoc.id} containing pool $poolId. Checking if route should be closed...',
          );

          // Use the PoolService to check and close the route if all pools are maintained
          final poolService = context.read<PoolService>();
          final routeClosed = await poolService.checkAndCloseRouteIfComplete(
            routeDoc.id,
            companyId,
          );

          if (routeClosed) {
            print('✅ Route ${routeDoc.id} was automatically closed!');
            // Show a notification to the user only if widget is still mounted
            if (mounted) {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '🎉 Route "${routeData['routeName'] ?? 'Unknown Route'}" has been completed and closed!',
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 4),
                  ),
                );
              } catch (e) {
                print('❌ Error showing route completion notification: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error checking and closing routes for pool $poolId: $e');
      // Don't show error to user as this is a background process
    }
  }
}
