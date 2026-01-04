# ros2.el - ROS2 Integration for Emacs

## V0.1.0 (In Progress)

### Core
- [x] Modeline indicator `[ros2:distro:workspace]`
- [x] Detect ROS_DISTRO from environment
- [x] Linux: Auto-source from `/opt/ros/<distro>/`
- [x] macOS/Windows: Rely on pixi.el for ROS2

### Workspace Detection
- [x] Detect workspace via `install/setup.bash`
- [x] Detect workspace via `src/*/package.xml`
- [x] Follow symlinks when scanning
- [x] `ros2-info` - show distro & workspace status

### Workspace Sourcing
- [x] `ros2-source` - source workspace `install/setup.bash`
- [x] `ros2-source-distro` - source system distro (Linux)
- [x] Auto-source on workspace change (controlled by `ros2-auto-source`)

### Package Management
- [x] `ros2-list-packages` - list source packages
- [x] `ros2-list-installed-packages` - list installed packages
- [x] `ros2-find-package` - navigate to package directory

### Build Commands
- [x] `ros2-build` - colcon build with optional args
- [x] `ros2-build-package` - build specific package (--packages-up-to)
- [x] `ros2-rosdep-install` - install dependencies
- [x] Default `--event-handlers console_direct+`

### Clean Commands
- [x] `ros2-clean` - remove build/install/log
- [x] `ros2-clean-package` - clean specific package

### Introspection
- [x] `ros2-topic-list` - list topics
- [x] `ros2-topic-echo` - echo topic with completion
- [x] `ros2-node-list` - list nodes
- [x] `ros2-service-list` - list services
- [x] `ros2-service-type` - show service type

### Launch Files
- [x] `ros2-list-launch-files` - list launch files for package

### Interfaces (msg/srv/action)
- [x] `ros2-list-package-msgs` - list .msg files
- [x] `ros2-list-package-srvs` - list .srv files
- [x] `ros2-list-package-actions` - list .action files
- [x] `ros2-list-interfaces` - list all interfaces
- [x] `ros2-show-msg` - show message definition
- [ ] `ros2-show-srv` - show service definition
- [ ] `ros2-show-action` - show action definition

### Documentation
- [x] `ros2-docs` - open ROS2 docs for current distro

### Hooks
- [x] `ros2-source-hook` - run after sourcing workspace/distro
- [x] `ros2-build-hook` - run after successful colcon build
- [x] `ros2-source-after-build` - auto-source after successful build

---

## V0.2.0 (Future)

### Launch
- [ ] `ros2-launch` - run launch file with completion
- [ ] `ros2-launch-package` - select package then launch file

### Run
- [ ] `ros2-run` - run a node (`ros2 run <pkg> <executable>`)

### Package Creation
- [ ] `ros2-create-package` - create new package

### Testing
- [ ] `ros2-test` - run colcon test
- [ ] `ros2-test-package` - test specific package

### Compile Integration
- [ ] Error regex for `next-error` navigation (CMake/GCC/Python)
- [ ] `ros2-build-current` - build package containing current file
- [ ] Build on save (opt-in)

### More Introspection
- [ ] `ros2-topic-info` - detailed topic info
- [ ] `ros2-node-info` - detailed node info
- [ ] `ros2-action-list` - list actions

### Parameters
- [ ] `ros2-param-list` - list parameters for a node
- [ ] `ros2-param-get` - get parameter value
- [ ] `ros2-param-set` - set parameter value

### Bags
- [ ] `ros2-bag-record` - record topics to bag
- [ ] `ros2-bag-play` - play bag file

### Keybindings
- [ ] `C-c R` prefix map (avoid conflict with `recompile`)

### UI Enhancements
- [ ] Transient menu
- [ ] Status buffer
