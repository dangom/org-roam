;;; org-roam-dailies.el --- Daily notes for Org-roam -*- coding: utf-8; lexical-binding: t; -*-
;;;
;; Copyright © 2020 Jethro Kuan <jethrokuan95@gmail.com>
;; Copyright © 2020 Leo Vivier <leo.vivier+dev@gmail.com>

;; Author: Jethro Kuan <jethrokuan95@gmail.com>
;; 	Leo Vivier <leo.vivier+dev@gmail.com>
;; URL: https://github.com/org-roam/org-roam
;; Keywords: org-mode, roam, convenience
;; Version: 1.2.1
;; Package-Requires: ((emacs "26.1") (dash "2.13") (f "0.17.2") (s "1.12.0") (org "9.3") (emacsql "3.0.0") (emacsql-sqlite3 "1.0.0"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; This library provides functionality for creating daily notes. This is a
;; concept borrowed from Roam Research.
;;
;;; Code:
;;; Library Requires
(require 'org-capture)
(require 'org-roam-capture)
(require 'org-roam-macs)

(defcustom org-roam-dailies-capture--header-default "#+title: %<%Y-%m-%d>\n"
  "Default header to use with `org-roam-dailies-capture-templates'."
  :group 'org-roam
  :type 'string)

(defcustom org-roam-dailies-capture-templates
  '(("d" "daily" entry #'org-roam-capture--get-point
     "* %?"
     :file-name "%<%Y-%m-%d>"))
  "Capture templates for daily-notes in Org-roam."
  :group 'org-roam
  ;; Adapted from `org-capture-templates'
  :type
  '(repeat
    (choice :value ("d" "daily" plain (function org-roam-capture--get-point)
                    ""
                    :immediate-finish t
                    :file-name "%<%Y-%m-%d>"
                    :head "#+title: %<%Y-%m-%d>")
            (list :tag "Multikey description"
                  (string :tag "Keys       ")
                  (string :tag "Description"))
            (list :tag "Template entry"
                  (string :tag "Keys              ")
                  (string :tag "Description       ")
                  (const :format "" plain)
                  (const :format "" (function org-roam-capture--get-point))
                  (choice :tag "Template          "
                          (string :tag "String"
                                  :format "String:\n            \
Template string   :\n%v")
                          (list :tag "File"
                                (const :format "" file)
                                (file :tag "Template file     "))
                          (list :tag "Function"
                                (const :format "" function)
                                (function :tag "Template function ")))
                  (const :format "" :immediate-finish) (const :format "" t)
                  (const :format "File name format  :" :file-name)
                  (string :format " %v" :value "#+title: ${title}\n")
                  (const :format "Header format     :" :head)
                  (string :format "\n%v" :value "%<%Y%m%d%H%M%S>-${slug}")
                  (plist :inline t
                         :tag "Options"
                         ;; Give the most common options as checkboxes
                         :options
                         (((const :format "%v " :prepend) (const t))
                          ((const :format "%v " :jump-to-captured) (const t))
                          ((const :format "%v " :empty-lines) (const 1))
                          ((const :format "%v " :empty-lines-before) (const 1))
                          ((const :format "%v " :empty-lines-after) (const 1))
                          ((const :format "%v " :clock-in) (const t))
                          ((const :format "%v " :clock-keep) (const t))
                          ((const :format "%v " :clock-resume) (const t))
                          ((const :format "%v " :time-prompt) (const t))
                          ((const :format "%v " :tree-type) (const week))
                          ((const :format "%v " :table-line-pos) (string))
                          ((const :format "%v " :kill-buffer) (const t))
                          ((const :format "%v " :unnarrowed) (const t))))))))

;; Declarations
(defvar org-roam-mode)
(declare-function org-roam--file-path-from-id "org-roam")
(declare-function org-roam-mode               "org-roam")

(defun org-roam-dailies--capture (time &optional goto)
  "Capture an entry in a daily note for TIME, creating it if necessary.

When GOTO is non-nil, go the note without creating an entry."
  (unless org-roam-mode (org-roam-mode))
  (let ((org-roam-capture-templates (--> org-roam-dailies-capture-templates
                                         (if goto (list (car it)) it)))
        (org-roam-capture--info (list (cons 'time time)))
        (org-roam-capture--context 'dailies))
    (org-roam--with-template-error 'org-roam-dailies-capture-templates
      (org-roam-capture--capture (when goto '(4))))))

;;----------------------------------------------------------------------------
;; Today
;;----------------------------------------------------------------------------
(defun org-roam-dailies-capture-today (&optional goto)
  "Create an entry in the daily note for today.

When GOTO is non-nil, go the note without creating an entry."
  (interactive "P")
  (org-roam-dailies--capture (current-time) goto))

(defun org-roam-dailies-find-today ()
  "Find the daily note for today, creating it if necessary."
  (interactive)
  (org-roam-dailies-capture-today t))

;;----------------------------------------------------------------------------
;; Tomorrow
;;----------------------------------------------------------------------------
(defun org-roam-dailies-capture-tomorrow (n &optional goto)
  "Create an entry in the daily note for tomorrow.

With numeric argument N, use N days in the future.

With a `C-u' prefix or when GOTO is non-nil, go the note without
creating an entry."
  (interactive "p")
  (org-roam-dailies--capture (time-add (* n 86400) (current-time)) goto))

(defun org-roam-dailies-find-tomorrow (n)
  "Find the daily note for tomorrow, creating it if necessary.

With numeric argument N, use N days in the future."
  (interactive "p")
  (org-roam-dailies-capture-tomorrow n t))

;;----------------------------------------------------------------------------
;; Yesterday
;;----------------------------------------------------------------------------
(defun org-roam-dailies-capture-yesterday (n &optional goto)
  "Create an entry in the daily note for yesteday.

With numeric argument N, use N days in the past.

When GOTO is non-nil, go the note without creating an entry."
  (interactive "p")
  (org-roam-dailies-capture-tomorrow (- n) goto))

(defun org-roam-dailies-find-yesterday (n)
  "Find the daily note for yesterday, creating it if necessary.

With numeric argument N, use N days in the future."
  (interactive "p")
  (org-roam-dailies-capture-tomorrow (- n) t))

;;----------------------------------------------------------------------------
;; Date
;;----------------------------------------------------------------------------
(defun org-roam-dailies-capture-date (&optional goto prefer-future)
  "Create an entry in the daily note for a date using the calendar.

Prefer past dates, unless PREFER-FUTURE is non-nil.

With a `C-u' prefix or when GOTO is non-nil, go the note without
creating an entry."
  (interactive "P")
  (let ((time (let ((org-read-date-prefer-future prefer-future))
                (org-read-date nil t nil "Date: "))))
    (org-roam-dailies--capture time goto)))

(defun org-roam-dailies-find-date ()
  "Find the daily note for a date using the calendar, creating it if necessary."
  (interactive)
  (org-roam-dailies-capture-date t))

;;----------------------------------------------------------------------------
;; Navigation
;;----------------------------------------------------------------------------
(defun org-roam-dailies--file-to-date (&optional file)
  "Get date from FILE or current buffer.

Return a cons of the format (file . time) where 'time is encoded.
See `encode-time' for details."
  (let ((file (or file
                  (-> (buffer-base-buffer)
                      (buffer-file-name)))))
    (list file
          (-> file
              (file-name-nondirectory)
              (file-name-sans-extension)
              (org-parse-time-string)
              (encode-time)))))

(defun org-roam-dailies--list-files (&optional file-or-dir)
  "List all files in FILE-OR-DIR.

FILE-OR-DIR can either be the path to a file or a directory.
Otherwise, use the file visited by the current buffer."
  (let ((dir (-> (or file-or-dir
                     (-> (buffer-base-buffer)
                         (buffer-file-name)))
                 (file-name-directory)
                 (expand-file-name)
                 (file-truename))))
    (directory-files-recursively dir "\.*")))

(defun org-roam-dailies--sort-files-by-date (&optional file-or-dir)
  "Sort files in FILE-OR-DIR by date.

FILE-OR-DIR can either be the path to a file or a directory.
Otherwise, use the file visited by the current buffer."
  (let ((files (org-roam-dailies--list-files file-or-dir)))
    (->> (mapcar #'org-roam-dailies--file-to-date files)
         (seq-sort-by #'cadr
                      #'time-less-p)
         (mapcar #'car))))

(defun org-roam-dailies--find-next-note-path (&optional n file)
  "Find next daily note from FILE.

With numeric argument N, find note N days in the future. If N is
negative, find note N days in the past.

If FILE is not provided, use the file visited by the current
buffer."
  (let* ((file (or file
                   (-> (buffer-base-buffer)
                       (buffer-file-name))))
         (list (org-roam-dailies--sort-files-by-date file))
         (position
          (cl-position-if (lambda (candidate)
                            (string= file candidate))
                          list)))
    (pcase n
      ((pred (natnump))
       (when (eq position (- (length list) 1))
         (user-error "Already at newest note")))
      ((pred (integerp))
       (when (eq position 0)
         (user-error "Already at oldest note"))))
    (nth (+ position n) list)))

(defun org-roam-dailies-find-next-note (&optional n)
  "Find next daily note.

With numeric argument N, find note N days in the future. If N is
negative, find note N days in the past."
  (interactive "p")
  (let ((n (or n 1)))
    (find-file (org-roam-dailies--find-next-note-path n))))

(defun org-roam-dailies-find-previous-note (&optional n)
  "Find previous daily note.

With numeric argument N, find note N days in the past. If N is
negative, find note N days in the future."
  (interactive "p")
  (let ((n (if n (- n) -1)))
    (org-roam-dailies-find-next-note n)))

;;----------------------------------------------------------------------------
;; Keybindings
;;----------------------------------------------------------------------------
(defvar org-roam-dailies-keymap (make-sparse-keymap)
  "Keymap for `org-roam-dailies'.")

(define-prefix-command 'org-roam-dailies-keymap)

(define-key org-roam-dailies-keymap (kbd "d") #'org-roam-dailies-find-today)
(define-key org-roam-dailies-keymap (kbd "y") #'org-roam-dailies-find-yesterday)
(define-key org-roam-dailies-keymap (kbd "t") #'org-roam-dailies-find-tomorrow)
(define-key org-roam-dailies-keymap (kbd "n") #'org-roam-dailies-capture-today)
(define-key org-roam-dailies-keymap (kbd "r") #'org-roam-dailies-find-next-note)
(define-key org-roam-dailies-keymap (kbd "l") #'org-roam-dailies-find-previous-note)
(define-key org-roam-dailies-keymap (kbd "c") #'org-roam-dailies-find-date)

(provide 'org-roam-dailies)

;;; org-roam-dailies.el ends here
