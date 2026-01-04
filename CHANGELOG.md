# Changelog

## [0.1.0] - 2025-01-04

Initial release.

### Features

#### Core
- Modeline indicator `[ros2:distro:workspace]`
- Detect ROS_DISTRO from environment
- Linux: Auto-source from `/opt/ros/<distro>/`
- macOS/Windows: Rely on pixi.el for ROS2

#### Workspace Detection
- Detect workspace via `install/setup.bash`
- Detect workspace via `src/*/package.xml`
- Follow symlinks when scanning
- `ros2-info` - show distro & workspace status

#### Workspace Sourcing
- `ros2-source` - source workspace `install/setup.bash`
- `ros2-source-distro` - source system distro (Linux)
- Auto-source on workspace change (controlled by `ros2-auto-source`)

#### Package Management
- `ros2-list-packages` - list source packages
- `ros2-list-installed-packages` - list installed packages
- `ros2-find-package` - navigate to package directory

#### Build Commands
- `ros2-build` - colcon build with optional args
- `ros2-build-package` - build specific package (--packages-up-to)
- `ros2-rosdep-install` - install dependencies
- Default `--event-handlers console_direct+`

#### Clean Commands
- `ros2-clean` - remove build/install/log
- `ros2-clean-package` - clean specific package

#### Introspection
- `ros2-topic-list` - list topics
- `ros2-topic-echo` - echo topic with completion
- `ros2-node-list` - list nodes
- `ros2-service-list` - list services
- `ros2-service-type` - show service type

#### Launch Files
- `ros2-list-launch-files` - list launch files for package

#### Interfaces (msg/srv/action)
- `ros2-list-package-msgs` - list .msg files
- `ros2-list-package-srvs` - list .srv files
- `ros2-list-package-actions` - list .action files
- `ros2-list-interfaces` - list all interfaces
- `ros2-show-msg` - show message definition

#### Documentation
- `ros2-docs` - open ROS2 docs for current distro

#### Hooks
- `ros2-source-hook` - run after sourcing workspace/distro
- `ros2-build-hook` - run after successful colcon build
- `ros2-source-after-build` - auto-source after successful build
