# Attributions

`claude-second-brain-jp` は [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian) (MIT) の fork であり、JP 経営者向けに schema preset / hot cache 階層 / cron 制約 / memory freshness gate を追加する派生プロジェクトです。

下記 attribution は upstream のものを保持しています。JP 派生固有の attribution は文末セクションに追記。

---

claude-obsidian is an original work. The following third-party patterns, tools, and creators informed its design.

---

## LLM Wiki Pattern

**Author:** Andrej Karpathy
**Source:** https://github.com/karpathy
**Use:** The core architecture of claude-obsidian — using an LLM to build and maintain a structured wiki from raw sources — is based on the LLM Wiki pattern Karpathy described publicly. claude-obsidian is an independent implementation; no code or content from Karpathy's repositories was copied.

---

## ITS CSS Snippets

**Author:** SlRvb
**Source:** https://github.com/SlRvb/Obsidian--ITS-Theme
**License:** GPL-2.0
**Files:**
- `.obsidian/snippets/ITS-Dataview-Cards.css`
- `.obsidian/snippets/ITS-Image-Adjustments.css`

These snippets are distributed under the GPL-2.0 license. Per GPL-2.0 terms, any modifications to these files must also be released under GPL-2.0.

---

## Obsidian Plugins (pre-installed)

The following Obsidian community plugins ship with this vault as pre-installed binaries. They are the property of their respective authors and are distributed here solely to reduce setup friction. Users should verify license terms via each plugin's repository.

| Plugin | Author | Repository |
|--------|--------|-----------|
| Calendar | Liam Cain | https://github.com/liamcain/obsidian-calendar-plugin |
| Thino | Boninall (Quorafind) | https://github.com/Quorafind/Obsidian-Thino |
| Obsidian Excalidraw | Zsolt Viczian | https://github.com/zsviczian/obsidian-excalidraw-plugin |
| Obsidian Banners | Danny Hernandez | https://github.com/noatpad/obsidian-banners |

`obsidian-excalidraw-plugin/main.js` is **not** included in this repository. It is downloaded automatically by `bin/setup-vault.sh` from the plugin's official GitHub releases.

---

## claude-obsidian (upstream)

**Author:** AgriciDaniel / AI Marketing Hub
**License:** MIT (see [LICENSE](LICENSE))
**Repository:** https://github.com/AgriciDaniel/claude-obsidian

---

## claude-second-brain-jp (this fork)

**Author:** Kazuya Hibara
**License:** MIT (see [LICENSE](LICENSE))
**Repository:** https://github.com/Kazuya-Hibara/claude-second-brain-jp
**Contact:** contact@kazuyahibara.com
**Forked at:** upstream v1.6.0 (2026-05-05)
**Differentiation roadmap:** see `IMPLEMENTATION-PLAN.md` Phase 2-5 (deferred to next milestone)
