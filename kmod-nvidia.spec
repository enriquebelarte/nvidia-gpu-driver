# Named version, usually just the driver version, or "latest"
%define _named_version 525.125.06 

# Distribution name, like .el8 or .el8_1
%define kmod_dist .el8

# Fields that are specific to the version build
%define kmod_driver_version	525.125.06
%define kmod_kernel	        5.14.0	
%define kmod_kernel_release	284.40.1
%define epoch			1
%define arch			x86_64

%define kmod_kernel_version	%{kmod_kernel}-%{kmod_kernel_release}%{kmod_dist}
%define kmod_module_path	/lib/modules/%{kmod_kernel_version}.%{_target_cpu}/extra/drivers/video/nvidia
%define kmod_modules		nvidia nvidia-uvm nvidia-modeset nvidia-drm nvidia-peermem

%define debug_package %{nil}
%define sbindir %( if [ -d "/sbin" -a \! -h "/sbin" ]; then echo "/sbin"; else echo %{_sbindir}; fi )

Source0:	kmod-nvidia-%{kmod_driver_version}-%{arch}.tar.xz

Name:		kmod-nvidia-%{kmod_driver_version}-%{kmod_kernel}-%{kmod_kernel_release}
Version:	%{kmod_driver_version}
Release:	1%{kmod_dist}
Summary:	NVIDIA graphics driver
Group:		System/Kernel
License:	Nvidia
URL:		http://www.nvidia.com/
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildRequires:	elfutils-libelf-devel
BuildRequires:	kernel-devel >= %kmod_kernel_version
BuildRequires:	openssl
BuildRequires:	redhat-rpm-config
ExclusiveArch:	x86_64 ppc64le aarch64

Provides:	kernel-modules = %kmod_kernel_version.%{_target_cpu}
# Meta-provides for all nvidia kernel modules. The precompiled version and the
# DKMS kernel module package both provide this and the driver package only needs
# one of them to satisfy the dependency.
Provides:	kmod-nvidia = %{?epoch:%{epoch}:}%{kmod_driver_version}

Supplements:	(nvidia-driver = %{epoch}:%{kmod_driver_version} and kernel = %{kmod_kernel_version})
Requires:	(kernel >= %{kmod_kernel_version} if kernel)
Conflicts:	kmod-nvidia-latest-dkms

%description
The NVIDIA %{kmod_driver_version} display driver kernel module for kernel %{kmod_kernel_version}

%prep
%setup -q -n kmod-nvidia-%{kmod_driver_version}-%{arch} 

%build
# A proper kernel module build uses /lib/modules/KVER/{source,build} respectively,
# but that creates a dependency on the 'kernel' package since those directories are
# not provided by kernel-devel. Both /source and /build in the mentioned directory
# just link to the sources directory in /usr/src however, which ddiskit defines
# as kmod_kernel_source.
KERNEL_SOURCES=/usr/src/kernels/%{kmod_kernel_version}.%{_arch}
KERNEL_OUTPUT=/usr/src/kernels/%{kmod_kernel_version}.%{_arch}
#KERNEL_SOURCES=/lib/modules/%{kmod_kernel_version}.%{_target_cpu}/source/
#KERNEL_OUTPUT=/lib/modules/%{kmod_kernel_version}.%{_target_cpu}/build

# Compile kernel modules
%{make_build} SYSSRC=${KERNEL_SOURCES} SYSOUT=${KERNEL_OUTPUT} modules

%post
depmod -a %{kmod_kernel_version}.%{_arch}

%postun
depmod -a %{kmod_kernel_version}.%{_arch}

%install
mkdir -p %{buildroot}/%{kmod_module_path}
for m in %{kmod_modules}; do
        install kernel-open/${m}.ko %{buildroot}/%{kmod_module_path}
done

%files
%defattr(644,root,root,755)
%{kmod_module_path}

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Fri Oct 19 2022 Fabien Dupont <fdupont@redhat.com>
- Trim the spec for Open GPU

* Wed Jul 07 2021 Kevin Mittman <kmittman@nvidia.com>
 - Add two-pass HSM certificate signing flow

* Tue Apr 27 2021 Kevin Mittman <kmittman@nvidia.com>
 - Unofficial support for ppc64le and aarch64

* Wed Mar 31 2021 Kevin Mittman <kmittman@nvidia.com>
 - Kernels version 5.10+ rename modules-common.lds to modules.lds

* Mon Feb 08 2021 Kevin Mittman <kmittman@nvidia.com>
 - Add nvidia-peermem module

* Wed Oct 21 2020 Kevin Mittman <kmittman@nvidia.com>
 - Include architecture in depmod command

* Fri Oct 09 2020 Kevin Mittman <kmittman@nvidia.com>
 - Run depmod for target kernel version, not running kernel

* Thu May 07 2020 Timm Bäder <tbaeder@redhat.com>
 - List generated files as %%ghost files
 - Only require the kernel if any kernel is installed

* Thu Apr 30 2020 Kevin Mittman <kmittman@nvidia.com>
 - Unique ld.gold filename

* Tue Apr 28 2020 Timm Bäder <tbaeder@redhat.com>
 - Removed unused kmod_rpm_release variable
 - Fix kernel_dist fallback to %%{dist}
 - Remove -m elf_x86_64 argument from linker invocations
 - Add /usr/bin/strip requirement for %%post scriptlet
 - Conflict with kmod-nvidia-latest-dkms, not dkms-nvidia

* Fri Dec 06 2019 Kevin Mittman <kmittman@nvidia.com>
 - Pass %{kernel_dist} as it may not match the system %{dist}

* Fri Jun 07 2019 Kevin Mittman <kmittman@nvidia.com>
 - Rename package, Change Requires, Remove %ghost

* Fri May 24 2019 Kevin Mittman <kmittman@nvidia.com>
 - Fixes for yum swap including %ghost and removal of postun actions

* Fri May 17 2019 Kevin Mittman <kmittman@nvidia.com>
 - Change Requires: s/nvidia-driver/nvidia-driver-%{driver_branch}/

* Fri Apr 12 2019 Kevin Mittman <kmittman@nvidia.com>
 - Change to kmod-nvidia-branch-AAA-X.XX.X-YYY.Y.Y.rAAA.BB.BB.el7.arch.rpm

* Mon Mar 11 2019 Kevin Mittman <kmittman@nvidia.com>
 - Remove %{_name_version} from Requires and Supplments

* Fri Mar 08 2019 Kevin Mittman <kmittman@nvidia.com>
 - Change from kmod-nvidia-branch-XXX-Y.YY.Y-YYYY.1.el7..rpm to kmod-nvidia-XXX.XX.XX-Y.YY.Y-YYY.el7..rpm

* Thu Mar 07 2019 Kevin Mittman <kmittman@nvidia.com>
 - Initial .spec from Timm Bäder

