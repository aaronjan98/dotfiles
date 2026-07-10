;;; init.el -*- lexical-binding: t; -*-

;; This is the Doom module list. Each line enables a feature.
;; Run `doom sync` after changing this file.
;; Run `doom doctor` to diagnose problems.

(doom! :completion
       vertico               ; fuzzy-find everything (M-x, file find, SPC commands)

       :ui
       doom                  ; Doom visual defaults (theme, fonts)
       dashboard             ; splash screen with useful shortcuts

       :editor
       (evil +everywhere)    ; vim keybindings in ALL buffers, including org-agenda

       :emacs
       undo                  ; persistent undo history across sessions

       :lang
       (org +pretty)         ; org-mode with nicer heading bullets and visuals

       :config
       (default +bindings +smartparens))  ; REQUIRED — Doom's SPC leader and base keybindings
