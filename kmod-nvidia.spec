%global _build_id_links none
# Named version, usually just the driver version, or "latest"
%define _named_version 535.43.16 

# Distribution name, like .el8 or .el8_1
%define kmod_dist %{?kernel_dist}%{?!kernel_dist:%{dist}}


# Fields that are specific to the version build
%define kmod_driver_version	535.43.16
%define kmod_kernel		5.14.0
%define kmod_kernel_release	284.40.1
%define epoch			1

%define kmod_kernel_version	%{kmod_kernel}-%{kmod_kernel_release}%{kmod_dist}
%define kmod_module_path	/lib/modules/%{kmod_kernel_version}.%{_target_cpu}/extra/drivers/video/nvidia
%define kmod_modules		nvidia nvidia-uvm nvidia-modeset nvidia-drm nvidia-peermem

%define debug_package %{nil}
%define sbindir %( if [ -d "/sbin" -a \! -h "/sbin" ]; then echo "/sbin"; else echo %{_sbindir}; fi )

Source0:	nvidia-kmod-%{kmod_driver_version}-x86_64.tar.xz
#Source0:	${CI_ARCHIVE_KMOD_NVIDIA}

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
%setup -q -n nvidia-kmod-%{kmod_driver_version}-%{_arch}

%build
pwd
ls -l 
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
* Fri Nov  24 2023 Enrique Belarte <enriquebelarte@redhat.com> - 0.0.1
- First test version 
