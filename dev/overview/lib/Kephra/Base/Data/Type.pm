use v5.20;
use warnings;

# KBOS store for standard data type checker objects, + added by owners + dep resolver +
# serialize keys: check, shortcut, default, file, package

package Kephra::Base::Data::Type;
our $VERSION = 0.1;

use Kephra::Base::Data::Type::Simple;
use Kephra::Base::Data::Type::Parametric;
use Kephra::Base::Data::Type::Standard;


1;
