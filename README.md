# Omarchy Taskwarrior

A native [Omarchy](https://omarchy.org/) QuickShell plugin for managing [Taskwarrior](https://taskwarrior.org/) from the bar.

![Omarchy Taskwarrior panel showing task filters, quick add, task actions, and pagination](assets/omarchy-taskwarrior.png)

## Features

- Ready, Today, Overdue, All, and Done views
- Quick task creation and completion
- Start and stop Taskwarrior time tracking
- Inline task editing for description, project, priority, and due date
- Native calendar and time picker
- Active and overdue bar indicators
- Paginated pending and completed task lists
- Theme-aware Omarchy controls and colors
- In-panel Taskwarrior installation prompt when `task` is unavailable

## Install

```bash
omarchy plugin add https://github.com/AliSayyah/omarchy-taskwarrior.git --enable
```

Run this from an interactive terminal: Omarchy will ask whether to place the widget on the **left**, **center**, or **right** of the bar. Right is preselected as the default, but you can choose any section.

For an existing installation, move it at any time:

```bash
omarchy bar move taskwarrior --section left
omarchy bar move taskwarrior --section center
omarchy bar move taskwarrior --section right
```

Taskwarrior is available from Arch's `task` package; if it is missing, the plugin offers to install it through `omarchy pkg add task`.

## Use

- Left-click the bar widget to open the panel.
- Right-click the widget to refresh.
- Use the filter buttons to switch task views.
- Use the row actions to start or stop tracking, edit, or complete a task.
- Use Previous and Next to move through task pages.

## Update

```bash
omarchy plugin update taskwarrior
```

## Remove

```bash
omarchy plugin remove taskwarrior
```

## Requirements

- Omarchy 4.0 or newer
- Taskwarrior 3.x; the plugin can install it when missing

## Development

The repository root is the plugin root. Runtime boundaries are intentionally small:

- `Panel.qml` composes the bar widget and popup.
- `TaskwarriorController.qml` owns Taskwarrior subprocesses and state.
- `Model.js` handles parsing, filtering, and datetime conversion.
- `components/` contains independent visual components.

Run all local checks on Omarchy:

```bash
./scripts/check
```

Saved QML files hot-reload. If QuickShell retains an older component instance, run:

```bash
omarchy restart shell
```

## License

[MIT](LICENSE)
