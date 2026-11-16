import { common } from '@kit.AbilityKit';
import { NetListener, NetSnapshot, NetworkMonitor } from '../network/NetworkMonitor';
import { fetchDirect, RequestResult } from '../network/DirectRequest';
import { ContinuousSync } from '../background/ContinuousSync';
import { WorkSync } from '../background/WorkSync';
import { LogListener, SyncEntry, SyncLog } from '../background/SyncLog';
import { kbps } from '../common/Format';
import { linkColor, linkGlow, weatherTint, linkLabel, linkSymbol, weatherSymbol } from '../common/Theme';
import { Caption, Chip, LogRow, ToggleCard } from '../components/Widgets';

@Entry
@Component
struct Index {
  @State snap: NetSnapshot = new NetSnapshot();
  @State busy: boolean = false;
  @State result: RequestResult = new RequestResult();
  @State liveOn: boolean = false;
  @State scheduledOn: boolean = false;
  @State log: Array<SyncEntry> = [];
  @State bgError: string = '';
  @State glow: number = 0.92;
  private ctx: common.UIAbilityContext | undefined = undefined;
  private onNet: NetListener = (s: NetSnapshot) => {
    this.snap = s;
  };
  private onLog: LogListener = () => this.reloadLog();

  aboutToAppear(): void {
    this.ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    NetworkMonitor.get().subscribe(this.onNet);
    SyncLog.onChange(this.onLog);
    this.liveOn = ContinuousSync.isRunning;
    WorkSync.isScheduled().then((on: boolean) => {
      this.scheduledOn = on;
    });
    this.reloadLog();
  }

  aboutToDisappear(): void {
    NetworkMonitor.get().unsubscribe(this.onNet);
    SyncLog.offChange(this.onLog);
  }

  // The scheduler worker writes from another process; pick up its runs on return.
  onPageShow(): void {
    this.reloadLog();
    this.snap = NetworkMonitor.get().refresh();
  }

  private reloadLog(): void {
    if (this.ctx) {
      this.log = SyncLog.read(this.ctx);
    }
  }

  private async fetch(): Promise<void> {
    if (this.busy) {
      return;
    }
    this.busy = true;
    const res = await fetchDirect();
    this.busy = false;
    this.result = res;
    if (this.ctx) {
      const e = new SyncEntry();
      e.at = res.at;
      e.trigger = 'manual';
      e.link = res.link;
      e.ms = res.totalMs;
      if (res.ok) {
        e.outcome = 'success';
      } else if (res.link !== 'none') {
        e.outcome = 'failed';
      } else {
        e.outcome = this.snap.kind === 'relay' ? 'skipped_relay' : 'skipped_offline';
      }
      e.detail = res.ok ? `${res.tempC.toFixed(1)}°C · ${res.totalMs}ms` : res.error;
      SyncLog.append(this.ctx, e);
    }
  }

  private async toggleLive(on: boolean): Promise<void> {
    if (!this.ctx) {
      return;
    }
    this.bgError = '';
    if (on) {
      const err = await ContinuousSync.start(this.ctx);
      this.bgError = err;
    } else {
      await ContinuousSync.stop(this.ctx);
    }
    this.liveOn = ContinuousSync.isRunning;
  }

  private toggleScheduled(on: boolean): void {
    this.bgError = '';
    if (on) {
      this.bgError = WorkSync.schedule();
    } else {
      WorkSync.cancel();
    }
    WorkSync.isScheduled().then((s: boolean) => {
      this.scheduledOn = s;
    });
  }

  private ringValue(): number {
    if (this.snap.standalone) {
      return 100;
    }
    return this.snap.kind === 'relay' ? 40 : 0;
  }

  private badge(): string {
    if (this.snap.standalone) {
      return 'STANDALONE';
    }
    return this.snap.kind === 'relay' ? 'VIA PHONE' : 'NO LINK';
  }

