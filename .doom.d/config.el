;;; config.el -*- lexical-binding: t; -*-

;;; Frame — match Ghostty's background color (#1a0810) and opacity (0.75)
(add-to-list 'default-frame-alist '(alpha-background . 75))

;; Solaire-mode remaps many faces through solaire-* variants and runs at hook depth 100.
;; Hook in at depth 110 so we always win, regardless of which buffer type we're in.
(add-hook 'doom-load-theme-hook
  (lambda ()
    (set-face-attribute 'default nil :height 130)
    (dolist (face '(default fringe
                    line-number line-number-current-line
                    mode-line mode-line-inactive mode-line-active header-line
                    solaire-default-face solaire-fringe-face
                    solaire-line-number-face
                    solaire-mode-line-face solaire-mode-line-inactive-face
                    solaire-mode-line-active-face solaire-header-line-face))
      (when (facep face)
        (set-face-attribute face nil :background "#1a0810"))))
  110)

;;; Cursor — red in all Evil states, blinking
(setq evil-normal-state-cursor '(box "red")
      evil-insert-state-cursor '(bar "red")
      evil-visual-state-cursor '(hollow "red")
      evil-emacs-state-cursor  '(box "red"))
(blink-cursor-mode 1)

;;; Org
(setq org-directory "~/org/"
      org-agenda-files '("~/org/tasks.org" "~/org/inbox.org"))
