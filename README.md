# Overview

External resources base image with CDKTF. This image is not intended to be used directly by final modules, it should be used as a base for a more specific images with a target provider. e.g: er-base-cdktf-aws.

Using common images on modules using the same provider saves a ton of bandwith by reeducing the number of required layers.
