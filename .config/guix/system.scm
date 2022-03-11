(use-modules (gnu)
	     (nongnu packages linux)
	     (gnu services security-token)
	     (gnu packages lisp))
(use-service-modules
  cups
  desktop
  networking
  ssh
  xorg)
(use-package-modules wm fonts)

(define %slip-fido2-rule
  (udev-rule
   "90-slip-fido2.rules"
   (string-append "KERNEL==\"hidraw*\", SUBSYSTEM==\"hidraw\", ATTRS{idProduct}==\"0407\", GROUP=\"plugdev\", ATTRS{idVendor}==\"1050\" TAG+=\"uaccess\"" "\n")))

(operating-system
 (kernel linux)
 (firmware (list linux-firmware))
  (locale "en_CA.utf8")
  (timezone "America/Toronto")
  (keyboard-layout (keyboard-layout "us,ru" #:options '("ctrl:swapcaps" "grp:alt_shift_toggle")))
  (host-name "guix")
  (users (cons* (user-account
                  (name "slip")
                  (comment "Michael Esch")
                  (group "users")
                  (home-directory "/home/slip")
                  (supplementary-groups
                    '("wheel" "netdev" "audio" "video" "plugdev")))
                %base-user-accounts))
  (packages
    (append
      (list (specification->package "emacs")
            (specification->package "emacs-exwm")
            (specification->package
             "emacs-desktop-environment")
	    (specification->package "pcsc-lite")
	    (specification->package "gnupg")
	    (specification->package "libu2f-host")
	    (specification->package "libfido2")
            (specification->package "nss-certs"))
      (list sbcl stumpwm `(,stumpwm "lib") sbcl-stumpwm-ttf-fonts sbcl-stumpwm-pass font-dejavu)
      %base-packages))
  (services
    (append
     (list (service gnome-desktop-service-type)
	   (service openssh-service-type)
	   (service pcscd-service-type)
	   (udev-rules-service 'u2f %slip-fido2-rule #:groups '("plugdev"))
            (set-xorg-configuration
              (xorg-configuration
                (keyboard-layout keyboard-layout))))
      %desktop-services))
  (bootloader
    (bootloader-configuration
      (bootloader grub-efi-bootloader)
      (targets (list "/boot/efi"))
      (keyboard-layout keyboard-layout)))
  (mapped-devices
    (list (mapped-device
            (source
              (uuid "1bcbdd01-83e4-495a-90fd-cb117c8203c7"))
            (target "cryptroot")
            (type luks-device-mapping))))
  (file-systems
    (cons* (file-system
             (mount-point "/boot/efi")
             (device (uuid "DC6A-778A" 'fat32))
             (type "vfat"))
           (file-system
             (mount-point "/")
             (device "/dev/mapper/cryptroot")
             (type "ext4")
             (dependencies mapped-devices))
           %base-file-systems)))
