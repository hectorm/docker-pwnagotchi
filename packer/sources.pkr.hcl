source "arm-image" "raspbian" {
  image_type = "raspberrypi"

  iso_url = "https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2020-02-07/2020-02-05-raspbian-buster-lite.zip"
  iso_checksum = "7ed5a6c1b00a2a2ab5716ffa51354547bb1b5a6d5bcb8c996b239f9ecd25292b"
  iso_checksum_type = "sha256"

  qemu_binary = "qemu-arm-static"
  qemu_args = ["-cpu", "arm1176", "-E", "LANG=en_US.UTF-8", "-E", "LC_ALL=en_US.UTF-8"]

  output_filename = "raspbian.img"
  target_image_size = 4294967296
}
