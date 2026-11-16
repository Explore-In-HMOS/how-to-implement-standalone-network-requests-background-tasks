import { clock } from '../common/Format';
import { outcomeColor, triggerLabel } from '../common/Theme';
import { SyncEntry } from '../background/SyncLog';

// Builders take a single object-literal param so the caller's state changes propagate by reference.

export interface ChipParams {
  text: string;
  tint: ResourceColor;
}

@Builder
export function Chip(p: ChipParams) {
  Text(p.text)
    .fontSize(10)
    .fontWeight(FontWeight.Bold)
    .letterSpacing(1.5)
    .fontColor(p.tint)
    .padding({ left: 10, right: 10, top: 3, bottom: 3 })
    .borderRadius(10)
    .border({ width: 1, color: p.tint })
    .backgroundColor('#14FFFFFF')
}

@Builder
export function Caption(text: string) {
  Text(text)
    .fontSize(10)
    .letterSpacing(2.5)
    .fontWeight(FontWeight.Medium)
    .fontColor($r('app.color.text_secondary'))
}

export interface ToggleCardParams {
  icon: Resource;
  title: string;
  subtitle: string;
  isOn: boolean;
  tint: ResourceColor;
  onToggle: (on: boolean) => void;
}

@Builder
export function ToggleCard(p: ToggleCardParams) {
  Row({ space: 8 }) {
    Stack() {
      SymbolGlyph(p.icon)
        .fontSize(16)
        .fontColor([p.isOn ? Color.Black : p.tint])
    }
    .width(30)
    .height(30)
    .borderRadius(15)
    .backgroundColor(p.isOn ? p.tint : '#1FFFFFFF')
    .animation({ duration: 250, curve: Curve.EaseOut })

    Column({ space: 1 }) {
      Text(p.title)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
      Text(p.subtitle)
        .fontSize(10)
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)

    Toggle({ type: ToggleType.Switch, isOn: p.isOn })
      .selectedColor(p.tint)
      .switchPointColor(Color.White)
      .width(36)
      .height(22)
      .onChange((on: boolean) => p.onToggle(on))
  }
  .width('100%')
  .padding({ left: 8, right: 6, top: 6, bottom: 6 })
  .borderRadius(22)
  .backgroundColor($r('app.color.surface'))
  .border({ width: 1, color: p.isOn ? p.tint : '#00000000' })
}

@Builder
export function LogRow(e: SyncEntry) {
  Row({ space: 6 }) {
    Circle()
      .width(6)
      .height(6)
      .fill(outcomeColor(e.outcome))
    Text(clock(e.at))
      .fontSize(10)
      .fontColor($r('app.color.text_secondary'))
      .fontFeature('"tnum" on')
    Text(triggerLabel(e.trigger))
      .fontSize(8)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.accent'))
    Text(e.detail)
      .fontSize(10)
      .fontColor($r('app.color.text_primary'))
      .layoutWeight(1)
      .maxLines(1)
      .textAlign(TextAlign.End)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
  }
  .width('100%')
  .height(22)
}
