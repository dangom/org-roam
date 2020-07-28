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

(defcustom org-roam-dailies-capture-templates
  '(("d" "daily" entry (function org-roam-capture--get-point)
     "* %?"
     :file-name "%<%Y-%m-%d>"
     :head "#+title: %<%Y-%m-%d>"))
  "Capture templates for daily notes in Org-roam."
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
  (let ((org-roam-capture-templates org-roam-dailies-capture-templates)
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
(defun org-roam-dailies-capture-date (&optional goto)
  "Create an entry in the daily note for a date using the calendar.

With a `C-u' prefix or when GOTO is non-nil, go the note without
creating an entry."
  (interactive "P")
  (let ((time (org-read-date nil 'to-time nil "Date:  ")))
    (org-roam-dailies--capture time goto)))

(defun org-roam-dailies-find-date ()
  "Find the daily note for a date using the calendar, creating it if necessary."
  (interactive)
  (org-roam-dailies-capture-date t))

(provide 'org-roam-dailies)

;;; org-roam-dailies.el ends here
