import { common } from '@kit.AbilityKit';
import { logI } from '../common/Constants';
import { fetchDirect } from '../network/DirectRequest';
import { currentNetwork, findStandaloneNet } from '../network/NetworkMonitor';
import { SyncEntry, SyncLog, SyncTrigger } from './SyncLog';

/**
 * One background sync cycle, shared by the continuous task and the WorkScheduler worker.
 * Connectivity is checked first so no request is attempted (and no radio woken) when it
 * cannot succeed, or when the only route is the phone's Bluetooth relay.
 */
export async function runSync(ctx: common.Context, trigger: SyncTrigger): Promise<SyncEntry> {
  const entry = new SyncEntry();
  entry.at = Date.now();
  entry.trigger = trigger;

  const net = currentNetwork();
  entry.link = net.kind;
  if (findStandaloneNet() === undefined) {
    if (net.kind === 'relay') {
      entry.outcome = 'skipped_relay';
      entry.detail = 'Phone relay only';
    } else {
      entry.outcome = 'skipped_offline';
      entry.detail = 'No network';
    }
  } else {
    const res = await fetchDirect();
    entry.link = res.link;
    entry.ms = res.totalMs;
    if (res.ok) {
      entry.outcome = 'success';
      entry.detail = isNaN(res.tempC) ? `HTTP ${res.code}` : `${res.tempC.toFixed(1)}°C`;
    } else {
      entry.outcome = 'failed';
      entry.detail = res.error;
    }
  }

  logI(`sync[${trigger}] ${entry.outcome} via ${entry.link} ${entry.detail}`);
  SyncLog.append(ctx, entry);
  return entry;
}
