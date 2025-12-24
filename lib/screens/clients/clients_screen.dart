import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';
import '../../providers/client_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/client.dart';
import '../../services/database_service.dart';
import '../../services/excel_generation_service.dart';
import '../../services/sync_service.dart';
import '../excel/trimester_selection_dialog.dart';
import '../forms/widgets/client_card.dart';
import 'add_edit_client_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().loadClients();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });

    // Trigger search when user types
    if (_searchQuery.isNotEmpty) {
      context.read<ClientProvider>().searchClients(_searchQuery);
    } else {
      // Load recent clients when search is cleared
      context.read<ClientProvider>().loadClients();
    }
  }

  List<Client> _getFilteredClients(List<Client> clients) {
    if (_searchQuery.isEmpty) {
      return clients;
    }

    return clients.where((client) {
      final name = '${client.firstName} ${client.lastName}'.toLowerCase();
      final email = client.email.toLowerCase();
      final address = client.address.toLowerCase();
      final phone = client.phone.toLowerCase();
      final holder = client.holder.toLowerCase();
      return name.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          address.contains(_searchQuery) ||
          phone.contains(_searchQuery) ||
          holder.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: GradientBackground(
        child: Column(
          children: [
            ModernHeader(
              title: 'Clienți',
              subtitle: 'Gestionează clienții și formularele',
              actions: [
                IconButton(
                  icon: const Icon(Icons.table_chart, color: Colors.white),
                  onPressed: () => _generateExcelReport(context),
                  tooltip: 'Generează Raport Excel',
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () async {
                    await context.read<MyAuthProvider>().signOut();
                    if (mounted) {
                      context.go('/login');
                    }
                  },
                  tooltip: 'Deconectare',
                ),
              ],
            ),
            _buildSearchSection(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Consumer<ClientProvider>(
                  builder: (context, clientProvider, child) {
                    if (clientProvider.isLoading) {
                      return _buildLoadingState();
                    }

                    if (clientProvider.error != null) {
                      return _buildErrorState(clientProvider);
                    }

                    final clients = _searchQuery.isEmpty
                        ? clientProvider.recentClients
                        : clientProvider.searchResults;

                    if (clients.isEmpty) {
                      return _searchQuery.isEmpty
                          ? _buildEmptyState()
                          : _buildNoResultsState();
                    }

                    return _buildClientsList(clients);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Se încarcă clienții...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ClientProvider clientProvider) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ceva nu a funcționat corect...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              clientProvider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                clientProvider.clearError();
                clientProvider.loadClients();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Încearcă'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.people_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nu există clienți',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adaugă primul tău client pentru a începe completarea formularelor',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.1),
                    Colors.amber.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.search_off,
                size: 48,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nu s-au găsit clienți',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Niciun client nu conține "$_searchQuery".\nÎncearcă un alt termen de căutare (nume, email, adresă, telefon).',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged();
                  },
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Reîncarcă toți clienții'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Caută client (nume, email, telefon, adresă)...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey.shade400),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged();
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildClientsList(List<Client> clients) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: clients.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: ClientCard(client: clients[index]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // DOWNLOAD button (pulls from cloud)
        FloatingActionButton(
          onPressed: _downloadFromCloud,
          heroTag: 'download',
          backgroundColor: Colors.white,
          child: Icon(Icons.cloud_download, color: Colors.blue),
          tooltip: 'Descarcă din Cloud',
        ),
        const SizedBox(height: 12),

        // UPLOAD button (pushes to cloud)
        FloatingActionButton(
          onPressed: _uploadToCloud,
          heroTag: 'upload',
          backgroundColor: Colors.white,
          child: Icon(Icons.cloud_upload, color: Colors.orange),
          tooltip: 'Încarcă în Cloud',
        ),
        const SizedBox(height: 16),

        // ADD CLIENT button
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _addNewClient,
            heroTag: 'add',
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _addNewClient() async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const AddEditClientScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
      ),
    );

    if (result == true && mounted) {
      context.read<ClientProvider>().loadClients();
    }
  }

  Future<void> _uploadToCloud() async {
    // Check if online first
    if (!await SyncService.instance.isOnline()) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.wifi_off, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Text('Fără Internet'),
            ],
          ),
          content: const Text('Nu există conexiune la internet. Conectează-te și încearcă din nou.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Get unsynced summary
    try {
      final summary = await SyncService.instance.getUnsyncedSummary();
      final clients = summary['clients'] as List<Map<String, dynamic>>;
      final totalClients = summary['totalClients'] as int;
      final totalForms = summary['totalForms'] as int;

      if (!mounted) return;

      // If nothing to upload
      if (totalClients == 0) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green),
                ),
                const SizedBox(width: 12),
                const Text('Totul Sincronizat'),
              ],
            ),
            content: const Text('Nu există clienți sau formulare nesincronizate.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cloud_upload, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Text('Încarcă în Cloud'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Găsit $totalClients ${totalClients == 1 ? 'client' : 'clienți'} nesincronizat${totalClients == 1 ? '' : 'i'}:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: clients.map((client) {
                      final name = client['name'] as String;
                      final formCount = client['formCount'] as int;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.person, size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$name ($formCount ${formCount == 1 ? 'formular' : 'formulare'})',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total: $totalClients ${totalClients == 1 ? 'client' : 'clienți'}, $totalForms ${totalForms == 1 ? 'formular' : 'formulare'}',
                        style: const TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Anulează'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Încarcă'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
              const SizedBox(height: 20),
              const Text(
                'Se încarcă datele în cloud...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );

      // Perform upload
      final results = await SyncService.instance.manualUploadToCloud();

      if (!mounted) return;
      Navigator.pop(context); // Close progress dialog

      // Show results dialog
      final successClients = results['successClients'] ?? 0;
      final failClients = results['failClients'] ?? 0;
      final successForms = results['successForms'] ?? 0;
      final failForms = results['failForms'] ?? 0;
      final allSuccess = failClients == 0 && failForms == 0;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (allSuccess ? Colors.green : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  allSuccess ? Icons.check_circle : Icons.info,
                  color: allSuccess ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Rezultat Încărcare'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Clienți sincronizați: $successClients',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Formulare sincronizate: $successForms',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              if (failClients > 0 || failForms > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Eșuate: $failClients clienți, $failForms formulare',
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Refresh client list to update UI
                context.read<ClientProvider>().loadClients();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.error, color: Colors.red),
              ),
              const SizedBox(width: 12),
              const Text('Eroare'),
            ],
          ),
          content: Text('A apărut o eroare la încărcare: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _downloadFromCloud() async {
    // Check if online first
    if (!await SyncService.instance.isOnline()) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.wifi_off, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Text('Fără Internet'),
            ],
          ),
          content: const Text('Nu există conexiune la internet. Conectează-te și încearcă din nou.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Show confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cloud_download, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            const Text('Descarcă din Cloud'),
          ],
        ),
        content: const Text(
          'Aceasta va descărca toți clienții și formularele din cloud care nu există deja local.\n\nDatele locale existente nu vor fi șterse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Descarcă'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 20),
            const Text(
              'Se descarcă datele din cloud...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );

    try {
      // Perform download
      final results = await SyncService.instance.manualDownloadFromCloud();

      if (!mounted) return;
      Navigator.pop(context); // Close progress dialog

      final newClients = results['newClients'] ?? 0;
      final newForms = results['newForms'] ?? 0;

      // Show results dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: Colors.green),
              ),
              const SizedBox(width: 12),
              const Text('Descărcare Completă'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_add, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Clienți noi: $newClients',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.description, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Formulare noi: $newForms',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              if (newClients == 0 && newForms == 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Toate datele sunt deja sincronizate!',
                          style: TextStyle(fontSize: 14, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Refresh client list to show new data
                context.read<ClientProvider>().loadClients();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close progress dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.error, color: Colors.red),
              ),
              const SizedBox(width: 12),
              const Text('Eroare'),
            ],
          ),
          content: Text('A apărut o eroare la descărcare: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _generateExcelReport(BuildContext context) async {
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => const TrimesterSelectionDialog(),
      );

      if (result == null) return;

      // Get year, trimester, and action from dialog
      final year = result['year'] as int;
      final trimester = result['trimester'] as int;
      final action = result['action'] as String? ?? 'download';

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text('Se generează raportul Excel...'),
            ],
          ),
        ),
      );

      // Use year and trimester directly
      await ExcelGenerationService.instance.generateClientReport(
        year: year,
        trimester: trimester,
        action: action,  // Pass the action
      );

      if (!mounted) return;
      Navigator.pop(context);

      // // Show appropriate success message
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Column(
      //       mainAxisSize: MainAxisSize.min,
      //       crossAxisAlignment: CrossAxisAlignment.start,
      //       children: [
      //         Row(
      //           children: [
      //             const Icon(Icons.check_circle, color: Colors.white),
      //             const SizedBox(width: 12),
      //             Expanded(
      //               child: Text(
      //                 action == 'share'
      //                     ? 'Raportul Excel a fost partajat cu succes!'
      //                     : 'Raportul Excel a fost salvat cu succes!',
      //               ),
      //             ),
      //           ],
      //         ),
      //         if (action == 'download') ...[
      //           const SizedBox(height: 4),
      //           Text(
      //             'Gaseste-l in folderul Downloads',
      //             style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
      //           ),
      //         ],
      //       ],
      //     ),
      //     backgroundColor: Colors.green,
      //     behavior: SnackBarBehavior.floating,
      //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      //     duration: const Duration(seconds: 4),
      //   ),
      // );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Eroare la generarea raportului: $e'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}