  // ---------- Page 1: live link status ----------
  @Builder
  LinkPage() {
    Stack() {
      Circle()
        .width('70%')
        .aspectRatio(1)
        .fill(Color.Transparent)
        .radialGradient({
          center: ['50%', '50%'],
          radius: '50%',
          colors: [[linkGlow(this.snap.kind), 0], ['#00000000', 1]]
        })
        .scale({ x: this.glow, y: this.glow })
        .onAppear(() => {
          this.getUIContext().animateTo({
            duration: 1800,
            curve: Curve.EaseInOut,
            iterations: -1,
            playMode: PlayMode.Alternate
          }, () => {
            this.glow = 1.08;
          });
        })

      Progress({ value: this.ringValue(), total: 100, type: ProgressType.Ring })
        .width('94%')
        .aspectRatio(1)
        .color(linkColor(this.snap.kind))
        .backgroundColor('#1AFFFFFF')
        .style({ strokeWidth: 8, shadow: true })

      Column({ space: 6 }) {
        Caption('NETWORK')
        SymbolGlyph(linkSymbol(this.snap.kind))
          .fontSize(46)
          .fontColor([linkColor(this.snap.kind)])
          .symbolEffect(new ScaleSymbolEffect(EffectScope.WHOLE, EffectDirection.UP), this.snap.netId)
        Text(linkLabel(this.snap.kind))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Chip({ text: this.badge(), tint: linkColor(this.snap.kind) })
        Row({ space: 10 }) {
          Row({ space: 2 }) {
            SymbolGlyph($r('sys.symbol.arrow_down')).fontSize(10).fontColor([$r('app.color.text_secondary')])
            Text(kbps(this.snap.downKbps)).fontSize(11).fontColor($r('app.color.text_secondary'))
          }

          Row({ space: 2 }) {
            SymbolGlyph(this.snap.validated ? $r('sys.symbol.checkmark_shield_fill') : $r('sys.symbol.exclamationmark_circle'))
              .fontSize(10)
              .fontColor([this.snap.validated ? $r('app.color.wifi') : $r('app.color.text_secondary')])
            Text(this.snap.validated ? 'Verified' : 'Unverified')
              .fontSize(11)
              .fontColor($r('app.color.text_secondary'))
          }
        }
        .margin({ top: 4 })
      }
    }
    .width('100%')
    .height('100%')
  }

