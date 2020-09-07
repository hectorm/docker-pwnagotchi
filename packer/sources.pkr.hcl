source "arm-image" "raspios" {
  image_type = "raspberrypi"

  iso_url = "https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2020-08-24/2020-08-20-raspios-buster-armhf-lite.zip"
  iso_checksum = "file:https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2020-08-24/2020-08-20-raspios-buster-armhf-lite.zip.sha256"

  qemu_binary = "qemu-arm-static"
  qemu_args = ["-cpu", "arm1176"]

  output_filename = "./dist/pwnagotchi.img"
  target_image_size = 4294967296
}
