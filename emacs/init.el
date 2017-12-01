(setq gc-cons-threshold (* 20 1024 1024)) 

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(load-theme 'misterioso)
(tool-bar-mode -1)
(setq inhibit-startup-message -1)
(setq inhibit-startup-screen -1)
(display-splash-screen -1)
(save-place-mode 1)
(global-linum-mode 1)

(prefer-coding-system 'utf-8)
(set-buffer-file-coding-system 'utf-8)
(fset 'yes-or-no-p 'y-or-n-p)
(global-set-key (kbd "C-x k") #'kill-this-buffer)


;; tick tock goes the clock
(defface bullsaw-display-time
  '((((type x w32 mac))
     ;; #060525 is the background colour of my default face.
     (:foreground "red" :inherit bold))
    (((type tty))
     (:foreground "black")))
  "Face used to display the time in the mode line.")

;; This causes the current time in the mode line to be displayed in
;; `bullsaw-display-time-face' to make it stand out visually.
(setq display-time-string-forms
      '((propertize (concat " " 24-hours ":" minutes " ")
 		    'face 'bullsaw-display-time)))
(display-time)

;; I like my backups hidden and in abundance
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


(use-package company-jedi
  :ensure t
  :bind (:map python-mode-map
	      ("M-." . jedi:goto-definition)
	      ("M-," . jedi:goto-definition-pop-marker))
  :init
  (add-hook 'python-mode-hook (lambda () (add-to-list 'company-backends 'company-jedi))))

(use-package magit
  :ensure t)

(require 'js-comint)
(setq inferior-js-program-command "node")
(add-hook 'js2-mode-hook '(lambda () 
			    (local-set-key "\C-x\C-e" 'js-send-last-sexp)
			    (local-set-key "\C-\M-x" 'js-send-last-sexp-and-go)
			    (local-set-key "\C-cb" 'js-send-buffer)
			    (local-set-key "\C-c\C-b" 'js-send-buffer-and-go)
			    (local-set-key "\C-cl" 'js-load-file-and-go)
			    ))


;; mapping ctrl ö and ä to {}
(define-key key-translation-map (kbd "C-ö") (kbd "{"))
(define-key key-translation-map (kbd "C-ä") (kbd "}"))
;; mapping to magit
(global-set-key (kbd "C-x g") 'magit-status )

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (js2-mode use-package smex projectile magit js-comint ivy company-jedi))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
