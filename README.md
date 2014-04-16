# OpenCrowbar Build Tools

Opencrowbar Build Toolset consists of tools that can be used to:

## Create RPM Packages
OpenCrowbar will be shipped via OS platform targetted RPM
packages. Where necessary additional RPM packages of dependencies may
also need to be made available. This document provides an overview of
the scripts and tools that can be used to meet these needs.


### OpenCrowbar Packages
OpenCrowbar is being shipped in the following component parts:

  1. The *OpenCrowbar* _*core*_ RPM package - this is an essential package

  1. **Add-On workload packages including:**
    1. __Ceph__ - The distributed file system workload
    1. __Hadoop__ - The Distributed Object Storage workload
    1. __Hardware__ - The RAID and BIOS toolset workload
    1. __Openstack__ - The Cloud compute workload

  1. Ancilliary Packages
    1. Build-Tools - The tools used to produce all RPM packages
    1. Crowbar-Utils - The Docker Developer-fiendly toolset
    1. An example pattern for workload creation


### RPM Packages of Dependencies
At this time CentOS/RHEL 6.5 does not provide a suitable ruby-2.0.0
RPM package. This build-tools repo provides a means of building this
RPM package suite.


## Produce OpenCrowbar Releases
The toolset that is used for continuous production of OpenCrowbar RPM
packages can be used to generate final release RPM packages.
