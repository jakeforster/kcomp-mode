;;; kcomp-mode.el --- Kill compilation buffer on success -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Jake Forster

;; Author: Jake Forster <jakecameron.forster@gmail.com>
;; Version: 1.0.0
;; Package-Requires: ((emacs "24.3"))
;; Keywords: convenience
;; URL: https://github.com/jakeforster/kcomp-mode

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; KComp mode is a minor mode.
;; If KComp mode is enabled in the buffer (`kcomp-mode')
;; or globally (`global-kcomp-mode')
;; when `compile' is invoked, the resulting compilation
;; buffer will be killed upon successful compilation.

;;; Code:

(require 'cl-lib)

(defgroup kcomp-mode nil
  "Kill compilation buffer on success."
  :prefix "kcomp-"
  :group 'convenience)

;;;###autoload
(define-minor-mode kcomp-mode
  "Toggle KComp mode.

If KComp mode is enabled in the buffer when `compile' is invoked,
the resulting compilation buffer will be killed upon successful
compilation."
  :lighter " KComp"
  :global nil)

;;;###autoload
(define-globalized-minor-mode global-kcomp-mode kcomp-mode kcomp-mode-on)

(defun kcomp-mode-on ()
  (kcomp-mode 1))

(defvar kcomp-mode--was-enabled nil
  "Whether KComp mode was enabled when `compile' was last invoked.")

(defvar kcomp-mode--buffers nil
  "A list of compilation buffers to be killed upon successful completion.")

(defun kcomp-mode--update (&rest _args)
  (setq kcomp-mode--was-enabled (bound-and-true-p kcomp-mode))

  ;; Remove any compilation buffers that were killed before their
  ;; compilation finished.
  (when kcomp-mode--buffers
    (setq kcomp-mode--buffers (cl-remove-if-not #'buffer-live-p kcomp-mode--buffers))))

(advice-add 'compile :before #'kcomp-mode--update)

(defun kcomp-mode--start (_process)
  (when kcomp-mode--was-enabled
    (setq kcomp-mode--buffers (cons (current-buffer) kcomp-mode--buffers))))

(add-hook 'compilation-start-hook #'kcomp-mode--start)

(defun kcomp-mode--finish (buffer msg)
  (when (member buffer kcomp-mode--buffers)
    (setq kcomp-mode--buffers (remove buffer kcomp-mode--buffers))
    (when (string-match "^finished" msg)
      (kill-buffer buffer))))

(add-to-list 'compilation-finish-functions #'kcomp-mode--finish)

(provide 'kcomp-mode)
;;; kcomp-mode.el ends here
