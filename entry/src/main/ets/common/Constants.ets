import { hilog } from '@kit.PerformanceAnalysisKit';

export const DOMAIN = 0x0000;
export const TAG = 'NetSolo';

export const BUNDLE_NAME = 'com.hmosdemos.wearable.how_to_implement_standalone_network_requests_background_tasks';
export const WORKER_ABILITY = 'NetSyncWorker';
export const WORK_ID = 1001;

// Key-free JSON endpoint (MET Norway): forecast for a fixed location. Its terms require
// an identifying User-Agent.
export const ENDPOINT = '<MET_NORWAY_WEATHER_FORECAST_URL>';
export const USER_AGENT = 'NetSolo/1.0 (HarmonyOS wearable sample)';

export const CONNECT_TIMEOUT_MS = 8000;
export const READ_TIMEOUT_MS = 8000;

// Continuous-task loop period while the app is backgrounded.
export const CONTINUOUS_INTERVAL_MS = 30 * 1000;
// WorkScheduler minimum repeat cycle is 20 minutes.
export const WORK_REPEAT_MS = 20 * 60 * 1000;

export const PREF_NAME = 'netsolo_sync';
export const PREF_LOG_KEY = 'log';
export const LOG_LIMIT = 20;

export function logI(msg: string): void {
  hilog.info(DOMAIN, TAG, '%{public}s', msg);
}

export function logE(msg: string): void {
  hilog.error(DOMAIN, TAG, '%{public}s', msg);
}
