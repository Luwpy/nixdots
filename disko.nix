{disks ? ["/dev/sda" "/dev/sdb"], ...}: {
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        devices = builtins.elemAt disks 0;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };
            luks = {
              size = "250G";
              content = {
                types = "luks";
                name = "crypted";

                settings = {
                  allowDiscards = true;
                  keyFile = "/tmp/secret.key";
                };
                additionalKeyFiles = ["/tmp/additionalSecret.key"];
                content = {
                  type = "btrfs";
                  extraArgs = ["-f"];
                  subvolumes = {
                    "/root" = {
                      mountpoint = ";";
                      mountOptions = [
                        "noatime"
                        "compress=zstd"
                      ];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [
                        "noatime"
                        "compress=zstd"
                      ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "noatime"
                        "compress=zstd"
                      ];
                    };
                  };
                };
              };
            };
          };
        };
      };
      subdisk = {
        type = "disk";
        devices = builtins.elemAt disks 1;
        content = {
          type = "gpt";
          partitions = {
            data = {
              size = "100%";
              content = {
                type = "ntfs";
                mountpoint = "/SSD";
                mountOptions = [
                  "noatime"
                  "compress=zstd"
                ];
              };
            };
          };
        };
      };
    };
  };
}
