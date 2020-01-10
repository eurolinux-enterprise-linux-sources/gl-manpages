%global codate 20130122

Name:           gl-manpages
Version:        1.1
Release:        7.%{codate}%{?dist}
Summary:        OpenGL manpages

License:        MIT and Open Publication
URL:            http://www.opengl.org/wiki/Getting_started/XML_Toolchain_and_Man_Pages
# see Source1
Source0:        gl-manpages-%{version}-%{codate}.tar.xz
Source1:        make-gl-man-snapshot.sh
# FIXME: Bundle mathml and the Oasis dbmathl until they are packaged
Source2:        http://www.oasis-open.org/docbook/xml/mathml/1.1CR1/dbmathml.dtd
Source3:        http://www.w3.org/Math/DTD/mathml2.tgz
# FIXME  These are the old gl-manpages source which 
# still have some manpages that khronos doesn't. 
# Ship until somebody in the know helps figuring whats what.
# When matching install the kronos version.
Source4:        gl-manpages-1.0.1.tar.bz2
#Silence author/version/manual etc. warnings
Source5:        metainfo.xsl

BuildArch:      noarch

BuildRequires:  libxslt docbook-style-xsl

%description
OpenGL manpages

%prep
%setup -q -n %{name}-%{version}-%{codate}
tar xzf %{SOURCE3}
cp -av %{SOURCE2} mathml2/
tar xjf %{SOURCE4}


%build
# FIXME Figure out how to build the GLSL manpages
export BD=`pwd`
xmlcatalog --create --noout \
	--add public "-//W3C//DTD MathML 2.0//EN" "file://$BD/mathml2/mathml2.dtd" \
	--add system "http://www.w3.org/TR/MathML2/dtd/mathml2.dtd" "file://$BD/mathml2/mathml2.dtd" \
	--add public "-//OASIS//DTD DocBook MathML Module V1.1b1//EN" "file://$BD/mathml2/dbmathml.dtd" \
	--add system "http://www.oasis-open.org/docbook/xml/mathml/1.1CR1/dbmathml.dtd" "file://$BD/mathml2/dbmathml.dtd" \
	mathml2.cat
export XML_CATALOG_FILES="$BD/mathml2.cat /etc/xml/catalog"
for MAN in man4 man3 man2 ; do
	pushd $MAN
	for MANP in gl*.xml ; do
		xsltproc --nonet %{SOURCE5} $MANP | xsltproc --nonet /usr/share/sgml/docbook/xsl-stylesheets/manpages/docbook.xsl -
	done
	popd
done


%install
mkdir -p $RPM_BUILD_ROOT%{_mandir}/man3/
cp -n {man4,man3,man2}/*.3G $RPM_BUILD_ROOT%{_mandir}/man3/
# install the old manpages source with 3gl -> 3G
# when matchin don't clobber the khronos version
for MANP in `find gl-manpages-1.0.1 -name *.3gl` ; do
	FN=${MANP//*\//}
	cp -a -n $MANP $RPM_BUILD_ROOT%{_mandir}/man3/${FN/.3gl/.3G}
done
find $RPM_BUILD_ROOT%{_mandir}/man3/ -type f -size -100b | xargs sed -i -e 's/\.3gl/\.3G/' -e 's,^\.so man3G/,.so man3/,'


%files
%{_mandir}/man3/*


%changelog
* Fri Dec 27 2013 Daniel Mach <dmach@redhat.com> - 1.1-7.20130122
- Mass rebuild 2013-12-27

* Wed Feb 13 2013 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.1-6.20130122
- Rebuilt for https://fedoraproject.org/wiki/Fedora_19_Mass_Rebuild

* Tue Jan 22 2013 Yanko Kaneti <yaneti@declera.com> - 1.1-5.%{codate}
- Newer upstream snapshot. Minor upstream rearrangement.
- Remove checkout script from sources and add to git.
- Try to actually use the bundled mathml2. Fix warnings.

* Wed Jan 16 2013 Yanko Kaneti <yaneti@declera.com> - 1.1-4.%{codate}
- Fix symlinked man references some more (#895986) 

* Mon Oct 15 2012 Yanko Kaneti <yaneti@declera.com> - 1.1-3.%{codate}
- Fix symlinked man variants. 
- Preserve timestamps on the older gl-manpages.

* Tue Oct  9 2012 Yanko Kaneti <yaneti@declera.com> - 1.1-2.%{codate}
- Re-add the older gl-manpages for those not present in khronos

* Tue Oct  9 2012 Yanko Kaneti <yaneti@declera.com> - 1.1-1.%{codate}
- Try building from source

* Wed Sep  5 2012 Yanko Kaneti <yaneti@declera.com> - 1.0.1-1
- Initial split from mesa
