import { describe, it, expect } from '@ohos/hypium';
import { clock, kbps } from '../main/ets/common/Format';

export default function formatTest() {
  describe('formatTest', () => {
    it('kbpsFormatsUnits', 0, () => {
      expect(kbps(0)).assertEqual('—');
      expect(kbps(512)).assertEqual('512 kb/s');
      expect(kbps(2500)).assertEqual('2.5 Mb/s');
      expect(kbps(54000)).assertEqual('54 Mb/s');
    });
    it('clockPadsFields', 0, () => {
      const t = new Date(2026, 0, 1, 7, 5, 9).getTime();
      expect(clock(t)).assertEqual('07:05:09');
    });
  });
}
