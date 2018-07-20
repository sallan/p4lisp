;;;; Let's work on some utilities to help us administer perforce
;;;;
;;;; This is work in progress so a lot of this will get tossed away.
;;;; ===============================================================

;;; TODO: Add a :service and :comment slots to the p4-server structure.
(defstruct p4-server host root brokers)

(defparameter *p4-servers* (make-array 22))
(setf (aref *p4-servers* 3)
      (make-p4-server :host "dvp4edgepl003"
		      :root "/data/perforce/dvp4edgepl003-edge"
		      :brokers '(1667)))

(setf (aref *p4-servers* 4)
      (make-p4-server :host "dvp4edgepl004"
		      :root "/data/perforce/dvp4edgepl004-edge"
		      :brokers '(1667)))

(setf (aref *p4-servers* 5)
      (make-p4-server :host "dvp4edgepl005"
		      :root "/data/perforce/dvp4edgepl005-edge"
		      :brokers '(1667)))

(setf (aref *p4-servers* 6)
      (make-p4-server :host "dvp4edgepl006"
		      :root "/data/perforce/dvp4edgepl006-ro-master"
		      :brokers '(1667)))

(setf (aref *p4-servers* 7)
      (make-p4-server :host "dvp4edgepl007"
		      :root "/data/perforce/dvp4edgepl007-fwd-master"
		      :brokers '(1667 1999)))

(setf (aref *p4-servers* 8)
      (make-p4-server :host "dvp4edgepl008"
		      :root "/data/perforce/dvp4edgepl008-fwd-master"
		      :brokers '(1667 1999)))

(setf (aref *p4-servers* 9)
      (make-p4-server :host "dvp4edgepl009"
		      :root "/data/perforce/master"
		      :brokers '(1666 1667)))

(setf (aref *p4-servers* 10)
      (make-p4-server :host "dvp4edgepl010"
		      :root "/data/perforce/dvp4edgepl010-ro-dvp4edgepl005-edge"
		      :brokers '(1667)))

(setf (aref *p4-servers* 12)
      (make-p4-server :host "dvp4edgepl012"
		      :root "/data/perforce/dvp4edgepl012-ro-dvp4edgepl003-edge"
		      :brokers '(1667)))

;; Offline replica
(setf (aref *p4-servers* 13)
      (make-p4-server :host "dvp4edgepl013"
		      :root "/data/perforce/offline"
		      :brokers '()))

(setf (aref *p4-servers* 21)
      (make-p4-server :host "dvp4edgepl021"
		      :root "/data/perforce/dvp4edgepl021-ro-dvp4edgepl004-edge"
		      :brokers '(1667)))

;; Sandbox servers for testing
(setf (aref *p4-servers* 16)
      (make-p4-server :host "dvp4edgepl016"
		      :root "/data/perforce/test-commit"
		      :brokers '()))

(setf (aref *p4-servers* 17)
      (make-p4-server :host "dvp4edgepl017"
		      :root "/data/perforce/test-edge"
		      :brokers '()))

;;; Proxies
;; Palo Alto proxy
(setf (aref *p4-servers* 14)
      (make-p4-server :host "dvp4edgepl014"
		      :root "/data/perforce/p4proxy-21667"
		      :brokers '(1667)))

;; London proxy
(setf (aref *p4-servers* 15)
      (make-p4-server :host "dvp4edgepl015"
		      :root "/data/perforce/p4proxy-21667"
		      :brokers '(1667)))

;; Edge proxies
(setf (aref *p4-servers* 18)
      (make-p4-server :host "dvp4edgepl018"
		      :root "/data/perforce/p4proxy-21667"
		      :brokers '(1667)))

(setf (aref *p4-servers* 19)
      (make-p4-server :host "dvp4edgepl019"
		      :root "/data/perforce/p4proxy-21667"
		      :brokers '(1667)))

(setf (aref *p4-servers* 20)
      (make-p4-server :host "dvp4edgepl020"
		      :root "/data/perforce/p4proxy-21667"
		      :brokers '(1667)))

;; Austin proxy
(setf (aref *p4-servers* 2)
      (make-p4-server :host "p4-aus-proxy-002"
		      :root "/data/perforce/p4proxy-21667"
		      :brokers '(1667)))

;; example usage
;;
;; (mapcar (lambda (x) (cons x (p4ssh x "ls /data/perforce/scripts"))) '(15 18 19 20))

;;; SSH commands
(defun ssh (host cmd)
  "Run CMD on HOST"

  ;; If HOST is not a string, try to pull the hostname from *p4-servers*
  (when (integerp host)
    (let ((p (aref *p4-servers* host)))
      (setf host (p4-server-host p))))
  
  (let ((string (with-output-to-string (str) 
		  (sb-ext:run-program "ssh" (list host cmd)
				      :search t
				      :wait t
				      :output str))))
    string))

(defun p4ssh (host cmd)
  "Run CMD on HOST as user perforce"
  (let ((newcmd (format nil "sudo -u perforce ~a" cmd)))
    (ssh host newcmd)))

;;; Cron functions
(defun cat-cron (n)
  "Cat the perforc-scripts file on server N"
  (let* ((p (aref *p4-servers* n))
	 (host (p4-server-host p)))
    (ssh host "sudo cat /etc/cron.d/perforce-scripts")))

;; NOTE: Using the -v option to mv causes an exception. The file gets
;; moved, but the sb-ext has difficulting with the output of the -v
;; option.
(defun cron-off (n)
  "Move perforce-scripts to a safe place on server N"
  (let* ((p (aref *p4-servers* n))
	 (host (p4-server-host p)))
    (ssh host "sudo mv /etc/cron.d/perforce-scripts /data/cronjobs/perforce-scripts")))
  
(defun cron-on (n)
  "Move perforce-scripts to a safe place on server N"
  (let* ((p (aref *p4-servers* n))
	 (host (p4-server-host p)))
    (ssh host "sudo mv  /data/cronjobs/perforce-scripts /etc/cron.d/perforce-scripts")))

;;; Set Broker
(defun set-broker (n mode)
  "Set broker on N to mode MODE

Acceptable values for MODE are maintenance or production"
  (let* ((p (aref *p4-servers* n))
	 (host (p4-server-host p))
	 (brokers (p4-server-brokers p)))
    (flet ((set-b (host script mode)
	     (p4ssh host (format nil "/data/perforce/scripts/~a ~a" script mode))))
      (if (<= (length brokers) 1)
	  (set-b host "set-broker.sh" mode)
	  (mapcar (lambda (b)
		    (set-b host (format nil "set-broker-~a.sh" b) mode))
		  brokers)))))

(defun maint-mode (n)
  "Put server N in maintenance mode.

If the server has multiple ports, it will attempt to put all of them
in mainteance mode."
  (set-broker n "maintenance"))

(defun prod-mode (n)
  "Put server N in production mode.

If the server has multiple ports, it will attempt to put all of them
in production mode."
  (set-broker n "production"))

(defun ls-server-home (n &optional (subdir ""))
  "Run ls in the server top-level directory for server N.

This script knows the name of the top-level directory for each server
and runs ls relative to that directory. With the optional relative
path string, it will run ls in that directory. This path must be under
the server home."

  (let* ((p (aref *p4-servers* n))
	 (host (p4-server-host p))
	 (root (p4-server-root p)))
    (p4ssh host (format nil "ls ~a/~a" root subdir))))
    
    
;;; A general p4 query command might be useful. We can't allow any
;;; interactive commands.
(defun p4q (host port client cmd)
  "Run CMD on host:port if CMD is 'legal'"
  ;; TODO: Learn how to use keyword arguments and defaults.
  (princ "To be written"))
