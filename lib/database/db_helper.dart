import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<void> initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bakan.db');

    _db = await openDatabase(
      path,
      version: 2, // Mise à jour de la version
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phone TEXT UNIQUE,
            password TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            description TEXT,
            purchasePrice REAL,
            salePrice REAL,
            quantity INTEGER,
            imagePath TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            total REAL,
            date TEXT,
            client_id INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE sale_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sale_id INTEGER,
            productName TEXT,
            quantity INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE clients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            phone TEXT,
            address TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            isDone INTEGER,
            priority TEXT,
            dueDate TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE wallet (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            description TEXT,
            amount REAL,
            type TEXT,
            category TEXT,
            date TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE wallet_categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE
          )
        ''');

        // Insert default categories
        const defaultCategories = [
          'Nourriture',
          'Transport',
          'Investissement',
          'Éducation',
          'Don',
          'Santé',
          'Épargne'
        ];
        for (final name in defaultCategories) {
          await db.insert('wallet_categories', {'name': name});
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE wallet_categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT UNIQUE
            )
          ''');
          // Insert default categories
          const defaultCategories = [
            'Nourriture',
            'Transport',
            'Investissement',
            'Éducation',
            'Don',
            'Santé',
            'Épargne'
          ];
          for (final name in defaultCategories) {
            await db.insert('wallet_categories', {'name': name});
          }
        }
      },
    );
  }

  static Future<void> _ensureDb() async {
    if (_db == null) {
      await initDb();
    }
  }

  static Future<int> registerUser(String phone, String password) async {
    await _ensureDb();
    return await _db!.insert('users', {
      'phone': phone,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>?> loginUser(
      String phone, String password) async {
    await _ensureDb();
    final result = await _db!.query(
      'users',
      where: 'phone = ? AND password = ?',
      whereArgs: [phone, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<int> insertProduct(Map<String, dynamic> data) async {
    await _ensureDb();
    return await _db!.insert('products', data);
  }

  static Future<List<Map<String, dynamic>>> getProducts() async {
    await _ensureDb();
    return await _db!.query('products');
  }

  static Future<int> updateProductQuantity(int id, int newQuantity) async {
    await _ensureDb();
    return await _db!.update('products', {'quantity': newQuantity},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> insertSale(double total) async {
    await _ensureDb();
    final now = DateTime.now().toIso8601String();
    await _db!.insert('sales', {'total': total, 'date': now});
  }

  static Future<List<Map<String, dynamic>>> getSales() async {
    await _ensureDb();
    return await _db!.query('sales', orderBy: 'date DESC');
  }

  static Future<void> insertSaleWithItems(
      double total, List<Map<String, dynamic>> items,
      {int? clientId}) async {
    await _ensureDb();
    final now = DateTime.now().toIso8601String();
    final saleId = await _db!.insert('sales', {
      'total': total,
      'date': now,
      'client_id': clientId,
    });
    for (final item in items) {
      await _db!.insert('sale_items', {
        'sale_id': saleId,
        'productName': item['name'],
        'quantity': 1,
      });
    }
  }

  static Future<List<Map<String, dynamic>>> getSaleItems(int saleId) async {
    await _ensureDb();
    return await _db!
        .query('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
  }

  static Future<int> insertClient(Map<String, dynamic> data) async {
    await _ensureDb();
    return await _db!.insert('clients', data);
  }

  static Future<List<Map<String, dynamic>>> getClients() async {
    await _ensureDb();
    return await _db!.query('clients');
  }

  static Future<int> updateClient(int id, Map<String, dynamic> data) async {
    await _ensureDb();
    return await _db!.update('clients', data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteClient(int id) async {
    await _ensureDb();
    return await _db!.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getSalesByClientId(
      int clientId) async {
    await _ensureDb();
    return await _db!.query('sales',
        where: 'client_id = ?', whereArgs: [clientId], orderBy: 'date DESC');
  }

  static Future<int> insertTask(Map<String, dynamic> task) async {
    await _ensureDb();
    return await _db!.insert('tasks', task);
  }

  static Future<List<Map<String, dynamic>>> getTasks() async {
    await _ensureDb();
    return await _db!.query('tasks', orderBy: 'dueDate ASC');
  }

  static Future<int> updateTaskStatus(int id, int isDone) async {
    await _ensureDb();
    return await _db!
        .update('tasks', {'isDone': isDone}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteTask(int id) async {
    await _ensureDb();
    return await _db!.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> insertTransaction(Map<String, dynamic> data) async {
    await _ensureDb();
    return await _db!.insert('wallet', data);
  }

  static Future<List<Map<String, dynamic>>> getTransactions() async {
    await _ensureDb();
    return await _db!.query('wallet', orderBy: 'date DESC');
  }

  static Future<double> getWalletBalance() async {
    await _ensureDb();
    final result = await _db!.rawQuery('''
    SELECT SUM(CASE WHEN type = 'Entrée' THEN amount ELSE -amount END) as balance
    FROM wallet
    ''');
    return result.first['balance'] == null
        ? 0.0
        : (result.first['balance'] as num).toDouble();
  }

  static Future<List<Map<String, dynamic>>> getTotalsByCategory() async {
    await _ensureDb();
    return await _db!.rawQuery('''
    SELECT category, SUM(CASE WHEN type = 'Entrée' THEN amount ELSE -amount END) as total
    FROM wallet
    GROUP BY category
    ORDER BY total DESC
    ''');
  }

  static Future<int> updateUserPassword(
      String phone, String newPassword) async {
    await _ensureDb();
    return await _db!.update('users', {'password': newPassword},
        where: 'phone = ?', whereArgs: [phone]);
  }

  static Future<int> updateProduct(int id, Map<String, dynamic> data) async {
    await _ensureDb();
    return await _db!
        .update('products', data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteProduct(int id) async {
    await _ensureDb();
    return await _db!.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Map<String, dynamic>?> getProductById(int id) async {
    await _ensureDb();
    final result =
        await _db!.query('products', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<int> insertCategory(String name) async {
    await _ensureDb();
    return await _db!.insert('wallet_categories', {'name': name});
  }

  static Future<List<String>> getCategories() async {
    await _ensureDb();
    final result = await _db!.query('wallet_categories');
    return result.map((e) => e['name'] as String).toList();
  }
}
