# Audit Log Date Format Fix

## Issue Summary

**Error:** `FormatException: Invalid date format` in the audit log page when reading existing audit logs from the database.

**Root Cause:** The `audit_logs` table stores the `created_at` column as an SQLite `INTEGER` with Unix timestamp in **seconds** (not milliseconds) because the default SQLite function `strftime('%s', CURRENT_TIMESTAMP)` returns seconds. Drift's `DateTimeColumn` expects **milliseconds since epoch** or **ISO8601 text format**.

When reading the existing database, Drift treats the seconds value as milliseconds (e.g., `1793095292` ms → 1970-01-01), causing a parsing failure when formatting the date in the UI (`DateFormat('dd/MM/yyyy HH:mm').format(log.createdAt.toLocal())`).

## Fix Details

### 1. Schema Migration (if creating a new database)
When defining the `audit_logs` table, ensure the `created_at` column uses the correct type:

```dart
DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
```

Drift's `dateTime()` column type stores data as **TEXT** in ISO8601 format by default. Use a proper default value (`currentDateAndTime`) to ensure the correct format.

### 2. Existing Database Handling
When working with an existing database that has the seconds format, add a migration in `onUpgrade` to normalize the `created_at` values:

```dart
if (from < 2 && to == 3) {
  // Convert seconds to milliseconds before the schema change
  await customStatement('''
    UPDATE audit_logs 
    SET created_at = created_at * 1000
  ''');
}
```

Or use a view-based approach to present the correct date values without modifying the stored data.

### 3. Defensive Date Formatting in UI
To prevent crashes from existing data, add defensive parsing in the UI code when formatting dates:

```dart
class _AuditLogTile extends StatelessWidget {
  // ...
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    try {
      // Check if date seems like it's in seconds (before year 2000)
      if (date.year < 2000) {
        // Convert from seconds to milliseconds
        date = DateTime.fromMillisecondsSinceEpoch(date.millisecondsSinceEpoch * 1000, isUtc: true);
      }
      return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
    } catch (e) {
      // Log the error and return a placeholder
      print('Error formatting date: $e, date: $date');
      return 'Date error';
    }
  }
}
```

Alternatively, ensure all date values are normalized when reading from the database:

```dart
static AuditLogEntity fromRow(AuditLog row) {
  DateTime normalizedCreatedAt = row.createdAt;
  
  // Check if the date seems to be in seconds (before year 2000)
  if (normalizedCreatedAt.year < 2000) {
    // Convert seconds to milliseconds
    normalizedCreatedAt = DateTime.fromMillisecondsSinceEpoch(
      normalizedCreatedAt.millisecondsSinceEpoch * 1000, 
      isUtc: true
    );
  }
  
  return AuditLogEntity(
    id: row.id,
    userId: row.userId,
    userName: row.userName,
    action: AuditAction.values.firstWhere(
      (e) => e.name == row.action,
      orElse: () => AuditAction.update,
    ),
    entityType: row.entityType,
    entityId: row.entityId,
    description: row.description,
    oldValue: row.oldValue,
    newValue: row.newValue,
    ipAddress: row.ipAddress,
    deviceInfo: row.deviceInfo,
    createdAt: normalizedCreatedAt,
  );
}
```

### 4. Database Singleton Pattern
When creating a singleton `AppDatabase` instance, ensure the `registerAllSyncMetas()` is called **after** the database instance is created, not inside the provider function.

```dart
// In main.dart
final db = AppDatabase();
registerAllSyncMetas(db);
runApp(MyApp(db: db));
```

## Best Practices

1. **Always use `currentDateAndTime` for `createdAt` columns** to ensure ISO8601 format.

2. **Add migrations for data normalization** when changing schema.

3. **Defensive parsing** in UI to handle potential data format mismatches.

4. **Test with existing data** to ensure the fix works before deployment.

5. **Document date format assumptions** in the database schema documentation.

## Testing

Create tests that verify the date formatting works correctly with both old (seconds) and new (milliseconds) format values:

```dart
void testAuditLogDateFormatting() {
  // Test with seconds format (from old database)
  final oldDate = DateTime.fromMillisecondsSinceEpoch(1793095292 * 1000, isUtc: true);
  // Should be correctly interpreted as 2026-10-27
  
  // Test with milliseconds format (from new database)
  final newDate = DateTime.fromMillisecondsSinceEpoch(1793095292000, isUtc: true);
  // Should be correctly interpreted as 2026-10-27
}
```

## References

- [Drift Documentation: DateTimeColumn](https://pub.dev/documentation/drift/latest/drift/DateTimeColumn-class.html)
- [SQLite strftime() Function](https://www.sqlite.org/lang_datefunc.html)
- [Flutter DateFormat Parsing](https://api.flutter.dev/flutter/dart-ui/DateFormat-class.html)
- [Audit Log UI Implementation](/lib/features/audit/presentation/audit_log_page.dart)