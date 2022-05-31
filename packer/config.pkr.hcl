packer {
  required_plugins {
    arm-image = {
      version = ">= 0.2.6"
      source  = "github.com/solo-io/arm-image"
    }
  }
}
