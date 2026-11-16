import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { LOG_LIMIT, logE, PREF_LOG_KEY, PREF_NAME } from '../common/Constants';
import { LinkKind } from '../network/NetworkMonitor';

export type SyncTrigger = 'continuous' | 'scheduler' | 'manual';
export type SyncOutcome = 'success' | 'skipped_offline' | 'skipped_relay' | 'failed';

export class SyncEntry {
  at: number = 0;
  trigger: SyncTrigger = 'manual';
  outcome: SyncOutcome = 'failed';
  link: LinkKind = 'none';
  ms: number = 0;
  detail: string = '';
}

export type LogListener = () => void;

const listeners: Array<LogListener> = [];

/**
 * Sync history persisted in Preferences. The WorkScheduler extension runs in a separate
 * process, so reads always drop the in-memory cache to pick up its writes.
 */
export class SyncLog {
  static onChange(listener: LogListener): void {
    listeners.push(listener);
  }

  static offChange(listener: LogListener): void {
    const i = listeners.indexOf(listener);
    if (i >= 0) {
      listeners.splice(i, 1);
    }
  }

  static read(ctx: common.Context): Array<SyncEntry> {
    try {
      preferences.removePreferencesFromCacheSync(ctx, PREF_NAME);
      const pref = preferences.getPreferencesSync(ctx, { name: PREF_NAME });
      const raw = pref.getSync(PREF_LOG_KEY, '[]') as string;
      return JSON.parse(raw) as Array<SyncEntry>;
    } catch (e) {
      logE(`SyncLog.read failed: ${JSON.stringify(e)}`);
      return [];
    }
  }

  static append(ctx: common.Context, entry: SyncEntry): void {
    try {
      const list = SyncLog.read(ctx);
      list.unshift(entry);
      const pref = preferences.getPreferencesSync(ctx, { name: PREF_NAME });
      pref.putSync(PREF_LOG_KEY, JSON.stringify(list.slice(0, LOG_LIMIT)));
      pref.flushSync();
    } catch (e) {
      logE(`SyncLog.append failed: ${JSON.stringify(e)}`);
    }
    listeners.forEach((l: LogListener) => l());
  }

  static clear(ctx: common.Context): void {
    try {
      const pref = preferences.getPreferencesSync(ctx, { name: PREF_NAME });
      pref.deleteSync(PREF_LOG_KEY);
      pref.flushSync();
    } catch (e) {
      logE(`SyncLog.clear failed: ${JSON.stringify(e)}`);
    }
    listeners.forEach((l: LogListener) => l());
  }
}
