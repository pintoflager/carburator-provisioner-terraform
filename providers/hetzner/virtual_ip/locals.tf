###
# Local variables for main.tf.
#
locals {
  location_opts  = ["nbg1", "fsn1", "hel1"]
  randl  = setproduct(range(length(var.vip_v4) + length(var.vip_v6)), local.location_opts)
}
