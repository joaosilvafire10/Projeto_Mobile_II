-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_tickets" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'ABERTO',
    "priority" TEXT NOT NULL DEFAULT 'MEDIA',
    "department" TEXT NOT NULL DEFAULT 'TI',
    "ai_summary" TEXT,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" DATETIME NOT NULL,
    "user_id" TEXT NOT NULL,
    "assigned_to_id" TEXT,
    "category_id" TEXT,
    "activity_id" TEXT,
    CONSTRAINT "tickets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "tickets_assigned_to_id_fkey" FOREIGN KEY ("assigned_to_id") REFERENCES "users" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "tickets_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "categories" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "tickets_activity_id_fkey" FOREIGN KEY ("activity_id") REFERENCES "activities" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);
INSERT INTO "new_tickets" ("activity_id", "ai_summary", "category_id", "created_at", "department", "description", "id", "priority", "status", "title", "updated_at", "user_id") SELECT "activity_id", "ai_summary", "category_id", "created_at", "department", "description", "id", "priority", "status", "title", "updated_at", "user_id" FROM "tickets";
DROP TABLE "tickets";
ALTER TABLE "new_tickets" RENAME TO "tickets";
CREATE INDEX "tickets_user_id_idx" ON "tickets"("user_id");
CREATE INDEX "tickets_status_idx" ON "tickets"("status");
CREATE INDEX "tickets_priority_idx" ON "tickets"("priority");
CREATE INDEX "tickets_department_idx" ON "tickets"("department");
CREATE INDEX "tickets_category_id_idx" ON "tickets"("category_id");
CREATE INDEX "tickets_activity_id_idx" ON "tickets"("activity_id");
CREATE INDEX "tickets_assigned_to_id_idx" ON "tickets"("assigned_to_id");
CREATE TABLE "new_users" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "role" TEXT NOT NULL DEFAULT 'USUARIO',
    "department" TEXT NOT NULL DEFAULT 'TI',
    "avatar_url" TEXT,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "refresh_token" TEXT,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" DATETIME NOT NULL
);
INSERT INTO "new_users" ("active", "avatar_url", "created_at", "department", "email", "id", "name", "password", "refresh_token", "role", "updated_at") SELECT "active", "avatar_url", "created_at", "department", "email", "id", "name", "password", "refresh_token", "role", "updated_at" FROM "users";
DROP TABLE "users";
ALTER TABLE "new_users" RENAME TO "users";
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
