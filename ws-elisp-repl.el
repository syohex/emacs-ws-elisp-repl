;;; ws-elisp-repl.el --- Emacs Lisp REPL in browser

;; Copyright (C) 2012 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL:
;; Version: 0.01

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(eval-when-compile
  (require 'cl))

(require 'websocket)

(defgroup ws-elisp-repl nil
  "Browser Emacs Lisp REPL"
  :prefix "ws-elisp-repl:")

(defcustom ws-elisp-repl:port 5000
  "Port number for Web Application"
  :type 'integer
  :group 'ws-elisp-repl)

(defun ws-elisp-repl:on-message (websocket frame)
  (let* ((input (websocket-frame-payload frame))
         (retval (or (ignore-errors
                       (ws-elisp-repl:eval
                        (decode-coding-string input 'utf-8)))
                     (format "Can't parse %s" input))))
    (websocket-send-text websocket (format "%s" retval))))

(defun ws-elisp-repl:create-websocket (url)
  (websocket-open
   url
   :on-message 'ws-elisp-repl:on-message
   :on-error (lambda (ws type err)
               (message "error connecting %s" err))
   :on-close (lambda (websocket)
               (setq wstest-closed t))))

(defun ws-elisp-repl:init-websocket (port)
  (let ((url (format "ws://0.0.0.0:%d/emacs" port)))
    (message "Connect to %s" url)
    (setq rtmv:websocket (ws-elisp-repl:create-websocket url))))

(defun ws-elisp-repl:eval (str)
  (eval (read str)))

(defun ws-elisp-repl:connect ()
  (interactive)
  (ws-elisp-repl:init-websocket ws-elisp-repl:port))

(provide 'ws-elisp-repl)

;;; elisp-repl.el ends here
