import { WorkSchedulerExtensionAbility, workScheduler } from '@kit.BackgroundTasksKit';
import { logI } from '../common/Constants';
import { runSync } from '../background/SyncJob';

/** Woken by WorkScheduler when its network condition is met; runs one gated sync and exits. */
export default class NetSyncWorker extends WorkSchedulerExtensionAbility {
  onWorkStart(work: workScheduler.WorkInfo): void {
    logI(`worker start ${work.workId}`);
    runSync(this.context, 'scheduler');
  }

  onWorkStop(work: workScheduler.WorkInfo): void {
    logI(`worker stop ${work.workId}`);
  }
}
