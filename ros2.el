;;; ros2.el --- ROS2 integration for Emacs -*- lexical-binding: t -*-

;; Copyright (C) 2025 Alvaro

;; Author: Alvaro
;; Maintainer: Alvaro
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.1"))
;; Keywords: tools, processes
;; URL: https://github.com/alvgaona/ros2.el
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:

;; ros2.el provides Emacs integration for ROS2 (Robot Operating System 2).
;;
;; Features:
;; - Modeline indicator showing active ROS2 distro
;;
;; Basic usage:
;;   (require 'ros2)

;;; Code:

;;; Customization

(defgroup ros2 nil
  "ROS2 integration for Emacs."
  :group 'tools
  :prefix "ros2-")

;;; Hooks

(defvar ros2-source-hook nil
  "Hook run after sourcing a ROS2 workspace or distro.")

(defvar ros2-build-hook nil
  "Hook run after a successful colcon build.")

;;; Internal variables

(defvar ros2--original-process-environment nil
  "Saved process environment before ros2 workspace sourcing.")

(defvar ros2--current-workspace nil
  "Path to the currently sourced workspace.")

(defvar ros2--build-workspace nil
  "Workspace path for the current/last build.")

(defcustom ros2-auto-source t
  "Automatically source workspace when entering a different ROS2 workspace."
  :type 'boolean
  :group 'ros2)

(defcustom ros2-show-modeline t
  "Whether to show ROS2 status in the modeline."
  :type 'boolean
  :group 'ros2)

(defcustom ros2-modeline-show-distro t
  "Whether to show ROS2 distro in the modeline."
  :type 'boolean
  :group 'ros2)

(defcustom ros2-modeline-show-workspace t
  "Whether to show workspace name in the modeline."
  :type 'boolean
  :group 'ros2)

(defcustom ros2-modeline-prefix "ros2"
  "Prefix string to show in the modeline. Set to nil to hide."
  :type '(choice (string :tag "Prefix")
                 (const :tag "None" nil))
  :group 'ros2)

(defcustom ros2-modeline-show-icon t
  "Whether to show the ROS2 icon in the modeline."
  :type 'boolean
  :group 'ros2)

(defcustom ros2-modeline-icon "\ue893"
  "Icon to display in the modeline (nf-dev-ros from Nerd Fonts)."
  :type 'string
  :group 'ros2)

;;; System ROS2 installation (Linux only)

(defconst ros2--linux-install-path "/opt/ros"
  "Standard ROS2 installation path on Linux.")

(defun ros2--linux-p ()
  "Return non-nil if running on Linux."
  (eq system-type 'gnu/linux))

(defun ros2--list-system-distros ()
  "List available ROS2 distros in /opt/ros (Linux only)."
  (when (and (ros2--linux-p)
             (file-directory-p ros2--linux-install-path))
    (cl-remove-if-not
     (lambda (dir)
       (file-exists-p (expand-file-name "setup.bash"
                        (expand-file-name dir ros2--linux-install-path))))
     (directory-files ros2--linux-install-path nil "^[^.]"))))

(defun ros2-source-distro (distro)
  "Source a system ROS2 DISTRO from /opt/ros (Linux only)."
  (interactive
   (list
    (let ((distros (ros2--list-system-distros)))
      (unless distros
        (user-error "No ROS2 distros found in %s" ros2--linux-install-path))
      (completing-read "Distro: " distros nil t))))
  (let ((setup-file (expand-file-name (format "%s/setup.bash" distro) ros2--linux-install-path)))
    (unless (file-exists-p setup-file)
      (user-error "Setup file not found: %s" setup-file))
    ;; Save original environment if not already saved
    (unless ros2--original-process-environment
      (setq ros2--original-process-environment (copy-sequence process-environment)))
    ;; Source and capture environment
    (let* ((cmd (format "source %s && env" setup-file))
           (output (shell-command-to-string (format "bash -c %s" (shell-quote-argument cmd))))
           (new-env (split-string output "\n" t)))
      (when new-env
        (setq process-environment new-env)
        (when-let ((path (getenv "PATH")))
          (setq exec-path (parse-colon-path path)))
        (run-hooks 'ros2-source-hook)
        (message "Sourced ROS2 %s" distro)))))

(defun ros2--maybe-source-system ()
  "Auto-source system ROS2 on Linux if available and not already sourced."
  (when (and (ros2--linux-p)
             (not (getenv "ROS_DISTRO")))
    (let ((distros (ros2--list-system-distros)))
      (when (= (length distros) 1)
        ;; Auto-source if exactly one distro available
        (ros2-source-distro (car distros))))))

;; Auto-source on Linux when loading
(ros2--maybe-source-system)

;;; Workspace detection

(defun ros2--has-install-setup-p (dir)
  "Check if DIR contains install/setup.bash (built workspace)."
  (file-exists-p (expand-file-name "install/setup.bash" dir)))

(defun ros2--has-src-packages-p (dir)
  "Check if DIR contains src/ with at least one package.xml."
  (let ((src-dir (expand-file-name "src" dir)))
    (and (file-directory-p src-dir)
         (directory-files-recursively src-dir "^package\\.xml$" nil nil 'follow-symlinks))))

(defun ros2--workspace-p (dir)
  "Check if DIR is a ROS2 workspace."
  (or (ros2--has-install-setup-p dir)
      (ros2--has-src-packages-p dir)))

(defun ros2--find-workspace-root (&optional dir)
  "Find the root of a ROS2 workspace starting from DIR."
  (let ((start-dir (or dir default-directory)))
    (locate-dominating-file start-dir #'ros2--workspace-p)))

(defun ros2--parse-package-name (package-xml)
  "Parse the package name from PACKAGE-XML file."
  (with-temp-buffer
    (insert-file-contents package-xml)
    (goto-char (point-min))
    (when (re-search-forward "<name>\\([^<]+\\)</name>" nil t)
      (match-string 1))))

(defun ros2--display-buffer (title content)
  "Display CONTENT with TITLE in the *ros2* buffer (read-only)."
  (with-current-buffer (get-buffer-create "*ros2*")
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert title)
      (insert "\n\n")
      (if (listp content)
          (dolist (item content)
            (insert (format "  %s\n" item)))
        (insert content)))
    (goto-char (point-min))
    (special-mode)
    (display-buffer (current-buffer))))

(defun ros2--list-packages (&optional workspace)
  "List source package names in WORKSPACE src/ directory."
  (let* ((root (or workspace (ros2--find-workspace-root)))
         (src-dir (expand-file-name "src" root)))
    (when (file-directory-p src-dir)
      (let ((package-xmls (directory-files-recursively src-dir "^package\\.xml$" nil nil 'follow-symlinks)))
        (delq nil (mapcar #'ros2--parse-package-name package-xmls))))))

(defun ros2--list-installed-packages (&optional workspace)
  "List installed package names in WORKSPACE install/ directory."
  (let* ((root (or workspace (ros2--find-workspace-root)))
         (install-dir (expand-file-name "install" root)))
    (when (file-directory-p install-dir)
      (let ((package-xmls (directory-files-recursively install-dir "^package\\.xml$" nil nil 'follow-symlinks)))
        (delq nil (mapcar #'ros2--parse-package-name package-xmls))))))

;;; Modeline

(defun ros2--modeline-string ()
  "Return the modeline string for ROS2 status."
  (when (and ros2-show-modeline (getenv "ROS_DISTRO"))
    (let ((parts '())
          (distro (getenv "ROS_DISTRO"))
          (workspace (ros2--find-workspace-root))
          (icon (when ros2-modeline-show-icon ros2-modeline-icon)))
      (when ros2-modeline-prefix
        (setq parts (append parts (list ros2-modeline-prefix))))
      (when ros2-modeline-show-distro
        (setq parts (append parts (list distro))))
      (when (and ros2-modeline-show-workspace workspace)
        (setq parts (append parts (list (file-name-nondirectory (directory-file-name workspace))))))
      (when (or icon parts)
        (format " %s%s"
                (if icon (concat icon " ") "")
                (string-join parts ":"))))))

(defvar ros2-mode-line
  '(:eval (ros2--modeline-string))
  "Modeline indicator for ROS2 status.")

(put 'ros2-mode-line 'risky-local-variable t)

(defun ros2-modeline-enable ()
  "Enable ROS2 modeline indicator."
  (interactive)
  (setq ros2-show-modeline t)
  (add-to-list 'mode-line-misc-info 'ros2-mode-line t))

(defun ros2-modeline-disable ()
  "Disable ROS2 modeline indicator."
  (interactive)
  (setq ros2-show-modeline nil)
  (setq mode-line-misc-info (delete 'ros2-mode-line mode-line-misc-info)))

(when ros2-show-modeline
  (add-to-list 'mode-line-misc-info 'ros2-mode-line t))

;;; Interactive commands

(defun ros2-info ()
  "Display information about the current ROS2 environment."
  (interactive)
  (let ((distro (getenv "ROS_DISTRO"))
        (workspace (ros2--find-workspace-root)))
    (message "ROS2: %s | Workspace: %s"
             (or distro "not sourced")
             (or workspace "not detected"))))

(defun ros2-list-packages ()
  "List source packages in the current ROS2 workspace."
  (interactive)
  (if-let ((packages (ros2--list-packages)))
      (ros2--display-buffer
       (format "ROS2 Source Packages (%d):" (length packages))
       (sort packages #'string<))
    (message "No packages found (not in a ROS2 workspace?)")))

(defun ros2-list-installed-packages ()
  "List installed packages in the current ROS2 workspace."
  (interactive)
  (if-let ((packages (ros2--list-installed-packages)))
      (ros2--display-buffer
       (format "ROS2 Installed Packages (%d):" (length packages))
       (sort packages #'string<))
    (message "No installed packages found (workspace not built?)")))

(defun ros2-clean ()
  "Remove build, install, and log directories from the workspace."
  (interactive)
  (let ((workspace (ros2--find-workspace-root)))
    (unless workspace
      (user-error "Not in a ROS2 workspace"))
    (when (yes-or-no-p (format "Clean workspace %s? (removes build/, install/, log/)" workspace))
      (let ((default-directory workspace))
        (dolist (dir '("build" "install" "log"))
          (when (file-directory-p dir)
            (delete-directory dir t)))
        (message "Workspace cleaned")))))

(defun ros2-clean-package (package-name)
  "Remove build and install directories for PACKAGE-NAME."
  (interactive
   (list
    (let ((packages (ros2--list-packages)))
      (unless packages
        (user-error "No packages found"))
      (completing-read "Package to clean: " packages nil t))))
  (let ((workspace (ros2--find-workspace-root)))
    (unless workspace
      (user-error "Not in a ROS2 workspace"))
    (let ((build-dir (expand-file-name (concat "build/" package-name) workspace))
          (install-dir (expand-file-name (concat "install/" package-name) workspace))
          (cleaned nil))
      (when (file-directory-p build-dir)
        (delete-directory build-dir t)
        (push "build" cleaned))
      (when (file-directory-p install-dir)
        (delete-directory install-dir t)
        (push "install" cleaned))
      (if cleaned
          (message "Cleaned %s: %s" package-name (string-join cleaned ", "))
        (message "Nothing to clean for %s" package-name)))))

(defun ros2-source ()
  "Source the workspace's install/setup.bash."
  (interactive)
  (let ((workspace (ros2--find-workspace-root)))
    (unless workspace
      (user-error "Not in a ROS2 workspace"))
    (let ((setup-file (expand-file-name "install/setup.bash" workspace)))
      (unless (file-exists-p setup-file)
        (user-error "Workspace not built (install/setup.bash not found)"))
      ;; Save original environment if not already saved
      (unless ros2--original-process-environment
        (setq ros2--original-process-environment (copy-sequence process-environment)))
      ;; Source and capture environment
      (let* ((cmd (format "source %s && env" setup-file))
             (output (shell-command-to-string (format "bash -c %s" (shell-quote-argument cmd))))
             (new-env (split-string output "\n" t)))
        (when new-env
          (setq process-environment new-env)
          (when-let ((path (getenv "PATH")))
            (setq exec-path (parse-colon-path path)))
          (setq ros2--current-workspace workspace)
          (run-hooks 'ros2-source-hook)
          (message "Sourced workspace: %s" workspace))))))

(defun ros2--get-package-directory (package-name)
  "Get the source directory for PACKAGE-NAME."
  (let* ((root (ros2--find-workspace-root))
         (src-dir (expand-file-name "src" root))
         (package-xmls (directory-files-recursively src-dir "^package\\.xml$" nil nil 'follow-symlinks)))
    (cl-loop for xml in package-xmls
             when (string= (ros2--parse-package-name xml) package-name)
             return (file-name-directory xml))))

(defun ros2-find-package (package-name)
  "Open the directory for PACKAGE-NAME."
  (interactive
   (list
    (let ((packages (ros2--list-packages)))
      (unless packages
        (user-error "No packages found"))
      (completing-read "Package: " packages nil t))))
  (let ((dir (ros2--get-package-directory package-name)))
    (if dir
        (dired dir)
      (user-error "Package %s not found" package-name))))

;;; Build commands

(defun ros2--compilation-finish (buffer msg)
  "Handle colcon build completion in BUFFER with result MSG."
  (when (and ros2--build-workspace
             (string-match-p "colcon build" (buffer-local-value 'compile-command buffer)))
    (if (string-match-p "finished" msg)
        (progn
          (run-hooks 'ros2-build-hook)
          (message "ROS2 build finished: %s" ros2--build-workspace))
      (message "ROS2 build failed"))))

(add-hook 'compilation-finish-functions #'ros2--compilation-finish)

(defun ros2-source-after-build ()
  "Auto-source the workspace after a successful build.
Add this to `ros2-build-hook' to enable:
  (add-hook \\='ros2-build-hook #\\='ros2-source-after-build)"
  (when ros2--build-workspace
    (let ((setup-file (expand-file-name "install/setup.bash" ros2--build-workspace)))
      (when (file-exists-p setup-file)
        ;; Save original if needed
        (unless ros2--original-process-environment
          (setq ros2--original-process-environment (copy-sequence process-environment)))
        ;; Source workspace
        (let* ((cmd (format "source %s && env" setup-file))
               (output (shell-command-to-string (format "bash -c %s" (shell-quote-argument cmd))))
               (new-env (split-string output "\n" t)))
          (when new-env
            (setq process-environment new-env)
            (when-let ((path (getenv "PATH")))
              (setq exec-path (parse-colon-path path)))
            (run-hooks 'ros2-source-hook)
            (message "Auto-sourced workspace after build")))))))

(defun ros2-build (&optional args)
  "Build the workspace with colcon build.
Optional ARGS are appended to the command."
  (interactive
   (list (read-string "colcon build args (optional): ")))
  (let* ((workspace (ros2--find-workspace-root)))
    (unless workspace
      (user-error "Not in a ROS2 workspace"))
    (setq ros2--build-workspace workspace)
    (let ((default-directory workspace)
          (cmd (if (and args (not (string-empty-p args)))
                   (format "colcon build --event-handlers console_direct+ %s" args)
                 "colcon build --event-handlers console_direct+")))
      (compile cmd))))

(defun ros2-rosdep-install (&optional args)
  "Install dependencies with rosdep.
Optional ARGS are appended to the command."
  (interactive
   (list (read-string "rosdep install args (optional): ")))
  (let* ((workspace (ros2--find-workspace-root)))
    (unless workspace
      (user-error "Not in a ROS2 workspace"))
    (let ((default-directory workspace)
          (base-cmd "rosdep install --from-paths src --ignore-src -r -y")
          (cmd (if (and args (not (string-empty-p args)))
                   (format "%s %s" base-cmd args)
                 base-cmd)))
      (compile cmd))))

(defun ros2-build-package (package-name &optional args)
  "Build PACKAGE-NAME with colcon build.
Optional ARGS are appended to the command."
  (interactive
   (let* ((packages (ros2--list-packages))
          (pkg (progn
                 (unless packages
                   (user-error "No packages found"))
                 (completing-read "Package: " packages nil t)))
          (args (read-string "Additional args (optional): ")))
     (list pkg (unless (string-empty-p args) args))))
  (let* ((workspace (ros2--find-workspace-root)))
    (unless workspace
      (user-error "Not in a ROS2 workspace"))
    (setq ros2--build-workspace workspace)
    (let ((default-directory workspace)
          (cmd (if args
                   (format "colcon build --event-handlers console_direct+ --packages-up-to %s %s" package-name args)
                 (format "colcon build --event-handlers console_direct+ --packages-up-to %s" package-name))))
      (compile cmd))))

;;; Introspection commands

(defun ros2--get-topics ()
  "Get list of available ROS2 topics."
  (let ((output (shell-command-to-string "ros2 topic list 2>/dev/null")))
    (when (not (string-empty-p output))
      (split-string output "\n" t))))

(defun ros2--get-nodes ()
  "Get list of running ROS2 nodes."
  (let ((output (shell-command-to-string "ros2 node list 2>/dev/null")))
    (when (not (string-empty-p output))
      (split-string output "\n" t))))

(defun ros2-topic-list ()
  "List available ROS2 topics."
  (interactive)
  (if-let ((topics (ros2--get-topics)))
      (ros2--display-buffer
       (format "ROS2 Topics (%d):" (length topics))
       topics)
    (message "No topics found (is ROS2 running?)")))

(defun ros2-node-list ()
  "List running ROS2 nodes."
  (interactive)
  (if-let ((nodes (ros2--get-nodes)))
      (ros2--display-buffer
       (format "ROS2 Nodes (%d):" (length nodes))
       nodes)
    (message "No nodes found (is ROS2 running?)")))

(defun ros2-topic-echo (topic)
  "Echo a ROS2 TOPIC."
  (interactive
   (list
    (let ((topics (ros2--get-topics)))
      (unless topics
        (user-error "No topics found (is ROS2 running?)"))
      (completing-read "Topic: " topics nil t))))
  (let ((buf (get-buffer-create (format "*ros2 echo %s*" topic))))
    (async-shell-command (format "ros2 topic echo %s" topic) buf)))

(defun ros2--get-services ()
  "Get list of available ROS2 services."
  (let ((output (shell-command-to-string "ros2 service list 2>/dev/null")))
    (when (not (string-empty-p output))
      (split-string output "\n" t))))

(defun ros2-service-list ()
  "List available ROS2 services."
  (interactive)
  (if-let ((services (ros2--get-services)))
      (ros2--display-buffer
       (format "ROS2 Services (%d):" (length services))
       services)
    (message "No services found (is ROS2 running?)")))

(defun ros2-service-type (service)
  "Show the type of a ROS2 SERVICE."
  (interactive
   (list
    (let ((services (ros2--get-services)))
      (unless services
        (user-error "No services found (is ROS2 running?)"))
      (completing-read "Service: " services nil t))))
  (let ((output (shell-command-to-string (format "ros2 service type %s 2>/dev/null" service))))
    (if (not (string-empty-p output))
        (message "%s: %s" service (string-trim output))
      (message "Could not get type for %s" service))))

(defun ros2-docs ()
  "Open ROS2 documentation for the current distro in browser."
  (interactive)
  (let ((distro (getenv "ROS_DISTRO")))
    (unless distro
      (user-error "ROS_DISTRO not set"))
    (browse-url (format "https://docs.ros.org/en/%s/" distro))))

(defun ros2--list-package-launch-files (package-name)
  "List launch files for PACKAGE-NAME."
  (let ((pkg-dir (ros2--get-package-directory package-name)))
    (when pkg-dir
      (let ((launch-dir (expand-file-name "launch" pkg-dir)))
        (when (file-directory-p launch-dir)
          (directory-files launch-dir nil "\\.launch\\(\\.py\\|\\.xml\\)?$"))))))

(defun ros2-list-launch-files (package-name)
  "List launch files for PACKAGE-NAME."
  (interactive
   (list
    (let ((packages (ros2--list-packages)))
      (unless packages
        (user-error "No packages found"))
      (completing-read "Package: " packages nil t))))
  (if-let ((launches (ros2--list-package-launch-files package-name)))
      (ros2--display-buffer
       (format "Launch files for %s (%d):" package-name (length launches))
       launches)
    (message "No launch files found for %s" package-name)))

;;; Interface commands (msg, srv, action)

(defun ros2--list-package-interfaces (package-name subdir extension)
  "List interface files for PACKAGE-NAME in SUBDIR with EXTENSION."
  (let ((pkg-dir (ros2--get-package-directory package-name)))
    (when pkg-dir
      (let ((interface-dir (expand-file-name subdir pkg-dir)))
        (when (file-directory-p interface-dir)
          (directory-files interface-dir nil (format "\\.%s$" extension)))))))

(defun ros2-list-package-msgs (package-name)
  "List message definitions for PACKAGE-NAME."
  (interactive
   (list
    (let ((packages (ros2--list-packages)))
      (unless packages
        (user-error "No packages found"))
      (completing-read "Package: " packages nil t))))
  (if-let ((msgs (ros2--list-package-interfaces package-name "msg" "msg")))
      (ros2--display-buffer
       (format "Messages for %s (%d):" package-name (length msgs))
       msgs)
    (message "No messages found for %s" package-name)))

(defun ros2-list-package-srvs (package-name)
  "List service definitions for PACKAGE-NAME."
  (interactive
   (list
    (let ((packages (ros2--list-packages)))
      (unless packages
        (user-error "No packages found"))
      (completing-read "Package: " packages nil t))))
  (if-let ((srvs (ros2--list-package-interfaces package-name "srv" "srv")))
      (ros2--display-buffer
       (format "Services for %s (%d):" package-name (length srvs))
       srvs)
    (message "No services found for %s" package-name)))

(defun ros2-list-package-actions (package-name)
  "List action definitions for PACKAGE-NAME."
  (interactive
   (list
    (let ((packages (ros2--list-packages)))
      (unless packages
        (user-error "No packages found"))
      (completing-read "Package: " packages nil t))))
  (if-let ((actions (ros2--list-package-interfaces package-name "action" "action")))
      (ros2--display-buffer
       (format "Actions for %s (%d):" package-name (length actions))
       actions)
    (message "No actions found for %s" package-name)))

(defun ros2-list-interfaces (package-name)
  "List all interfaces (msg, srv, action) for PACKAGE-NAME."
  (interactive
   (list
    (let ((packages (ros2--list-packages)))
      (unless packages
        (user-error "No packages found"))
      (completing-read "Package: " packages nil t))))
  (let ((msgs (ros2--list-package-interfaces package-name "msg" "msg"))
        (srvs (ros2--list-package-interfaces package-name "srv" "srv"))
        (actions (ros2--list-package-interfaces package-name "action" "action")))
    (if (or msgs srvs actions)
        (with-current-buffer (get-buffer-create "*ros2*")
          (let ((inhibit-read-only t))
            (erase-buffer)
            (insert (format "Interfaces for %s:\n\n" package-name))
            (when msgs
              (insert (format "Messages (%d):\n" (length msgs)))
              (dolist (msg msgs)
                (insert (format "  %s\n" msg)))
              (insert "\n"))
            (when srvs
              (insert (format "Services (%d):\n" (length srvs)))
              (dolist (srv srvs)
                (insert (format "  %s\n" srv)))
              (insert "\n"))
            (when actions
              (insert (format "Actions (%d):\n" (length actions)))
              (dolist (action actions)
                (insert (format "  %s\n" action)))))
          (goto-char (point-min))
          (special-mode)
          (display-buffer (current-buffer)))
      (message "No interfaces found for %s" package-name))))

(defun ros2--get-all-msgs ()
  "Get all message files across all packages as (package . msg) pairs."
  (let ((packages (ros2--list-packages))
        result)
    (dolist (pkg packages)
      (dolist (msg (ros2--list-package-interfaces pkg "msg" "msg"))
        (push (cons pkg msg) result)))
    (nreverse result)))

(defun ros2-show-msg (package-name msg-name)
  "Show the definition of MSG-NAME from PACKAGE-NAME."
  (interactive
   (let* ((all-msgs (ros2--get-all-msgs))
          (choices (mapcar (lambda (pair)
                             (format "%s/%s" (car pair) (cdr pair)))
                           all-msgs))
          (choice (completing-read "Message: " choices nil t))
          (parts (split-string choice "/")))
     (list (car parts) (cadr parts))))
  (let* ((pkg-dir (ros2--get-package-directory package-name))
         (msg-file (expand-file-name (format "msg/%s" msg-name) pkg-dir)))
    (if (file-exists-p msg-file)
        (with-current-buffer (get-buffer-create "*ros2*")
          (let ((inhibit-read-only t))
            (erase-buffer)
            (insert (format "%s/%s\n\n" package-name msg-name))
            (insert-file-contents msg-file))
          (goto-char (point-min))
          (special-mode)
          (display-buffer (current-buffer)))
      (user-error "Message file not found: %s" msg-file))))

;;; Auto-sourcing

(defun ros2--maybe-source ()
  "Auto-source workspace if in a different ROS2 workspace."
  (when ros2-auto-source
    (let ((workspace (ros2--find-workspace-root)))
      (when (and workspace
                 (ros2--has-install-setup-p workspace)
                 (not (equal workspace ros2--current-workspace)))
        ;; Restore to original environment first
        (when ros2--original-process-environment
          (setq process-environment (copy-sequence ros2--original-process-environment)))
        ;; Source the new workspace
        (ros2-source)))))

(add-hook 'find-file-hook #'ros2--maybe-source)
(add-hook 'dired-mode-hook #'ros2--maybe-source)

(provide 'ros2)
;;; ros2.el ends here