  // ---------- Page 2: direct request ----------
  @Builder
  RequestPage() {
    Column({ space: 8 }) {
      Caption('DIRECT REQUEST')

      Stack() {
        if (this.busy) {
          LoadingProgress()
            .width(64)
            .height(64)
            .color($r('app.color.accent'))
        } else if (this.result.ok) {
          Row({ space: 6 }) {
            SymbolGlyph(weatherSymbol(this.result.sky))
              .fontSize(34)
              .fontColor([weatherTint(this.result.sky)])
            Text(`${Math.round(this.result.tempC)}°`)
              .fontSize(48)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
          }
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: 0.8, y: 0.8 })))
        } else if (this.result.at > 0) {
          Column({ space: 4 }) {
            SymbolGlyph($r('sys.symbol.exclamationmark_triangle_fill'))
              .fontSize(34)
              .fontColor([$r('app.color.offline')])
            Text(this.result.error)
              .fontSize(11)
              .fontColor($r('app.color.offline'))
              .maxLines(2)
              .textAlign(TextAlign.Center)
          }
        } else {
          Column({ space: 4 }) {
            SymbolGlyph($r('sys.symbol.paperplane_fill'))
              .fontSize(36)
              .fontColor([$r('app.color.accent')])
            Text('Fetch over the watch\'s\nown radio — no phone')
              .fontSize(11)
              .fontColor($r('app.color.text_secondary'))
              .textAlign(TextAlign.Center)
          }
        }
      }
      .height(72)

      if (this.result.ok && !this.busy) {
        Text(`Berlin · wind ${Math.round(this.result.windKmh)} km/h`)
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
        this.TimingBar()
      }

      Button({ type: ButtonType.Capsule, stateEffect: true }) {
        Row({ space: 6 }) {
          SymbolGlyph(this.result.at > 0 ? $r('sys.symbol.arrow_clockwise') : $r('sys.symbol.paperplane_fill'))
            .fontSize(14)
            .fontColor([Color.White])
          Text(this.busy ? 'Fetching…' : (this.result.at > 0 ? 'Again' : 'Fetch'))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
      }
      .width('56%')
      .height(38)
      .enabled(!this.busy)
      .opacity(this.busy ? 0.5 : 1)
      .linearGradient({
        angle: 90,
        colors: [[$r('app.color.accent'), 0], [$r('app.color.cellular'), 1]]
      })
      .onClick(() => this.fetch())

      if (this.result.at > 0 && this.result.link !== 'none') {
        Row({ space: 4 }) {
          SymbolGlyph(linkSymbol(this.result.link))
            .fontSize(10)
            .fontColor([linkColor(this.result.link)])
          Text(`via ${linkLabel(this.result.link)}`)
            .fontSize(10)
            .fontColor(linkColor(this.result.link))
        }
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ left: '12%', right: '12%' })
  }

  @Builder
  TimingBar() {
    Column({ space: 3 }) {
      Row() {
        Blank()
          .layoutWeight(Math.max(this.result.dnsMs, 1))
          .backgroundColor($r('app.color.relay'))
        Blank()
          .layoutWeight(Math.max(this.result.tcpMs, 1))
          .backgroundColor($r('app.color.cellular'))
        Blank()
          .layoutWeight(Math.max(this.result.tlsMs, 1))
          .backgroundColor($r('app.color.accent'))
        Blank()
          .layoutWeight(Math.max(this.result.totalMs - this.result.dnsMs - this.result.tcpMs - this.result.tlsMs, 1))
          .backgroundColor($r('app.color.wifi'))
      }
      .width('100%')
      .height(5)
      .borderRadius(3)
      .clip(true)

      Row() {
        Text('DNS·TCP·TLS·DATA')
          .fontSize(8)
          .letterSpacing(1)
          .fontColor($r('app.color.text_secondary'))
        Blank()
        Text(`${this.result.totalMs} ms`)
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
    }
    .width('80%')
  }

  // ---------- Page 3: background tasks ----------
  @Builder
  BackgroundPage() {
    Column({ space: 6 }) {
      Caption('BACKGROUND')

      ToggleCard({
        icon: $r('sys.symbol.bolt_fill'),
        title: 'Live sync',
        subtitle: 'Every 30 s',
        isOn: this.liveOn,
        tint: $r('app.color.wifi'),
        onToggle: (on: boolean) => {
          this.toggleLive(on);
        }
      })

      ToggleCard({
        icon: $r('sys.symbol.clock_fill'),
        title: 'Scheduled',
        subtitle: 'Every 20 min',
        isOn: this.scheduledOn,
        tint: $r('app.color.cellular'),
        onToggle: (on: boolean) => {
          this.toggleScheduled(on);
        }
      })

      if (this.bgError.length > 0) {
        Text(this.bgError)
          .fontSize(10)
          .fontColor($r('app.color.offline'))
      }

      if (this.log.length === 0) {
        Text('No runs yet')
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 8 })
      } else {
        List() {
          ForEach(this.log, (e: SyncEntry) => {
            ListItem() {
              LogRow(e)
            }
          }, (e: SyncEntry) => `${e.at}-${e.trigger}`)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .fadingEdge(true)
        .onClick(() => this.reloadLog())
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: '13%', right: '13%', top: '13%', bottom: '14%' })
  }

  build() {
    Swiper() {
      this.LinkPage()
      this.RequestPage()
      this.BackgroundPage()
    }
    .vertical(true)
    .loop(false)
    .indicator(new DotIndicator()
      .itemWidth(4)
      .itemHeight(4)
      .selectedItemWidth(4)
      .selectedItemHeight(12)
      .color('#40FFFFFF')
      .selectedColor(Color.White))
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg'))
  }
}
