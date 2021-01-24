source "arm-image" "arm64" {
  image_type = "raspberrypi"

  iso_url = "https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2020-08-24/2020-08-20-raspios-buster-arm64-lite.zip"
  iso_checksum = "file:https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2020-08-24/2020-08-20-raspios-buster-arm64-lite.zip.sha256"

  qemu_binary = "qemu-aarch64-static"
  qemu_args = ["-cpu", "cortex-a72"]

  output_filename = "./dist/arm64/pwnagotchi.img"
  target_image_size = 6442450944
}

source "arm-image" "armhf" {
  image_type = "raspberrypi"

  iso_url = "https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-01-12/2021-01-11-raspios-buster-armhf-lite.zip"
  iso_checksum = "file:https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-01-12/2021-01-11-raspios-buster-armhf-lite.zip.sha256"

  qemu_binary = "qemu-arm-static"
  qemu_args = ["-cpu", "arm1176"]

  output_filename = "./dist/armhf/pwnagotchi.img"
  target_image_size = 6442450944
}
