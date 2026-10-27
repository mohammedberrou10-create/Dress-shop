PRAGMA foreign_keys = ON;

CREATE TABLE customers (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT NOT NULL,
  phone      TEXT,
  created_at TEXT DEFAULT (date('now'))
);

CREATE TABLE dresses (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL UNIQUE,
  rental_price INTEGER,          -- بالدينار الجزائري
  note         TEXT
);

CREATE TABLE rentals (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_id INTEGER NOT NULL REFERENCES customers(id),
  dress_id    INTEGER NOT NULL REFERENCES dresses(id),
  start_date  TEXT NOT NULL,     -- YYYY-MM-DD
  end_date    TEXT NOT NULL CHECK (end_date >= start_date),
  price       INTEGER DEFAULT 0,
  deposit     INTEGER DEFAULT 0,
  returned    INTEGER DEFAULT 0, -- 0 = لم يُرجَع، 1 = أُرجع
  note        TEXT
);

CREATE INDEX idx_customers_name ON customers(name);
CREATE INDEX idx_rentals_dress_dates ON rentals(dress_id, start_date, end_date);

-- البحث باسم الزبون: موعد الكراء وعدد الأيام
-- ملاحظة: LIKE في SQLite لا يوحّد الهمزات (أ/ا) ولا (ة/ه)،
-- لذلك يُفضّل توحيد النص في الواجهة قبل الإرسال أو تخزين عمود name_search موحّد.
SELECT c.name AS customer,
       d.name AS dress,
       r.start_date,
       r.end_date,
       CAST(julianday(r.end_date) - julianday(r.start_date) AS INTEGER) + 1 AS days,
       r.returned
FROM rentals r
JOIN customers c ON c.id = r.customer_id
JOIN dresses   d ON d.id = r.dress_id
WHERE c.name LIKE '%' || :q || '%'
ORDER BY r.start_date DESC;

-- كشف تعارض الحجز لنفس الفستان قبل الحفظ
SELECT r.id
FROM rentals r
WHERE r.dress_id = :dress_id
  AND r.returned = 0
  AND r.start_date <= :new_end
  AND :new_start <= r.end_date;
