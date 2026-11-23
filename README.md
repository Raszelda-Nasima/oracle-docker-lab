# 🗄️ ORACLE DATABASE MINI-LAB

**A focused demonstration of Oracle Database concepts and operations**

---

## Quick Start

```bash
# Start Oracle container
docker-compose up -d

# Wait for Oracle to initialize (60-90 seconds)
docker-compose logs -f oracle

# When healthy, connect to database
docker exec -it oracle-mini-lab sqlplus system/MySecurePass2024!@localhost:1521/xe

# Or use SQL*Plus inside container
docker exec -it oracle-mini-lab sqlplus app_user/AppPass2024!@localhost:1521/xe
```

---

## Oracle vs PostgreSQL: Key Differences

| Feature | PostgreSQL | Oracle |
|---------|-----------|--------|
| **Auto-increment** | SERIAL type | SEQUENCE + TRIGGER |
| **Large text** | TEXT | CLOB (Character LOB) |
| **Views** | CREATE VIEW | CREATE OR REPLACE VIEW |
| **Procedures** | PL/pgSQL | PL/SQL |
| **Transactions** | AUTOCOMMIT OFF | AUTOCOMMIT OFF (default) |
| **System User** | postgres | sys/system |
| **Connection** | localhost:5432 | localhost:1521 |
| **Backup** | pg_dump | exp/expdp (export) |
| **Monitoring** | pg_stat_* views | v$* views (v$sessions, v$sql) |

---

## Schema Components

### 1. Users Table
```sql
-- Oracle-style with constraints
CREATE TABLE users (
    user_id NUMBER PRIMARY KEY,
    username VARCHAR2(50) UNIQUE NOT NULL,
    email VARCHAR2(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- Query users
SELECT * FROM users;
```

**Key Concepts:**
- `NUMBER` = Oracle's numeric type (supports precision, scale)
- `VARCHAR2` = Oracle's string type (always specify length)
- `TIMESTAMP` = Includes time with timezone capability
- `SYSTIMESTAMP` = Current timestamp in session timezone

### 2. Products Table with CHECK Constraints
```sql
CREATE TABLE products (
    product_id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    description CLOB,              -- Character Large Object
    price NUMBER(10,2) CHECK (price > 0),
    stock_quantity NUMBER DEFAULT 0 CHECK (stock_quantity >= 0)
);
```

**Oracle Features:**
- `CLOB` = Can store up to 4GB of text (unlike VARCHAR2 max 4000)
- `NUMBER(10,2)` = 10 total digits, 2 after decimal
- Inline CHECK constraints (Oracle supports constraints inline)

### 3. Orders Table with Foreign Keys
```sql
CREATE TABLE orders (
    order_id NUMBER PRIMARY KEY,
    user_id NUMBER CONSTRAINT fk_orders_user 
        REFERENCES users(user_id) ON DELETE CASCADE,
    product_id NUMBER CONSTRAINT fk_orders_product 
        REFERENCES products(product_id),
    quantity NUMBER CHECK (quantity > 0),
    total_price NUMBER(10,2) CHECK (total_price > 0)
);
```

**Oracle Naming Convention:**
- Named constraints: `CONSTRAINT fk_orders_user` (easier to debug than unnamed)
- Reference syntax: `REFERENCES table(column)`

---

## Oracle-Specific Features

### 1. SEQUENCES (Auto-increment)

```sql
-- Create sequence
CREATE SEQUENCE users_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

-- Use sequence
INSERT INTO users (user_id, username, email)
VALUES (users_seq.NEXTVAL, 'john', 'john@example.com');

-- Check current sequence value
SELECT users_seq.CURRVAL FROM dual;
```

**Why SEQUENCE?**
- PostgreSQL's SERIAL is built on sequences
- Oracle makes sequences explicit (more control)
- Multiple tables can share sequences if needed

### 2. VIEWS (Data Abstraction)

```sql
-- Create reusable view
CREATE OR REPLACE VIEW user_order_summary AS
SELECT 
    u.user_id,
    u.username,
    COUNT(o.order_id) as total_orders,
    SUM(o.total_price) as total_spending
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
GROUP BY u.user_id, u.username;

-- Query view
SELECT * FROM user_order_summary WHERE total_orders > 0;
```

**Benefits:**
- Hide complexity from application
- Consistent business logic
- Easy to modify without breaking queries

### 3. STORED PROCEDURES (PL/SQL)

```sql
-- PL/SQL procedure
CREATE OR REPLACE PROCEDURE create_new_order(
    p_user_id IN NUMBER,
    p_product_id IN NUMBER,
    p_quantity IN NUMBER,
    p_total_price IN NUMBER
)
AS
BEGIN
    INSERT INTO orders (order_id, user_id, product_id, quantity, total_price)
    VALUES (orders_seq.NEXTVAL, p_user_id, p_product_id, p_quantity, p_total_price);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Order created successfully');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Call procedure
CALL create_new_order(1, 2, 3, 89.97);
```

