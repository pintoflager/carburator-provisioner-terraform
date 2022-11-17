###
# Local variables for main.tf.
#
locals {
  randl  = setproduct(range(length(var.servers)), var.locations)
}
