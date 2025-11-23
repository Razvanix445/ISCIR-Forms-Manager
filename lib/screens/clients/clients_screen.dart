import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';
import '../../providers/client_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/client.dart';
import '../../services/database_service.dart';
import '../../services/excel_generation_service.dart';
import '../../services/firestore_service.dart';
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

  void _showUserMenu() {
    final authProvider = context.read<MyAuthProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme
                        .of(context)
                        .colorScheme
                        .primary,
                    child: Text(
                      authProvider.userDisplayName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(authProvider.userDisplayName),
                  subtitle: Text(authProvider.user?.email ?? ''),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                      'Ieși din cont', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await authProvider.signOut();
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: GradientBackground(
        child: Column(
          children: [
            ModernHeader(
              title: 'Formulare ISCIR',
              subtitle: 'Gestionează-ți clienții și completează rapoarte',
              showBackButton: false,
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.engineering,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              actions: [
                /// Excel export button
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.table_chart,
                      color: Colors.white,
                    ),
                    onPressed: () => _generateExcelReport(context),
                    tooltip: 'Generează registru Excel',
                  ),
                ),

                /// User menu button
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Consumer<MyAuthProvider>(
                    builder: (context, authProvider, _) {
                      return IconButton(
                        onPressed: _showUserMenu,
                        icon: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Text(
                            authProvider.userDisplayName[0].toUpperCase(),
                            style: TextStyle(
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        tooltip: 'Meniu Utilizator',
                      );
                    },
                  ),
                ),
              ],
            ),

            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildSearchSection(),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        child: Consumer<ClientProvider>(
                          builder: (context, clientProvider, child) {
                            if (clientProvider.isLoading) {
                              return _buildLoadingState();
                            }

                            if (clientProvider.error != null) {
                              return _buildErrorState(clientProvider);
                            }

                            // Use search results when searching, recent clients otherwise
                            final allClients = _searchQuery.isNotEmpty
                                ? clientProvider.searchResults
                                : clientProvider.recentClients;

                            // Remove local filtering since search is handled by provider
                            final filteredClients = allClients;

                            if (allClients.isEmpty && _searchQuery.isEmpty) {
                              return _buildEmptyState();
                            }

                            if (filteredClients.isEmpty && _searchQuery.isNotEmpty) {
                              return _buildNoSearchResultsState();
                            }

                            return _buildClientsList(filteredClients);
                          },
                        ),
                      ),
                    ),
                  ],
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme
                      .of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme
                        .of(context)
                        .colorScheme
                        .primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Se încarcă clienții...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
              label: const Text('Reîncearcă'),
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
              color: Theme
                  .of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.1),
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
                    Theme
                        .of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.1),
                    Theme
                        .of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.people_outline,
                size: 64,
                color: Theme
                    .of(context)
                    .colorScheme
                    .primary,
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
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme
                        .of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Caută clienți...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 16,
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme
                              .of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          Theme
                              .of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.search,
                      color: Theme
                          .of(context)
                          .colorScheme
                          .primary,
                      size: 20,
                    ),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? Container(
                    margin: const EdgeInsets.all(12),
                    child: IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged();
                      },
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(24, 24),
                      ),
                    ),
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoSearchResultsState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme
                  .of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.1),
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
        FloatingActionButton(
          onPressed: () async {
            final db = await DatabaseService.instance.database;

            final unsynced = await db.query('forms', where: 'firestore_id IS NULL');

            if (unsynced.isEmpty) {
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
                        child: Icon(Icons.check_circle, color: Colors.green),
                      ),
                      SizedBox(width: 12),
                      Text('Sincronizare'),
                    ],
                  ),
                  content: Text('Nu există formulare nesincronizate'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
              return;
            }

            print('Found ${unsynced.length} unsynced forms');
            int successCount = 0;
            int failCount = 0;

            for (var formData in unsynced) {
              final formId = formData['id'] as int;
              print('Manually syncing form $formId...');

              final form = await DatabaseService.instance.getForm(formId);
              if (form == null) {
                failCount++;
                continue;
              }

              final localClientId = int.tryParse(form.clientId);
              if (localClientId == null) {
                failCount++;
                continue;
              }

              final clientResult = await db.query(
                'clients',
                columns: ['firestore_id'],
                where: 'id = ?',
                whereArgs: [localClientId],
              );

              if (clientResult.isEmpty) {
                print('Client $localClientId not found');
                failCount++;
                continue;
              }

              final clientFirestoreId = clientResult.first['firestore_id'] as String?;
              if (clientFirestoreId == null) {
                print('Client has no firestore_id yet');
                failCount++;
                continue;
              }

              try {
                final formForFirebase = form.copyWith(clientId: clientFirestoreId);
                final firestoreId = await FirestoreService.instance.createForm(formForFirebase);
                await DatabaseService.instance.updateFormFirestoreId(formId, firestoreId);
                print('✅ Form $formId synced with ID $firestoreId');
                successCount++;
              } catch (e) {
                print('❌ Failed: $e');
                failCount++;
              }
            }

            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (successCount > 0 && failCount == 0 ? Colors.green : Colors.orange).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        successCount > 0 && failCount == 0 ? Icons.check_circle : Icons.info,
                        color: successCount > 0 && failCount == 0 ? Colors.green : Colors.orange,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Rezultat Sincronizare'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Sincronizate cu succes: $successCount',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Eșuate: $failCount',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          },
          heroTag: 'sync',
          backgroundColor: Colors.white,
          child: Icon(Icons.cloud_upload, color: Theme.of(context).colorScheme.primary),
        ),
        SizedBox(height: 16),
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
            backgroundColor: Colors.blue,
            elevation: 2,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _addNewClient() async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (context, animation,
            secondaryAnimation) => const AddEditClientScreen(),
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

  Future<void> _generateExcelReport(BuildContext context) async {
    try {
      final selection = await showDialog<Map<String, int>>(
        context: context,
        builder: (context) => const TrimesterSelectionDialog(),
      );

      if (selection == null) return;

      final year = selection['year']!;
      final trimester = selection['trimester']!;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                const SizedBox(height: 16),
                Text(
                  'Se generează registrul pentru\nTrimestrul $trimester, $year...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await ExcelGenerationService.instance.generateClientReport(
        year: year,
        trimester: trimester,
      );

      Navigator.pop(context);

    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Eroare la generarea registrului: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

class ClientListTile extends StatelessWidget {
  final Client client;

  const ClientListTile({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          client.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 ${client.address}'),
            if (client.phone.isNotEmpty) Text('📞 ${client.phone}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Navigate to client detail screen
          context.push('/client/${client.id}');
        },
        onLongPress: () {
          _showClientOptions(context, client);
        },
      ),
    );
  }

  void _showClientOptions(BuildContext context, Client client) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editează Client'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => AddEditClientScreen(client: client),
                ),
              );
              if (result == true && context.mounted) {
                context.read<ClientProvider>().loadClients();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Șterge Client', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context, client);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Șterge Client'),
        content: Text('Ești sigur că vrei să ștergi "${client.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Renunță'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<ClientProvider>().deleteClient(client.id!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success
                      ? 'Client șters cu succes'
                      : 'Ștergerea clientului a eșuat')),
                );
              }
            },
            child: const Text('Șterge', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
