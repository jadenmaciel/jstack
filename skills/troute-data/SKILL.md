---
name: troute-data
description: PostgreSQL query patterns, Alembic migration templates, and SQLAlchemy selectinload for troute-shipping. merchant_id must scope every query.
origin: custom
---

# troute-data

PostgreSQL + Alembic patterns for troute-shipping. Combined because schema and query work always go together.

## When to Activate

- Writing SQL or SQLAlchemy queries
- Creating or modifying Alembic migrations
- Adding indexes, constraints, or columns
- Diagnosing slow queries or N+1 problems
- Planning zero-downtime schema changes

## Alembic Migration Template

```python
"""add_shipment_external_id

Revision ID: abc123def456
Revises: previous_revision_id
Create Date: 2026-04-02 12:00:00
"""
from alembic import op
import sqlalchemy as sa

revision = "abc123def456"
down_revision = "previous_revision_id"

def upgrade() -> None:
    # Safe: nullable column - no table rewrite
    op.add_column("shipments", sa.Column("external_id", sa.Text, nullable=True))
    # Concurrent index - must be outside a transaction block
    op.execute(
        "CREATE INDEX CONCURRENTLY IF NOT EXISTS "
        "ix_shipments_external_id ON shipments (external_id)"
    )

def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS ix_shipments_external_id")
    op.drop_column("shipments", "external_id")
```

```bash
alembic revision --autogenerate -m "add_shipment_external_id"
alembic upgrade head
alembic downgrade -1
```

## Migration Safety Checklist

Before applying any migration to production:
- [ ] New columns are nullable OR have an explicit default (never NOT NULL without default)
- [ ] Indexes use CREATE INDEX CONCURRENTLY (avoids write locks on large tables)
- [ ] Schema change and data backfill are separate migrations
- [ ] Tested against a prod-sized dataset (100 rows passing != 10M rows passing)
- [ ] Downgrade path is verified

## Index Patterns for troute

```sql
-- Standard merchant_id composite (most frequent pattern)
CREATE INDEX CONCURRENTLY ix_shipments_mid_status
  ON shipments (merchant_id, status);

-- merchant_id + time-range for dashboard queries
CREATE INDEX CONCURRENTLY ix_shipments_mid_created
  ON shipments (merchant_id, created_at DESC);

-- Partial: skip soft-deleted rows
CREATE INDEX CONCURRENTLY ix_shipments_mid_active
  ON shipments (merchant_id) WHERE deleted_at IS NULL;
```

Index rule: equality columns first, range/sort columns last.

## SQLAlchemy N+1 Prevention

```python
from sqlalchemy import select
from sqlalchemy.orm import selectinload

# BAD: triggers N queries loading shipment.labels
shipments = (await db.execute(select(Shipment).where(
    Shipment.merchant_id == merchant_id
))).scalars().all()

# GOOD: second batch query loads all labels at once
result = await db.execute(
    select(Shipment)
    .options(selectinload(Shipment.labels))
    .where(Shipment.merchant_id == merchant_id)
    .order_by(Shipment.created_at.desc())
    .limit(50)
)
shipments = result.scalars().all()
```

## merchant_id Scoping Rule

Every read or write operation must scope by merchant_id. No exceptions.

```python
# WRONG - returns data for all merchants
result = await db.execute(select(Shipment).where(Shipment.status == "pending"))

# CORRECT
result = await db.execute(
    select(Shipment).where(
        Shipment.merchant_id == merchant_id,
        Shipment.status == "pending",
    )
)
```

## Zero-Downtime Column Rename (Expand-Contract)

Never rename a column directly on a live table. Use three migrations:

```
Migration 1: Add new_column (nullable)
Deploy v1:   app writes both old_column and new_column
Migration 2: Backfill existing rows (separate migration, batched)
Deploy v2:   app reads from new_column only
Migration 3: Drop old_column
```

## Quick Diagnostics

```sql
-- Slow queries (requires pg_stat_statements extension)
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC LIMIT 10;

-- Unindexed foreign keys
SELECT conrelid::regclass, a.attname
FROM pg_constraint c
JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
WHERE c.contype = 'f'
  AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = c.conrelid AND a.attnum = ANY(i.indkey)
  );
```
