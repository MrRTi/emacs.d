(defvar elpaca-installer-version 0.7)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                                :ref nil :depth 1
                                :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                                :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
        (build (expand-file-name "elpaca/" elpaca-builds-directory))
        (order (cdr elpaca-order))
        (default-directory repo))
    (add-to-list 'load-path (if (file-exists-p build) build repo))
    (unless (file-exists-p repo)
    (make-directory repo t)
    (when (< emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                    ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                    ,@(when-let ((depth (plist-get order :depth)))
                                                        (list (format "--depth=%d" depth) "--no-single-branch"))
                                                    ,(plist-get order :repo) ,repo))))
                    ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                    (emacs (concat invocation-directory invocation-name))
                    ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                    ((require 'elpaca))
                    ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
            (error "%s" (with-current-buffer buffer (buffer-string))))
        ((error) (warn "%s" err) (delete-directory repo 'recursive))))
    (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Install a package via the elpaca macro
;; See the "recipes" section of the manual for more details.

;; (elpaca example-package)

;; Install use-package support
(elpaca elpaca-use-package
;; Enable use-package :ensure support for Elpaca.
(elpaca-use-package-mode))

;;When installing a package used in the init file itself,
;;e.g. a package which adds a use-package key word,
;;use the :wait recipe keyword to block until that package is installed/configured.
;;For example:
;;(use-package general :ensure (:wait t) :demand t)

;; Expands to: (elpaca evil (use-package evil :demand t))
(use-package evil
    :init
    (setq evil-want-integration t)
    (setq evil-want-keybinding nil)
    (setq evil-vsplit-window-right t)
    (setq evil-split-window-below t)
    (evil-mode 1)
    :ensure (:wait t) :demand t)
(use-package evil-collection
    :after evil
    :config
    (setq evil-collection-mode-list '(dashboard dired ibuffer help magit))
    (evil-collection-init)
    :ensure (:wait t) :demand t)
(use-package evil-tutor :ensure (:wait t) :demand t)

;;Turns off elpaca-use-package-mode current declaration
;;Note this will cause evaluate the declaration immediately. It is not deferred.
;;Useful for configuring built-in emacs features.
(use-package emacs :ensure nil :config (setq ring-bell-function #'ignore))

(use-package general
    :ensure (:wait t) :demand t
    :config
    (general-evil-setup)

    ;; set up 'SPC' as the gloval leader key
    (general-create-definer rti/leader-keys
        :prefix "SPC" ;; set leader
        :global-prefix "M-;") ;; access leader in insert mode

    ;; Search keymaps
    (rti/leader-keys
        :states 'normal
        "." '(find-file :wk "Find file")
        "f" '(:ignore t :wk "File...")
        "f c" '((lambda () (interactive) (find-file "~/.emacs.d/config.org")) :wk "Open emacs config filr"))

    ;; nvim like comment line keybinding
    (general-define-key
        :states 'normal
        "g c c" '(comment-line :wk "Comment line")) 

    (general-define-key
        :states 'visual
        "g c" '(comment-line :wk "Comment lines")) 

    (general-define-key
        :states 'normal
        "g t" '(org-open-at-point :wk "Go to")) 

    ;; Buffer keymaps
    (rti/leader-keys
        :states '(normal visual)
        "b" '(:ignore t :wk "Buffer...") ;; Group description, :wk = "which key"
        "b b" '(switch-to-buffer :wk "Switch buffer")
        "b i" '(ibuffer :wk "Ibuffer")
        "b k" '(kill-this-buffer :wk "Kill this buffer")
        "b n" '(next-buffer :wk "Next buffer")
        "b p" '(previous-buffer :wk "Previous buffer")
        "b r" '(revert-buffer :wk "Reload buffer"))

    ;; Evaluation / hot reload keymaps
    (rti/leader-keys
        :states '(normal visual)
        "e" '(:ignore t :wk "Evaluate...")
        "e b" '(eval-buffer :wk "Evaluate elisp in buffer")
        "e d" '(eval-defun :wk "Evaluate defun containing or after point")
        "e e" '(eval-expression :wk "Evaluate elisp expression")
        "e l" '(eval-last-sexp :wk "Evaluate elisp expression before point")
        "e r" '(eval-region :wk "Evaluate elisp in region"))

    ;; Help keybindings
    (rti/leader-keys
        :states 'normal
        "h" '(:ignore t :wk "Help...")
        "h f" '(describe-function :wk "Describe function")
        "h v" '(describe-variable :wk "Describe variable")
        "h k" '(describe-key :wk "Describe key")
        "h r" '(:ignore t :wk "Reload...")
        "h r r" '(reload-init-file :wk "Reload emacs config"))

    ;; Toggle keybindings
    (rti/leader-keys
        :states 'normal
        "t" '(:ignore t :wk "Toggle...")
        "t l" '(display-line-numbers-mode :wk "Toggle line numbers")
        "t t" '(visual-line-mode :wk "Toggle line wrap"))

)

(set-face-attribute 'default nil
    :font "JetBrainsMono Nerd Font Mono"
    :height 160
    :weight 'semi-bold)
(set-face-attribute 'variable-pitch nil
    :font "Helvetica"
    :height 180
    :weight 'medium)
(set-face-attribute 'fixed-pitch nil
    :font "JetBrainsMono Nerd Font Mono"
    :height 160
    :weight 'semi-bold)
;; Makes commented text and keywords italics.
;; This is working in emacsclient but not emacs.
;; Your font must have an italic face available.
(set-face-attribute 'font-lock-comment-face nil
    :slant 'italic
    :weight 'semi-light)
(set-face-attribute 'font-lock-keyword-face nil
    :weight 'bold)

;; This sets the default font on all graphical frames created after restarting Emacs.
;; Does the same thing as 'set-face-attribute default' above, but emacsclient fonts
;; are not right unless I also add this method of setting the default font.
(add-to-list 'default-frame-alist '(font . "JetBrainsMono Nerd Font Mono-16"))

;; Uncomment the following line if line spacing needs adjusting.
(setq-default line-spacing 0.20)

(global-set-key (kbd "C-=") 'text-scale-increase)
(global-set-key (kbd "C--") 'text-scale-decrease)
(global-set-key (kbd "<C-wheel-up>") 'text-scale-increase)
(global-set-key (kbd "<C-wheel-down>") 'text-scale-decrease)

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'relative)
(global-hl-line-mode 1)
(setopt display-fill-column-indicator t)
(setopt display-fill-column-indicator-column 80)
(setopt display-fill-column-indicator-column 120)

(global-visual-line-mode t)

(use-package toc-org
    :commands toc-org-enable
    :ensure (:wait t) :demand t
    :init (add-hook 'org-mode-hook 'toc-org-enable))

(add-hook 'org-mode-hook 'org-indent-mode)
(use-package org-bullets :ensure (:wait t) :demand t)
(add-hook 'org-mode-hook (lambda () (org-bullets-mode 1)))

(electric-indent-mode -1)

(require 'org-tempo)

(defun reload-init-file ()
    (interactive)
    (load-file user-init-file))

(use-package which-key
    :init
        (which-key-mode 1)
    :ensure (:wait t) :demand t
    :config
    (setq which-key-side-window-location 'bottom
        which-key-sort-order #'which-key-key-order-alpha
        which-key-sort-uppercase-first nil
        which-key-add-column-padding 1
        which-key-max-display-columns nil
        which-key-min-display-lines 6
        which-key-side-window-slot -10
        which-key-side-window-max-height 0.25
        which-key-idle-delay 0.8
        which-key-max-description-length 25
        which-key-allow-imprecise-window-fit t
        which-key-separator " → " ))
