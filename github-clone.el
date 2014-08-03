;;; github-clone.el --- Fork and clone github repos  -*- lexical-binding: t; -*-

;; Copyright (C) 2014  Charles Comstock

;; Author: Charles Comstock <clgc@nocturnal>
;; Created: 2 Aug 2014
;; Version: 0.1
;; Keywords: vc, tools
;; Package-Requires: ((magit "1.2.0") (gh.el "20140706"))

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

;; 

;;; Code:

(require 'eieio)

(require 'gh)
(require 'gh-repos)
(require 'subr-x)

(defun github-clone-fork (user repo-id)
  (let* ((api (gh-repos-api "api"))
         (repo (github-clone-info user repo-id)))
    (oref (gh-repos-fork api repo) :data)))

(defun github-clone-info (user repo-id)
  (thread-first (gh-repos-api "api")
    (gh-repos-repo-get repo-id user)
    (oref :data)))

(defun github-clone-remotes (user repo-id)
  (let* ((repo (github-clone-info user repo-id))
         (forks (oref (gh-repos-forks-list (gh-repos-api "api") repo) :data)))
    (cl-loop for fork in forks
             collect (cons (oref (oref fork :owner) :login)
                           (oref fork :git-url)))))

(defun github-clone-upstream (repo)
  (if (eq (oref repo :fork) t)
      (cons "upstream" (oref (oref repo :parent) :git-url))
    nil))

(defun github-clone-repo (repo directory)
  (let* ((name (oref repo :name))
        (target (expand-file-name name directory))
        (repo-url (oref repo :git-url)))
    (message "Cloning %s into %s" name target)
    (shell-command (format "git clone %s %s" repo-url target))
    (magit-status target)
    (if-let (upstream (github-clone-upstream repo))
        (progn
          (message "Adding remote %s" upstream)
          (magit-add-remote (car upstream) (cdr upstream))))))


(provide 'github-clone)
;;; github-clone.el ends here