**PL/SQL vs PL/pgSQL:**
- Similar concepts (variables, loops, conditionals)
- Different syntax
- Oracle: `AS BEGIN ... END;` with `/` terminator
- PostgreSQL: `AS $$ ... $$;`

---

## Common SQL*Plus Commands

```sql
-- Connection
CONNECT system/MySecurePass2024!@localhost:1521/xe
DISCONNECT

-- Display settings
SHOW USER;              -- Current connected user
SHOW PAGESIZE;          -- Lines per page
SHOW LINESIZE;          -- Characters per line
SET FEEDBACK ON;        -- Show row counts

-- Formatting
COLUMN username FORMAT A20;     -- Format column width
COLUMN price FORMAT $9,999.99;  -- Format as currency

-- Scripting
@/path/to/script.sql   -- Run SQL script
@@ relative_script.sql  -- Run from current directory
START filename.sql      -- Alternative to @

-- Exiting
EXIT;
QUIT;
```

---

## Basic Operations Guide

### Query Users and Orders

```sql
-- Simple join
SELECT u.username, COUNT(o.order_id) as order_count
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
GROUP BY u.user_id, u.username
ORDER BY order_count DESC;
```

### Insert Order (Using Sequence)

```sql
INSERT INTO orders (order_id, user_id, product_id, quantity, total_price)
VALUES (orders_seq.NEXTVAL, 1, 2, 2, 59.98);
COMMIT;
```

### Update Product Stock

```sql
UPDATE products
SET stock_quantity = stock_quantity - 1
WHERE product_id = 1
AND stock_quantity > 0;
COMMIT;
```

### Explain Query Plan (Oracle equivalent)

```sql
-- Set AUTOTRACE to see execution plan
SET AUTOTRACE ON EXPLAIN;

SELECT * FROM orders WHERE user_id = 1;

-- Output shows query plan and execution statistics
```

### View Data Dictionary (Oracle-specific)

```sql
-- See all tables in current schema
SELECT table_name FROM user_tables;

-- See all columns in a table
DESC users;
-- or
SELECT column_name, data_type FROM user_tab_columns WHERE table_name = 'USERS';

-- See all constraints
SELECT constraint_name, constraint_type FROM user_constraints WHERE table_name = 'ORDERS';

-- See index information
SELECT index_name, table_name FROM user_indexes;
```

---

## Systems Engineering: Oracle Operations

### 1. User & Security Management (Oracle-Specific)

```sql
-- Create read-only user
CREATE USER reporting_user IDENTIFIED BY ReadOnly123!;
GRANT CREATE SESSION TO reporting_user;
GRANT SELECT ON app_user.users TO reporting_user;
GRANT SELECT ON app_user.products TO reporting_user;
GRANT SELECT ON app_user.orders TO reporting_user;

-- Connect as reporting user (read-only)
CONNECT reporting_user/ReadOnly123!@localhost:1521/xe
SELECT * FROM app_user.users;    -- ✅ Works
INSERT INTO app_user.users ...;  -- ❌ Permission denied
```

### 2. Tablespace Management (Oracle Feature)

```sql
-- Oracle stores objects in tablespaces (logical storage)
-- Check default tablespace
SELECT DEFAULT_TABLESPACE FROM user_users;

-- See tablespace usage
SELECT tablespace_name, SUM(bytes) / 1024 / 1024 as size_mb
FROM dba_free_space
GROUP BY tablespace_name;
```

### 3. Backup (Export/Dump)

```bash
# Export schema (Oracle's backup mechanism)
docker exec oracle-mini-lab expdp app_user/AppPass2024! \
    DIRECTORY=export_dir \
    DUMPFILE=app_user_backup.dmp \
    LOGFILE=app_user_backup.log

# Import schema (restore)
docker exec oracle-mini-lab impdp app_user/AppPass2024! \
    DIRECTORY=export_dir \
    DUMPFILE=app_user_backup.dmp
```

### 4. Monitoring (Oracle V$ Views)

```sql
-- Connected sessions
SELECT username, sid, serial#, status FROM v$session;

-- Current SQL statements
SELECT username, sql_text FROM v$sql WHERE username IS NOT NULL;

-- Database size
SELECT SUM(bytes) / 1024 / 1024 / 1024 as size_gb FROM dba_data_files;

-- Table sizes
SELECT table_name, num_rows FROM user_tables;
```
---

## Next Steps

1. Connect via SQL*Plus and explore the data
2. Run the views and stored procedure
3. Practice inserts/updates and observe constraints
4. Compare operations with PostgreSQL lab (note the differences)
5. Document what you learned about Oracle vs PostgreSQL

Your two labs now show:
- **PostgreSQL**: Open-source, modern, cloud-ready
- **Oracle**: Enterprise, robust, feature-rich

**This is exactly what systems engineers need to know!**
