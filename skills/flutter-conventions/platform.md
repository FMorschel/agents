## Platform checks

- In UI code, never branch on `Platform.isAndroid`, `Platform.isIOS`, etc. They throw on web (`dart:io` is unavailable there; `kIsWeb` must be checked first) and hardcode a platform where the layout should adapt to what the device can do.
- For UI that must differ per platform, use `Theme.of(context).platform` (cached per `state.md`). It works on web, respects the `ThemeData.platform` override (tests, previews), and rebuilds when the theme changes. Use `defaultTargetPlatform` only where there is no `BuildContext`.
- For everything else prefer capability or context signals: `MediaQuery`/`LayoutBuilder` for size, input and device capabilities.
- A `Platform.isFoo` check is acceptable only for non-UI logic with no adaptive alternative (e.g. choosing a file-system or plugin backend). Guard every such check with `!kIsWeb` first (`!kIsWeb && Platform.isWindows`) so it short-circuits before `Platform` is touched on web.
- Keep these checks out of widgets: put them in a service or data source, per the project's architecture (`layered-architecture`).
