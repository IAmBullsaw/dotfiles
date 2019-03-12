(setq gc-cons-threshold (* 20 1024 1024))

;;
;; Packages
;;

;; Special settings for work (not pushed)
(add-to-list 'load-path "~/.emacs.d/work/")
(require 'work)
(require 'babelreader)
(add-to-list 'auto-mode-alist '("\\.decoded\\'" . babelreader-mode))
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; very good parenthesis handling
;;(use-package smartparens-config
;;  :ensure t
;;  :init
;;  (add-hook 'prog-mode-hook #'smartparens-mode))

;; Coloring parenthesises for easier spotting of things
(use-package rainbow-delimiters
  :ensure t
  :init
  (add-hook 'prog-mode-hook #'rainbow-delimiters-mode))

;; Spel checking
(use-package flycheck
  :ensure t
  :config
  (global-flycheck-mode 1))

;; To be able to comment and uncomment code
(use-package evil-commentary
  :ensure t
  :config
  (evil-commentary-mode 1))

(use-package evil-surround
  :ensure t
  :config
  (global-evil-surround-mode 1))

;; Useful for git projects
(use-package projectile
  :ensure t
  :config
  (projectile-global-mode))

(use-package ivy
  :ensure t
  :ensure smex
  :config
  (setq projectile-completion-system 'ivy
	ivy-height 15
	ivy-count-format "(%d/%d) "
	ivy-display-style 'fancy)
  (ivy-mode 1))

(use-package company
  :ensure t
  :config
  (add-hook 'prog-mode-hook 'company-mode)
  (setq company-idle-delay 0
	company-minimum-prefix-length 2
	company-tooltip-align-annotations t
	company-require-match nil))

(use-package magit
  :ensure t)

(use-package evil
  :ensure t
  :config
  (evil-mode 1)
 (setq evil-emacs-state-cursor '("red" box))
  (setq evil-normal-state-cursor '("green" box))
  (setq evil-visual-state-cursor '("orange" box))
  (setq evil-insert-state-cursor '("red" bar))
  (setq evil-replace-state-cursor '("red" (hbar . 8)))
  (setq evil-operator-state-cursor '("green" (hbar . 8))) )

;; For python, not up to date
;; (use-package company-jedi
;;   :ensure t
;;   :bind (:map python-mode-map
;; 	      ("M-." . jedi:goto-definition)
;; 	      ("M-," . jedi:goto-definition-pop-marker))
;;   :init
;;   (add-hook 'python-mode-hook (lambda () (add-to-list 'company-backends 'company-jedi))))


;;
;; Themeing
;;

(load-theme 'misterioso)

;; Stretch cursos over full char width, good for ex. tabs
(setq x-stretch-cursor 1)

;; Better line highlight color matching Misterioso theme
;; (set-face-attribute 'highlight nil :inherit nil :background "#40b5a9")
;; (set-face-attribute 'lazy-highlight nil :inherit nil :background "#40b5a9")
(global-hl-line-mode)
(set-face-attribute 'cursor nil :inherit nil :background "#e5e5e5")
(set-face-attribute 'hl-line nil :inherit nil :background "#415062")

;; Show me all that unwanted whitespace!
(setq-default show-trailing-whitespace t)


;; This causes the current time in the mode line to be displayed in
;; `xtremely-red-display-time-face' to make it stand out visually.
;; tick tock goes the clock
(defface xtremely-red-display-time
  '((((type x w32 mac))
     ;; #060525 is the background colour of my default face.
     (:foreground "red" :inherit bold))
    (((type tty))
     (:foreground "black")))
  "Face used to display the time in the mode line.")

(setq display-time-string-forms
      '((propertize (concat " " 24-hours ":" minutes " ")
 		    'face 'xtremely-red-display-time)))
(display-time)

;; Color the line numbers
(set-face-attribute 'line-number nil
		    :foreground "#dd1818")
(set-face-attribute 'line-number-current-line nil
                    :foreground "#dd1818")


;;
;; Backups - I like my backups hidden and in abundance, to quote Jonas.
;;

(unless (file-exists-p "~/.emacs.d/backups")
  (mkdir "~/.emacs.d/backups/per-save" t)
  (mkdir "~/.emacs.d/backups/per-session" t))

 (setq backup-directory-alist '(("" . "~/.emacs.d/backups/per-save"))
       backup-by-copying t
       delete-old-versions t
       kept-new-versions 10
       kept-old-versions 0
       auto-save-default nil
       vc-make-backup-files t
       version-control t)

(defun force-backup-of-buffer ()
  "Always save file backups on save."
  (unless buffer-backed-up
    (let ((backup-directory-alist '(("" . "~/.emacs.d/backups/per-session"))))
      (backup-buffer)))
  (let ((buffer-backed-up nil))
    (backup-buffer)))
(add-hook 'before-save-hook  'force-backup-of-buffer)


;;
;; Key bindings
;;

;; mapping ctrl ö and ä to {}
(define-key key-translation-map (kbd "C-ö") (kbd "{"))
(define-key key-translation-map (kbd "C-ä") (kbd "}"))

(global-set-key (kbd "C-x k") #'kill-this-buffer)

;; mapping to magit
(global-set-key (kbd "C-x g") 'magit-status )

;; mapping for projectile
(global-set-key (kbd "C-x p") 'projectile-find-file)
(global-set-key (kbd "C-c p") 'projectile-find-file-in-known-projects)

;;
;; Settings
;;

;; Remove the horrible tool bar buttons up top
(tool-bar-mode -1)

(scroll-bar-mode -1)

;; Be gone with the pesky startup screen
(setq inhibit-startup-message -1)
(setq inhibit-startup-screen -1)
(display-splash-screen -1)

;; When opening a file, this returns you to were you were
(save-place-mode 1)

;; Prefer UTF-8
(prefer-coding-system 'utf-8)
(set-buffer-file-coding-system 'utf-8)

;; Set all 'yes or no' prompts to 'y or n'
(fset 'yes-or-no-p 'y-or-n-p)

;; Set hybrid mode for line numbers
(global-display-line-numbers-mode)
(setq display-line-numbers-current-absolute 1)
(setq display-line-numbers 'relative)

;;
;; Emacs' Custom package 
;;

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (rainbow-delimiters evil-surround evil-commentary flycheck use-package smex projectile magit ivy evil))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
