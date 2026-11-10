import { pgTable, serial, integer, text, timestamp } from 'drizzle-orm/pg-core';
export const notificationDevices = pgTable('notification_devices', {
  id: text('id').primaryKey(), teamId: integer('team_id'),
  permission: text('permission').notNull(), subscribed: integer('subscribed').notNull().default(0),
  installedAt: timestamp('installed_at', { withTimezone: true }),
  bellCount: integer('bell_count').notNull().default(0),
  firstSeen: timestamp('first_seen', { withTimezone: true }).notNull().defaultNow(),
  lastSeen: timestamp('last_seen', { withTimezone: true }).notNull().defaultNow(),
});
export const notificationEvents = pgTable('notification_events', {
  id: serial('id').primaryKey(), deviceId: text('device_id').notNull(), teamId: integer('team_id'),
  event: text('event').notNull(), createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const tradeDigestAdditions = pgTable('trade_digest_additions', {
  id: text('id').primaryKey(), teamId: integer('team_id').notNull(),
  playerId: integer('player_id').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  sentAt: timestamp('sent_at', { withTimezone: true }),
});
export const tradeDigestRuns = pgTable('trade_digest_runs', {
  day: text('day').primaryKey(),
  sentAt: timestamp('sent_at', { withTimezone: true }).notNull().defaultNow(),
});

export const rosterAlertDeliveries = pgTable('roster_alert_deliveries', {
  alertKey: text('alert_key').primaryKey(),
  sentAt: timestamp('sent_at', { withTimezone: true }).notNull().defaultNow(),
});
