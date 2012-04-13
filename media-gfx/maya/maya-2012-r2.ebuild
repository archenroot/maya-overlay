# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: Maya-2012 for amd64$

inherit rpm eutils

EAPI="4"
IUSE="bundled-libs openmotif"

S="${WORKDIR}"

DESCRIPTION="Autodesk's Maya. Commercial modeling and animation package"
HOMEPAGE="http://usa.autodesk.com/maya/"
SRC_URI="autodesk_maya_2012_english_linux_64bit2.tgz"
RESTRICT="fetch nouserpriv"
SLOT="2012"
LICENSE="maya-12.0"
KEYWORDS="~amd64"

# Needed for install
DEPEND="app-arch/rpm2targz app-arch/tar"

# MayaPy needs at least this to work:
RDEPEND="app-shells/tcsh media-libs/libpng:1.2 dev-lang/python
	x11-libs/libXinerama x11-libs/libXrender media-libs/fontconfig"

# The ./setup program needs these two libs to work
RDEPEND="${RDEPEND} x11-libs/libXrandr x11-libs/libXft"


# Stuff I'm not sure about
RDEPEND="${RDEPEND}
	x11-libs/libxcb app-admin/gamin dev-libs/libgamin
	media-libs/libquicktime media-libs/audiofile
	sys-libs/e2fsprogs-libs media-libs/openal

	amd64? (
		!bundled-libs? ( x11-libs/libXpm x11-libs/libXmu x11-libs/libXt
			x11-libs/libXp x11-libs/libXi x11-libs/libXext x11-libs/libX11
			x11-libs/libXau x11-libs/libxcb )
		bundled-libs? (	app-emulation/emul-linux-x86-xlibs )
			bundled-libs? ( app-emulation/emul-linux-x86-baselibs )
			bundled-libs? (	app-emulation/emul-linux-x86-qtlibs )
			openmotif? ( x11-libs/openmotif ) ) "

MAYADIR="/opt/Autodesk"

pkg_nofetch() {
	einfo "This ebuild expects that you place the file ${SRC_URI} in /usr/portage/distfiles"
}

src_unpack() {
	unpack ${A}

	# Unpack of RPM files
	rpm2tar adlmapps4-4.0.35-0.x86_64.rpm -O | tar -x
	assert "Failed to unpack adlmapps4-4.0.35-0.x86_64.rpm"

	rpm2tar adlmflexnetclient-4.0.35-0.x86_64.rpm -O | tar -x
	assert "Failed to unpack adlmflexnetclient-4.0.35-0.x86_64.rpm"

	rpm2tar adlmflexnetserver-4.0.35-0.x86_64.rpm -O | tar -x
	assert "Failed to adlmflexnetserver-4.0.35-0.x86_64.rpm"

	rpm2tar Maya2012_0_64-2012.0-499.x86_64.rpm -O | tar -x
	assert "Failed to unpack Maya2012_0_64-2012.0-499.x86_64.rpm"
}

src_install() {
	# Copy the unpacked things to to the build directory
	cp -pPR ./usr ./var ./opt ${D} || die

	# Linking party! \:D/
	mkdir -p ${D}usr/lib64/ ${D}usr/lib/
	ln -s libtiff.so   ${D}usr/lib/libtiff.so.3
	ln -s libssl.so    ${D}usr/lib64/libssl.so.6
	ln -s libcrypto.so ${D}usr/lib64/libcrypto.so.6

	mkdir -p ${D}usr/bin/
	ln -s /usr/autodesk/maya2012-x64/bin/maya2012 ${D}usr/bin/maya
	ln -s /usr/autodesk/maya2012-x64/bin/Render   ${D}usr/bin/Render
	ln -s /usr/autodesk/maya2012-x64/bin/fcheck   ${D}usr/bin/fcheck
	ln -s /usr/autodesk/maya2012-x64/bin/imgcvt   ${D}usr/bin/imgcvt

	ln -s maya2012-x64 ${D}usr/autodesk/maya

	# For those of you who want an icon
	mkdir -p ${D}usr/share/applications/
	mkdir -p ${D}usr/share/icons/hicolor/48x48/apps/
	ln -s /usr/autodesk/maya2012-x64/desktop/Autodesk-Maya.desktop ${D}usr/share/applications/Autodesk-Maya.desktop
	ln -s /usr/autodesk/maya2012-x64/desktop/Maya.png              ${D}usr/share/icons/hicolor/48x48/apps/Maya.png

	# Flex License Management needs this folder to work
	mkdir -p ${D}var/flexlm/
	chmod ugo+w ${D}var/flexlm/
	touch ${D}var/flexlm/maya.lic

	# Mental Ray needs it's own temporary directory
	mkdir ${D}usr/tmp
	chmod ugo+w ${D}usr/tmp
}

pkg_postinst() {
	einfo "To activate your license you must follow these steps:"
	einfo
	einfo
	einfo "Doublecheck this file: /usr/autodesk/maya2012-x64/bin/License.env"
	einfo " # echo 'MAYA_LICENSE=unlimited'      >  /usr/autodesk/maya2012-x64/bin/License.env"
	einfo " # echo 'MAYA_LICENSE_METHOD=network' >> /usr/autodesk/maya2012-x64/bin/License.env"
	einfo
	einfo
	einfo "And then you need to run this as root to activate your license:"
	einfo " # LD_LIBRARY_PATH=/opt/Autodesk/Adlm/R4/lib64 /usr/autodesk/maya2012-x64/bin/adlmreg -i S 657D1 657D1 2012.0.0.F <your serial number> /var/opt/Autodesk/Adlm/Maya2012/MayaConfig.pit"
	einfo
	einfo
	einfo "If you have a network license you need to do this:"
	einfo " # echo 'SERVER <servername> 0' >  /var/flexlm/maya.lic"
	einfo " # echo 'USE_SERVER'            >> /var/flexlm/maya.lic"
	einfo
	einfo
	einfo "You might need to run the setup as root by hand even after this to make license things work..."
	einfo " # mkdir ~/maya; cd ~/maya; cp /usr/portage/distfiles/${SRC_URI} .; tar -xf ${SRC_URI}; ./setup; cd ~; rm -rf ~/maya"
	einfo "It *seems to not matter* if the rpm install fails, it alter files somewhere that makes licenses to work. Correct me on this?"
	einfo
	einfo
	einfo "The file: /var/opt/Autodesk/Adlm/.config/ProductInformation.pit shuld be possible to pass around between computers for shared licenses. I don't know what it does."
	einfo "The file: /var/opt/Autodesk/Adlm/Maya2012/install.env seems to be created by the ./setup program and contains the license info, I don't know if that's whats needed to get license running without running ./setup program"
}

