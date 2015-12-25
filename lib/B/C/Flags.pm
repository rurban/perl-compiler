# written by B::C Makefile.PL. $extra_{cflags,libs} need a leading space if used.
package B::C::Flags;

$VERSION = '5.022005';
$B::C::REVISION = '-3510-gd172f83';

# -fav-init optimization
$have_independent_comalloc = 0;
$use_declare_independent_comalloc = 0;

# use extra compiler flags, after ccopts, resp. ldopts
$extra_cflags = "";
$extra_libs = "";
@deps = qw( AnyDBM_File B B::AV B::BINOP B::BM B::C B::C::Debug B::C::Debug::Walker B::C::Decimal B::C::File B::C::Flags B::C::HV B::C::Helpers B::C::Helpers::Symtable B::C::InitSection B::C::Optimizer B::C::Optimizer::DynaLoader B::C::Optimizer::ForceHeavy B::C::Optimizer::UnusedPackages B::C::OverLoad B::C::Packages B::C::Save B::C::Save::Hek B::C::Save::Signals B::C::Section B::C::Setup B::C::Setup::Debug B::COP B::CV B::FAKEOP B::FM B::Flags B::GV B::HE B::HV B::INVLIST B::IO B::IV B::LEXWARN B::LISTOP B::LOGOP B::LOOP B::MAGIC B::METHOP B::NULL B::NV B::OBJECT B::OP B::PADLIST B::PADNAME B::PADNAMELIST B::PADOP B::PMOP B::PV B::PVIV B::PVLV B::PVMG B::PVNV B::PVOP B::REGEXP B::RHE B::RV B::SPECIAL B::STASHGV B::SV B::SVOP B::Section B::UNOP B::UNOP_AUX B::UV CORE CORE::GLOBAL Carp Config DB DynaLoader EV Encode Errno Exporter Exporter::Heavy ExtUtils ExtUtils::Constant ExtUtils::Constant::ProxySubs Fcntl FileHandle IO IO::File IO::Handle IO::Poll IO::Seekable IO::Socket IO::Socket::SSL Internals Net Net::DNS O POSIX PerlIO PerlIO::Layer PerlIO::scalar Regexp SV SelectSaver Symbol UNIVERSAL XSLoader __ANON__ arybase arybase::mg constant main mro parent re strict threads utf8 vars version warnings warnings::register );

our %Config = (
  'archname' => 'i386-linux-64int',
  'cc' => '/usr/bin/gcc',
  'ccflags' => '-DPERL_DISABLE_PMC -I/usr/local/cpanel/3rdparty/perl/522/include -L/usr/local/cpanel/3rdparty/perl/522/lib -I/usr/local/cpanel/3rdparty/include -L/usr/local/cpanel/3rdparty/lib -fwrapv -fno-strict-aliasing -pipe -fstack-protector -I/usr/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -D_FORTIFY_SOURCE=2',
  'd_c99_variadic_macros' => 'define',
  'd_dlopen' => 'define',
  'd_isinf' => 'define',
  'd_isnan' => 'define',
  'd_longdbl' => 'define',
  'dlext' => 'so',
  'i_dlfcn' => 'define',
  'ivdformat' => '"Ld"',
  'ivsize' => '8',
  'longsize' => '4',
  'mad' => undef,
  'nvgformat' => '"g"',
  'ptrsize' => '4',
  'static_ext' => ' ',
  'usecperl' => undef,
  'usedl' => 'define',
  'useithreads' => undef,
  'uselongdouble' => undef,
  'usemultiplicity' => undef,
  'usemymalloc' => 'n',
  'uvuformat' => '"Lu"'
);

# make it a restricted hash
1;
