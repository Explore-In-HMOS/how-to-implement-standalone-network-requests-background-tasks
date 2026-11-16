import { workScheduler } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { BUNDLE_NAME, logE, logI, WORK_ID, WORK_REPEAT_MS, WORKER_ABILITY } from '../common/Constants';

function workInfo(): workScheduler.WorkInfo {
  return {
    workId: WORK_ID,
    bundleName: BUNDLE_NAME,
    abilityName: WORKER_ABILITY,
    // The system only fires the work when a network is up: the first connectivity gate.
    networkType: workScheduler.NetworkType.NETWORK_TYPE_ANY,
    isRepeat: true,
    repeatCycleTime: WORK_REPEAT_MS
  };
}

/** Deferred, system-scheduled sync that runs in NetSyncWorker even when the app is closed. */
export class WorkSync {
  static schedule(): string {
    try {
      workScheduler.startWork(workInfo());
      logI('work scheduled');
      return '';
    } catch (e) {
      const err = e as BusinessError;
      logE(`startWork failed: ${err.code} ${err.message}`);
      return `Error ${err.code}`;
    }
  }

  static cancel(): void {
    try {
      workScheduler.stopWork(workInfo(), true);
      logI('work cancelled');
    } catch (e) {
      const err = e as BusinessError;
      logE(`stopWork failed: ${err.code} ${err.message}`);
    }
  }

  static async isScheduled(): Promise<boolean> {
    try {
      const info = await workScheduler.getWorkStatus(WORK_ID);
      return info !== undefined && info.workId === WORK_ID;
    } catch (e) {
      return false;
    }
  }
}
