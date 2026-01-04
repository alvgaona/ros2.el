# ros2.el

Emacs integration for [ROS2](https://docs.ros.org/) (Robot Operating System 2).

## Features

- **Auto-source**: Automatically source workspace when opening files
- **Modeline indicator**: Shows `[ros2:distro:workspace]` in the modeline
- **Linux**: Auto-detect distros in `/opt/ros/`
- **macOS/Windows**: Rely on [pixi.el](https://github.com/alvgaona/pixi.el) for ROS2
- **Build integration**: Colcon build with compile-mode
- **Introspection**: Topics, nodes, services with completion
- **Hooks**: Customize behavior with `ros2-source-hook`, `ros2-build-hook`

## Installation

### Manual

Clone the repository and add to your `load-path`:

```elisp
(add-to-list 'load-path "/path/to/ros2.el")
(require 'ros2)
```

### use-package

```elisp
(use-package ros2
  :load-path "/path/to/ros2.el")
```

## Usage

### Workspace Sourcing

| Command                  | Description                          |
|--------------------------|--------------------------------------|
| `M-x ros2-source`        | Source workspace `install/setup.bash`|
| `M-x ros2-source-distro` | Source system distro (Linux)         |
| `M-x ros2-info`          | Show distro & workspace status       |

### Package Management

| Command                         | Description                    |
|---------------------------------|--------------------------------|
| `M-x ros2-list-packages`        | List source packages           |
| `M-x ros2-list-installed-packages` | List installed packages     |
| `M-x ros2-find-package`         | Navigate to package directory  |

### Build Commands

| Command                  | Description                          |
|--------------------------|--------------------------------------|
| `M-x ros2-build`         | Colcon build with optional args      |
| `M-x ros2-build-package` | Build specific package               |
| `M-x ros2-rosdep-install`| Install dependencies                 |
| `M-x ros2-clean`         | Remove build/install/log             |
| `M-x ros2-clean-package` | Clean specific package               |

### Introspection

| Command                  | Description                          |
|--------------------------|--------------------------------------|
| `M-x ros2-topic-list`    | List topics                          |
| `M-x ros2-topic-echo`    | Echo topic with completion           |
| `M-x ros2-node-list`     | List running nodes                   |
| `M-x ros2-service-list`  | List services                        |
| `M-x ros2-service-type`  | Show service type                    |

### Interfaces

| Command                       | Description                     |
|-------------------------------|---------------------------------|
| `M-x ros2-list-package-msgs`  | List .msg files for package     |
| `M-x ros2-list-package-srvs`  | List .srv files for package     |
| `M-x ros2-list-package-actions` | List .action files for package|
| `M-x ros2-list-interfaces`    | List all interfaces for package |
| `M-x ros2-show-msg`           | Show message definition         |

### Other

| Command                    | Description                        |
|----------------------------|------------------------------------|
| `M-x ros2-list-launch-files` | List launch files for package    |
| `M-x ros2-docs`            | Open ROS2 docs in browser          |

## Configuration

```elisp
;; Disable auto-source on workspace change (default: t)
(setq ros2-auto-source nil)
```

## Hooks

```elisp
;; Auto-source workspace after successful build
(add-hook 'ros2-build-hook #'ros2-source-after-build)

;; Custom action after sourcing
(add-hook 'ros2-source-hook
          (lambda ()
            (message "ROS2 workspace sourced!")))
```

## Requirements

- Emacs 28.1+
- ROS2 installation (Linux: `/opt/ros/`, or via pixi on macOS/Windows)

## License

GPL-3.0-or-later
