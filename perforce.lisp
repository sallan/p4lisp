;;;; Let's work on some utilities to help us administer perforce
;;;;
;;;; This is work in progress so a lot of this will get tossed away.
;;;; ===============================================================
(defstruct p4-server host root service comment brokers)
(defparameter *p4-servers* (make-array 22))

(setf (aref *p4-servers* 3)
      (make-p4-server :host "dvp4edgepl003"
		      :root "/data/perforce/dvp4edgepl003-edge"
		      :service 'edge-server
		      :comment "Teamcity builds using shared directory"
		      :brokers '(1667)))

(setf (aref *p4-servers* 4)
      (make-p4-server :host "dvp4edgepl004"
		      :root "/data/perforce/dvp4edgepl004-edge"
		      :service 'edge-server
		      :comment "Supposed to be for Perf"
		      :brokers '(1667)))

(setf (aref *p4-servers* 5)
      (make-p4-server :host "dvp4edgepl005"
		      :root "/data/perforce/dvp4edgepl005-edge"
		      :service 'edge-server
		      :comment "Teamcity Gauntlet configs and AWS Temcity build"
		      :brokers '(1667)))

(setf (aref *p4-servers* 6)
      (make-p4-server :host "dvp4edgepl006"
		      :root "/data/perforce/dvp4edgepl006-ro-master"
		      :service 'replica
		      :comment "RO Replica for the Commit server"
		      :brokers '(1667)))

(setf (aref *p4-servers* 7)
      (make-p4-server :host "dvp4edgepl007"
		      :root "/data/perforce/dvp4edgepl007-fwd-master"
		      :service 'forwarding-replica
		      :comment "Forwarding Replica for the Commit server"
		      :brokers '(1667 1999)))

(setf (aref *p4-servers* 8)
      (make-p4-server :host "dvp4edgepl008"
		      :root "/data/perforce/dvp4edgepl008-fwd-master"
		      :service 'forwarding-replica
		      :comment "Forwarding Replica for the Commit server"
		      :brokers '(1667 1999)))

(setf (aref *p4-servers* 9)
      (make-p4-server :host "dvp4edgepl009"
		      :root "/data/perforce/master"
		      :service 'commit-server
		      :comment "The Commit server"
		      :brokers '(1666 1667)))

(setf (aref *p4-servers* 10)
      (make-p4-server :host "dvp4edgepl010"
		      :root "/data/perforce/dvp4edgepl010-ro-dvp4edgepl005-edge"
		      :service 'replica
		      :comment "RO Replica for the 005 Edge server"
		      :brokers '(1667)))

(setf (aref *p4-servers* 12)
      (make-p4-server :host "dvp4edgepl012"
		      :root "/data/perforce/dvp4edgepl012-ro-dvp4edgepl003-edge"
		      :service 'replica
		      :comment "RO Replica for the 003 Edge server"
		      :brokers '(1667)))

(setf (aref *p4-servers* 21)
      (make-p4-server :host "dvp4edgepl021"
		      :root "/data/perforce/dvp4edgepl021-ro-dvp4edgepl004-edge"
		      :service 'replica
		      :comment "RO Replica for the 004 Edge server"
		      :brokers '(1667)))

;; Offline replica
(setf (aref *p4-servers* 13)
      (make-p4-server :host "dvp4edgepl013"
		      :root "/data/perforce/offline"
		      :service nil
		      :comment "Offline DR server for the Commit server."
		      :brokers '()))


;; Sandbox servers for testing
(setf (aref *p4-servers* 16)
      (make-p4-server :host "dvp4edgepl016"
		      :root "/data/perforce/test-commit"
		      :service 'commit-server
		      :comment "Test Commit server"
		      :brokers '(1667)))

(setf (aref *p4-servers* 17)
      (make-p4-server :host "dvp4edgepl017"
		      :root "/data/perforce/test-edge"
		      :service 'edge-server
		      :comment "Test Edge server for the 017 test server"
		      :brokers '(1667)))

;;; Proxies
;; Palo Alto proxy
(setf (aref *p4-servers* 14)
      (make-p4-server :host "dvp4edgepl014"
		      :root "/data/perforce/p4proxy-21667"
		      :service 'proxy
		      :comment "Palo Alto Proxy - points to Commit server"
		      :brokers '(1667)))

;; London proxy
(setf (aref *p4-servers* 15)
      (make-p4-server :host "dvp4edgepl015"
		      :root "/data/perforce/p4proxy-21667"
		      :service 'proxy
		      :comment "London Proxy - points to the 004 Edge Server"
		      :brokers '(1667)))

;; Edge proxies
(setf (aref *p4-servers* 18)
      (make-p4-server :host "dvp4edgepl018"
		      :root "/data/perforce/p4proxy-21667"
		      :comment "Proxy to the 003 Edge server"
		      :brokers '(1667)))

(setf (aref *p4-servers* 19)
      (make-p4-server :host "dvp4edgepl019"
		      :root "/data/perforce/p4proxy-21667"
		      :service 'proxy
		      :comment "Proxy to the 004 Edge server"
		      :brokers '(1667)))

(setf (aref *p4-servers* 20)
      (make-p4-server :host "dvp4edgepl020"
		      :root "/data/perforce/p4proxy-21667"
		      :service 'proxy
		      :comment "Proxy to the 005 Edge server"
		      :brokers '(1667)))

;; Austin proxy
(setf (aref *p4-servers* 2)
      (make-p4-server :host "p4-aus-proxy-002"
		      :service 'proxy
		      :root "/data/perforce/p4proxy-21667"
		      :service 'proxy
		      :comment "Austin Proxy - points to the 004 Edge server"
		      :brokers '(1667)))

;; example usage
;;
;; (mapcar (lambda (x) (cons x (p4ssh x "ls /data/perforce/scripts"))) '(15 18 19 20))
;; (remove-if #'numberp *p4-servers*)

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

(defun scp (file host dest)
  "Copy FILE to DEST on HOST"
  ;; If HOST is not a string, try to pull the hostname from *p4-servers*
  (when (integerp host)
    (let ((p (aref *p4-servers* host)))
      (setf host (p4-server-host p))))

  ;; On Windows, scp with a full path causes problems - can't
  ;; correctly parse the drive letter. So we'll cd into the directory.
  (let* ((filename (file-namestring file))
	 (directory (directory-namestring file))
	 (string (with-output-to-string (str) 
		  (sb-ext:run-program "scp" (list filename (format nil "~a:~a" host dest))
				      :search t
				      :wait t
				      :directory directory
				      :output str))))
    string))

(defun p4ssh (host cmd)
  "Run CMD on HOST as user perforce"
  (let ((newcmd (format nil "sudo -u perforce ~a" cmd)))
    (ssh host newcmd)))

(defun p4scp (file host dest &optional mode force)
  "Copy FILE to DEST on HOST

Since we can't actually use scp without a password, we have to fake
this by copying the file to /data/transfer as you, then moving it to
the destination."

  ;; This will fail if destination isn't writeable
  (scp file host "/data/transfer/")
  (let* ((filename (file-namestring file))
	 (tempfile (format nil "/data/transfer/~a" filename))
	 (force-option (if force "-f" ""))
	 (mv-cmd (format nil "sudo -u perforce mv ~a ~a ~a " force-option tempfile dest)))
    (ssh host (format nil "sudo chown perforce:perforce ~a" tempfile))
    (when mode
      (ssh host (format nil "sudo -u perforce chmod ~a ~a" mode tempfile)))
    (ssh host mv-cmd)))

;; (p4scp "D:/perforce-admin/triggers/check_client_view.py" "dvp4edgepl016" "/data/perforce/test-commit/root/triggers/" 555)
    
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

;; LS in server home
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


;; p4 info
(defun p4-info (&optional port)
  "Run p4 info on PORT or default port if none provided."
  (let* ((port-arg (when port
		    (list "-p" (format nil "~a" port))))
	 (string (with-output-to-string (str) 
		   (sb-ext:run-program "p4" (append port-arg (list "info"))
				       :search t
				       :wait t
				       :output str))))
    string))

;; Check brokers
(defun check-brokers (n)
  "Run 'p4 info' on each of the broker ports for server N"
  (let* ((p (aref *p4-servers* n))
	 (host (p4-server-host p))
	 (brokers (p4-server-brokers p)))
    (mapcar (lambda (port)
	      (let ((port (format nil "~a:~a" host port)))
		(cons port (p4-info port))))
	    brokers)))

;; Check server
(defun check-server (n)
  "Run 'p4 info' on the server port (21667) for N"
  (let* ((p (aref *p4-servers* n))
	 (host (p4-server-host p))
	 (port (format nil "~a:21667" host)))
    (cons port (p4-info port))))

;; A mapping function
(defun map-servers (f)
  "Call F on all perforce servers and  collect results in list"
  (loop
     for i below (length *p4-servers*)
     when (not (numberp (aref *p4-servers* i)))
     collect (funcall f i)))

;; Show server summary
(defun show (n)
  "Describe the server number N"
  (let ((p (aref *p4-servers* n)))
    (princ p)
    nil))
