source "arm-image" "raspbian" {
  image_type = "raspberrypi"

  iso_url = "https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2020-02-14/2020-02-13-raspbian-buster-lite.zip"
  iso_checksum = "12ae6e17bf95b6ba83beca61e7394e7411b45eba7e6a520f434b0748ea7370e8"
  iso_checksum_type = "sha256"

  qemu_binary = "qemu-arm-static"
  qemu_args = ["-cpu", "arm1176", "-E", "LANG=en_US.UTF-8", "-E", "LC_ALL=en_US.UTF-8"]

  output_filename = "raspbian.img"
  target_image_size = 4294967296
}
